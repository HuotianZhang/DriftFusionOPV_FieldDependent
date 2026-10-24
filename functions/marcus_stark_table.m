function table = marcus_stark_table(lambda, RCT, deltaG, direction, T, delta_alpha)
% marcus_stark_table - Marcus transfer rate versus electric field, with the
% linear and quadratic Stark shifts of the CT state (see marcus_equation_stark)
%
% Inputs:
%   lambda      - Reorganization energy of the LE<->CT transfer (eV)
%   RCT         - Electron-hole separation of the CT state (nm); sets the
%                 CT dipole |Delta_mu| = e*RCT (linear Stark shift)
%   deltaG      - Zero-field free energy change of the transfer (eV):
%                 -offset for LE->CT, +offset for CT->LE
%   direction   - +1 for LE->CT, -1 for CT->LE
%   T           - Temperature (K)
%   delta_alpha - Polarizability volume change LE -> CT (Angstrom^3);
%                 quadratic Stark shift -Delta_alpha*F^2/2
%
% Returns:
%   table - [F, k]: field F (V/m) in the first column, rate k (s^-1) in the
%           second. The Marcus rate is scaled by 0.1, equivalent to an
%           electronic coupling of sqrt(0.1)*Hab.

Hab = 0.01;              % Electronic coupling matrix element (eV)
F_values = (0:1e5:5e7)'; % V/m

ket = 0.1*marcus_equation_stark(Hab, lambda, deltaG, T, F_values, RCT*1e-9, delta_alpha, direction);
table = [F_values ket];

end
