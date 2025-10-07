%% Example usage of external_model function
% This script demonstrates how to use the external_model function
% which provides a simplified interface to run Marcus transfer J-V simulations

% Add all subdirectories to path
addpath(genpath(pwd));

%% Example 1: Using external_model with a voltage vector
fprintf('Example 1: Using external_model with voltage vector\n');

% Define voltage array
VV = linspace(0, 1.2, 50);  % 50 points from 0 to 1.2 V

% Define parameters
offset = 0.05;       % Energy offset (eV)
lifetime_ex = 10;    % Exciton lifetime (ps)
lambda = 0.5;        % Reorganization energy (eV)
RCT = 1.5;           % Charge transfer distance (nm)

% Call external_model
fprintf('Running external_model...\n');
JJ = external_model(VV, offset, lifetime_ex, lambda, RCT);

% Plot results
figure('Name', 'External Model Example 1');
plot(VV, JJ, 'LineWidth', 2);
xlabel('Voltage [V]');
ylabel('Current Density [mA/cm^2]');
title(sprintf('J-V from external\\_model (offset=%.2feV, \\tau=%.1fps)', offset, lifetime_ex));
grid on;

fprintf('Simulation complete. Generated %d data points.\n', length(JJ));

%% Example 2: Comparing different offsets
fprintf('\nExample 2: Comparing different offsets\n');

VV = linspace(0, 1.2, 30);  % 30 points from 0 to 1.2 V
offsets = [0.00, 0.05, 0.10, 0.15];

figure('Name', 'External Model - Offset Comparison');
hold on;
for i = 1:length(offsets)
    fprintf('  Computing for offset = %.2f eV...\n', offsets(i));
    JJ = external_model(VV, offsets(i), lifetime_ex, lambda, RCT);
    plot(VV, JJ, 'LineWidth', 2, 'DisplayName', sprintf('offset = %.2f eV', offsets(i)));
end
hold off;
xlabel('Voltage [V]');
ylabel('Current Density [mA/cm^2]');
title('J-V Characteristics for Different Offsets');
legend('Location', 'best');
grid on;

fprintf('\nAll simulations complete!\n');
