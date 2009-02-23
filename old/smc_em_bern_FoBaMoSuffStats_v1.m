function [S M] = smc_em_bern_FoBaMoSuffStats_v1(Sim,R,P)

%% makes code prettier :-)
B.sig2_c    = P.sigma_c^2*Sim.dt;
B.sig2_o    = P.sigma_o^2;
B.a         = 1-Sim.dt/P.tau_c;
B.beta      = P.beta;
B.kx        = P.k'*Sim.x;
if Sim.M>0
    B.sig2_h    = P.sigma_h.^2*Sim.dt;
    B.g         = 1-Sim.dt/P.tau_h;
    B.omega     = P.omega;
end

%% forward step
if Sim.van==false
    S = smc_em_bern_BackSampl_v2(Sim,R,B);
else
    S = smc_em_bern_PriorSampl_v1(Sim,R,B);
end

%% initialize stuff for backwards step and suff stats
S.w_b   = 1/Sim.N*ones(Sim.N,Sim.T);
ln_Pn   = zeros(Sim.N,1);
oney    = ones(Sim.N,1);
% M.Q     = zeros(2,2);
% M.L     = zeros(2,1);
% M.u     = 0;
% for m = 1:Sim.M,
%     M.v{m} = 0;
% end
syms    Ptau_c Pbeta

M.Q     = zeros(2,2);
M.L     = zeros(2,1);
M.u     = 0;
for m = 1:Sim.M,
    M.v{m} = 0;
end

%% get suff stats
for t=Sim.T-1:-1:2

    C1 = S.C(:,t);
    n1 = S.n(:,t);

    ln_Pn(n1==1)  = log(S.p(n1==1,t));
    ln_Pn(~n1)    = log(1-S.p(~n1,t));

    C1mat = C1(:,oney); %C1b= repmat(S.C(:,t),1,Sim.N);

    C0 = B.a*S.C(:,t-1)+B.beta*n1;
    C0mat = C0(:,oney)';%C0a = repmat(S.C(:,t-1)',Sim.N,1); n0 = repmat(n1',Sim.N,1); C0b  = B.a*C0a+B.beta*n0;

    ln_PC_Cn    = -0.5*(C0mat - C1mat).^2/B.sig2_c;

    ln_Ph_hn    = zeros(Sim.N);
    ln_Ph_hn2   = zeros(Sim.N);
    for l=1:Sim.M
        h1 = S.h(:,t,l);
        h1 = h1(:,oney);%h1b = repmat(S.h(:,t,l),1,Sim.N);
        h0 = B.g(l)*S.h(:,t-1,l)+S.n(:,t-1);
        h0 = h0(:,oney)';%h0b = repmat(B.g(l)*S.h(:,t-1,l)'+S.n(:,t-1)',Sim.N,1);
        ln_Ph_hn2 = ln_Ph_hn2 - 0.5*(h0 - h1).^2/B.sig2_h(l);
    end

    sum_lns = ln_Pn(:,oney)+ln_PC_Cn + ln_Ph_hn;
    mx      = max(sum_lns,[],1);
    mx      = mx(oney,:);
    T0      = exp(sum_lns-mx);
    Tn      = sum(T0,1);
    T       = T0./Tn(oney,:);%Tb  = scale_cols(T0,1./Tn);

    PHHn    = (T*S.w_f(:,t))';
    PHHn2   = PHHn(oney,:)';%PHHn2b = repmat(PHHn',1,Sim.N);
    PHH     = T .* (S.w_b(:,t)*S.w_f(:,t)')./PHHn2;

    S.w_b(:,t-1)= sum(PHH,1);

    C01 = (S.C(:,t-1)*Sim.dt);
    %n01 = -n1;     %PHHT  = PHH'; %Xterms = -n1*S.C(:,t-1)'*Sim.dt;  %bmatT = bmat';

    M.Q(1,1) = M.Q(1,1) + C01'*PHH*C01; %sum(PHHT(:).*repmat((S.C(:,t-1)*Sim.dt).^2,Sim.N,1));
    M.Q(1,2) = M.Q(1,2) - n1'*PHH*C01; %sum(PHH(:).*Xterms(:));
    M.Q(2,2) = M.Q(2,2) + n1'*PHH*n1; %sum(PHH(:).*repmat((-n1).^2,Sim.N,1));

    bmat = C1mat-repmat(S.C(:,t-1)',Sim.N,1);
    bPHH = PHH.*bmat;

    M.L(1) = M.L(1) + sum(bPHH*C01); %sum(PHHT(:).*(2*repmat(S.C(:,t-1)*Sim.dt,Sim.N,1).*bmatT(:)));
    M.L(2) = M.L(2) - sum(bPHH*n1); %sum(PHH(:).*(2*repmat(-n1,Sim.N,1).*bmat(:)));

    if mod(t,100)==0
        fprintf('backward step %d\n',t)
    end

end
M.Q(2,1) = M.Q(1,2);
M.L = 2*M.L;

%%   get moments
M.nbar = sum(S.w_b.*S.n,1);
M.nvar = sum((repmat(M.nbar,Sim.N,1)-S.n).^2)/Sim.N;

M.Cbar = sum(S.w_b.*S.C,1);
M.Cvar = sum((repmat(M.Cbar,Sim.N,1)-S.C).^2)/Sim.N;
