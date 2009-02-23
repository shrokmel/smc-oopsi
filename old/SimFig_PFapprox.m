function [Sim, P, R, B, S, O]  = SimFig_PFapprox
% this file sets the parameters and does the simulation for making the
% schematic fig.  stimulus is a sinusoid. It generates the following:
%
% Sim:  simulation parameters
% P:    parameters of "real" neuron
% R:    "real" neuron data      (smc_em_bern_real_exp)
% S:    simulation states       (smc_em_bern_FoBaMo)
% M:    moments                 (smc_em_bern_FoBaMo)
% fig:  see fig file for details(GetSchemFig1)

%% set simulation parameters
Sim.dt      = 0.005;            %time step size (sec)
Sim.Nsec    = 0.65;             %# of sec
Sim.N       = 100;              %total number of particles
Sim.M       = 1;                %number of spike history terms
Sim.freq    = 5;                %frequency of observations
Sim.van     = false;

%% make code prettier
Sim.T       = Sim.Nsec/Sim.dt;  %total # of steps
Sim.T_o     = Sim.T/Sim.freq;   %number of observations
Sim.tvec    = 0:Sim.dt:Sim.Nsec-Sim.dt; %time vector

%% generate stimulus
Sim.x       = ones(1,Sim.T);

%% set "real" parameters
P.k         = 5;                %bias term
P.tau_c     = .5;              %decay rate of calcium
P.beta      = 1;                %jump size of calcium after spike
P.sigma_c   = .1;               %std of noise on calcium
P.sigma_o   = 20*sqrt(P.sigma_c^2*Sim.dt);%std of noise on observations

P.omega     = 0;                %jump size for h after spike
P.tau_h     = 1;                %decay rate for spike history terms
P.sigma_h   = 0.01;             %std of noise on spike history terms

%% get "real" data
R.n         = zeros(1,Sim.T);   %spike times
R.C         = zeros(1,Sim.T);   %initialize calcium
epsilon_c   = P.sigma_c*sqrt(Sim.dt)*randn(1,Sim.T);%generate noise on calcium

for t=2:Sim.T                   %update calcium
    R.C(t)  = (1-Sim.dt/P.tau_c)*R.C(t-1) + P.beta*R.n(t) + epsilon_c(t);
end
R.O = R.C + P.sigma_o*randn(1,Sim.T);%add noise to observations


%% makes code prettier :-)
B.sig2_c    = P.sigma_c^2*Sim.dt;
B.sig2_o    = P.sigma_o^2;
B.a         = 1-Sim.dt/P.tau_c;
B.beta      = P.beta;
B.kx        = P.k'*Sim.x;
if Sim.M>0
    B.sig2_h    = P.sigma_h.^2*Sim.dt;
    B.g         = 1-Sim.dt/P.tau_h;
    B.omega     = P.omega;
end

S.p         = zeros(Sim.N,Sim.T);               %extize rate
S.w_f       = 1/Sim.N*ones(Sim.N,Sim.T);        %extize forward weights

% if spike histories
if Sim.M>0
    S.h         = zeros(Sim.N,Sim.T,Sim.M);     %extize spike history terms
    epsilon_h   = zeros(Sim.N, Sim.T, Sim.M);   %generate noise on h
    for m=1:Sim.M                               %add noise to each h
        epsilon_h(:,:,m)   = sqrt(B.sig2_h(m))*randn(Sim.N,Sim.T);
    end
    % if not, comput P[n_t] for all t
else
    S.p         = repmat(1-exp(-exp(B.kx)*Sim.dt)',Sim.N,1);
end

% extize stuff needed for REAL backwards sampling
O.p_o       = zeros(2^(Sim.freq-1),Sim.freq);                %extize backwards mean
O.mu_o      = zeros(2^(Sim.freq-1),Sim.freq);                %extize backwards mean
O.sig2_o    = zeros(1,Sim.freq);                %extize backwards variance

O.p         = zeros(Sim.freq,Sim.freq);
O.mu        = zeros(Sim.freq,Sim.freq);
O.sig2      = zeros(Sim.freq,Sim.freq);

% initialize backwards distributions
s              = Sim.freq;
O.p_o(1,s)     = 1;
O.mu_o(1,s)    = R.O(s);                      %initialize mean of P[O_s | C_s]
O.sig2_o(s)    = B.sig2_o;                     %initialize var of P[O_s | C_s]

O.p(1,s)     = 1;
O.mu(1,s)    = R.O(s);                      %initialize mean of P[O_s | C_s]
O.sig2(s)    = B.sig2_o;                     %initialize var of P[O_s | C_s]

for tt=s:-1:2
    spikemat(:,tt-1)            = repmat([repmat(0,1,2^(s-tt)) repmat(1,1,2^(s-tt))],1,2^(tt-2))';
end
nspikes=sum(spikemat')';

for n=0:Sim.freq-1
    ninds{n+1}= find(nspikes==n);
    lenn(n+1) = length(ninds{n+1});
end

for n=0:Sim.freq-1
    tempinds=find(nspikes==n);
    len=length(tempinds);
    ninds2(n+1,1:len)=tempinds;
    leninds(n+1)=len;
end

O               = UpdateMoments(Sim,R,B,S,O,s);%recurse back to get P[O_s | C_s] before the first observation

%% update moments function
    function O = UpdateMoments(Sim,R,B,S,O,t)

        s               = Sim.freq;                     %find next observation time
        O.mu_o(1,s)       = R.O(t+s);                     %initialize mean of P[O_s | C_s]
        O.sig2_o(s)     = B.sig2_o;                     %initialize var of P[O_s | C_s]

        O.mu(1,s)       = R.O(t+s);                     %initialize mean of P[O_s | C_s]
        O.sig2(s)     = B.sig2_o;                     %initialize var of P[O_s | C_s]

        if Sim.M>0
            hhat        = zeros(Sim.freq,Sim.M);        %extize hhat
            phat        = zeros(1,Sim.freq+1);          %extize phat

            hs          = S.h(:,t,:);                   %this is required for matlab to handle a m-by-n-by-p matrix
            h(:,1:Sim.M)= hs(:,1,1:Sim.M);              %this too
            hhat(1,:)   = sum(repmat(S.w_f(:,t),1,Sim.M).*h,1);%initialize hhat
            phat(1)     = sum(S.w_f(:,t).*S.p(:,t),1);  %initialize phat
        end

        if Sim.M>0
            for tt=1:s
                % update hhat
                for m=1:Sim.M                           %for each spike history term
                    hhat(tt+1,m)=B.g(m)*hhat(tt,m)+phat(tt);
                end
                y_t     = B.kx(tt+t)+B.omega'*hhat(tt+1,:)';%input to neuron
                phat(tt+1)  = 1-exp(-exp(y_t)*Sim.dt);      %update phat
            end
        else
            phat  = 1-exp(-exp(B.kx(t+1:t+s)')*Sim.dt);      %update phat
        end

        for tt=s:-1:2
            O.p_o(1:2^(s-tt+1),tt-1)    = repmat(O.p_o(1:2^(s-tt),tt),2,1).*[(1-phat(tt))*ones(1,2^(s-tt)) phat(tt)*ones(1,2^(s-tt))]';
            O.mu_o(1:2^(s-tt+1),tt-1)   = B.a^(-1)*(repmat(O.mu_o(1:2^(s-tt),tt),2,1)-B.beta*spikemat(1:2^(s-tt+1),tt-1));     %mean of P[O_s | C_k]
            O.sig2_o(tt-1)              = B.a^(-2)*(B.sig2_c+O.sig2_o(tt)); %var of P[O_s | C_k]

            for n=0:s-tt+1
                nind=ninds{n+1};
                O.p(n+1,tt-1)   = sum(O.p_o(nind,tt-1));
                ps              = (O.p_o(nind,tt-1)/O.p(n+1,tt-1))';
                O.mu(n+1,tt-1)  = ps*O.mu_o(nind,tt-1);
                O.sig2(n+1,tt-1)= O.sig2_o(tt-1) + ps*(O.mu_o(nind,tt-1)-repmat(O.mu(n+1,tt-1)',lenn(n+1),1)).^2;
            end

%             for n=0:s-tt+1
%                 O.p2(n+1,tt-1) = sum(O.p_o(ninds2(n+1,:),tt-1));
%             end
        end

    end %function UpdateMoments

%% make some figs
GetFig_PFapprox(O)

end