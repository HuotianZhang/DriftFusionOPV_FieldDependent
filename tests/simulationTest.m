function tests = simulationTest
% J-V simulations of reference devices: regression against recorded
% results and checks that the results are physically sensible.
% Run from MATLAB with:  results = runtests('tests'); assertSuccess(results)
tests = functiontests(localfunctions);
end

function setupOnce(testCase)
import matlab.unittest.fixtures.CurrentFolderFixture
import matlab.unittest.fixtures.PathFixture
root = fileparts(fileparts(mfilename('fullpath')));
testCase.applyFixture(CurrentFolderFixture(root));
testCase.applyFixture(PathFixture(root, 'IncludingSubfolders', true));

% name, offset (eV), exciton lifetime (ps), lambda (eV), RCT (nm), E_gap (eV),
% Marcus weight, further name-value arguments
cases = {
    'marcus_default',          0.05,  10, 0.5, 1.5, 1.8, 1, {}
    'marcus_offset020',        0.20,  10, 0.5, 1.5, 1.8, 1, {}
    'marcus_tau100',           0.05, 100, 0.5, 1.5, 1.8, 1, {}
    'marcus_nofield',          0.05,  10, 0.5, 1.5, 1.8, 0, {}
    'marcus_dipole_only',      0.05,  10, 0.5, 1.5, 1.8, 1, {'delta_alpha', 0}
    'marcus_polarizability_only', 0.05, 10, 0.5, 0, 1.8, 1, {}
    };
R = struct();
for c = 1:size(cases, 1)
    [DP, Prec] = build_MarcusTransfer_device(cases{c, 2:6}, cases{c, 8}{:}, 'verbose', false);
    DP.Layers{2}.marcus.weight = cases{c, 7};
    R.(cases{c, 1}) = simulate(DP, Prec, 1.6);
end
[DP, Prec] = example_workflow_device();
R.example_workflow = simulate(DP, Prec, 1.5);
testCase.TestData.R = R;

for name = fieldnames(R)'
    r = R.(name{1});
    fprintf('RESULT %s Jsc=%.10g Voc=%.10g FF=%.10g Jscrad=%.10g Vocrad=%.10g DPVoc=%.10g Jdark_eq=%.4g maxF_Vm=%.4g\n', ...
        name{1}, r.Jsc, r.Voc, r.FF, r.Jscrad, r.Vocrad, r.DPVoc, r.Jdark_eq, r.maxF);
end
end

function testRegression(testCase)
% Reference values. The solver merge and refactoring reproduced the
% previous code's results to 1e-6 (Oct 2026). These values were recorded
% after recomputing the Laguerre table for the actual Huang-Rhys factor,
% which lowers the radiative limit Vocrad and with it Voc by 5 mV
% (Marcus devices) and 11-12 mV (example device), and switching to CODATA
% constants (effect on Vocrad below 0.01 mV). The linear Stark shift of the
% CT dipole (e*RCT, orientation-averaged) was then added to the quadratic
% one: it raises Jsc by 0.2-1.1 % in the Marcus devices, and
% marcus_polarizability_only (RCT = 0) keeps the earlier default results.
ref = struct( ...
    'marcus_default',   [1.747166685  1.233062927  0.3596722351], ...
    'marcus_offset020', [6.714204085  1.179339402  0.6524444602], ...
    'marcus_tau100',    [8.936195509  1.290791077  0.5044375280], ...
    'marcus_nofield',   [0.6569693836 1.231500222  0.8998961134], ...
    'marcus_dipole_only', [0.6669889635 1.231495127 0.8870894699], ...
    'marcus_polarizability_only', [1.727457575 1.233063844 0.3634651799], ...
    'example_workflow', [0.3027620932 0.9341220427 0.8119981246]);
R = testCase.TestData.R;
for name = fieldnames(ref)'
    r = R.(name{1});
    verifyEqual(testCase, [r.Jsc r.Voc r.FF], ref.(name{1}), 'RelTol', 1e-4, name{1});
end
end

function testRadiativeLimits(testCase)
% Jsc and Voc cannot exceed the radiative limits, and FF cannot exceed the
% ideal-diode fill factor at the simulated Voc
R = testCase.TestData.R;
for name = fieldnames(R)'
    r = R.(name{1});
    verifyGreaterThan(testCase, r.Jsc, 0, name{1});
    verifyLessThanOrEqual(testCase, r.Jsc, r.Jscrad, name{1});
    verifyGreaterThan(testCase, r.Voc, 0, name{1});
    verifyLessThan(testCase, r.Voc, r.Vocrad, name{1});
    voc = r.Voc/(8.617333262e-5*300);
    FFmax = (voc - log(voc + 0.72))/(voc + 1);
    verifyGreaterThan(testCase, r.FF, 0.25, name{1});
    verifyLessThanOrEqual(testCase, r.FF, FFmax + 0.005, name{1});
end
end

function testDarkEquilibriumHasNoCurrent(testCase)
% Detailed balance: no current flows at equilibrium in the dark
R = testCase.TestData.R;
for name = fieldnames(R)'
    verifyLessThan(testCase, R.(name{1}).Jdark_eq, 1e-9, name{1});   % mA/cm^2
end
end

function testVocMatchesDetailedBalance(testCase)
% DP.results.Voc = kT*ln(Jscrad/J0) assumes the LE, CT and CS populations
% are in quasi-equilibrium at open circuit. In the example device exciton
% dissociation is fast compared with exciton decay, so the simulation must
% reproduce it. With slower transfer the excitons are not in equilibrium
% with the CT and CS states and Voc can only be lower.
R = testCase.TestData.R;
verifyEqual(testCase, R.example_workflow.Voc, R.example_workflow.DPVoc, 'AbsTol', 0.005);
for name = fieldnames(R)'
    verifyLessThanOrEqual(testCase, R.(name{1}).Voc, R.(name{1}).DPVoc + 0.005, name{1});
end
end

function testParameterTrends(testCase)
R = testCase.TestData.R;
% Larger LE-CT offset: more driving force for dissociation, lower CT energy
verifyGreaterThan(testCase, R.marcus_offset020.Jsc, R.marcus_default.Jsc);
verifyLessThan(testCase, R.marcus_offset020.Voc, R.marcus_default.Voc);
% Longer exciton lifetime: more excitons reach the CT state, less recombination
verifyGreaterThan(testCase, R.marcus_tau100.Jsc, R.marcus_default.Jsc);
verifyGreaterThan(testCase, R.marcus_tau100.Voc, R.marcus_default.Voc);
% The built-in field assists dissociation
verifyGreaterThan(testCase, R.marcus_default.Jsc, R.marcus_nofield.Jsc);
% The quadratic Stark shift lowers the CT level in the field: faster LE->CT
% and slower CT->LE transfer
verifyGreaterThan(testCase, R.marcus_default.Jsc, R.marcus_dipole_only.Jsc);
end

function testFieldWithinMarcusTable(testCase)
% The Marcus tables reach 5e7 V/m; larger fields would be extrapolated
R = testCase.TestData.R;
for name = fieldnames(R)'
    verifyLessThan(testCase, R.(name{1}).maxF, 5e7, name{1});
end
end

function r = simulate(DP, Prec, Vend)
DV = device(DP);
DV.Prec = Prec;
DV = device.runsolJsc(DV, 1);
DV = device.runsolJV(DV, 1, 0, Vend);
[r.Jsc, r.Voc, r.FF] = dfplot.JV_new(DV.sol_JV, 0);
r.Jscrad = Prec.results.Jscrad;
r.Vocrad = Prec.results.Vocrad;
r.DPVoc = DP.results.Voc;
Jeq = dfana.calcJ(DV.sol_eq);
r.Jdark_eq = max(abs(Jeq.tot(end, :)))*1e3;
[FV, ~] = dfana.calcF(DV.sol_JV);
r.maxF = max(abs(FV(:)))*100;   % V/cm -> V/m
end

function [DP, Prec] = example_workflow_device()
% Parameters of examples/ex05_recombination_and_spectra.m
Prec                        = paramsRec;
offset                      = 0.55;
Prec.params.tickness        = 100 * 1e-9;
Prec.params.Ex.DG0          = 1.8;
Prec.params.CT.DG0          = Prec.params.Ex.DG0 - offset;
Prec.params.Ex.f            = 2.56;
Prec.params.CT.f            = 2e-4;
Prec.params.Ex.sigma        = 0.01;
Prec.params.CT.sigma        = 0.01;
Prec.params.Ex.numbrestate  = 1;
Prec.params.CT.numbrestate  = 1;
Prec.params.Ex.L0           = 0.1;
Prec.params.Ex.Li           = 0.1;
Prec.params.CT.L0           = 0.2;
Prec.params.CT.Li           = 0.2;
Prec.params.RCTE            = 1e-2;
Prec.params.Excitondesnity  = 1e26;
Prec.params.Vstar           = 0.000;
Prec.const.T                = 300;
Prec                        = paramsRec.calcall(Prec);

DP = deviceparams(fullfile('parameters', 'DeviceParameters_Default.xlsx'));
DP.solveropt.verbose        = false;
DP.light_properties.OM      = 0;
DP.Time_properties.tpoints  = 100;
DP.Layers{2}.tp             = Prec.params.tickness * 100;
DP = DP.generateDeviceparams(2e19, 2, 5e-4, 1e10, 1e11, Prec, 1e-10, 0);
DP.Layers{2}.r0_CT = 0;
DP.Layers{2}.r0_Ex = 0;
end
