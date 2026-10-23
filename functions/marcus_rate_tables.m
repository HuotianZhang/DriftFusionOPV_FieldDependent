function [E_values, k_values, k_bak_values] = marcus_rate_tables(lambda, RCT, offset, T, RCTE)
% marcus_rate_tables - Field-dependent LE->CT and CT->LE rate tables for pndriftHCT_forMarcus
%
% The back-transfer rate is the Marcus CT->LE rate divided by RCTE, so that
% at zero field k_bak/k = exp(-offset/kT)/RCTE. This is the same detailed
% balance that deviceparams.generateDeviceparams uses for kforEx, so the
% equilibrium densities (CT0, Ex0) stay consistent with the solver rates.
%
% Inputs:
%   lambda - Reorganization energy (eV)
%   RCT    - Charge transfer distance (nm)
%   offset - Energy offset between excited state and CT state (eV)
%   T      - Temperature (K); use the device temperature (Prec.const.T)
%   RCTE   - Ratio of CT to LE density of states (Prec.params.RCTE)
%
% Outputs (column vectors):
%   E_values     - Electric field (V/m)
%   k_values     - LE->CT rate (s^-1)
%   k_bak_values - CT->LE rate (s^-1)
%
% Example:
%   [E, k, k_bak] = marcus_rate_tables(0.5, 1.5, 0.05, 300, 0.1);

kLECT = kDis_stark(lambda, RCT, offset, T);
kCTLE = kBak_stark(lambda, RCT, offset, T);

E_values = kLECT(:, 1);
k_values = kLECT(:, 2);
k_bak_values = kCTLE(:, 2) / RCTE;

end
