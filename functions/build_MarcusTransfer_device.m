function [DP, Prec] = build_MarcusTransfer_device(offset, lifetime_ex, lambda, RCT, E_gap)
% build_MarcusTransfer_device - Device parameters for the Marcus transfer J-V simulation
%
% Builds the recombination parameters (Prec) and the device parameters (DP)
% used by run_MarcusTransfer_JV, without running any simulation.
%
% Inputs:
%   offset      - Energy offset between excited state and CT state (eV)
%   lifetime_ex - Exciton lifetime in picoseconds (ps)
%   lambda      - Reorganization energy (eV)
%   RCT         - Charge transfer distance (nm)
%   E_gap       - Energy gap (eV)
%
% Outputs:
%   DP   - deviceparams object, ready for device_forMarcus
%   Prec - paramsRec object
%
% Example:
%   [DP, Prec] = build_MarcusTransfer_device(0.05, 10, 0.5, 1.5, 1.8);

% Initialize recombination parameters
Prec = paramsRec;

% Set parameters
Prec.params.tickness        = 100 * 1e-9;           % m
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
Prec.params.RCTE            = 1e-1;
Prec.params.Excitondesnity  = 8e27;
Prec.params.Vstar           = 0.000;
Prec.const.T                = 300;
Prec                        = paramsRec.calcall(Prec);

% Field-dependent rate constants, using the same temperature and RCTE as
% the device so that forward and back transfer obey detailed balance
[E_values, k_values, k_bak_values] = marcus_rate_tables(lambda, RCT, offset, Prec.const.T, Prec.params.RCTE);

% Device parameters
activelayer = 2;
NC          = 2e19;
Kfor        = 2.5e-10;
kdis        = 5e10;
kdisex      = k_values(1);
mobility    = 5e-2;

deviceParameterFile = 'DeviceParameters_Default.xlsx';
DP = deviceparams(fullfile('parameters',deviceParameterFile));

DP.light_properties.OM      = 0;
DP.Time_properties.tpoints  = 100;
DP.Layers{activelayer}.tp   = Prec.params.tickness * 100;

DP.physical_const.E_values     = E_values;
DP.physical_const.k_values     = k_values;
DP.physical_const.k_bak_values = k_bak_values;
DP.Layers{activelayer}.offset  = offset;
DP.Layers{activelayer}.RCTE    = Prec.params.RCTE;

DP = DP.generateDeviceparams(NC, activelayer, mobility, kdis, kdisex, Prec, Kfor, 0);

% generateDeviceparams sets krec and krecexc from Prec; override them here
DP.Layers{activelayer}.r0_CT   = 0;
DP.Layers{activelayer}.r0_Ex   = 1;
DP.Layers{activelayer}.krec    = 1e9;
DP.Layers{activelayer}.krecexc = 1/lifetime_ex*1e12;

end
