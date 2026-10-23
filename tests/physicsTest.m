function tests = physicsTest
% Consistency tests for the Marcus transfer model and the solver set-up.
% Run from MATLAB with:  results = runtests('tests'); assertSuccess(results)
tests = functiontests(localfunctions);
end

function setupOnce(testCase)
% All code loads data relative to the repository root
% (parameters/, optical_data/, resourceFiles/), so run from there.
import matlab.unittest.fixtures.CurrentFolderFixture
import matlab.unittest.fixtures.PathFixture
root = fileparts(fileparts(mfilename('fullpath')));
testCase.applyFixture(CurrentFolderFixture(root));
testCase.applyFixture(PathFixture(root, 'IncludingSubfolders', true));
end

function testMarcusZeroFieldDetailedBalance(testCase)
% k_bak/k at zero field must follow exp(-offset/kT)/RCTE for any T and RCTE
kB = 8.6173324e-5;  % eV/K, as in deviceparams
for T = [300 320]
    for RCTE = [0.1 0.3]
        for offset = [0.05 0.15]
            [E, k, k_bak] = marcus_rate_tables(0.5, 1.5, offset, T, RCTE);
            verifyEqual(testCase, E(1), 0);
            verifyEqual(testCase, k_bak(1)/k(1), exp(-offset/(kB*T))/RCTE, 'RelTol', 1e-3, ...
                sprintf('T = %g K, RCTE = %g, offset = %g eV', T, RCTE, offset));
        end
    end
end
end

function testMarcusDeviceZeroFieldConsistency(testCase)
% The zero-field Marcus rates used by the solver must match the
% detailed-balance kforEx that deviceparams uses for the equilibrium densities
[DP, ~] = build_MarcusTransfer_device(0.1, 10, 0.5, 1.5, 1.8);
L = DP.Layers{2};
kbT = DP.physical_const.kB*DP.physical_const.T;
verifyEqual(testCase, L.kdisexc, DP.physical_const.k_values(1));
verifyEqual(testCase, L.kforEx/L.kdisexc, ...
    DP.physical_const.k_bak_values(1)/DP.physical_const.k_values(1), 'RelTol', 1e-3);
% Field-independent branch of pndriftHCT_forMarcus for this layer
verifyEqual(testCase, L.kdisexc*exp(-L.offset/kbT)/L.RCTE, L.kforEx, 'RelTol', 1e-12);
end

function testGenerateDeviceparamsUsesActiveLayer(testCase)
[~, Prec] = build_MarcusTransfer_device(0.1, 10, 0.5, 1.5, 1.8);
DP0 = deviceparams(fullfile('parameters', 'DeviceParameters_Default.xlsx'));
NC = 2e19;
kdisex = 3e11;
DP = DP0.generateDeviceparams(NC, 1, 5e-4, 1e10, kdisex, Prec, 1e-10, 0);
verifyEqual(testCase, DP.Layers{1}.kdisexc, kdisex);
verifyEqual(testCase, DP.Layers{2}.kdisexc, DP0.Layers{2}.kdisexc);
for ii = 1:DP.layers_num
    verifyEqual(testCase, DP.Layers{ii}.N0C, NC);
    verifyEqual(testCase, DP.Layers{ii}.N0V, NC);
end
end

function testBoundaryCondition1Runs(testCase)
% BC = 1 (fixed carrier densities at the contacts) used to reference an
% undefined variable. Starting from equilibrium the contacts already hold
% the boundary densities, so a short run must stay finite.
[DP, ~] = build_MarcusTransfer_device(0.05, 10, 0.5, 1.5, 1.8);
sol_eq = EquilibratePNHCT_forMarcus(0, DP);
p = sol_eq.params;
p.Experiment_prop.BC = 1;
p.Time_properties.tmax = 1e-9;
p = update_time(p);

sol = pndriftHCT_forMarcus(sol_eq, p);
verifyTrue(testCase, all(isfinite(sol.sol(:))));

% pndriftHCT reads r0_Ex as a distance; switch the field dependence off
p.Layers{2}.r0_Ex = 0;
sol = pndriftHCT(sol_eq, p);
verifyTrue(testCase, all(isfinite(sol.sol(:))));
end

function testExternalModelSeriesResistance(testCase)
% With R_s > 0 the voltage grid is shifted by J*R_s, so external_model must
% interpolate even when VV has as many points as the simulation output
args = {0.05, 10, 0.5, 1.5, 1.8};
[J0, V0] = run_MarcusTransfer_JV([0 1.2], args{:}, 0);
Rs = 0.01;
VV = linspace(0, 1.2, numel(J0));
JJ = external_model(VV, args{:}, Rs);
expected = interp1(V0 + J0*Rs, J0, VV, 'linear', 'extrap');
verifySize(testCase, JJ, size(VV));
verifyEqual(testCase, JJ, expected, 'AbsTol', 1e-9*max(abs(J0)));
end
