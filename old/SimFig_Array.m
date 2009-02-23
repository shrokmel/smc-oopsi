% this m-file generates the data and then plots the fig demonstrating how
% backwards sampler works for different intermittencies and noise on
% observations. It generates the following:
%
% Sim:  simulation parameters
% P:    parameters of "real" neuron
% R:    "real" neuron data                  (smc_em_bern_real_exp)
% S:    simulation states for both samplers (smc_em_bern_main)
% M:    moments for both samplers           (smc_em_bern_main)
% fig:  see fig file for details            (GetArrayFig1)

%% start function
clear; clc;

%% set simulation parameters
Sim.dt      = 0.005;            %time step size (sec)
Sim.Nsec    = 1.4;              %# of sec
Sim.N       = 100;              %total number of particles
Sim.M       = 1;                %number of spike history terms

%% make code prettier
Sim.K       = Sim.Nsec/Sim.dt;  %total # of steps
Sim.tvec    = 0:Sim.dt:Sim.Nsec-Sim.dt;%time vector

%% generate stimulus
Sim.x       = ones(Sim.K,1);     %make one input stationary

%% set "real" parameters
P.k         = 1.1;                %bias term
P.tau_c     = 0.5;              %decay rate of calcium
P.beta      = 1;                %jump size of calcium after spike
P.sigma_c   = .1;               %std of noise on calcium
P.sigma_o   = 10*sqrt(P.sigma_c^2*Sim.dt);%std of noise on observations

P.omega     = 0;                %jump size for h after spike
P.tau_h     = 0.8;              %decay rate for spike history terms
P.sigma_h   = 0.01;             %std of noise on spike history terms

%% get "real" data
% R           = smc_em_bern_real_exp_v2(Sim,P);
% max(R.p)*Sim.K/Sim.Nsec

R.I         = zeros(1,Sim.K);   %spike times
R.C         = zeros(1,Sim.K);   %initialize calcium
epsilon_c   = P.sigma_c*sqrt(Sim.dt)*randn(1,Sim.K);%generate noise on calcium
spt         = [83 121 155];         %forced spike times
R.I(spt)    = 1;                %force spikes

for k=2:Sim.K                   %update calcium
    R.C(k)  = (1-Sim.dt/P.tau_c)*R.C(k-1) + P.beta*R.I(k) + epsilon_c(k);
end

Sim.van     = false;
sig_o       = sqrt(P.sigma_c^2*Sim.dt);
sig_os      = [0; 10*sig_o; 20*sig_o; 50*sig_o; 100*sig_o];
freq        = [1; 5; 10; 20; 40];

%% do EM recursions
for n=1:length(sig_os)
    for i=1:length(freq)
        R.O = R.C + sig_os(n)*randn(1,Sim.K);               %add noise to observations
        Sim.freq    = freq(i);
        Sim.K_o     = Sim.K/Sim.freq;                
        [S(n,i), M(n,i)] = smc_em_bern_main_v4(Sim,R,P);
        Os{n,i} = R.O;
    end
end

%% make some figs
GetFig_Array1(Sim,R,M,Os,freq)