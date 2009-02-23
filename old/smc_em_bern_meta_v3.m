% this file is a meta-m-file, which calls various other m-files, depending
% on the desired use.
%
% inputs: this is not a proper function, so there are technically no inputs
% 
% outputs: again, this is not a proper function, noneless, the following structures are created:
% Sim:  simulation parameters
% R:    "real" neuron data
% P:    parameters of "real" neuron
% S:    simulation states
% E:    parameter estimates (from each EM iteration)
% M:    moments (from each EM iteration)

%% start function
clear; clc;
% dbstop if warning
warning off all

%% set simulation parameters
Sim.dt          = 0.005;                                %time step size (sec)
Sim.Nsec        = 0.8;                                  %# of sec
Sim.KernelSize  = 1;                                    %dimensionality of linear kernel for each neuron operating on stimulus
Sim.iters       = 1;                                    %number of EM iterations
Sim.N           = 100;                                  %total number of particles
Sim.M           = 1;                                    %number of spike history terms
Sim.dtSample    = 20*Sim.dt;                                %frequency of observations
Sim.pfs         = [1 2];                                %which particle filters to use: 1) prior, 2) one-step, 3) backwards

%% make code prettier
Sim.K           = Sim.Nsec/Sim.dt;                      %total # of steps
Sim.K_o         = Sim.Nsec/Sim.dtSample;                %number of observations
Sim.frac        = Sim.dtSample/Sim.dt;                  %# of samples per observation
Sim.tvec        = 0:Sim.dt:Sim.Nsec-Sim.dt;             %time vector

%% generate stimulus
Sim.x           = rand(Sim.KernelSize,Sim.K);           %the stimulus is white gaussian noise (we add the vector of ones to deal with the bias)
Sim.x(1,:)      = 1;                                    %make one input stationary
pulses          = linspace(10,12,4);
sp              = [55:56 75:76 95:96 115:116];
Sim.x(1,sp(1:2))= pulses(1);
Sim.x(1,sp(3:4))= pulses(2);
Sim.x(1,sp(5:6))= pulses(3);
Sim.x(1,sp(7:8))= pulses(4);

if Sim.KernelSize>1                                     %modulate time-varying stimuli with a sinusoid
        Sim.x(2:Sim.KernelSize,:) = Sim.x(2:Sim.KernelSize,:).*repmat(0.2*sin(linspace(-10*pi,10*pi,Sim.K)),Sim.KernelSize-1,1);%modulate input by a sinusoid
end

%% set "real" parameters
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

%% get "real" data
R = smc_em_bern_real_exp_v2(Sim,P)

%% do EM recursion
[S, M, E] = smc_em_bern_main_v1(Sim,R,P);

%% make some figs
close all
GetSchemFig1G(Sim,R,S,B,M)
GetPriorFig2H(Sim,R,S)