function [JJ, VV] = run_MarcusTransfer_JV(VV, offset, lifetime_ex, lambda, RCT, E_gap, R_s, varargin)
% run_MarcusTransfer_JV - Run Marcus transfer J-V simulation
%
% This function performs a drift-diffusion simulation with Marcus transfer 
% rates for organic photovoltaic devices. It replaces the workflow from
% MarcusTransfer_JV_0620_334.m with a cleaner function-based approach.
%
% Inputs:
%   VV          - Voltage array (V) - can be a vector; its range determines Vstart and Vend
%                 If scalar, will use default range [0, VV]
%                 Example: [0:0.1:1.2] or 1.2
%   offset      - Energy offset between excited state and CT state (eV)
%                 Can be any positive value
%                 Example: 0.00, 0.05, 0.10, 0.15, 0.20, etc.
%   lifetime_ex - Exciton lifetime in picoseconds (ps)
%                 Example: 10 ps
%   lambda      - Reorganization energy (eV)
%                 Example: 0.5 eV
%   RCT         - Electron-hole separation of the CT state (nm); sets the
%                 CT dipole e*RCT for the linear Stark shift (0 = off)
%                 Example: 1.5 nm
%   E_gap       - Energy gap (eV)
%                 Example: 1.8 eV
%   R_s         - Series resistance per area (kOhms·cm²) V_R_series = V + J * R_s
%                 Example: 0.001 kOhms·cm²
%   Name-value  - Optional device parameters passed to build_MarcusTransfer_device
%                 ('delta_alpha', 'thickness', 'NC', 'mobility', 'kdis',
%                 'kfor', 'krec', 'RCTE', 'T', 'verbose')
%
% Outputs:
%   JJ - Current density array (mA/cm²)
%   VV - Voltage array (V)
%
% Example:
%   [JJ, VV] = run_MarcusTransfer_JV([0:0.1:1.2], 0.05, 10, 0.5, 1.5, 1.8, 0.001);
%   plot(VV, JJ);
%   xlabel('Voltage [V]');
%   ylabel('Current Density [mA/cm^2]');

% Determine Vstart and Vend from VV input
if isscalar(VV)
    % If VV is scalar, use it as Vend with Vstart=0
    Vend = VV;
    Vstart = 0;
else
    % If VV is a vector, use its min and max
    Vstart = min(VV);
    Vend = max(VV);
end

% Build the device (recombination parameters, Marcus rate tables, layers)
[DP, Prec] = build_MarcusTransfer_device(offset, lifetime_ex, lambda, RCT, E_gap, varargin{:});

DV2 = device(DP);
DV2.Prec = Prec;

% Run simulations
Gen = 1;  % 1 sun
DV2 = device.runsolJsc(DV2, Gen);
DV2 = device.runsolJV(DV2, Gen, Vstart, Vend);

% Extract JV data without plotting
[~, ~, ~, JJ, VV] = dfplot.JV_new(DV2.sol_JV, 0);

% Apply series resistance correction to the J-V characteristics
% This accounts for voltage drop across series resistance in the device
[VV, JJ] = apply_series_resistance(VV, JJ, R_s); % Use provided Rs value

end
