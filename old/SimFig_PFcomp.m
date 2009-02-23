% this script does makes a figure showing how the smc-em approach
% outperforms other approaches even for just noisy data, by doing:
% 
% 1) set simulation metadata (eg, dt, T, # particles, etc.)
% 2) initialize parameters
% 3) generate fake data
% 4) infers spikes using a variety of approaches
% 5) plots results

clear, clc, fprintf('\nPrior vs Optimal Simulation Fig\n')

%% 1) set simulation metadata
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Sim.T       = 405;                                  % # of time steps
Sim.dt      = 0.025;                                % time step size
Sim.freq    = 1;                                    % # of time steps between observations
Sim.Nsec    = Sim.T*Sim.dt;                         % # of actual seconds
Sim.T_o     = Sim.T;                                % # of observations
Sim.tvec    = Sim.dt:Sim.dt:Sim.Nsec;               % vector of times
Sim.N       = 200;                                  % # of particles
Sim.M       = 0;                                    % number of spike history dimensions
Sim.pf      = 1;                                    % use conditional sampler (not prior) when possible
Sim.StimDim = 1;                                    % # of stimulus dimensions
Sim.x       = ones(1,Sim.T);                        % stimulus

Sim.Mstep   = false;                                % do M-step
Sim.C_params = true;                                 % whether to estimate calcium parameters {tau,A,C_0,sig}
Sim.n_params = true;                                 % whether to estimate rate governing parameters {b,k}
Sim.h_params = false;                                % whether to estimate spike history parameters {h}
Sim.F_params = false;                                % whether to estimate observation parameters {alpha,beta,gamma,zeta}
Sim.MaxIter = 0;                                    % max # of EM iterartions

%% 2) initialize parameters
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% initialize barrier and wiener filter parameters

spt     = round([26 50 84 128 199 247 355]);
P.rate  = numel(spt)/(Sim.T*Sim.dt);                % expected spike rate
P.A     = 1;                                        % jump size ($\mu$M)
P.tau   = 0.5;                                        % calcium decay time constant (sec)
P.lam   = 1/sqrt(P.rate*P.A);                           % expected jump size ber time bin
P.sig   = 1;                                        % standard deviation of noise (\mu M)

% initialize particle filter parameters
P.k         = log(-log(1-P.rate*Sim.dt)/Sim.dt);    % linear filter
P.tau_c     = P.tau;
P.A         = 5;
P.C_0       = .1;                                   % baseline [Ca++]
P.C_init    = P.C_0;                                % initial [Ca++]
P.sigma_c   = P.sig;
P.n         = 1.0;                                  % hill equation exponent
P.k_d       = 200;                                  % hill coefficient
P.alpha     = 1;                                    % F_max
P.beta      = 0;                                    % F_min
P.gamma     = 0e-5;                                 % scaled variance
P.zeta      = 5e-5;                            % constant variance
P.a         = Sim.dt/P.tau_c;

%% 3) simulate data
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% n=rand(Sim.T,1)<1-exp(-exp(P.k)*Sim.dt);
n=zeros(Sim.T,1); n(spt)=1;
C=zeros(Sim.T,1);
epsilon_c = P.sigma_c*sqrt(Sim.dt)*randn(1,Sim.T);      %generate noise on calcium
for t=2:Sim.T                                           %recursively update calcium
    C(t)  = (1-P.a)*C(t-1) + P.a*P.C_0 + P.A*n(t) + epsilon_c(t);   
end
R.C=C;
S=Hill_v1(P,R.C);
eps_t=randn(Sim.T,1);
F=P.alpha*S+P.beta+sqrt(P.gamma*S+P.zeta).*eps_t;
F(F<=0)=eps;
figure(2), clf,
subplot(311), plot(z1(F)+1); hold on, stem(n), 
subplot(312), plot(S+sqrt(P.gamma*S+P.zeta).*eps_t);
subplot(313), plot(C*max(S)/6+sqrt(P.zeta).*eps_t); 
Sim.n = double(n); Sim.n(Sim.n==0)=NaN;          % for plotting purposes in ParticleFiltD

%% 4) infer spikes and estimate parameters
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Sim.Alg=7;

for m=1:2
    Sim.pf  = m-1;
    I{m}    = DataComp13(F,P,Sim);
end

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 5) plot results
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

fig=figure(1); clf,
nrows = 5;
gray  = [.75 .75 .75];              % define gray color
col   = [1 0 0; 0 .5 0];            % define colors for mean
ccol  = col+.8; ccol(ccol>1)=1;     % define colors for std
inter = 'none';                     % interpreter for axis labels
xlims = [20 Sim.T-2];              % xmin and xmax for current plot
fs=12;                              % font size
ms=20;                              % marker size for real spike
sw=1.5;                             % spike width
lw=2;                               % line width
% make xticks
Nsec = floor(Sim.T*Sim.dt);
secs = zeros(1,Nsec-1);
for i=1:Nsec
    secs(i) = find(Sim.tvec>=i,1);
end
I{7}.name=[{'Inferred'}; {'Spikes'}];

% plot fluorescence data
i=1; subplot(nrows,1,i), hold on
plot(z1(C*max(S)/6+sqrt(P.gamma*S+P.zeta).*eps_t),'k','LineWidth',2);
% stem(Sim.n,'Marker','none','LineWidth',sw,'Color','k')
ylab=ylabel([{'Fluorescence'}],'Interpreter',inter,'FontSize',fs);
set(ylab,'Rotation',0,'HorizontalAlignment','right','verticalalignment','middle')
set(gca,'YTick',[],'YTickLabel',[])
set(gca,'XTick',secs,'XTickLabel',[],'FontSize',fs)
axis([xlims 0 1.1])

% plot calcium
i=i+1; subplot(nrows,1,i), hold on
plot(z1(C),'k','LineWidth',2);
ylab=ylabel([{'Calcium'}],'Interpreter',inter,'FontSize',fs);
set(ylab,'Rotation',0,'HorizontalAlignment','right','verticalalignment','middle')
set(gca,'YTick',[],'YTickLabel',[])
set(gca,'XTick',secs,'XTickLabel',[],'FontSize',fs)
axis([xlims 0 1.1])

% plot spike train
i=i+1; subplot(nrows,1,i), hold on
stem(spt,Sim.n(spt),'Marker','.','MarkerSize',ms,'LineWidth',sw,'Color','k','MarkerFaceColor','k','MarkerEdgeColor','k')
ylab=ylabel([{'Spike'}; {'Train'}],'Interpreter',inter,'FontSize',fs);
set(ylab,'Rotation',0,'HorizontalAlignment','right','verticalalignment','middle')
set(gca,'YTick',[],'YTickLabel',[])
set(gca,'XTick',secs,'XTickLabel',[],'FontSize',fs)
axis([xlims 0 1])


% plot inferred spike trains
for m=Algs
    i=i+1;
    subplot(nrows,1,i), hold on,

    if any(m==[7 9])
        subplot(nrows,1,i), hold on,
        stem(spt,Sim.n(spt),'Marker','.','MarkerSize',ms,'LineWidth',sw,'Color','k','MarkerFaceColor','k','MarkerEdgeColor','k')
        BarVar=I{m}.M.nbar+I{m}.M.nvar; BarVar(BarVar>1)=1;
        spts=find(BarVar>1e-3);
        stem(spts,BarVar(spts),'Marker','none','LineWidth',sw,'Color',ccol(2,:));
        spts=find(I{m}.M.nbar>1e-3);
        stem(spts,I{m}.M.nbar(spts),'Marker','none','LineWidth',sw,'Color',col(2,:))
        axis([xlims 0 1])
    else
        subplot(nrows,1,i), hold on,
        n_est   = I{m}.n; n_est   = n_est/max(n_est(20:Sim.T));   %normalize estimate
        stem(spt,Sim.n(spt),'Marker','.','MarkerSize',ms,'LineWidth',sw,'Color','k','MarkerFaceColor','k','MarkerEdgeColor','k')
        
        neg = find(n_est<=0);
        stem(neg,n_est(neg),'Marker','none','LineWidth',sw,'Color',col(1,:))
        
        pos = find(n_est>0);
        stem(pos,n_est(pos),'Marker','none','LineWidth',sw,'Color',col(2,:))
        
        axis([xlims min(n_est) max(n_est(20:Sim.T))])
    end

    hold off,
    ylab=ylabel(I{m}.name,'Interpreter',inter,'FontSize',fs);
    set(ylab,'Rotation',0,'HorizontalAlignment','right','verticalalignment','middle')
    set(gca,'YTick',0:2,'YTickLabel',[])
    set(gca,'XTick',secs,'XTickLabel',[])
    set(gca,'XTickLabel',[])
    box off
end

subplot(nrows,1,nrows)
set(gca,'XTick',secs,'XTickLabel',1:Nsec,'FontSize',fs)
xlabel('Time (sec)','FontSize',fs)

% print fig
wh=[7 5];   %width and height
set(fig,'PaperPosition',[0 11-wh(2) wh]);
print('-depsc','NoisySim')