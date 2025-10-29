function y=blackbody(T,Edistribution)
% Physical constants (CODATA 2018 values)
q = 1.602176634e-19;    % Elementary charge [C]
h = 6.62607015e-34;     % Planck constant [J s]
kbeV=8.6173324e-5;      % Boltzmann constant [eV K^-1]
c = 2.99792458e10;      % Speed of light [cm s^-1]
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