function [R P] = smc_em_bern_real_exp_v1(Sim)
%% this function simulates a neuron according to the following model
% y_k   = kappa' * x_k + omega' * h_k
% p_k   = p(spike | y_k) = 1-exp(-exp(y_k))
% h_k   = (1-dt/tau_h) h_{k-1} + I_k + epsilon_{hk}, 
% C_k   = (1-dt/tau_c) C_{k-1} + beta*I_k + epsilon_{ck}
% O_k   = C_k + epsilon_{ok}

%% inputs
% Sim   : simulation parameters (eg, dt, Nparticles, etc.)
% 
%% outputs
% R     : states of "real" neuron
% P     : parameters of "real" neuron 

%%%%%%%% set "real" parameters
P.k         = 5*ones(Sim.KernelSize,1);%3*sin(linspace(pi/2,8*pi/2,Sim.KernelSize))'; %bias and stimulus kernel
P.k(1)      = 0.5;                                            %bias term

P.tau_c     = 0.5;                                          %decay rate of calcium
P.beta      = 1;                                            %jump size of calcium after spike
P.sigma_c   = .1;                                            %std of noise on calcium
P.sigma_o   = 10*sqrt(P.sigma_c^2*Sim.dt);                   %std of noise on observations

if Sim.M>0                                                  %if spike history terms are included
    P.omega     = -2*ones(Sim.M,1);  %jump size for h after spike
    P.tau_h     = 0.8*ones(Sim.M,1)+0.001*rand(Sim.M,1);    %decay rate for spike history terms
    P.sigma_h   = 0.01*ones(Sim.M,1);                       %std of noise on spike history terms
end

%%%%%%%% initialize "real" data
R.p         = zeros(1,Sim.K);       %spike rate
R.I         = zeros(1,Sim.K);       %spike times
R.C         = 0*ones(1,Sim.K);      %initialize calcium
R.O         = NaN*zeros(1,Sim.K);   %initialize observations
if Sim.M>0
    R.h = 0*ones(Sim.M,Sim.K); %spike history
end

%%%%%%%% simulate "real" data
xk        = P.k'*Sim.x;                                 %external input to neuron
epsilon_c = P.sigma_c*sqrt(Sim.dt)*randn(1,Sim.K);      %generate noise on calcium
epsilon_o = P.sigma_o*randn(1,Sim.K);                   %generate noise on observations
U_sampl   = rand(1,Sim.K);                              %generate random number to use for sampling

if Sim.M>0
    epsilon_h = repmat(P.sigma_h*sqrt(Sim.dt),1,Sim.K).*randn(Sim.M,Sim.K); %generate noise on spike history
    for k=2:Sim.K                                       %update states
        R.h(:,k)= (1-Sim.dt./P.tau_h).*R.h(:,k-1)+R.I(k-1) + epsilon_h(:,k);%update h terms
        y_t=xk(k)+P.omega'*R.h(:,k);                    %generate operand for rate function
        R.p(k)=1-exp(-exp(y_t)*Sim.dt);                        %generate rate
        R.I(k)  = U_sampl(k)<R.p(k);              %sample from poisson with rate proportional to lambda(k)
    end %time loop
else
    R.p = 1-exp(-exp(xk)*Sim.dt);
    R.I = U_sampl<R.p;
end

for k=2:Sim.K     %update calcium
    R.C(k)  = (1-Sim.dt/P.tau_c)*R.C(k-1) + P.beta*R.I(k) + epsilon_c(k);   
end
R.O = R.C + epsilon_o;                        %add noise to observations

end