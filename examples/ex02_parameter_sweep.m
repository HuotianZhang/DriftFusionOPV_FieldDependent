%% Example 2: how material and device parameters change the J-V curve
% Part A sweeps a positional material parameter (the LE - CT offset).
% Part B sweeps a device parameter given as a name-value option (the
% carrier mobility). Runtime about 1 min.
%
% All name-value options are listed in `help build_MarcusTransfer_device`:
% 'delta_alpha', 'thickness', 'NC', 'mobility', 'kdis', 'kfor', 'krec',
% 'RCTE', 'T' and 'verbose'.

run(fullfile(fileparts(mfilename('fullpath')), '..', 'startup.m'));

lifetime_ex = 10;     % ps
lambda      = 0.5;    % eV
RCT         = 1.5;    % nm
E_gap       = 1.8;    % eV
R_s         = 0;      % kOhm cm^2
V = linspace(0, 1.4, 141);

%% Part A: LE - CT energy offset
% A larger offset gives more driving force for exciton dissociation (higher
% Jsc) but a lower CT energy, which lowers Voc.
offsets = [0 0.1 0.2 0.3];   % eV
figure('Name', 'Example 2A: offset');
hold on
Jmax = 0;
fprintf('\n offset (eV)   Jsc (mA/cm^2)   Voc (V)    FF\n');
for k = 1:numel(offsets)
    J = external_model(V, offsets(k), lifetime_ex, lambda, RCT, E_gap, R_s);
    pv = jv_parameters(V, J);
    fprintf('   %.2f          %6.2f        %.3f    %.3f\n', offsets(k), pv.Jsc, pv.Voc, pv.FF);
    Jmax = max(Jmax, pv.Jsc);
    plot(V, J, 'LineWidth', 2, 'DisplayName', sprintf('offset %.2f eV', offsets(k)));
end
hold off
xlabel('Voltage (V)'); ylabel('Current density (mA/cm^2)');
ylim([-1.2 0.5]*Jmax);
legend('Location', 'northwest'); grid on

%% Part B: carrier mobility (name-value option)
% Low mobility slows the extraction of free carriers, so more of them
% recombine: FF drops first, then Jsc.
mobilities = [1e-4 1e-3 1e-2];   % cm^2/(V s)
figure('Name', 'Example 2B: mobility');
hold on
Jmax = 0;
fprintf('\n mobility (cm^2/Vs)   Jsc (mA/cm^2)   Voc (V)    FF\n');
for k = 1:numel(mobilities)
    J = external_model(V, 0.2, lifetime_ex, lambda, RCT, E_gap, R_s, 'mobility', mobilities(k));
    pv = jv_parameters(V, J);
    fprintf('   %.0e              %6.2f        %.3f    %.3f\n', mobilities(k), pv.Jsc, pv.Voc, pv.FF);
    Jmax = max(Jmax, pv.Jsc);
    plot(V, J, 'LineWidth', 2, 'DisplayName', sprintf('\\mu = %.0e cm^2/(V s)', mobilities(k)));
end
hold off
xlabel('Voltage (V)'); ylabel('Current density (mA/cm^2)');
title('offset 0.2 eV');
ylim([-1.2 0.5]*Jmax);
legend('Location', 'northwest'); grid on

% Next: ex03_stark_effect.m shows how the electric field enters the LE -> CT rates.
