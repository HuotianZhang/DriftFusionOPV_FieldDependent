function y=blackbody(T,Edistribution)
pc = physconst();
q = pc.q;
h = pc.h;
kbeV = pc.kB_eV;
c = pc.c*100;   % cm/s
i=0;
% bb=0;
bb(:,1)=Edistribution';
for E=Edistribution%=0.001:0.001:4
    i=i+1;
    bb(i,2)=q*q*2*pi*1e3*(q^2/h^3/c^2)*power(E,2).*exp(-E./kbeV/T);%in unit of mA 
%     bb(i,2)=2*pi/(heV^3*c^2)*power(E,2)*exp(-E/kbeV/T);
end
y=bb;
end 