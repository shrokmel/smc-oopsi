function [S M] = smc_em_bern_FoBaMo_v2(Sim,R,P)

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
    fprintf('\n forward mixture step..........')
    S = smc_em_bern_k_comp_BackSampl_v1(Sim,R,B);
else
    fprintf('\n forward prior step..........')
    S = smc_em_bern_PriorSampl_v1(Sim,R,B);
end

%% backward step
fprintf('\n backward step..........')
S.w_b = smc_em_bern_backwardPF_v7(Sim,S,B);

%%   compute moments
M.nbar = sum(S.w_b.*S.n,1);
M.nvar = sum((repmat(M.nbar,Sim.N,1)-S.n).^2)/Sim.N;

M.Cbar = sum(S.w_b.*S.C,1);
M.Cvar = sum((repmat(M.Cbar,Sim.N,1)-S.C).^2)/Sim.N;