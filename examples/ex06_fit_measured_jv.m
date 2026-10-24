%% Example 6: fit model parameters to a measured J-V curve
% external_model returns J on any voltage grid, so it can be used directly
% as the model function in a least-squares fit. This example fits the
% LE - CT offset to a synthetic "measured" curve with base-MATLAB fminbnd
% (one parameter). For several parameters use fminsearch, or lsqcurvefit
% if you have the Optimization Toolbox. Each evaluation is a full
% simulation (~8 s); runtime about 2 min.

run(fullfile(fileparts(mfilename('fullpath')), '..', 'startup.m'));

lifetime_ex = 10;     % ps
lambda      = 0.5;    % eV
RCT         = 1.5;    % nm
E_gap       = 1.8;    % eV
R_s         = 0.001;  % kOhm cm^2

%% "Measured" data
% Replace this block with your own data, e.g.
%   data = readmatrix('my_device_JV.csv');   % columns: V (V), J (mA/cm^2)
%   V_meas = data(:, 1);  J_meas = data(:, 2);
% with J < 0 where the cell delivers power.
offset_true = 0.15;
V_meas = (0:0.05:1.3)';
rng(1);
J_meas = external_model(V_meas, offset_true, lifetime_ex, lambda, RCT, E_gap, R_s) ...
    + 0.05*randn(size(V_meas));

%% Fit
sse = @(offset) sum((external_model(V_meas, offset, lifetime_ex, lambda, RCT, E_gap, R_s) - J_meas).^2);
opts = optimset('TolX', 2e-3, 'Display', 'iter');
[offset_fit, sse_min] = fminbnd(sse, 0, 0.4, opts);
fprintf('Fitted offset %.3f eV (true %.2f eV), rms residual %.3f mA/cm^2\n', ...
    offset_fit, offset_true, sqrt(sse_min/numel(V_meas)));

V = linspace(0, 1.3, 131);
J_fit = external_model(V, offset_fit, lifetime_ex, lambda, RCT, E_gap, R_s);
figure('Name', 'Example 6: fit');
plot(V_meas, J_meas, 'ko', V, J_fit, 'LineWidth', 1.5);
xlabel('Voltage (V)'); ylabel('Current density (mA/cm^2)');
legend('measured', sprintf('fit, offset = %.3f eV', offset_fit), 'Location', 'northwest');
grid on
