function [DP, Prec] = build_MarcusTransfer_device(offset, lifetime_ex, lambda, RCT, E_gap, varargin)
% build_MarcusTransfer_device - Device parameters for the Marcus transfer J-V simulation
%
% Builds the recombination parameters (Prec) and the device parameters (DP)
% used by run_MarcusTransfer_JV, without running any simulation.
%
% Inputs:
%   offset      - Energy offset between excited state and CT state (eV)
%   lifetime_ex - Exciton lifetime in picoseconds (ps)
%   lambda      - Reorganization energy (eV)
%   RCT         - Electron-hole separation of the CT state (nm). Sets the
%                 CT dipole |Delta_mu| = e*RCT (1 nm corresponds to 48.0 D)
%                 for the linear Stark shift; 0 switches it off. For a
%                 dipole measured by electroabsorption, RCT = |Delta_mu|/(48.0 D) nm.
%   E_gap       - Energy gap (eV)
%
% Stark shift of the CT state in a field F (LE state unshifted), averaged
% over isotropic CT orientations theta (see marcus_equation_stark):
%   E_CT(F) = E_CT(0) - e*RCT*F*cos(theta) - delta_alpha*F^2/2
% It enters the LE<->CT Marcus rates. Both terms vanish at zero field, so
% detailed balance and the equilibrium densities do not depend on them.
%
% Optional name-value arguments (defaults in brackets):
%   'delta_alpha' - Polarizability volume change LE -> CT, Delta_alpha,
%                   Angstrom^3 [8.5e5]; 0 switches the quadratic Stark
%                   shift off. The default keeps the quadratic shift of
%                   the earlier model, which took the polarizability of
%                   TCNQ (85 A^3 for a 1.5 A dipole length) scaled by
%                   (RCT/1.5 A)^4, here at RCT = 1.5 nm.
%   'thickness' - Active layer thickness, nm [100]
%   'NC'        - Effective density of states, cm^-3 [2e19]
%   'mobility'  - Electron and hole mobility, cm^2/(V s) [5e-2]
%   'kdis'      - CT dissociation rate constant, s^-1 [5e10]
%   'kfor'      - CS->CT formation rate constant, cm^3/s [2.5e-10]
%   'krec'      - CT decay rate, s^-1 [1e9]
%   'RCTE'      - Ratio of CT to LE density of states [0.1]
%   'T'         - Temperature, K [300]
%   'verbose'   - Print progress and solver statistics [true]
%   'mesh'      - Spatial mesh, 'legacy' or 'exact' ['legacy']. 'legacy'
%                 reproduces the published results but its layers are
%                 thinner than specified (95.9 nm active layer for 100 nm);
%                 'exact' meshes every layer to its full thickness.
%
% Outputs:
%   DP   - deviceparams object, ready for device
%   Prec - paramsRec object
%
% Example:
%   [DP, Prec] = build_MarcusTransfer_device(0.05, 10, 0.5, 1.5, 1.8);

validateattributes(RCT, {'numeric'}, {'scalar', 'real', 'nonnegative'}, mfilename, 'RCT', 4);

ip = inputParser;
ip.addParameter('delta_alpha', 8.5e5, @(x) isscalar(x) && isreal(x) && x >= 0);
ip.addParameter('thickness', 100, @(x) isscalar(x) && x > 0);
ip.addParameter('NC', 2e19, @(x) isscalar(x) && x > 0);
ip.addParameter('mobility', 5e-2, @(x) isscalar(x) && x > 0);
ip.addParameter('kdis', 5e10, @(x) isscalar(x) && x > 0);
ip.addParameter('kfor', 2.5e-10, @(x) isscalar(x) && x > 0);
ip.addParameter('krec', 1e9, @(x) isscalar(x) && x > 0);
ip.addParameter('RCTE', 1e-1, @(x) isscalar(x) && x > 0);
ip.addParameter('T', 300, @(x) isscalar(x) && x > 0);
ip.addParameter('verbose', true, @(x) islogical(x) || isnumeric(x));
ip.addParameter('mesh', 'legacy', @(x) any(strcmp(x, {'legacy', 'exact'})));
ip.parse(varargin{:});
opt = ip.Results;

% Initialize recombination parameters
Prec = paramsRec;

% Set parameters
Prec.params.tickness        = opt.thickness * 1e-9; % m
Prec.params.Ex.DG0          = E_gap;                % eV
Prec.params.CT.DG0          = Prec.params.Ex.DG0 - offset;
Prec.params.Ex.f            = 2.56e-0;
Prec.params.CT.f            = 2e-4;
Prec.params.Ex.sigma        = 0.0001;
Prec.params.CT.sigma        = 0.0001;
Prec.params.Ex.numbrestate  = 1;
Prec.params.CT.numbrestate  = 1;
Prec.params.Ex.L0           = 0.1;
Prec.params.Ex.Li           = 0.15;
Prec.params.CT.L0           = 0.10;
Prec.params.CT.Li           = 0.15;
Prec.params.RCTE            = opt.RCTE;
Prec.params.Excitondesnity  = 8e27;
Prec.params.Vstar           = 0.000;
Prec.const.T                = opt.T;
Prec                        = paramsRec.calcall(Prec);

% Field-dependent rate constants, using the same temperature and RCTE as
% the device so that forward and back transfer obey detailed balance
[E_values, k_values, k_bak_values] = marcus_rate_tables(lambda, RCT, offset, ...
    Prec.const.T, Prec.params.RCTE, opt.delta_alpha);

% Device parameters
activelayer = 2;
NC          = opt.NC;
Kfor        = opt.kfor;
kdis        = opt.kdis;
kdisex      = k_values(1);
mobility    = opt.mobility;

DP = deviceparams(repo_path('parameters', 'DeviceParameters_Default.xlsx'));
DP.solveropt.verbose        = logical(opt.verbose);
DP.solveropt.mesh           = opt.mesh;

DP.light_properties.OM      = 0;
DP.Time_properties.tpoints  = 100;
DP.Layers{activelayer}.tp   = Prec.params.tickness * 100;

DP = DP.generateDeviceparams(NC, activelayer, mobility, kdis, kdisex, Prec, Kfor, 0);

% Field-dependent LE<->CT rates from the Marcus tables (weight 1: the
% constant kdisexc/kforEx are not used in this layer)
DP.Layers{activelayer}.marcus = struct('E', E_values, 'k', k_values, 'k_bak', k_bak_values, 'weight', 1);
DP.Layers{activelayer}.r0_CT   = 0;

% generateDeviceparams sets krec and krecexc from Prec; override them here
% and update J0/Voc in DP.results to match
DP.Layers{activelayer}.krec    = opt.krec;
DP.Layers{activelayer}.krecexc = 1/lifetime_ex*1e12;
DP = DP.recombinationResults(Prec, activelayer);

end
