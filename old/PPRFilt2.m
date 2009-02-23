function n = PPRFilt2(F,dt,P)
% this m-file generates runs blind projection pursuit regression algorithm
% for the following model:
%
% F_t = C_t + eps_t, eps_t ~ N(0,sigma_F^2)
% C_t - C_{t-1} = -dt/tau_c (C_{t-1}-C_0) + A n_t
%
% we iteratively solve:
% min_{n} sum_t (F_t - C_t)^2
% min_{A,tau_c,C_0} = sum_t (F_t - C_t)^2
%
% Input---
% F:        a vector fluorescence observations
% dt:       time step size
% P.        parameter structure - the only parameters that matter are:
%   A:      jump size
%   tau_c:  decay time constant
%   C_0:    baseline calcium concentration
%   sigma_F:sd on observation noise
%
% Output---
% n:        list of spike times inferred using the ppr algorithm

T       = length(F);    %number of time steps
z       = zeros(1,T);   %vector of zeros for speeding things up
n       = z;            %init est spike train
ker_err = Inf;
ker_con = false;

while ker_con == false %spt_err >= ker_err
    n_est   = z;        %init est spike train
    C       = z;        %init est calcium
    resid   = F;        %resid error
    err     = sum(resid.^2);%resid squared error
    spt_err = err;      %new error to compare whether adding an additional spike increases or decreases residual square error
    k       = P.A*exp(-[0:dt:T*dt-dt]/P.tau_c);%calcium kernel
    spt_con = false;

    while spt_con   == false %err >= spt_err%if adding a spike REDUCES residual square error,  iterate
        [foo spt]   = max(filter(P.A,[1 -(1-dt/P.tau_c)],resid(T:-1:1)));
        spt         = T - spt;              %find time of next spike to add
        new_sp      = [z(1:spt) k(1:end-spt)];%fast way to get convolved new spike with kernel
        resid       = resid - new_sp;       %update new residual
        err         = sum(resid.^2);        %update new error
        if err      <= spt_err              %if adding a spike REDUCES residual square error
            C       = C + new_sp;           %update inferred calcium
            n_est(spt+1)= 1;                %update the estimated spike train
            spt_err = err;                  %udate residual square error to be the error from the last iteration
        else
            spt_con = true;
%             spt_err = err;
        end
    end %end adding spikes using this kernel

    if spt_err      < ker_err
        ker_err     = spt_err;
%         H           = [C(1:end-1); n_est(2:end); 1+z(1:end-1)];
%         Q           = H*H'/T;
%         L           = H*C(1:end-1)'/T;
%         [x foo]     = quadprog(Q, L,[],[],[],[],[0 0 0],[inf inf inf],-[1-dt/P.tau_c, P.A, P.C_0*dt/P.tau_c]);
%         P.tau_c     = dt/(1-x(1));
%         P.A         = x(2);
%         P.C_0       = x(3)*P.tau_c/dt;
%         P.sigma_F   = sqrt((0.5*x'*Q*x + L'*x))/T;
        n           = n_est;
    else
        ker_con     = true;
    end
end