function GetPriorFig(Sim,R,S,B,M)

O=R.O.*repmat([NaN*ones(1,Sim.frac-1) 1],1,Sim.K_o);
pf=[2 6];
xs=[100:200];
cmin1=min(min(S{pf(1)}.C(:,xs)));
cmin2=min(min(S{pf(2)}.C(:,xs)));
cmax1=max(max(S{pf(1)}.C(:,xs)));
cmax2=max(max(S{pf(2)}.C(:,xs)));
%%
k=Sim.K;
figure(3), clf, 
subplot(3,2,1), hold on
plot(Sim.tvec(xs),R.p(xs),'k')
axis([min(Sim.tvec(xs)) max(Sim.tvec(xs)) 0 max(R.p(xs))])

subplot(3,2,3), hold on
plot(Sim.tvec(xs),(S{pf(1)}.C(:,xs)'-cmin1)/(cmax1-cmin1),'Color',[0.75 0.75 0.75])
plot(Sim.tvec(xs),(O(xs)-cmin1)/(cmax1-cmin1),'ok','LineWidth',2)
plot(Sim.tvec(xs),(R.C(xs)-cmin1)/(cmax1-cmin1),'k','LineWidth',2)
stem(Sim.tvec(xs),R.I(xs)/10,'Marker','none','Color','k','LineWidth',2)
axis([min(Sim.tvec(xs)) max(Sim.tvec(xs)) 0 1])

subplot(3,2,5), hold on
plot(Sim.tvec(xs),(S{pf(2)}.C(:,xs)'-cmin2)/(cmax2-cmin2),'Color',[0.75 0.75 0.75])
plot(Sim.tvec(xs),(O(xs)-cmin2)/(cmax2-cmin2),'ok','LineWidth',2)
plot(Sim.tvec(xs),(R.C(xs)-cmin2)/(cmax2-cmin2),'k','LineWidth',2)
stem(Sim.tvec(xs),R.I(xs)/10,'Marker','none','Color','k','LineWidth',2)
axis([min(Sim.tvec(xs)) max(Sim.tvec(xs)) 0 1])

subplot(3,2,2), hold on
plot(Sim.tvec(xs),R.p(xs),'k')
axis([min(Sim.tvec(xs)) max(Sim.tvec(xs)) 0 max(R.p(xs))])

subplot(3,2,4), hold on
plot(Sim.tvec(xs),(S{pf(1)}.C(:,xs)'-cmin1)/(cmax1-cmin1),'Color',[0.75 0.75 0.75])
plot(Sim.tvec(xs),(O(xs)-cmin1)/(cmax1-cmin1),'ok','LineWidth',2)
plot(Sim.tvec(xs),(R.C(xs)-cmin1)/(cmax1-cmin1),'k','LineWidth',2)
stem(Sim.tvec(xs),R.I(xs)/10,'Marker','none','Color','k','LineWidth',2)
axis([min(Sim.tvec(xs)) max(Sim.tvec(xs)) 0 1])

subplot(3,2,6), hold on
plot(Sim.tvec(xs),(S{pf(2)}.C(:,xs)'-cmin2)/(cmax2-cmin2),'Color',[0.75 0.75 0.75])
plot(Sim.tvec(xs),(O(xs)-cmin2)/(cmax2-cmin2),'ok','LineWidth',2)
plot(Sim.tvec(xs),(R.C(xs)-cmin2)/(cmax2-cmin2),'k','LineWidth',2)
stem(Sim.tvec(xs),R.I(xs)/10,'Marker','none','Color','k','LineWidth',2)
axis([min(Sim.tvec(xs)) max(Sim.tvec(xs)) 0 1])