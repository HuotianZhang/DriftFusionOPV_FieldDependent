function [JJ, VV] = run_MarcusTransfer_JV(lifetime_ex, offset)
% run_MarcusTransfer_JV - Run Marcus transfer J-V simulation
%
% This function performs a drift-diffusion simulation with Marcus transfer 
% rates for organic photovoltaic devices. It replaces the workflow from
% MarcusTransfer_JV_0620_334.m with a cleaner function-based approach.
%
% Inputs:
%   lifetime_ex - Exciton lifetime in picoseconds (ps)
%                 Example: 10 ps
%   offset      - Energy offset between excited state and CT state (eV)
%                 Can be any positive value
%                 Example: 0.00, 0.05, 0.10, 0.15, 0.20, etc.
%
% Outputs:
%   JJ - Current density array (mA/cm²)
%   VV - Voltage array (V)
%
% Example:
%   [JJ, VV] = run_MarcusTransfer_JV(10, 0.05);
%   plot(VV, JJ);
%   xlabel('Voltage [V]');
%   ylabel('Current Density [mA/cm^2]');

% Calculate field-dependent rate constants with the given offset
% Fixed parameters: lambda = 0.5 eV, RCT = 1.5 nm
lambda = 0.5;  % eV
RCT = 1.5;     % nm

kLECT = kDis_stark(lambda, RCT, offset);
kCTLE = kBak_stark(lambda, RCT, offset);

% Get E_values (electric field values) and rate values
E_values = kLECT(:, 1);
k_values = kLECT(:, 2);
k_bak_values = kCTLE(:, 2) * 10;

% Initialize recombination parameters
Prec = paramsRec;

% Set parameters
Prec.params.tickness        = 100 * 1e-9;           % m
Prec.params.Ex.DG0          = 1.4;                 
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

% Device parameters
activelayer = 2;
NC          = 2e19;
Kfor        = 2.5e-10;
kdis        = 5e10;
kdisex      = k_values(1);
mobility    = 5e-2;

deviceParameterFile = 'DeviceParameters_Default.xlsx';
DP = deviceparams(['parameters\',deviceParameterFile]);

DP.light_properties.OM      = 0;
DP.Time_properties.tpoints  = 100;
DP.Layers{activelayer}.tp   = Prec.params.tickness * 100;

DP.Layers{2}.krec       = 1e9;
DP.Layers{2}.krecexc    = 1/lifetime_ex*1e12;
DP.physical_const.E_values    = E_values;
DP.physical_const.k_values    = k_values;
DP.physical_const.k_bak_values = k_bak_values;
DP.Layers{2}.offset     = offset;
DP.Layers{2}.RCTE       = Prec.params.RCTE;

DP = DP.generateDeviceparams(NC, activelayer, mobility, kdis, kdisex, Prec, Kfor, 0);

% Run JV scan
Vstart  = 0;
Vend    = 1.2;

DP.Layers{2}.r0_CT  = 0;
DP.Layers{2}.r0_Ex  = 1;
DP.Layers{2}.krec   = 1e9;
DP.Layers{2}.krecexc = 1/lifetime_ex*1e12;
DP.physical_const.E_values = E_values;
DP.physical_const.k_values = k_values;

DV2 = device_forMarcus(DP);
DV2.Prec = Prec;

% Run simulations
Gen = 1;  % 1 sun
DV2 = device_forMarcus.runsolJsc(DV2, Gen);
DV2 = device_forMarcus.runsolJV(DV2, Gen, Vstart, Vend);

% Extract JV data without plotting
[~, ~, ~, JJ, VV] = dfplot.JV_new(DV2.sol_JV(end), 0);

end
