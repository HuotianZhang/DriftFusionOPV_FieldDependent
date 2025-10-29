function ket = marcus_equation_stark(Hab, lambda, deltaG, T, F, d_CT)
  % Physical constants (CODATA 2018 values)
  epsilon0 = 8.8541878128e-12; % Vacuum permittivity [F m^-1]
  hbar = 1.054571817e-34;      % Reduced Planck constant [J s]
  k = 1.380649e-23;            % Boltzmann constant [J K^-1]
  q = 1.602176634e-19;         % Elementary charge [C]
  d_TCNQ = 1.5e-10;            % (Å) excited state electric dipole length
  alpha_prime_TCNQ = 85;       % (Å^3) cgs units ->SI units
  
  alpha_TCNQ = 4*pi*epsilon0*alpha_prime_TCNQ*1e-30; %Å^3 to m^3 (F m^2)
  alpha_CT = alpha_TCNQ*(d_CT/d_TCNQ)^4;
  deltaE_CT = -1/2*alpha_CT*F*abs(F)/q;


  % Calculate the charge transfer rate
  ket = (2*pi/hbar) * abs(Hab*q)^2 * (1/sqrt(4*pi*lambda*k*T*q)) * exp(-(lambda + deltaG + deltaE_CT).^2 / (4*lambda*k*T/q));

end

