% this m-file generates the data and then plots the fig demonstrating how
% the two different sampling strategies differ.  It generates the following:
% 
% Sim:  simulation parameters
% P:    parameters of "real" neuron
% R:    "real" neuron data                  (smc_em_bern_real_exp)
% S:    simulation states for both samplers (smc_em_bern_main)
% M:    moments for both samplers           (smc_em_bern_main)
% fig:  see fig file for details            (GetSamplFig1)

%% start function
clear; clc;

%% set simulation parameters
Sim.dt      = 0.005;            %time step size (sec)
Sim.Nsec    = 10;              %# of sec
Sim.N       = 100;              %total number of particles
Sim.M       = 1;                %number of spike history terms
Sim.freq    = 10;               %relative frequency of observations

%% make code prettier
Sim.K       = Sim.Nsec/Sim.dt;  %total # of steps
Sim.K_o     = Sim.K/Sim.freq;   %number of observations
Sim.tvec    = 0:Sim.dt:Sim.Nsec-Sim.dt;%time vector

%% generate stimulus
Sim.x       = ones(Sim.K,1);     %make one input stationary

%% set "real" parameters
P.k         = 0.69;             %bias term
P.tau_c     = 0.5;              %decay rate of calcium
P.beta      = 1;                %jump size of calcium after spike
P.sigma_c   = .1;               %std of noise on calcium
P.sigma_o   = 20*sqrt(P.sigma_c^2*Sim.dt);%std of noise on observations

P.omega     = 0;                %jump size for h after spike
P.tau_h     = 0.8;              %decay rate for spike history terms
P.sigma_h   = 0.01;             %std of noise on spike history terms

%% get "real" data
R           = smc_em_bern_real_exp_v2(Sim,P);


%% do EM recursion
for i=1:2
    if i==1                     %first do a backwards sampler
        Sim.van=false;
    else                        %then a vanilla sampler
        Sim.van=true;
    end
    [S(i) M(i)] = smc_em_bern_main_v5(Sim,R,P);
end

%% make some figs
GetSamplFig2A(Sim,R,S,M)