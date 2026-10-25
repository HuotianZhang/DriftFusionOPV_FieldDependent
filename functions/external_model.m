function JJ = external_model(VV, offset, lifetime_ex, lambda, RCT, E_gap, R_s, varargin)
% external_model - External model for J-V simulation using Marcus transfer
%
% This function provides a simple interface to run Marcus transfer J-V simulations.
% It replaces simple fitting equations (e.g., Y = k02 * X.^2 + k20) with
% physics-based Marcus transfer calculations.
%
% Inputs:
%   VV          - Voltage array (V) - can be a vector; its range determines Vstart and Vend
%                 Example: [0:0.1:1.2] or linspace(0, 1.2, 50)
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
%   Name-value  - Optional device parameters ('delta_alpha', 'thickness',
%                 'NC', 'mobility', 'kdis', 'kfor', 'krec', 'RCTE', 'T',
%                 'mesh') and the J-V current method ('current'), see
%                 build_MarcusTransfer_device. Output is quiet unless
%                 'verbose', true is given.
%
% Outputs:
%   JJ - Current density array (mA/cm²) corresponding to the voltage array VV
%
% Example:
%   VV = linspace(0, 1.2, 50);
%   offset = 0.05;
%   lifetime_ex = 10;
%   lambda = 0.5;
%   RCT = 1.5;
%   E_gap = 1.8;
%   R_s = 0.001;
%   JJ = external_model(VV, offset, lifetime_ex, lambda, RCT, E_gap, R_s);
%   plot(VV, JJ);
%   xlabel('Voltage [V]');
%   ylabel('Current Density [mA/cm^2]');
%
% Note:
%   This function uses run_MarcusTransfer_JV internally to compute the J-V
%   characteristics based on Marcus transfer theory instead of simple
%   polynomial fitting equations.

% Call run_MarcusTransfer_JV with the provided parameters
% The function will determine Vstart and Vend from the VV range
if ~any(strcmpi(varargin(1:2:end), 'verbose'))
    varargin = [varargin, {'verbose', false}];   % quiet by default, e.g. inside a fit
end
[JJ_output, VV_output] = run_MarcusTransfer_JV(VV, offset, lifetime_ex, lambda, RCT, E_gap, R_s, varargin{:});

% Always interpolate onto the input grid: run_MarcusTransfer_JV only uses the
% range of VV, and the series resistance correction shifts every voltage
% point by J*R_s, so VV_output differs from VV even when the lengths match
JJ = interp1(VV_output, JJ_output, VV, 'linear', 'extrap');

end
