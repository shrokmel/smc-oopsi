% this m-file generates the data and then plots the fig demonstrating
% how stonger priors make the sampling more efficient
% observations. It generates the following:
%
% Sim:  simulation parameters
% P:    parameters of "real" neuron
% R:    "real" neuron data                  (smc_em_bern_real_exp)
% S:    simulation states for both samplers (smc_em_bern_FoBaMo)
% M:    moments for both samplers           (smc_em_bern_FoBaMo)
% fig:  see fig file for details

%% start function
clear; clc;

[Sim P] = InitializeStuff;

%% set simulation parameters
Sim.Nsec    = 5;                        %# of sec
Sim.T       = round(Sim.Nsec/Sim.dt);   %total # of steps (round deals with numerical error)
rem         = mod(Sim.T,Sim.freq);      %remainder
if rem~=0
    Sim.T=Sim.T-rem;                    %fix number of steps
end
Sim.T_o     = round(Sim.T/Sim.freq);    %number of observations (round deals with numerical error)
Sim.tvec    = Sim.dt:Sim.dt:Sim.Nsec-Sim.dt*rem;%time vector
Sim.x       = ones(Sim.StimDim,Sim.T);  %generate stimulus

epsilon_c   = P.sigma_c*sqrt(Sim.dt)*randn(1,Sim.T);%generate noise on calcium
ISI         = [200 50];
randF       = randn(1,Sim.T);
P.A         = 2; 
P.zeta      = 1e-3;  
P.a         = Sim.dt/P.tau_c;
P.alpha     = 1;
P.beta      = 0;

% do EM recursions
for k=1:2                       
    spt            = [round(Sim.T/ISI(k)):ISI(k):Sim.T];
    spt(spt<200)   = [];
    R(k).n         = zeros(1,Sim.T);           %spike times
    R(k).C         = P.C_0*ones(1,Sim.T);      %initialize calcium
    R(k).n(spt)    = 1;                        %force spikes
    for t=2:Sim.T                           %update calcium
        R(k).C(t)  = (1-P.a)*R(k).C(t-1) + P.A*R(k).n(t) + P.a*P.C_0 + epsilon_c(t);
    end
    F_mu        = P.alpha*Hill_v1(P,R(k).C)+P.beta;        %compute E[F_t]
    F_var       = P.gamma*Hill_v1(P,R(k).C)+P.zeta;    %compute V[F_t]
    R(k).F      = F_mu+sqrt(F_var).*randF;%add noise to observations
    R(k).F(R(k).F<0)  = eps;                      %observations must be non-negative
    [S(k) M(k)] = smc_em_bern_FoBaMo_v5(Sim,R(k),P);%do forward-backward and get moments
%     [SL(k) ML(k)] = DoLinThing(Sim,R(k));
end

%% make a fig
figure(5), clf,

%let O be only observations at sample times
O       = R(1).F.*repmat([NaN*ones(1,Sim.freq-1) 1],1,Sim.T_o);
Onan    = find(~isfinite(O));
Oind    = find(isfinite(O));
O(Onan) = [];

%define colors
gray=[0.75 0.75 0.75];          %define gray
col=[0 0 1; 0 .5 0; 1 0 0; 0 1 1; 1 0 1; 1 .5 0; 1 .5 1];%define colors for mean
ccol=col+.8; ccol(ccol>1)=1;    %define colors for std
ind     = Sim.T:-1:1;                   %inverse indices for 'fill' function
xmin    = Oind(3);
xmax    = Oind(end-2);
xind    = xmin:xmax;
xs      = [Sim.tvec(xmin) Sim.tvec(xmax)];

%other stuff
tl  = [.04 .25];                %tick length [2d, 3d]
yfs = 15;                       %ylabel font size
xfs = 15;                       %xlabel font size
tfs = 15;                       %title font size
lfs = 15;                       %label font size
sw  = 2;                        %spike width
lw  = 2;                        %line width

% plot real n, C, F
for k=1:2
    %fluorescence
    subplot(3,2,k), hold on, %title(num2str(sum(R.n)))
    plot(Sim.tvec,(R(k).F-P.beta)/P.alpha,'k','LineWidth',lw)
    axis([xs 0 1])
    if k==1, 
        ylab=ylabel('F_t');
        set(ylab,'Rotation',0,'HorizontalAlignment','right','verticalalignment','middle','color','k','fontsize',yfs)
    end
    set(gca,'YTick',[0 0.5 1],'YTickLabel',[])
    set(gca,'XTick',[])
    
    %calcium
    subplot(3,2,k+2), hold on, %title(num2str(sum(R.n)))
    cmax(2)=max(R(2).C(xind)-P.C_0);
    cmin(2)=min(R(2).C(xind)-P.C_0);
    ptiles = GetPercentiles([.25 .75],S(k).w_b,S(k).C);
    hfill=fill([Sim.tvec Sim.tvec(ind)],([ptiles(1,:) ptiles(2,ind)]-P.C_0-cmin(2))/(cmax(2)-cmin(2)),ccol(2,:));
    set(hfill,'edgecolor',ccol(2,:))    
    plot(Sim.tvec,(R(k).C-P.C_0-cmin(2))/(cmax(2)-cmin(2)),'color',gray,'LineWidth',lw)
    plot(Sim.tvec,(M(k).Cbar-P.C_0-cmin(2))/(cmax(2)-cmin(2)),'color',col(2,:),'LineWidth',lw)
%     plot(Sim.tvec,(ML(k).Cbar-P.C_0-cmin(2))/(cmax(2)-cmin(2)),'color',ccol(3,:),'LineWidth',1)
    plot(100, [.5:.01:.75],'k')
    axis([xs 0 1])
    if k==1, 
        ylab=ylabel('C_t');
        set(ylab,...
            'Rotation',0,...
            'HorizontalAlignment','right',...
            'verticalalignment','middle',...
            'color','k',...
            'fontsize',yfs)
    end
    set(gca,'YTick',[0 0.5 1],'YTickLabel',[])
    set(gca,'XTick',[])

    %spikes
    subplot(3,2,k+4), hold on, %title(num2str(sum(R.n)))
    stem(Sim.tvec,R(k).n,'Marker','none','Color',gray,'LineWidth',sw)
    BarVar=M(k).nbar+M(k).nvar;
    BarVar(BarVar>1)=1;
    stem(Sim.tvec,BarVar,'Marker','none','Color',ccol(2,:),'LineWidth',sw)
    stem(Sim.tvec,M(k).nbar,'Marker','none','Color',col(2,:),'LineWidth',sw)
    axis([xs 0 1])
    set(gca,'YTick',[0 0.5 1],'YTickLabel',[])
    if k==1, 
        ylab=ylabel('n_t');
        set(ylab,...
        'Rotation',0,...
        'HorizontalAlignment','right',...
        'verticalalignment','middle',...
        'color','k',...
        'fontsize',yfs)
    else
        set(gca,'YTickLabel',[])
    end
    xlab=xlabel('Time (sec)');
    set(xlab,'fontsize',xfs);
end

% print to (color) eps
fig=figure(5);
wh=[7 3];   %width and height
set(fig,'PaperPosition',[0 11-wh(2) wh]);
print -depsc C:\D\Research\liam\SMC_EM_GLM\satur