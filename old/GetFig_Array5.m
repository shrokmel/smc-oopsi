function GetFig_Array5(Sim,R,M,Os,A)

%% preset stuff for fig
figure(3), clf, cla                 %clear the fig
set(gcf, 'color', 'w');             %make background color white

Nrows   = length(A.sig_os);                %rows are different observation noise
Ncols   = length(A.freq);             %columns are different sampling frequencies

gray    = [0.75 0.75 0.75];         %define gray
col     = [0 0 1; 0 .5 0; 1 0 0];   %define colors for mean
ccol    = col+.8; ccol(ccol>1)=1;   %define colors for std
ind     = Sim.T:-1:1;               %inverse indices for 'fill' function

tl   = [.05 0.25];                  %tick length
yfs  = 16;                          %ylabel font size
xfs  = 14;                          %xlabel font size

xs      = [Sim.tvec(Sim.freq) Sim.tvec(end-Sim.freq*2)];%the limits of x-axis on which to plot things
xmin    = find(Sim.tvec>xs(1),1);   %find index of first time step
xmax    = find(Sim.tvec>xs(2),1)+Sim.dt;%find index of last time step
xind    = xmin:xmax;                %indices of x-axis

for i=1:Ncols                       %find effective min and max for each simulation
    for n=1:Nrows
        Omin(i,n)   = min(Os{n,i});
        Omax(i,n)   = max(Os{n,i});
        cmin(i,n)   = min(M(n,i).Cbar(xind)-sqrt(M(n,i).Cvar(xind)));
        cmax(i,n)   = max(M(n,i).Cbar(xind)+sqrt(M(n,i).Cvar(xind)));
    end
end
cmin=min(min(cmin(:)), min(Omin(:)));                  %use cmin and cmax to normalize...
cmax=max(max(cmax(:), Omax(:)));                  %all the calcium plots to go between 0 and 1


%% make fig
for i=1:Ncols
    Sim.freq    = A.freq(i);                                                              %set frequency
    Sim.T_o     = Sim.T/Sim.freq;                                                       %number of observations
    for n=1:Nrows
        clear O Onan Oind Ointer
        O           = Os{n,i}.*repmat([NaN*ones(1,Sim.freq-1) 1],1,Sim.T_o);%let O be only observations at sample times
        ONaNind     = find(~isfinite(O));
        Oind        = find(isfinite(O));
        O(ONaNind)  = [];

        j=(Nrows-n)*(Ncols)+i;                                                          %index of subplot
        subplot(Nrows,Ncols,j), cla, hold on

        plot(Oind*Sim.dt,(O-cmin)/(cmax-cmin)+1,'.k','LineWidth',1,'markersize',7)         %plot observations
        plot(Sim.tvec,ones(size(Sim.tvec)),'k')                                         %plot a line dividing calcium and spikes

        % plot spike stuff
        ptilesj = ptiles{i,n};
        hfill=fill([Sim.tvec Sim.tvec(ind)],([ptilesj(1,:) ptilesj(2,ind)]-cmin)/(cmax-cmin)+1,ccol(i,:));
        set(hfill,'edgecolor',ccol(2,:))
        plot(Sim.tvec,(ptiles(2,:)-cmin)/(cmax-cmin)+1,'linewidth',2,'color',col(2,:))

        stem(Sim.tvec,R.n,'Marker','none','Color',gray,'LineWidth',1)                   %plot actual spikes
        BarVar=M(n,i).nbar+M(n,i).nvar;                                                 %make sure var of spikes doesn't get larger than 1
        BarVar(BarVar>1)=1;
        stem(Sim.tvec,BarVar,'Marker','none','Color',ccol(2,:),'LineWidth',2)           %plot variance of spikes
        stem(Sim.tvec,M(n,i).nbar,'Marker','none','Color',col(2,:),'LineWidth',2)       %plot mean of spikes
        axis([xs 0 2])

        % set labels and such
        set(gca,'TickLength',tl,'XTick',xs(1):.1:xs(2))
        set(gca,'XTickLabel',[],'YTickLabel',[]),

        if n==1,
            xlab=[num2str(1/(A.freq(i)*Sim.dt)) ' Hz'];
            set(get(gca,'XLabel'),'String',xlab,'fontsize',xfs),
        end
        if i==1,
            ylab=[num2str(A.sig_os(n)/A.sig_os(1)) ' sigma_o'];
            set(get(gca,'YLabel'),...
                'String',texlabel(ylab),...
                'fontsize',yfs,...
                'Rotation',0,...
                'HorizontalAlignment','right',...
                'verticalalignment','middle',...
                'fontsize',yfs,...
                'color','k')

        end
    end
end

%% add some stuff to make fig pretty
annotation('arrow',[0.07 0.07],[0.4084 0.628],'linewidth',2);   	%yaxis arrow  %[x(1) x(2)], [y(1) y(2)]
annotation('arrow',[0.6219 0.4156],[0.07 0.07],'linewidth',1.5);    %xaxis arrow

text('Interpreter','tex',...
    'String','Increasing Sampling Frequency',...
    'Position',[-2.355 -12.33 17.32],...
    'FontSize',14,...
    'FontName','Helvetica')

text('Interpreter','tex',...
    'String','Increasing Observation Noise',...
    'Position',[-4.588 -7.46 17.32],...
    'FontSize',14,...
    'FontName','Helvetica',...
    'Rotation',90)


%% print fig to epsc
fig=figure(3);
bgr=[7 7];
set(fig,'PaperPosition',[0 11-bgr(2) bgr]);
print -depsc C:\D\Research\liam\SMC_EM_GLM\array