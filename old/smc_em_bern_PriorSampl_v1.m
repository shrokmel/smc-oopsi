function S = smc_em_bern_PriorSampl_v1(Sim,R,B)

%% initialize stuff
S.p     = zeros(Sim.N,Sim.T);                   %initialize rate
S.n     = zeros(Sim.N,Sim.T);                   %initialize spike counts
S.C     = zeros(Sim.N,Sim.T);               %initialize calcium
S.w_f   = 1/Sim.N*ones(Sim.N,Sim.T);          %initialize N_{eff}
S.w_b   = 1/Sim.N*ones(Sim.N,Sim.T);          %initialize N_{eff}
S.Neff  = Sim.N*ones(1,Sim.T_o);                %initialize N_{eff}

epsilon_c   = sqrt(B.sig2_c)*randn(Sim.N,Sim.T);%generate noise on c
U_sampl     = rand(Sim.N,Sim.T);                %random samples

if Sim.M>0  %if spike histories, generate noise on them
    S.h         = zeros(Sim.N,Sim.T,Sim.M);   %initialize spike history terms
    epsilon_h   = zeros(Sim.N, Sim.T, Sim.M);
    for m=1:Sim.M
        epsilon_h(:,:,m)   = sqrt(B.sig2_h(m))*randn(Sim.N,Sim.T);   %generate noise on h
    end
else	    %if no spike histories, generate p and sample I
    S.p(1,:) = 1-exp(-exp(B.kx)*Sim.dt);                                  %update rate for those particles with y_t<0
    S.p      = repmat(S.p(1,:),Sim.N,1);%make rate the same for each particle
    S.n      = U_sampl<S.p;             %generate random number to use for sampling
end

% preprocess stuff for stratified resampling
ints        = linspace(0,1,Sim.N+1);
diffs       = ints(2)-ints(1);
U_resamp    = repmat(ints(1:end-1),Sim.T_o,1)+diffs*rand(Sim.T_o,Sim.N);

%% loop-de-loop
for t=2:Sim.T

    % if h's, update h and I recursively
    if Sim.M>0                                      %update noise on h
        for m=1:Sim.M
            S.h(:,t,m)=B.g(m)*S.h(:,t-1,m)+S.n(:,t-1)+epsilon_h(:,t,m);
        end

        % update rate and sample spikes
        hs              = S.h(:,t,:);               %this is required for matlab to handle a m-by-n-by-p matrix
        h(:,1:Sim.M)    = hs(:,1,1:Sim.M);          %this too
        y_t             = B.kx(t)+B.omega'*h';      %input to neuron
        S.p(:,t)        = 1-exp(-exp(y_t)*Sim.dt);  %update rate for those particles with y_t<0
        S.n(:,t)        = U_sampl(:,t)<S.p(:,t);    %sample
    end

    % sample C
    if mod(t,Sim.freq)==0 && B.sig2_o==0
        S.c(:,t)=R.C(t);
    else
        S.C(:,t)=B.a*S.C(:,t-1)+B.beta*S.n(:,t)+epsilon_c(:,t);
    end

    % stratified resample at every observation
    if mod(t,Sim.freq)==0
        if B.sig2_o==0
            S.w_f(:,t)  = 1/Sim.N*ones(Sim.N,1);
        else
            ln_w        = -0.5*(R.O(t)-S.C(:,t)).^2/B.sig2_o;     %compute log of weights
            ln_w        = ln_w-max(ln_w);                       %subtract the max to avoid rounding errors
            w           = exp(ln_w);                            %exponentiate to get actual weights
            S.w_f(:,t)  = w/sum(w);                             %normalize to define a legitimate distribution
        end
        S = smc_em_bern_stratresamp_v7(Sim,S,t,U_resamp);
   
        if mod(t,100)==0 && t<1000              %print # of observations
            fprintf('\b\b\b%d',t)
        elseif mod(t,100)==0 && t<10000
            fprintf('\b\b\b\b%d',t)
        elseif mod(t,100)==0 && t<100000
            fprintf('\b\b\b\b\b%d',t)
        end
    end %resample
end