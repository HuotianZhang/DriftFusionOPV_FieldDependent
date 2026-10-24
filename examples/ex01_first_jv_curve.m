%% Example 1: your first J-V curve
% Simulates the J-V curve of an organic solar cell under 1 sun and prints
% Jsc, Voc, FF and PCE. Runtime about 10 s.
%
% What is simulated: light creates excitons (LE states) in the active
% layer. They transfer to charge-transfer (CT) states with Marcus rates that
% depend on the local electric field, and the CT states dissociate into free
% electrons and holes, which drift and diffuse to the contacts. The rest of
% the device (contacts, transport layers, mobilities, ...) is the default in
% parameters/DeviceParameters_Default.xlsx. See docs/solver.md.

run(fullfile(fileparts(mfilename('fullpath')), '..', 'startup.m'));   % add the code to the MATLAB path

% Material parameters, the positional inputs of external_model
offset      = 0.2;    % LE - CT energy offset (eV); try 0.05 for a weaker driving force
lifetime_ex = 10;     % exciton lifetime (ps)
lambda      = 0.5;    % reorganization energy of the LE -> CT transfer (eV)
RCT         = 1.5;    % electron-hole separation of the CT state (nm)
E_gap       = 1.8;    % LE energy, i.e. the optical gap (eV)
R_s         = 0;      % series resistance (kOhm cm^2)

% Only the range of V sets the simulated sweep; J is returned on this grid
V = linspace(0, 1.4, 141);   % V
J = external_model(V, offset, lifetime_ex, lambda, RCT, E_gap, R_s);   % mA/cm^2

% Figures of merit. J < 0 means the cell delivers power.
pv = jv_parameters(V, J);
fprintf('Jsc = %.2f mA/cm^2, Voc = %.3f V, FF = %.3f, PCE = %.2f %%\n', pv.Jsc, pv.Voc, pv.FF, pv.PCE);

figure('Name', 'Example 1: J-V curve');
plot(V, J, 'LineWidth', 2);
hold on
plot(pv.Vmpp, pv.Jmpp, 'ko', 'MarkerFaceColor', 'k');
yline(0, ':');
hold off
xlabel('Voltage (V)');
ylabel('Current density (mA/cm^2)');
title(sprintf('J_{sc} = %.2f mA/cm^2, V_{oc} = %.3f V, FF = %.2f', pv.Jsc, pv.Voc, pv.FF));
legend('J-V curve', 'maximum power point', 'Location', 'northwest');
grid on

% Next: ex02_parameter_sweep.m varies the material and device parameters.
