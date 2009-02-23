function GetFig_Sampl2(Sim,R,S,M)

%% preset stuff for fig
figure(2), cla, clf,
set(gcf, 'color', 'w');

gray    = [0.75 0.75 0.75];         %define gray
col     = [0 0 1; 0 .5 0; 1 0 0];   %define colors for mean
ccol    = col+.8; ccol(ccol>1)=1;   %define colors for std

O       = R.O.*repmat([NaN*ones(1,Sim.freq-1) 1],1,Sim.K_o);%make O only be observations (NaN'ing R.O at not observation times)
Oind    = find(~isnan(O));          %find the indices of observations that are not NaN's

xs      = [Sim.tvec(Oind(2)) 1];    %set the limits of the x-axis
xmin    = find(Sim.tvec>xs(1),1);   %index of lower limit on x
xmax    = find(Sim.tvec>xs(2),1)+Sim.dt;%index of upper limit on x
xind    = xmin:xmax;                %indices of x-axis

AX      = [xs 0 1];                 %axes

%get min and max of calcium to normalize within plots
for i=1:2
    cmin(i) = min(min(S(i).C(:,xind)));
    cmax(i) = max(max(S(i).C(:,xind)));
end
cmin=min(cmin(:));          
cmax=max(cmax(:));          

%get forward means and variances
fCbar1   = sum(S(1).w_b.*S(1).C,1);
fnbar1   = sum(S(1).w_b.*S(1).n,1);
fnvar1   = sum((repmat(M(1).nbar,Sim.N,1)-S(1).n).^2)/Sim.N;

fCbar2   = sum(S(2).w_b.*S(2).C,1);
fnbar2   = sum(S(2).w_b.*S(2).n,1);
fnvar2   = sum((repmat(M(2).nbar,Sim.N,1)-S(2).n).^2)/Sim.N;


% set subfig sizes
l1   = .25;     %left of 1st col
w   = .35;      %width of subfigs
b   = .21;      %bottom of subfigs
h   = .3;       %height of subfigs
hs  = .05;      %height spacer
l2  = .05+l1+w; %left of second col
yfs = 16;       %ylabel font size
xfs = 14;       %xlabel font size
tfs = 19;       %title font size

%% plot forward particles
subplot('Position',[l1 (b+h+hs) w h]) %subplot('Position',[left bottom width height])
cla, hold on
plot(Sim.tvec,(S(1).C'-cmin)/(cmax-cmin),'Color',ccol(2,:))                 %plot calcium particles
plot(Sim.tvec,(fCbar1-cmin)/(cmax-cmin),'Color',col(2,:),'linewidth',2)     %plot calcium forward mean
plot(Sim.tvec,(O-cmin)/(cmax-cmin),'ok','LineWidth',.5,'markersize',3)      %plot observations
plot(Sim.tvec,(R.C-cmin)/(cmax-cmin),'color',gray,'LineWidth',1)            %plot true calcium
axis(AX)
set(gca,'YTickLabel',[],'XTickLabel',[])
ylab=ylabel({'Calcium';'Particles'});
set(ylab,'Rotation',0,'HorizontalAlignment','right','verticalalignment','middle','fontsize',yfs)
title('Backwards','fontsize',tfs)

subplot('Position',[l1 b w h]) %subplot('Position',[left bottom width height])
cla, hold on
stem(Sim.tvec,R.n,'Marker','none','Color',gray,'LineWidth',1)               %plot true spikes
BarVar1=fnbar1+fnvar1;                                                      %make var of spikes not exceed 1
BarVar1(BarVar1>1)=1;
stem(Sim.tvec,BarVar1,'Marker','none','Color',ccol(2,:),'LineWidth',2)      %plot forward spike var
stem(Sim.tvec,fnbar1,'Marker','none','Color',col(2,:),'LineWidth',2)        %plot forward spike mean
axis(AX)
set(gca,'YTickLabel',[])
ylab=ylabel({'Spike';'Histogram'});
set(ylab,'Rotation',0,'HorizontalAlignment','right','verticalalignment','middle','fontsize',yfs)
xlab=xlabel('Time (sec)');
set(xlab,'fontsize',xfs)

%% vanilla particle filter

subplot('Position',[l2 (b+h+hs) w h]) %subplot('Position',[left bottom width height])
cla, hold on
plot(Sim.tvec,(S(2).C'-cmin)/(cmax-cmin),'Color',ccol(3,:))
plot(Sim.tvec,(fCbar2-cmin)/(cmax-cmin),'Color',col(3,:),'linewidth',2)
plot(Sim.tvec,(O-cmin)/(cmax-cmin),'ok','LineWidth',0.5,'markersize',3)
plot(Sim.tvec,(R.C-cmin)/(cmax-cmin),'color',gray,'LineWidth',1)
axis(AX)
set(gca,'YTickLabel',[])
set(gca,'XTickLabel',[])
title('Prior','fontsize',tfs)

subplot('Position',[l2 b w h]) %subplot('Position',[left bottom width height])
cla, hold on
stem(Sim.tvec,R.n,'Marker','none','Color',gray,'LineWidth',1)
BarVar2=fnbar2+fnvar2;
BarVar2(BarVar2>1)=1;
stem(Sim.tvec,BarVar2,'Marker','none','Color',ccol(3,:),'LineWidth',2)
stem(Sim.tvec,fnbar2,'Marker','none','Color',col(3,:),'LineWidth',2)
axis(AX)
set(gca,'YTick',[]), set(gca,'YTickLabel',[])
xlab=xlabel('Time (sec)');
set(xlab,'fontsize',xfs)

fig=figure(2);
wh=[6 2]
set(fig,'PaperPosition',[0 11-wh(2) wh]);
print -depsc C:\D\Research\liam\SMC_EM_GLM\sampl