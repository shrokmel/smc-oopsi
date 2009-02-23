% this file sets the parameters and does the simulation for making the
% m-step fig.  stimulus is multidimensional gaussian noise. It generates the following:
%
% Sim:  simulation parameters
% P:    parameters of "real" neuron
% R:    "real" neuron data
% S:    simulation states for both samplers
% M:    moments for both samplers
% E:    parameter estimates (not used)
% fig:  see fig file for details

%% start function
clear; clc; close all

[Sim P] = InitializeStuff;

% set simulation parameters
Sim.Nsec= 10;                       %# of sec
Sim.T   = round(Sim.Nsec/Sim.dt);   %total # of steps (round deals with numerical error)
rem     = mod(Sim.T,Sim.freq);      %remainder
if rem~=0
    Sim.T=Sim.T-rem;                %fix number of steps
end
Sim.T_o = round(Sim.T/Sim.freq);    %number of observations (round deals with numerical error)
Sim.tvec= Sim.dt:Sim.dt:Sim.Nsec-Sim.dt*rem;%time vector
Sim.M       = 1;                    %# spike history terms
Sim.StimDim = 5;                    %stimulus dimensionality
Sim.Mstep   = true;                 %go M-step
Sim.MaxIter = 20;                   %max # of iters
Sim.Ntrials = 10;
Sim.Cparams = true;
Sim.Rparams = true;               %whether to estimate rate governing parameters

P.k         = 0.5*(1:Sim.StimDim)'+.5;     %linear kernel
P.k(2:2:end)= -1*P.k(2:2:end)+1;
P.omega     = -5*P.k(1);            %spike history weight
P.tau_h     = .025;                 %gecay rate for spike history terms
P.tau_c     = 0.5;                  %gecay rate of calcium
P.A         = 0.1;                  %jump size of calcium after spike
P.C_0       = 0.5;                  %baseline calcium
P.gamma     = 1e-5;                 %var gainh
P.zeta      = 1e-4;                 %var offset


% E(1:Sim.Ntrials)=EI;
figure(3), clf, hold on, stem([P.tau_c; P.A; P.C_0; P.sigma_c],'r','linewidth',2),
figure(4), clf, hold on, plot([P.k; P.omega],'r','linewidth',2),

%%
for k=1:Sim.Ntrials
    Sim.x       = 2*rand(Sim.StimDim,Sim.T);
    Sim.x(1,:)  = 1*ones(1,Sim.T);        %make a constant stim for baseline firing rate
    R           = smc_em_bern_real_exp_v5(Sim,P);
    fprintf('\n\nTrial #%g, # spikes=%g\n',k,sum(R.n))

    EI          = GetInitParams_v1(Sim,R.F,P);
    Enew        = EI;
    E(1)        = Enew;
    ErrNewC     = norm([Enew.tau_c; Enew.A; Enew.C_0; Enew.sigma_c]-[P.tau_c; P.A; P.C_0; P.sigma_c]);
    ErrOldC     = ErrNewC;
    dthetaC     = inf;
    ErrNewN     = norm([Enew.k; Enew.omega]-[P.k; P.omega]);
    ErrOldN     = ErrNewN;
    dthetaN     = inf;
    i           = 0;                    %iteration number
    Sim.conv    = false;
    figure(1), clf, hold on, stem(([Enew.tau_c; Enew.A; Enew.C_0; Enew.sigma_c]-[P.tau_c; P.A; P.C_0; P.sigma_c])./([EI.tau_c; EI.A; EI.C_0; EI.sigma_c]-[P.tau_c; P.A; P.C_0; P.sigma_c]))
    figure(2), clf, hold on, plot([P.k; P.omega],'r'), plot([Enew.k; Enew.omega],'b'), legend('real')
    while Sim.conv==false;
        [S M]   = smc_em_bern_FoBaMo_v5(Sim,R,Enew);
        Eold    = Enew;
        Enew    = smc_em_bern_mstep_v2(Sim,S,M,Enew);
        i       = i+1;
        ErrOldC = ErrNewC;
        ErrNewC = norm([Enew.tau_c; Enew.A; Enew.C_0; Enew.sigma_c]-[P.tau_c; P.A; P.C_0; P.sigma_c]);
        dthetaC = norm([Enew.tau_c; Enew.A; Enew.C_0]-[Eold.tau_c; Eold.A; Eold.C_0])/norm([Eold.tau_c; Eold.A; Eold.C_0; Enew.sigma_c]);

        ErrOldN = ErrNewN;
        ErrNewN = norm([Enew.k; Enew.omega]-[P.k; P.omega]);
        dthetaN = norm([Enew.k; Enew.omega]-[Eold.k; Eold.omega])/norm([Eold.k; Eold.omega]);

        fprintf('\nIteration #%g, C error=%g, N error=%g, derrC=%g, derrN=%g, dthetaC=%g, dthetaN=%g\n',i,ErrNewC,ErrNewN,ErrOldC-ErrNewC,ErrOldN-ErrNewN,dthetaC,dthetaN)
        for kk=1:Sim.StimDim
            fprintf('\nest=%g, true=%g',Enew.k(kk),P.k(kk))
        end
        fprintf('\nomega: est=%g, true=%g',Enew.omega,P.omega)
        fprintf('\ntau_c: est=%g, true=%g',Enew.tau_c,P.tau_c)
        fprintf('\nA: est=%g, true=%g',Enew.A,P.A)
        fprintf('\nC_0: est=%g, true=%g',Enew.C_0,P.C_0)
        fprintf('\nsigma_c: est=%g, true=%g',Enew.sigma_c,P.sigma_c)        
        save('M_params','Sim','R','P','M','E')
        figure(1), stem(([Enew.tau_c; Enew.A; Enew.C_0; Enew.sigma_c]-[P.tau_c; P.A; P.C_0; P.sigma_c])./([EI.tau_c; EI.A; EI.C_0; EI.sigma_c]-[P.tau_c; P.A; P.C_0; P.sigma_c])), drawnow
        figure(2), plot([Enew.k; Enew.omega],'b'), drawnow
        if i>Sim.MaxIter || (dthetaC<.01 && dthetaN<.04)
            Sim.conv=true;
            if ErrNewC>ErrOldC
                E(k)=Eold;
            else
                E(k)=Enew;
            end
            figure(3), stem([E(k).tau_c; E(k).A; E(k).C_0; E(k).sigma_c],'b','linewidth',2), drawnow
            figure(4), plot([E(k).k; E(k).omega],'b','linewidth',2), drawnow
        end
        %         figure(5), clf, hold on, plot(S.C'), plot(R.C,'r','linewidth',2), drawnow
    end
end
%%
% plot real n, C, F
figure(5), clf, hold on, title(num2str(sum(R.n)))
subplot(311), plot(Sim.tvec,R.p/Sim.dt), ylabel('n')
subplot(312), plot(Sim.tvec,R.C), ylabel('[Ca++]'), axis([0 Sim.Nsec min(R.C) max(R.C)])
subplot(313), plot(Sim.tvec,R.F), ylabel('F_t'), axis([0 Sim.Nsec min(R.F) max(R.F)])
% subplot(312), plot(Sim.tvec,R.C-P.C_0), ylabel('[Ca++]'), axis([0 Sim.Nsec min(R.C-P.C_0) max(R.C-P.C_0)])
% subplot(313), plot(Sim.tvec,(R.F-P.beta)/P.alpha), ylabel('F_t'), axis([0 Sim.Nsec min((R.F-P.beta)/P.alpha) max((R.F-P.beta)/P.alpha)])

%
figure(6),
subplot(511), plot(P.k'*Sim.x), ylabel('filt stim'), set(gca,'XTickLabel',[]), axis('tight'), title(['min=', num2str(min(P.k'*Sim.x)), ', max=',num2str(max(P.k'*Sim.x))])
subplot(512), plot(R.p), ylabel('p'), title(sum(R.n)/Sim.Nsec), set(gca,'XTickLabel',[])
subplot(513), stem(R.n), title(sum(R.n)), set(gca,'XTickLabel',[])
ISI=diff(find(R.n)); % x = 1:length(ISI); n=histc(ISI,x); n=n/sum(n); c=cumsum(n); bar(x,c),
subplot(514), plot(ISI), ylabel('ISI'), set(gca,'XTickLabel',[]), axis([0 length(ISI) 0 10]), title(length(find(diff(find(R.n))<Sim.freq))/sum(R.n))
subplot(515), plot(Sim.tvec,P.omega*R.h), ylabel('h'), axis('tight')

figure(7), clf, hold on,
plot(S.C')
plot(R.C,'r','linewidth',2)

%%
load M_params
gray    = [0.75 0.75 0.75];
yfs     = 12;
tfs     = 12;
bl      = .2;
clear kvec theta 

figure(8), clf, hold on

subplot('Position', [.1 bl .43 .8]), hold on        
plot(P.k(2:end),'linewidth',2,'color',gray)
for kk=2:length(E)
    kvec(kk,:)=E(kk).k(2:end);
end
meankvec=mean(kvec);
stdkvec=sqrt(var(kvec));
errorbar(meankvec,stdkvec,'color','k','linewidth',2)
axis([.9 Sim.StimDim-.9 min(min(P.k),min(meankvec-stdkvec)) max(max(P.k),max(meankvec-stdkvec))])
set(gca,'XTickLabel',[],'YTickLabel',[])
ylab=ylabel('Magnitude (a.u.)');
set(ylab,'fontsize',yfs)
title('Linear Filter','fontsize',tfs)

subplot('Position', [.60 bl .35 .8]), cla, hold on        
thetastar=[P.tau_c; P.A; P.C_0]; hold on
% plot(thetastar,'color',gray,'linewidth',2)
plot(thetastar./thetastar,'o','color',gray,'linewidth',2)
for kk=2:length(E)
    theta(kk,:)=[E(kk).tau_c; E(kk).A; E(kk).C_0];
end
meantheta=mean(theta);
stdtheta=sqrt(var(theta));
errorbar(meantheta./thetastar',stdtheta,'color','k','linewidth',2)
axis([.9 3.1 min(0,min(meantheta./thetastar'-stdtheta)) max(meantheta./thetastar'+stdtheta)])

tit='Calcium Parameters';
title(tit,'fontsize',tfs)

ypos = -0.25;
text('Position',[0.9517 ypos 17.32],...
    'Interpreter','tex',...
    'String','{\tau}_{c}',...
    'FontSize',yfs);
text('Position',[1.98 ypos 17.32],...
    'Interpreter','tex',...
    'String','A',...
    'FontSize',yfs);
text('Position',[2.8 ypos 17.32],...
    'Interpreter','tex',...
    'String','[Ca^{2+}]_0',...
    'FontSize',yfs);
set(gca,'XTick',[1 2 3],'XTickLabel',[],'YTick',[1 2 3])

ylab=ylabel('Error (%/100)');
set(ylab,'fontsize',yfs)

%
fig=figure(8);
bgr=[6 2];
set(fig,'PaperPosition',[0 11-bgr(2) bgr]);
print -depsc C:\D\Research\liam\SMC_EM_GLM\mstep