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

[Sim P] = InitializeStuff;

% set simulation parameters
Sim.freq    = 3;                        %frequency of observations
Sim.Nsec    = 2.5;                      %# of sec
Sim.StimDim = 1;                        %# of stimulus dimensions
Sim.M       = 1;                        %number of spike history terms
Sim.N       = 5;
Sim.pf      = 1;                        %not vanilla particle filtering
Sim.T       = round(Sim.Nsec/Sim.dt);   %total # of steps (round deals with numerical error)
rem         = mod(Sim.T,Sim.freq);      %remainder
if rem~=0
    Sim.T=Sim.T-rem;                    %fix number of steps
end
Sim.T_o     = round(Sim.T/Sim.freq);    %number of observations (round deals with numerical error)
Sim.tvec    = Sim.dt:Sim.dt:Sim.Nsec-Sim.dt*rem;%time vector
Sim.x       = ones(1,Sim.T);     %make one input stationary

P.k         = 0;                        %bias term
P.gamma     = .1e-5;                     %var gainh
P.zeta      = .1e-5;                    %var offset
P.A         = .08;
P.sigma_c   = .1;
P.tau_h     = .01;                %decay rate for spike history terms
P.a         = Sim.dt/P.tau_c;

% get "real" data
R.n         = zeros(1,Sim.T);   %spike times
R.h         = zeros(1,Sim.T);   %spike times
R.C         = P.C_init*ones(1,Sim.T);   %initialize calcium
epsilon_c   = P.sigma_c*sqrt(Sim.dt)*randn(1,Sim.T);%generate noise on calcium
% spt         = [3*Sim.freq:Sim.freq:50 81 131 181 231 281 331 381 431 481];    %forced spike times
spt         = [181 231 281 331 381 431 481];    %forced spike times
spt         = spt(spt<Sim.T);
R.n(spt)    = 1;                %force spikes
epsilon_h = repmat(P.sigma_h*sqrt(Sim.dt),1,Sim.T).*randn(Sim.M,Sim.T); %generate noise on spike history

for t=2:Sim.T                   %update calcium
    R.h(:,t)= (1-Sim.dt./P.tau_h).*R.h(:,t-1)+R.n(t-1) + epsilon_h(:,t);%update h terms
    R.C(t)  = (1-P.a)*R.C(t-1) + P.A*R.n(t) + P.a*P.C_0 + epsilon_c(t);
end
F_mu        = P.alpha*Hill_v1(P,R.C)+P.beta;        %compute E[F_t]
F_var       = P.gamma*Hill_v1(P,R.C)+P.zeta;    %compute V[F_t]
R.F         = F_mu+sqrt(F_var).*randn(1,Sim.T);%add noise to observations
R.F(R.F<0)  = eps;                      %observations must be non-negative

% do EM recursion
Sim.pf=1;
[S M] = smc_em_bern_FoBaMo_v5(Sim,R,P);

%% make a fig
n=1;
figure(2), cla, clf,

gray    = [0.75 0.75 0.75];         %define gray
col     = [1 0 0; 0 .5 0];          %define colors for mean
ccol    = col+.8; ccol(ccol>1)=1;   %define colors for std

O           = R.F.*repmat([NaN*ones(1,Sim.freq-1) 1],1,Sim.T_o);%let O be only observations at sample times
ONaNind     = find(~isfinite(O));
Oind        = find(isfinite(O));
O(ONaNind)  = [];
finv        = ((P.k_d.*(P.beta-O))./(O-P.beta-P.alpha)).^(1/P.n);

nind    = find(R.n);                %find spike times
nind    = nind(n);
xmin    = Oind(find(Oind>nind,1)-1)-1;
xmax    = Oind(find(Oind>nind,1))+1;
xs      = Sim.tvec([xmin xmax]);%set the limits of the x-axis
xind    = xmin:xmax;                %indices of x-axis
ind     = Sim.T:-1:1;               %inverse index for 'fill' plots

%get min and max of calcium to normalize within plots

cshift=inf;
cmin = min(min(R.C(xind)),min(min(S.C(:,xind))));
cmax = max(max(R.C(xind)),max(max(S.C(:,xind))));
cshift  = min(min(min(S.C(:,xind))),cshift);
cdiff   = cmax-cmin;

hmin = min(min(P.omega*R.h(xind)),min(min(P.omega*S.h(:,xind))));
hmax = max(max(P.omega*R.h(xind)),max(max(P.omega*S.h(:,xind))));
M.hbar = sum(S.w_b.*S.h,1);
M.hvar = sum((repmat(M.hbar,Sim.N,1)-S.h).^2)/Sim.N;


hmin    = min(hmin(:));
hmax    = max(hmax(:));
hdiff   = hmax-hmin;

for i=1%:2
    C=(S.C(:,xind)-cmin)/cdiff;
    hh=(P.omega*S.h(:,xind)-hmin)/hdiff;
end


%get forward means and variances
fCbar = sum(S.w_f.*S.C,1);
fnbar = sum(S.w_f.*S.n,1);
fnvar = sum((repmat(fnbar(i,:),Sim.N,1)-S.n).^2)/Sim.N;

% set subfig sizes
fs  = 12;       %default font size
yfs = fs;       %ylabel font size
xfs = fs;       %xlabel font size
titfs = 12;   %title font size
ticfs = fs;     %tick font size
texfs = fs;     %text font size
tfs   = 14;
tl  = [.03 .03];%tick length
sw  = 5;        %spike width
bw  = .3;
bw2 = .0015;
xticks = xs(1):Sim.dt:xs(2);
tx  = 1.435;
ty  = 2.1;
sp  = 1.2;
lw  = 2;

Nrows=3;
Ncols=1;
AX  = [xs 0 1];

% true h
subplot(Nrows,Ncols,1), cla, hold on
plot(Sim.tvec(xind),(P.omega*R.h(xind)-hmin)/hdiff,'color',gray,'LineWidth',2)              %plot true calcium
set(gca,'YTick',[0 1],'YTickLabel',round([hmin hmax]*100)/100)
set(gca,'XTick',Sim.tvec(xind),'XTickLabel',[])
axis(AX)
title('Particles','fontsize',titfs,'Interpreter','latex'),
ylabel({'$\omega h_t$ (a.u.)'},'fontsize',yfs,'Interpreter','latex')


% tru spike
subplot(Nrows,Ncols,2), cla, hold on
for x=xind(1)+1:xind(end)
    bar(Sim.tvec(x),R.n(x),'EdgeColor',gray,'FaceColor',gray,'BarWidth',bw2)%plot true spikes
end
set(gca,'YTick',[0 1],'YTickLabel',[0 1])
set(gca,'XTick',Sim.tvec(xind),'XTickLabel',[])
axis(AX)
ylabel({'$n_t$ $(\#)$'},'fontsize',yfs,'Interpreter','latex')

% true calcium
subplot(Nrows,Ncols,3), cla, hold on
plot(Sim.tvec(xind),(R.C(xind)-cmin)/cdiff,'color',gray,'LineWidth',2)              %plot true calcium
plot(Sim.tvec(xind(2)), (R.C(xind(2))-cmin)/cdiff,'ok','LineWidth',2,'markersize',11)
plot(Sim.tvec(xind(end)-1), (R.C(xind(end)-1)-cmin)/cdiff,'ok','LineWidth',2,'markersize',11)
set(gca,'YTick',[0 1],'YTickLabel',round((([cmin cmax])-cmin)*10)/10)
set(gca,'XTick',Sim.tvec(xind),'XTickLabel',[{''};{'u'}; {''}; {''}; {'v'}])
xlabel('Time (sec)', 'fontsize',xfs,'Interpreter','latex');
ylabel([{'[Ca$^{2+}]_t$ ($\mu$M)'}],'Interpreter','latex','fontsize',yfs)
axis(AX)

for x=2:length(xind)
    % h particles
    subplot(Nrows,Ncols,1), hold on
    plot(Sim.tvec(xind(x-1):xind(x)),hh(:,x-1:x)','Color',col(2,:))
    for nn=1:Sim.N
        plot(Sim.tvec(xind(x)),hh(nn,x)','.','Color',col(2,:),'markersize',50*(S.w_f(nn,x)))                   %plot calcium particles
    end

    % spike particles
    subplot(Nrows,Ncols,2), hold on
    bar(Sim.tvec(xind(x)),sum(S.n(:,xind(x)))/5,'EdgeColor',col(2,:),'FaceColor',col(2,:),'BarWidth',bw2)                  %plot spike particles

    % calcium particles
    subplot(Nrows,Ncols,3), hold on
    for nn=1:Sim.N
        plot(Sim.tvec(xind(x)),C(nn,x)','.','Color',col(2,:),'markersize',50*(S.w_f(nn,x)))                   %plot calcium particles
    end
    plot(Sim.tvec(xind(x-1):xind(x)),C(:,x-1:x)','Color',col(2,:))
    
    % print to (color) eps
    fig=figure(2);
    wh=[5 7];
    set(fig,'PaperPosition',[0 11-wh(2) wh]);
    filename = ['C:\D\working_copies\neur_ca_imag\trunk\columbia_talk\for_rec_approx' num2str(x)];
    print('-depsc', filename);

end