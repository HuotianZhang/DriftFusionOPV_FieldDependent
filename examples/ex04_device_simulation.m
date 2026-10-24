%% Example 4: step-by-step device simulation
% external_model wraps four steps. Running them yourself gives access to the
% device parameters, the full solutions and the internal profiles:
%   1. build_MarcusTransfer_device  device and recombination parameters
%   2. device(DP)                   equilibrium in the dark
%   3. device.runsolJsc             1 sun at short circuit
%   4. device.runsolJV              voltage sweep under illumination
% Runtime about 30 s.

run(fullfile(fileparts(mfilename('fullpath')), '..', 'startup.m'));

%% 1. Device parameters
% Same positional inputs as external_model (without V and R_s), plus the
% name-value options of build_MarcusTransfer_device
[DP, Prec] = build_MarcusTransfer_device(0.2, 10, 0.5, 1.5, 1.8, 'verbose', false);

active = 2;                        % index of the active layer
L = DP.Layers{active};
fprintf('Active layer: %.0f nm, mobility %.1e cm^2/(V s)\n', L.tp*1e7, L.muee);
fprintf('Rates: LE->CT %.2e s^-1 at zero field, CT->CS %.2e s^-1, CT decay %.2e s^-1, LE decay %.2e s^-1\n', ...
    L.kdisexc, L.kdis, L.krec, L.krecexc);
fprintf('Radiative-limit Voc %.3f V, quasi-equilibrium Voc %.3f V\n', DP.results.Vocrad, DP.results.Voc);

%% 2.-4. Equilibrium, short circuit and J-V sweep
DV = device(DP);
DV.Prec = Prec;
DV = device.runsolJsc(DV, 1);           % 1 sun
DV = device.runsolJV(DV, 1, 0, 1.4);    % sweep 0 -> 1.4 V
[Jsc, Voc, FF, J, V] = dfplot.JV_new(DV.sol_JV, 0);
fprintf('Simulated: Jsc = %.2f mA/cm^2, Voc = %.3f V, FF = %.3f\n', Jsc, Voc, FF);

%% Internal profiles at short circuit
% Solution variables: n, p (free carriers), CT, Ex (LE) densities in cm^-3
% and the potential V; x is in cm
sol = DV.sol_Jsc;
[~, ~, x, ~, n, p, CT, Ex] = dfana.splitsol(sol);
FV = dfana.calcF(sol);                  % field (V/cm)
xnm = x*1e7;
edges = cumsum(cellfun(@(Lk) Lk.tp, DP.Layers))*1e7;   % layer boundaries (nm)

figure('Name', 'Example 4: profiles at short circuit');
subplot(2, 1, 1)
semilogy(xnm, n(end, :), xnm, p(end, :), xnm, CT(end, :), xnm, Ex(end, :), 'LineWidth', 2);
xline(edges(1:end-1), ':');
ylim([1e5 1e20]);
ylabel('Density (cm^{-3})'); legend('n', 'p', 'CT', 'LE', 'Location', 'eastoutside'); grid on
subplot(2, 1, 2)
plot(xnm, abs(FV(end, :))/1e6, 'LineWidth', 2);
xline(edges(1:end-1), ':');
legend('|F|', 'Location', 'eastoutside');   % keeps the x axes of both panels aligned
xlabel('Position (nm)'); ylabel('|F| (MV/cm)'); grid on

%% Changing a rate after the device is built
% Rates can be edited in DP.Layers{active}. After changing krec or krecexc,
% call recombinationResults so that DP.results (J0, Voc) stays consistent.
DP2 = DP;
DP2.Layers{active}.krec = 10*DP.Layers{active}.krec;    % 10x faster CT decay
DP2 = DP2.recombinationResults(Prec, active);
DV2 = device(DP2);
DV2.Prec = Prec;
DV2 = device.runsolJsc(DV2, 1);
DV2 = device.runsolJV(DV2, 1, 0, 1.4);
[Jsc2, Voc2, FF2, J2, V2] = dfplot.JV_new(DV2.sol_JV, 0);
fprintf('10x CT decay: Jsc = %.2f mA/cm^2, Voc = %.3f V, FF = %.3f\n', Jsc2, Voc2, FF2);

figure('Name', 'Example 4: CT decay rate');
plot(V, J, V2, J2, 'LineWidth', 2);
xlabel('Voltage (V)'); ylabel('Current density (mA/cm^2)');
legend(sprintf('k_{rec} = %.0e s^{-1}', DP.Layers{active}.krec), ...
    sprintf('k_{rec} = %.0e s^{-1}', DP2.Layers{active}.krec), 'Location', 'northwest');
ylim([min(J) - 1, 2]); grid on

% Next: ex05_recombination_and_spectra.m sets up the states from optical
% parameters and simulates PL and EL spectra.
