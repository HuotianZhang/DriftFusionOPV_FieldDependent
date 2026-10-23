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
verifyEqual(testCase, L.kdisexc, L.marcus.k(1));
verifyEqual(testCase, L.kforEx/L.kdisexc, L.marcus.k_bak(1)/L.marcus.k(1), 'RelTol', 1e-3);
end

function testMarcusRateWrappers(testCase)
% kDis_stark/kBak_stark are the LE->CT and CT->LE directions of one table
kf = kDis_stark(0.5, 1.5, 0.1, 300);
kb = kBak_stark(0.5, 1.5, 0.1, 300);
verifyEqual(testCase, kf, marcus_stark_table(0.5, 1.5, -0.1, 1, 300));
verifyEqual(testCase, kb, marcus_stark_table(0.5, 1.5, 0.1, -1, 300));
% Field lowers the CT energy: forward rate up for lambda > offset, back rate down
verifyGreaterThan(testCase, kf(end, 2), kf(1, 2));
verifyLessThan(testCase, kb(end, 2), kb(1, 2));
end

function testRecombinationResultsMatchesPrec(testCase)
% With the rates from Prec, recombinationResults reproduces Prec's
% non-radiative voltage loss
Prec = example_prec();
DP = deviceparams(fullfile('parameters', 'DeviceParameters_Default.xlsx'));
DP.Layers{2}.tp = Prec.params.tickness * 100;
DP = DP.generateDeviceparams(2e19, 2, 5e-4, 1e10, 1e11, Prec, 1e-10, 0);
verifyEqual(testCase, DP.results.DVnr, Prec.results.Dvnr, 'AbsTol', 1e-6);
% Faster CT decay -> larger J0 -> lower Voc
DP.Layers{2}.krec = 10*DP.Layers{2}.krec;
DP2 = DP.recombinationResults(Prec, 2);
verifyLessThan(testCase, DP2.results.Voc, DP.results.Voc);
end

function testLaguerreRecurrence(testCase)
% Explicit series for the generalized Laguerre polynomial, incl. negative a
for n = 0:5
    for m = 0:15
        a = m - n;
        for x = [0.3 1 2.7]
            ref = 0;
            for i = 0:n
                ref = ref + (-1)^i*genbinom(n + a, n - i)*x^i/factorial(i);
            end
            verifyEqual(testCase, paramsRec.laguerre(n, a, x), ref, 'AbsTol', 1e-9);
        end
    end
end
end

function testR0ExIsADistance(testCase)
% The old Marcus switch r0_Ex = 1 would mean 1 cm; the solver rejects it
[DP, ~] = build_MarcusTransfer_device(0.05, 10, 0.5, 1.5, 1.8);
DP.Layers{2}.r0_Ex = 1;
verifyError(testCase, @() pndriftHCT(struct('sol', 0), DP), 'pndriftHCT:r0_Ex');
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
DP.solveropt.verbose = false;
sol_eq = EquilibratePNHCT(0, DP);
p = sol_eq.params;
p.Experiment_prop.BC = 1;
p.Time_properties.tmax = 1e-9;
p = update_time(p);
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

function c = genbinom(r, k)
% Binomial coefficient r over k for integer r of any sign
c = prod(r - (0:k-1))/factorial(k);
end

function Prec = example_prec()
% Recombination parameters of Example_workflow.m
Prec                        = paramsRec;
Prec.params.tickness        = 100 * 1e-9;
Prec.params.Ex.DG0          = 1.8;
Prec.params.CT.DG0          = 1.8 - 0.55;
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
end
