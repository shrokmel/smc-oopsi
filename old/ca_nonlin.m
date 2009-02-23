function ca_nonlin(o)
% F ~ N[f(C),g(C)]

% set parameters
n       = 1.2;                      %hill coefficient
k_d     = 1.3;                      %dissociation constant
alpha   = 1;                        %mean gain
beta    = 0;                       %mean offset
gamma   = 1e-3;                     %var gainh
zeta    = .5e-3;                    %var offset

% compute mean
finv    = ((k_d*(o-beta))./(alpha-o+beta)).^(1/n); %initialize search with f^{-1}(o)
ffit    = fminunc(@fnlogL,finv);     %max P(O|H)

% compute variance
syms Cest
logL=-fnlogL(Cest);
dlogL=diff(logL,'Cest');            %dlog L / dC
ddlogL=diff(dlogL,'Cest');          %ddlog L / dCC
VC = -1/ddlogL;                     %neg inverse
Cest = ffit;                        %eval at max P(O|H)
varF=eval(VC);                      %variance approximation

    function mu_F = fmu_F(C)        %this function compute E[F]=f(C)
        mu_F    = alpha*C.^n./(C.^n+k_d)+beta; 
    end

    function var_F = fvar_F(C)      %this function compute V[F]=f(C)
        var_F   = gamma*C.^n./(C.^n+k_d)+zeta;
    end

    function logL = fnlogL(C)        %this function compute log L = log P(O|H)
        logL = (((o-fmu_F(C)).^2)./fvar_F(C)+log(fvar_F(C)))/2;
    end


%% just find max to check numerically
C       = 0.01:.001:50;             %possible values for C
mu_F    = fmu_F(C);                 %E[F] forall C
var_F   = fvar_F(C);                %V[F] forall C
L       = -fnlogL(C);                %L eval at o forall C
[foo ind]=max(L);                   %get max numerically to check
fnum    = C(ind);                   

% check approx quality
Lapprox = 1/sqrt(2*pi*varF)*exp(-.5*(ffit-C).^2/varF);

% plot E[F] vs. log C
figure(11); clf, 
subplot(311);
semilogx(C,mu_F); ylabel('mean F'); grid on
axis('tight');  

% plot var[F] vs. log C
subplot(312);
semilogx(C,sqrt(var_F)); ylabel('noise std')
axis('tight')

% plot L vs. C
subplot(313); hold on; title(['o=' num2str(o)])
plot(C,(exp(L)+o)/sum(exp(L)+o)); ylabel('L');
plot(C, Lapprox/sum(Lapprox),'-k'); ylabel('L approx')
axis('tight')
end