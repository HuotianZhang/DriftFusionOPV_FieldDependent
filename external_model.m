function JJ = external_model(VV, offset, lifetime_ex, lambda, RCT)
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
%   RCT         - Charge transfer distance (nm)
%                 Example: 1.5 nm
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
%   JJ = external_model(VV, offset, lifetime_ex, lambda, RCT);
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
[JJ, ~] = run_MarcusTransfer_JV(VV, offset, lifetime_ex, lambda, RCT);

end
