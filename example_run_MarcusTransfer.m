%% Example usage of run_MarcusTransfer_JV function
% This script demonstrates how to use the refactored run_MarcusTransfer_JV function
% which replaces the workflow in MarcusTransfer_JV_0620_334.m

% Add all subdirectories to path
addpath(genpath(pwd));

% Define input parameters
lifetime_ex = 10;  % Exciton lifetime in picoseconds (ps)
offset = 0.05;     % Energy offset in eV (valid range: 0.00 to 0.45 in steps of 0.05)

% Call the function
fprintf('Running simulation with lifetime_ex = %.1f ps, offset = %.2f eV\n', lifetime_ex, offset);
[JJ, VV] = run_MarcusTransfer_JV(lifetime_ex, offset);

% Display results
fprintf('Simulation complete.\n');
fprintf('Number of voltage points: %d\n', length(VV));
fprintf('Number of current density points: %d\n', length(JJ));

% You can now use JJ and VV for further analysis or plotting
% Example: plot the J-V curve
figure('Name', sprintf('J-V Curve (lifetime=%.1fps, offset=%.2feV)', lifetime_ex, offset));
plot(VV, JJ, 'LineWidth', 2);
xlabel('Voltage [V]');
ylabel('Current Density [mA/cm^2]');
title(sprintf('J-V Characteristic (\\tau_{ex} = %.1f ps, offset = %.2f eV)', lifetime_ex, offset));
grid on;

% Example: run multiple simulations with different parameters
% This demonstrates the flexibility of the new function-based approach
fprintf('\nRunning multiple simulations...\n');
offsets = [0.00, 0.10, 0.20, 0.30];  % Different offset values
lifetime_values = [10];  % Different lifetime values

figure('Name', 'Multiple J-V Curves');
hold on;
for i = 1:length(offsets)
    for j = 1:length(lifetime_values)
        [JJ, VV] = run_MarcusTransfer_JV(lifetime_values(j), offsets(i));
        plot(VV, JJ, 'DisplayName', sprintf('offset=%.2feV, \\tau=%.1fps', offsets(i), lifetime_values(j)));
    end
end
hold off;
xlabel('Voltage [V]');
ylabel('Current Density [mA/cm^2]');
title('J-V Characteristics for Different Parameters');
legend('Location', 'best');
grid on;
