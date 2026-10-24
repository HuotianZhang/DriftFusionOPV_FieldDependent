function ket = marcus_equation_stark(Hab, lambda, deltaG, T, F, r_CT, delta_alpha, direction)
% marcus_equation_stark - Marcus LE<->CT transfer rate in an electric field,
% with the linear and quadratic Stark shifts of the CT state, averaged over
% an isotropic distribution of CT-state orientations
%
% In a field of magnitude F, a CT state whose dipole makes an angle theta
% with the field has the energy
%
%   E_CT(F, theta) = E_CT(0) - |Delta_mu| F cos(theta) - 1/2 Delta_alpha F^2
%
% with |Delta_mu| = e r_CT the change in dipole moment on going from LE to
% CT (linear Stark effect) and Delta_alpha the change in polarizability
% (quadratic Stark effect); the LE state is taken as unshifted. These are
% the Liptay parameters measured by electroabsorption. The Marcus rate
%
%   k = (2 pi/hbar) |Hab|^2 (4 pi lambda kT)^(-1/2) exp(-(lambda + dG)^2/(4 lambda kT))
%
% is evaluated with dG = deltaG + direction*(E_CT(F, theta) - E_CT(0)) and
% averaged over u = cos(theta) uniform in [-1, 1]. With s = |Delta_mu| F
% and x0 = lambda + deltaG - direction*Delta_alpha F^2/2 the average is
%
%   <exp(-(x0 - s u)^2/c)> = sqrt(pi c)/(4 s) [erf((x0 + s)/sqrt(c)) - erf((x0 - s)/sqrt(c))]
%
% with c = 4 lambda kT. Each orientation obeys detailed balance, so the
% zero-field rates are unchanged by the Stark parameters.
%
% Inputs:
%   Hab         - Electronic coupling (eV)
%   lambda      - Reorganization energy (eV)
%   deltaG      - Zero-field free energy change of the transfer (eV)
%   T           - Temperature (K)
%   F           - Field magnitude (V/m), scalar or array
%   r_CT        - Electron-hole separation of the CT state (m); |Delta_mu| = e r_CT
%   delta_alpha - Polarizability volume change LE -> CT (Angstrom^3)
%   direction   - +1 for LE->CT, -1 for CT->LE
%
% Returns:
%   ket - Orientation-averaged rate (s^-1), same size as F

pc = physconst();
kT = pc.kB_eV*T;                                    % eV
c = 4*lambda*kT;                                    % eV^2
alpha_SI = 4*pi*pc.eps0*delta_alpha*1e-30;          % F m^2
s = r_CT*abs(F);                                    % e r_CT F in eV
x0 = lambda + deltaG - direction*0.5*alpha_SI*F.^2/pc.q;   % eV

avg = exp(-x0.^2/c);
lin = s > 0;
avg(lin) = sqrt(pi*c)./(4*s(lin)).*erf_diff((x0(lin) - s(lin))/sqrt(c), (x0(lin) + s(lin))/sqrt(c));

ket = (2*pi/pc.hbar)*(Hab*pc.q)^2/sqrt(4*pi*lambda*kT*pc.q^2)*avg;

end

function d = erf_diff(a, b)
% erf(b) - erf(a) for a <= b, using erfc in the tails to avoid cancellation
d = erf(b) - erf(a);
up = a > 0;
d(up) = erfc(a(up)) - erfc(b(up));
dn = b < 0;
d(dn) = erfc(-b(dn)) - erfc(-a(dn));
end
