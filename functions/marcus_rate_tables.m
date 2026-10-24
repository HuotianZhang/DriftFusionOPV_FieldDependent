function [E_values, k_values, k_bak_values] = marcus_rate_tables(lambda, RCT, offset, T, RCTE, delta_alpha)
% marcus_rate_tables - Field-dependent LE->CT and CT->LE rate tables for pndriftHCT
%
% The rates include the Stark shift of the CT state,
%   E_CT(F) = E_CT(0) - e*RCT*F*cos(theta) - delta_alpha*F^2/2,
% averaged over isotropic CT orientations (see marcus_equation_stark).
% The back-transfer rate is the Marcus CT->LE rate divided by RCTE, so that
% at zero field k_bak/k = exp(-offset/kT)/RCTE. This is the same detailed
% balance that deviceparams.generateDeviceparams uses for kforEx, so the
% equilibrium densities (CT0, Ex0) stay consistent with the solver rates.
% The Stark shift vanishes at zero field, so this holds for any RCT and
% delta_alpha.
%
% Inputs:
%   lambda      - Reorganization energy (eV)
%   RCT         - Electron-hole separation of the CT state (nm); sets the
%                 CT dipole |Delta_mu| = e*RCT (1 nm corresponds to 48.0 D).
%                 0 switches the linear Stark shift off.
%   offset      - Energy offset between excited state and CT state (eV)
%   T           - Temperature (K); use the device temperature (Prec.const.T)
%   RCTE        - Ratio of CT to LE density of states (Prec.params.RCTE)
%   delta_alpha - Polarizability volume change LE -> CT, Delta_alpha
%                 (Angstrom^3). 0 switches the quadratic Stark shift off.
%
% Outputs (column vectors):
%   E_values     - Electric field (V/m)
%   k_values     - LE->CT rate (s^-1)
%   k_bak_values - CT->LE rate (s^-1)
%
% Store them in a layer as Layers{kk}.marcus = struct('E',E,'k',k,'k_bak',k_bak,'weight',1).
%
% Example:
%   [E, k, k_bak] = marcus_rate_tables(0.5, 1.5, 0.05, 300, 0.1, 8.5e5);

kLECT = kDis_stark(lambda, RCT, offset, T, delta_alpha);
kCTLE = kBak_stark(lambda, RCT, offset, T, delta_alpha);

E_values = kLECT(:, 1);
k_values = kLECT(:, 2);
k_bak_values = kCTLE(:, 2) / RCTE;

end
