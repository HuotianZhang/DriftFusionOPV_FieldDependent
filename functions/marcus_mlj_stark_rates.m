function [k_f, k_b] = marcus_mlj_stark_rates(Hab, lambda, offset, T, F, r_CT, delta_alpha, S, hw, sigma)
% marcus_mlj_stark_rates - LE->CT and CT->LE transfer rates with a
% high-frequency vibrational mode (Marcus-Levich-Jortner), Gaussian
% disorder of the CT energy, and the Stark shift of the CT state
%
% For a CT state whose dipole makes an angle theta with the field F, the
% free-energy change of the LE -> CT transfer is
%   dG(F, theta) = -offset - e*r_CT*F*cos(theta) - delta_alpha*F^2/2,
% where offset is the free-energy offset between the LE state and the
% thermalised CT population. CT energies are Gaussian-distributed with
% width sigma, so their mean lies sigma^2/(2kT) above the free energy.
%
% The forward rate from the LE state to a CT state of the distribution is
%   k_f = (2 pi/hbar) |Hab|^2 (pi c)^(-1/2) sum_n w_n exp(-(lambda + n hw + dG_mean)^2/c)
% with dG_mean = dG + sigma^2/(2kT), c = 4 lambda kT + 2 sigma^2 (the
% Marcus lineshape convolved with the disorder) and w_n = e^-S S^n/n! the
% Franck-Condon weights of the high-frequency mode (hw >> kT). The back
% rate follows from detailed balance at each orientation,
%   k_b = k_f exp(dG/kT),
% and both are averaged over isotropic orientations (Gauss-Legendre in
% cos(theta)). At zero field k_b/k_f = exp(-offset/kT) for any S, hw and
% sigma; with S = 0 and sigma = 0 this is the classical Marcus rate of
% marcus_equation_stark.
%
% Inputs:
%   Hab         - Electronic coupling (eV)
%   lambda      - Low-frequency (outer) reorganization energy (eV)
%   offset      - LE - CT free-energy offset at zero field (eV)
%   T           - Temperature (K)
%   F           - Field magnitude (V/m), vector
%   r_CT        - Electron-hole separation of the CT state (m)
%   delta_alpha - Polarizability volume change LE -> CT (Angstrom^3)
%   S           - Huang-Rhys factor of the high-frequency mode
%   hw          - Energy of the high-frequency mode (eV)
%   sigma       - Gaussian disorder of the CT energy (eV)
%
% Returns (column vectors, same length as F):
%   k_f - LE -> CT rate (s^-1)
%   k_b - CT -> LE rate (s^-1), before division by RCTE

pc = physconst();
kT = pc.kB_eV*T;
[u, w] = gauss_legendre(64);   % cos(theta) nodes and weights on [-1, 1]
alpha_SI = 4*pi*pc.eps0*delta_alpha*1e-30;   % F m^2
F = F(:);
dG = -offset - r_CT*F*u' - 0.5*alpha_SI*F.^2/pc.q*ones(1, numel(u));   % eV, numel(F) x numel(u)
dG_mean = dG + sigma^2/(2*kT);
c = 4*lambda*kT + 2*sigma^2;   % eV^2

if S > 0
    n = 0:ceil(S + 10*sqrt(S) + 10);
    wn = exp(-S + n*log(S) - gammaln(n + 1));
else
    n = 0;
    wn = 1;
end
kf = zeros(size(dG));
for j = 1:numel(n)
    kf = kf + wn(j)*exp(-(lambda + n(j)*hw + dG_mean).^2/c);
end
kf = (2*pi/pc.hbar)*(Hab*pc.q)^2/sqrt(pi*c*pc.q^2)*kf;
kb = kf.*exp(dG/kT);

k_f = 0.5*kf*w;
k_b = 0.5*kb*w;

end

function [x, w] = gauss_legendre(n)
% Gauss-Legendre nodes and weights on [-1, 1] (Golub-Welsch)
k = 1:n-1;
b = k./sqrt(4*k.^2 - 1);
[V, D] = eig(diag(b, 1) + diag(b, -1));
[x, i] = sort(diag(D));
w = 2*V(1, i)'.^2;
end
