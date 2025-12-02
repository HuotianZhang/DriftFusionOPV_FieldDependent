%% Example usage of run_MarcusTransfer_JV function
% This script demonstrates how to use the refactored run_MarcusTransfer_JV function
% which replaces the workflow in MarcusTransfer_JV_0620_334.m

% Add all subdirectories to path
addpath(genpath(pwd));

% Define input parameters
VV = 0.8;         % Voltage endpoint (will simulate from 0 to 1.2 V)
offset = 0.3;    % Energy offset in eV (can be any positive value)
lifetime_ex = 100; % Exciton lifetime in picoseconds (ps)
lambda = 0.3;     % Reorganization energy (eV)
RCT = 0;        % Charge transfer distance (nm)
E_gap = 1.8;     % Energy gap (eV)
R_s = 0.001;     % Series resistance per area (kOhms/cm²)

% Call the function
fprintf('Running simulation with VV = %.1f V, offset = %.2f eV, lifetime_ex = %.1f ps, lambda = %.2f eV, RCT = %.2f nm\n, E_gap = %.2f eV, R_s = %.4f kOhms·cm²\n', ...
        VV, offset, lifetime_ex, lambda, RCT, E_gap, R_s);
[JJ, VV_out] = run_MarcusTransfer_JV(VV, offset, lifetime_ex, lambda, RCT, E_gap, R_s);

% Display results
fprintf('Simulation complete.\n');
fprintf('Number of voltage points: %d\n', length(VV_out));
fprintf('Number of current density points: %d\n', length(JJ));

% You can now use JJ and VV_out for further analysis or plotting
% Example: plot the J-V curve
figure('Name', sprintf('J-V Curve (lifetime=%.1fps, offset=%.2feV)', lifetime_ex, offset));
plot(VV_out, JJ, 'LineWidth', 2);
xlabel('Voltage [V]');
ylabel('Current Density [mA/cm^2]');
title(sprintf('J-V Characteristic (\\tau_{ex} = %.1f ps, offset = %.2f eV)', lifetime_ex, offset));
grid on;

% Example: run multiple simulations with different parameters
% This demonstrates the flexibility of the new function-based approach
fprintf('\nRunning multiple simulations...\n');
offsets = [0.00, 0.10, 0.20, 0.30];  % Different offset values
lifetime_values = [100];  % Different lifetime values

figure('Name', 'Multiple J-V Curves');
hold on;
for i = 1:length(offsets)
    for j = 1:length(lifetime_values)
        [JJ, VV_out] = run_MarcusTransfer_JV(1.2, offsets(i), lifetime_values(j), lambda, RCT, E_gap, R_s);
        plot(VV_out, JJ, 'DisplayName', sprintf('offset=%.2feV, \\tau=%.1fps', offsets(i), lifetime_values(j)));
    end
end
hold off;
xlabel('Voltage [V]');
ylabel('Current Density [mA/cm^2]');
title('J-V Characteristics for Different Parameters');
legend('Location', 'best');
grid on;
