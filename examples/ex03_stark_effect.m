%% Example 3: the Stark effect on the LE -> CT transfer
% In the internal electric field F, a CT state whose dipole makes an angle
% theta with the field has its energy shifted relative to the LE state by
%
%   dE_CT = -e*RCT*F*cos(theta) - delta_alpha*F^2/2
%
% (linear and quadratic Stark effect). The Marcus LE <-> CT rates are
% averaged over isotropic orientations. Two controls set the magnitude:
%   RCT          positional, nm: electron-hole separation, CT dipole e*RCT
%   'delta_alpha' name-value, Angstrom^3: polarizability change LE -> CT
% Setting either to 0 switches that term off. See docs/solver.md.
% Runtime about 40 s.

run(fullfile(fileparts(mfilename('fullpath')), '..', 'startup.m'));

offset      = 0.05;   % eV
lifetime_ex = 10;     % ps
lambda      = 0.5;    % eV
E_gap       = 1.8;    % eV
R_s         = 0;      % kOhm cm^2
T           = 300;    % K
RCTE        = 0.1;    % CT/LE density-of-states ratio (default of build_MarcusTransfer_device)
alpha0      = 8.5e5;  % default delta_alpha (Angstrom^3)

% name, RCT (nm), delta_alpha (Angstrom^3)
cases = {
    'no Stark shift',      0,   0
    'linear term only',    1.5, 0
    'quadratic term only', 0,   alpha0
    'both (default)',      1.5, alpha0
    };

%% Part A: field-dependent transfer rates
% marcus_rate_tables returns the LE -> CT and CT -> LE rates that the solver
% interpolates at the local field. In an isotropic film the linear term
% averages out to first order, so it changes the rates much less than the
% quadratic term at the default delta_alpha.
figure('Name', 'Example 3A: rates');
for c = 1:size(cases, 1)
    [F, k, k_bak] = marcus_rate_tables(lambda, cases{c, 2}, offset, T, RCTE, cases{c, 3});
    subplot(1, 2, 1); semilogy(F/1e8, k, 'LineWidth', 2, 'DisplayName', cases{c, 1}); hold on
    subplot(1, 2, 2); semilogy(F/1e8, k_bak, 'LineWidth', 2, 'DisplayName', cases{c, 1}); hold on
end
subplot(1, 2, 1); hold off; grid on; xlim([0 0.2]);
xlabel('Field (MV/cm)'); ylabel('k_{LE\rightarrowCT} (s^{-1})'); legend('Location', 'northwest');
subplot(1, 2, 2); hold off; grid on; xlim([0 0.2]);
xlabel('Field (MV/cm)'); ylabel('k_{CT\rightarrowLE} (s^{-1})');

%% Part B: effect on the J-V curve
V = linspace(0, 1.4, 141);
figure('Name', 'Example 3B: J-V');
hold on
fprintf('\n %-22s Jsc (mA/cm^2)   Voc (V)    FF\n', 'case');
for c = 1:size(cases, 1)
    J = external_model(V, offset, lifetime_ex, lambda, cases{c, 2}, E_gap, R_s, 'delta_alpha', cases{c, 3});
    pv = jv_parameters(V, J);
    fprintf(' %-22s    %6.3f       %.3f    %.3f\n', cases{c, 1}, pv.Jsc, pv.Voc, pv.FF);
    plot(V, J, 'LineWidth', 2, 'DisplayName', cases{c, 1});
end
hold off
xlabel('Voltage (V)'); ylabel('Current density (mA/cm^2)');
title(sprintf('offset %.2f eV, \\lambda = %.1f eV', offset, lambda));
legend('Location', 'northwest'); grid on

% For your own material, take |Delta_mu| and delta_alpha from electroabsorption
% data: RCT = |Delta_mu| / (48.0 D) nm, delta_alpha in Angstrom^3.
% Next: ex04_device_simulation.m works with the device object directly.
