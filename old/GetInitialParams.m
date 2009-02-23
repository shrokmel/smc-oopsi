function EI = GetInitialParams(Sim,F)

[Sim P] = InitializeStuff;

EI          = P;                    %initialize parameter estimates

% EI.k        = 0*EI.k;
% EI.omega    = 0;

EI.tau_c    = 1.1*EI.tau_c;
EI.A        = 1.1*EI.A;
EI.C_0      = 1.1*EI.C_0;
EI.sigma_c  = 10*EI.sigma_c;

% %let O be only observations at sample times
% O       = R.F.*repmat([NaN*ones(1,Sim.freq-1) 1],1,Sim.T_o);
% Onan    = find(~isfinite(O));
% Oind    = find(isfinite(O));
% O(Onan) = [];
% finv	= ((P.k_d.*(P.beta-O))./(O-P.beta-P.alpha)).^(1/P.n);
% 
% %maximize tau_c, A, and C_0
% A   = [finv(1:end-1)*Sim.dt; -R.n(2:end); -repmat(Sim.dt,1,Sim.T-1)]';
% b   = (R.C(2:end)-R.C(1:end-1))';
% H = A'*A;
% f = A'*b;
% [minobsabc] = quadprog(H, f,[],[],[],[],[0 0 0],[inf inf inf]);
% sigobs=sqrt(sum((R.C(2:end)-R.C(1:end-1)*(1-Sim.dt*minobsabc(1))-minobsabc(2)*R.n(2:end)-Sim.dt*minobsabc(3)).^2)/(Sim.T*Sim.dt));
% [1/minobsabc(1), minobsabc(2), minobsabc(3)/minobsabc(1), sigobs; P.tau_c, P.A, P.C_0, P.sigma_c];
% 
% EI.tau_c    = 1/minobsabc(1);
% EI.A        = minobsabc(2);
% EI.C_0      = minobsabc(3)/minobsabc(1);
% EI.sigma_c  = sigobs;

end