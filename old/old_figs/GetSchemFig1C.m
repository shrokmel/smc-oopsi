function GetSchemFig1C(Sim,R,B,M)

O=R.O.*repmat([NaN*ones(1,Sim.frac-1) 1],1,Sim.K_o);
for k=1/Sim.dt:Sim.K-1/Sim.dt
    sumn(k)=sum(R.I(k:k+1/Sim.dt));
end
[maxn ind]=max(sumn);
int     = 0.25;
xs      = [1 1.5];%[ind*Sim.dt-int ind*Sim.dt+int];
xmin    = find(Sim.tvec>xs(1),1);
xmax    = find(Sim.tvec>xs(2),1)+Sim.dt;
xind    = [xmin:xmax];

pmax = max(R.p(xind));
pAX  = [xs 0 pmax];

spikemax= max(1,max(R.I(xind)));
spikeAX = [xs 0 spikemax];

cmin=min(min(min(R.C(xind)),min(M.Cbar(xind))),min(O(xind)));
cmax=max(max(max(R.C(xind)),max(M.Cbar(xind))),max(O(xind)));

gray=[0.75 0.75 0.75];

figure
Nsubs=5;

%% filtered stimulus
i=1; subplot(Nsubs,1,i), cla
plot(Sim.tvec,B.kx,'k','LineWidth',2)
set(gca,'XTickLabel',[]), set(gca,'YTickLabel',[])
set(gca,'XTick',[]), set(gca,'YTick',[])
axis([xs min(B.kx(xind)) max(B.kx(xind))])

%% hidden states
i=i+1; subplot(Nsubs,1,i), cla, hold on
plot(Sim.tvec,-1*R.I+1.95,'+','Color',gray,'LineWidth',2)
plot(Sim.tvec,(R.C-cmin)/(cmax-cmin),'Color',gray,'LineWidth',2)
plot(Sim.tvec,R.p/pmax,'-','Color',gray,'LineWidth',1)
set(gca,'XTickLabel',[]), set(gca,'YTickLabel',[])
set(gca,'XTick',[]), set(gca,'YTick',[])
axis(spikeAX)

%% observation state
i=i+1; subplot(Nsubs,1,i), cla, hold on
plot(Sim.tvec,-1*R.I+1.95,'+','Color',gray,'LineWidth',2)
plot(Sim.tvec,(R.C-cmin)/(cmax-cmin),'Color',gray)
plot(Sim.tvec,(O-cmin)/(cmax-cmin),'ok','LineWidth',2)
set(gca,'XTickLabel',[]), set(gca,'YTickLabel',[])
set(gca,'XTick',[]), set(gca,'YTick',[])
axis(spikeAX)

%% inferred calcium
i=i+1; subplot(Nsubs,1,i), cla, hold on, 

col=[0 0 1; 0 .5 0; 1 0 0; 0 1 1; 1 0 1; 1 .5 0; 1 .5 1];
ccol=col+.8; ccol(ccol>1)=1;
ind=Sim.K:-1:1;

h=fill([Sim.tvec Sim.tvec(ind)],([M.Cbar-M.Cvar M.Cbar(ind)+M.Cvar(ind)]-cmin)/(cmax-cmin),ccol(1,:));
set(h,'edgecolor',ccol(1,:))
plot(Sim.tvec,(M.Cbar-cmin)/(cmax-cmin),'linewidth',2,'color',col(1,:))

plot(Sim.tvec,-1*R.I+1.95,'+','Color',gray,'LineWidth',2)
plot(Sim.tvec,(R.C-cmin)/(cmax-cmin),'LineWidth',2,'Color',gray)
% plot(Sim.tvec,(O-cmin)/(cmax-cmin),'o','LineWidth',1,'Color',gray);

set(gca,'XTickLabel',[]), set(gca,'YTickLabel',[])
set(gca,'XTick',[]), set(gca,'YTick',[])
axis(spikeAX)

%% inferred spikes
i=i+1; subplot(Nsubs,1,i), cla, hold on, 

h=fill([Sim.tvec Sim.tvec(ind)],[M.Ibar-M.Ivar M.Ibar(ind)+M.Ivar(ind)],ccol(1,:));
set(h,'edgecolor',ccol(1,:))
plot(Sim.tvec,M.Ibar,'linewidth',1,'color',col(1,:))

plot(Sim.tvec,-1*R.I+1.95,'+','Color',gray,'linewidth',2)
plot(Sim.tvec,(O-cmin)/max(O(xind)),'o','LineWidth',2,'Color',gray);
set(gca,'YTickLabel',[]), %set(gca,'XTickLabel',[])
set(gca,'YTick',[]), %set(gca,'XTick',[])
axis(spikeAX)