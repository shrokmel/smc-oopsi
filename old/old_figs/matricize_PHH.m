clear all, clc,
Sim.T   = 2;
Sim.N   = 3;
t       = 2;
S.w_f   = rand(Sim.N,Sim.T);
w_b     = rand(Sim.N,Sim.T);
oney    = ones(Sim.N,1);
T2      = zeros(Sim.N);

for t=1:Sim.T
    S.w_f(:,t)=S.w_f(:,t)/sum(S.w_f(:,t));
    w_b(:,t)=w_b(:,t)/sum(w_b(:,t));
end

T0 = rand(Sim.N);% T0=exp(sum_lns-mx);
Tn=sum(T0,1);
T=T0./Tn(oney,:);

for j=1:Sim.N
    T2(:,j)=T0(:,j)/sum(T0(:,j));
end
norm(T-T2)

PHHn = (T*S.w_f(:,t-1))';
PHHn2 = PHHn(oney,:)';
PHH =  T .* (w_b(:,t)*S.w_f(:,t-1)')./PHHn2;

w_b(:,t-1)= sum(PHH,1);

for i=1:Sim.N
    for j=1:Sim.N
        PHH2(i,j)=w_b(i,t)*T(i,j)*S.w_f(j,t-1)/(T(i,:)*S.w_f(:,t-1));
    end
end
norm(PHH-PHH2)

PHHn3 = (T0*S.w_f(:,t-1))';
PHHn3 = PHHn3(oney,:)';
PHH3 =  T0 .* (w_b(:,t)*S.w_f(:,t-1)')./PHHn3;
norm(PHH-PHH3)