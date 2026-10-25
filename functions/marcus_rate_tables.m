function [E_values, k_values, k_bak_values] = marcus_rate_tables(lambda, RCT, offset, T, RCTE, delta_alpha, varargin)
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
% Optional name-value arguments (vibronic and disorder option; with the
% defaults the rates are the classical Marcus rates above):
%   'huang_rhys'  - Huang-Rhys factor S of a high-frequency mode [0]
%   'mode_energy' - Energy of that mode, eV [0.17]
%   'disorder'    - Gaussian disorder sigma of the CT energy, eV [0]
% With S > 0 or sigma > 0 the rates are Marcus-Levich-Jortner rates averaged
% over the CT disorder (see marcus_mlj_stark_rates). offset is then the
% free-energy offset to the thermalised CT population, and the back rate
% follows from detailed balance, so k_bak/k at zero field is still
% exp(-offset/kT)/RCTE.
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

ip = inputParser;
ip.addParameter('huang_rhys', 0, @(x) isscalar(x) && isreal(x) && x >= 0);
ip.addParameter('mode_energy', 0.17, @(x) isscalar(x) && isreal(x) && x > 0);
ip.addParameter('disorder', 0, @(x) isscalar(x) && isreal(x) && x >= 0);
ip.parse(varargin{:});
opt = ip.Results;

if opt.huang_rhys == 0 && opt.disorder == 0
    kLECT = kDis_stark(lambda, RCT, offset, T, delta_alpha);
    kCTLE = kBak_stark(lambda, RCT, offset, T, delta_alpha);
    E_values = kLECT(:, 1);
    k_values = kLECT(:, 2);
    k_bak_values = kCTLE(:, 2) / RCTE;
else
    % Same coupling, scaling and field grid as marcus_stark_table
    Hab = 0.01;
    E_values = (0:1e5:5e7)';
    [k_f, k_b] = marcus_mlj_stark_rates(Hab, lambda, offset, T, E_values, RCT*1e-9, ...
        delta_alpha, opt.huang_rhys, opt.mode_energy, opt.disorder);
    k_values = 0.1*k_f;
    k_bak_values = 0.1*k_b / RCTE;
end

end
