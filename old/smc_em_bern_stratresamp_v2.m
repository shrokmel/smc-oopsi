function S = smc_em_bern_stratresamp_v2(Sim,S,k,U_resamp)
% this function does stratified resampling for neuron models with spike
% history terms
%
%% inputs %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Sim       : simulation parameters (eg, dt, N, etc.)
% S         : simulation states (eg, n, lambda, C, h)
% k         : current time step index
% U_resamp  : resampling matrix (so that i needed generate random numbers
%             which each resample, but rather, can just call them

%% outputs %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% %
% S: this has particle states having resampled them, and equalized weights

%% function %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% 0) Compute N_{eff},
Nresamp=k/Sim.frac;                             %increase sample counter
S.Neff(Nresamp)  = 1/sum(S.w_f(:,k).^2);

if S.Neff(Nresamp) < Sim.N/2
    % 1) re-sort to avoid bias due to ordering
    new_ind     = randperm(Sim.N);
    S.p(:,k)    = S.p(new_ind,k);
    S.I(:,k)    = S.I(new_ind,k);
    S.C(:,k)    = S.C(new_ind,k);
    S.w_f(:,k)  = S.w_f(new_ind,k);
    if Sim.M>0
        S.h(:,k,:) = S.h(new_ind,k,:);
    end

    % 2) compute cumulative weights
    cum_w   = cumsum(S.w_f(:,k));                   %get cumulative sum of weights for sampling purposese

    % 3) resample
    for n=1:Sim.N                                   %for each particle
        Nparticle   = find(U_resamp(Nresamp,n)<cum_w,1);%sample
        S.p(n,k)    = S.p(Nparticle,k);             %resample rate
        S.I(n,k)    = S.I(Nparticle,k);             %resample n
        S.C(n,k)    = S.C(Nparticle,k);             %resample C
        if Sim.M>0                                  %if spike history terms
            S.h(n,k,:) = S.h(Nparticle,k,:);        %resample all h's
        end
    end
    S.w_f(:,k)=(1/Sim.N)*ones(Sim.N,1);             %reset weights
end %if Neff<N/2

end %function