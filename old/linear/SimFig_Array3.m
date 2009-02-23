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
Sim.M       = 0;                %number of spike history terms
Sim.pf      = 3;                %k-component mixture

%% make code prettier
Sim.T       = Sim.Nsec/Sim.dt;  %total # of steps
Sim.tvec    = Sim.dt:Sim.dt:Sim.Nsec;%time vector

%% generate stimulus
Sim.x       = ones(1,Sim.T);    %make 1D fixed input

%% set "real" parameters
P.k         = 0.88;             %bias term (such that neuron spikes thrice in the time displayed in the fig)
P.tau_c     = 0.5;              %decay rate of calcium
P.beta      = 1;                %jump size of calcium after spike
P.sigma_c   = .1;               %std of noise on calcium
P.sigma_o   = 10*sqrt(P.sigma_c^2*Sim.dt);%std of noise on observations

P.omega     = 0;                %jump size for h after spike
P.tau_h     = 0.8;              %decay rate for spike history terms
P.sigma_h   = 0.01;             %std of noise on spike history terms

%% get "real" data

R.n         = zeros(1,Sim.T);   %spike times
R.C         = zeros(1,Sim.T);   %initialize calcium
epsilon_c   = P.sigma_c*sqrt(Sim.dt)*randn(1,Sim.T);%generate noise on calcium
spt         = [83 121 155];     %forced spike times
R.n(spt)    = 1;                %force spikes

for t=2:Sim.T                   %update calcium
    R.C(t)  = (1-Sim.dt/P.tau_c)*R.C(t-1) + P.beta*R.n(t) + epsilon_c(t);
end

sig_o       = 10*sqrt(P.sigma_c^2*Sim.dt);              %unit for observation noise
A.freq       = [1; 5];% 10; 20];% 20; 40];                    %vector of # of times between each observation
A.sig_os     = A.freq*sig_o;     %vector of observation noises

randno=randn(1,Sim.T);
%% do EM recursions
for i=1:length(A.sig_os)                                        %loop over different amounts of noise
    P.sigma_o       = A.sig_os(i);
    for j=1:length(A.freq)                                      %loop over different sampling frequencies
        fprintf('\n\nvar=%d, freq=%d\n',A.freq(i),A.freq(j)); 
        R.O             = R.C + A.sig_os(i)*randno;     %add noise to observations
        Sim.freq        = A.freq(j);                            %set sampling frequency
        Sim.T_o         = Sim.T/Sim.freq;                       %fix # of observations
        [S(i,j) M(i,j)] = smc_em_bern_FoBaMo_v3(Sim,R,P);       %do forward-backward and get moments
        Os{i,j} = R.O;                                          %store the observations so that they may be plotted
    end
end

%% make some figs
GetFig_Array5(Sim,R,M,Os,A)