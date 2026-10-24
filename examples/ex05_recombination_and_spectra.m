%% Example 5: states from optical parameters, PL/EL spectra and J-V
% The recombination parameters (paramsRec, "Prec") describe the LE and CT
% states through their energies, oscillator strengths and line shapes.
% From them the code computes the absorption spectrum, the radiative limits
% (Jsc_rad, Voc_rad), the non-radiative voltage loss and the PL and EL
% spectra. deviceparams then builds a device from a parameter file in
% parameters/ and these rates. This is the full-control route: here the
% LE -> CT rate is a constant (no Marcus field dependence).
% Runtime about 20 s. Parameter descriptions: docs/List_of_Parameters.docx.

run(fullfile(fileparts(mfilename('fullpath')), '..', 'startup.m'));

%% Recombination parameters of the LE (Ex) and CT states
Prec                        = paramsRec;      % default values
offset                      = 0.55;           % LE - CT energy offset (eV)
Prec.params.tickness        = 100e-9;         % active-layer thickness (m)
Prec.params.Ex.DG0          = 1.8;            % LE energy (eV)
Prec.params.CT.DG0          = Prec.params.Ex.DG0 - offset;   % CT energy (eV)
Prec.params.Ex.f            = 2.56;           % LE oscillator strength
Prec.params.CT.f            = 2e-4;           % CT oscillator strength
Prec.params.Ex.sigma        = 0.01;           % Gaussian disorder width (eV)
Prec.params.CT.sigma        = 0.01;
Prec.params.Ex.numbrestate  = 1;              % states sampled in the disorder distribution
Prec.params.CT.numbrestate  = 1;
Prec.params.Ex.L0           = 0.1;            % outer (low-frequency) reorganization energy (eV)
Prec.params.Ex.Li           = 0.1;            % inner (high-frequency) reorganization energy (eV)
Prec.params.CT.L0           = 0.2;
Prec.params.CT.Li           = 0.2;
Prec.params.RCTE            = 1e-2;           % CT/LE density-of-states ratio
Prec.params.Excitondesnity  = 1e26;           % density of LE sites (m^-3)
Prec.params.Vstar           = 0.000;          % LE-CT electronic coupling for intensity borrowing (eV)
Prec.const.T                = 300;            % temperature (K)
Prec                        = paramsRec.calcall(Prec);   % compute spectra and rates

fprintf('Radiative limits: Jsc_rad = %.2f mA/cm^2, Voc_rad = %.3f V\n', Prec.results.Jscrad, Prec.results.Vocrad);
fprintf('Non-radiative voltage loss %.3f V, expected Voc %.3f V\n', Prec.results.Dvnr, Prec.results.Vocrad - Prec.results.Dvnr);

%% Device from a parameter file
% To use your own stack, copy parameters/DeviceParameters_Default.xlsx,
% edit it, and load the copy here
activelayer = 2;        % index of the active layer
NC          = 2e19;     % effective density of states (cm^-3)
kfor        = 1e-10;    % CS -> CT formation rate constant (cm^3/s)
kdis        = 1e10;     % CT -> CS dissociation rate (1/s)
kdisex      = 1e11;     % LE -> CT transfer rate (1/s)
mobility    = 5e-4;     % electron and hole mobility (cm^2/(V s))

DP = deviceparams(fullfile('parameters', 'DeviceParameters_Default.xlsx'));
DP.light_properties.OM      = 0;    % uniform generation (2: transfer-matrix profile)
DP.Time_properties.tpoints  = 100;
DP.Layers{activelayer}.tp   = Prec.params.tickness*100;   % cm
DP = DP.generateDeviceparams(NC, activelayer, mobility, kdis, kdisex, Prec, kfor, 0);
DP.Layers{activelayer}.r0_CT = 0;   % no field dependence of CT dissociation
DP.Layers{activelayer}.r0_Ex = 0;   % no field dependence of LE -> CT transfer

%% Steady-state PL and EL spectra and the absorption (EQE) spectrum
fig = 1;
DP.simulate_PL(Prec, fig);
DP.simulate_EL(Prec, fig);
figure(fig)
subplot(3, 1, 1)
semilogy(Prec.const.Edistribution, Prec.results.AbsLJ, 'LineWidth', 2, 'Color', [1 0 0]);
xlabel('Energy (eV)'); ylabel('EQE (a.u.)');
ylim([1e-7 1.5]); xlim([1 2]);
sgtitle(sprintf('V_{oc,rad} = %.3f V, \\DeltaV_{nr} = %.3f V, V_{oc} = %.3f V', ...
    DP.results.Vocrad, DP.results.DVnr, DP.results.Voc));

%% J-V under 1 sun
DV = device(DP);
DV.Prec = Prec;
DV = device.runsolJsc(DV, 1);
DV = device.runsolJV(DV, 1, 0, 1.5);
figure(2)
[Jsc, Voc, FF] = dfplot.JV_new(DV.sol_JV, 1);
title('Example 5: J-V');
fprintf('Simulated: Jsc = %.2f mA/cm^2, Voc = %.3f V, FF = %.3f\n', Jsc, Voc, FF);

% Next: ex06_fit_measured_jv.m fits model parameters to a measured J-V curve.
