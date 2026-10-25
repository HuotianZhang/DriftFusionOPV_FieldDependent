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
% k_bak/k at zero field must follow exp(-offset/kT)/RCTE for any T and RCTE,
% whatever the Stark parameters (the Stark shift vanishes at zero field)
kB = 8.6173324e-5;  % eV/K, as in deviceparams
stark = [1.5 8.5e5; 0 0; 3 1e4];   % RCT (nm), delta_alpha (A^3)
for T = [300 320]
    for RCTE = [0.1 0.3]
        for offset = [0.05 0.15]
            for j = 1:size(stark, 1)
                [E, k, k_bak] = marcus_rate_tables(0.5, stark(j, 1), offset, T, RCTE, stark(j, 2));
                verifyEqual(testCase, E(1), 0);
                verifyEqual(testCase, k_bak(1)/k(1), exp(-offset/(kB*T))/RCTE, 'RelTol', 1e-3, ...
                    sprintf('T = %g K, RCTE = %g, offset = %g eV, RCT = %g nm, delta_alpha = %g A^3', ...
                    T, RCTE, offset, stark(j, 1), stark(j, 2)));
            end
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
kf = kDis_stark(0.5, 1.5, 0.1, 300, 8.5e5);
kb = kBak_stark(0.5, 1.5, 0.1, 300, 8.5e5);
verifyEqual(testCase, kf, marcus_stark_table(0.5, 1.5, -0.1, 1, 300, 8.5e5));
verifyEqual(testCase, kb, marcus_stark_table(0.5, 1.5, 0.1, -1, 300, 8.5e5));
% The quadratic shift lowers the CT energy: forward rate up for
% lambda > offset, back rate down
kf = kDis_stark(0.5, 0, 0.1, 300, 8.5e5);
kb = kBak_stark(0.5, 0, 0.1, 300, 8.5e5);
verifyGreaterThan(testCase, kf(end, 2), kf(1, 2));
verifyLessThan(testCase, kb(end, 2), kb(1, 2));
end

function testStarkOrientationAverage(testCase)
% The closed-form orientation average equals the numerical average of the
% Marcus rate over cos(theta), for both directions and both Stark terms
pc = physconst();
Hab = 0.01; lambda = 0.5; T = 300;
for F = [1e5 1e7 5e7]
    for direction = [1 -1]
        for dG = [0.05 0.3]
            deltaG = -direction*dG;
            for stark = [1.5 0; 1.5 8.5e5; 3 1e4]'
                r_CT = stark(1)*1e-9;
                dalpha = 4*pi*pc.eps0*stark(2)*1e-30;
                shift = @(u) -r_CT*F*u - 0.5*dalpha*F^2/pc.q;   % eV
                ref = 0.5*integral(@(u) marcus_plain(Hab, lambda, deltaG + direction*shift(u), T), ...
                    -1, 1, 'RelTol', 1e-12, 'AbsTol', 0);
                k = marcus_equation_stark(Hab, lambda, deltaG, T, F, r_CT, stark(2), direction);
                verifyEqual(testCase, k, ref, 'RelTol', 1e-9, sprintf('F = %g V/m, direction %d, dG = %g eV', F, direction, dG));
            end
        end
    end
end
end

function testStarkLimits(testCase)
lambda = 0.5; offset = 0.05; T = 300;
% Without Stark terms the rates do not depend on the field
kf = kDis_stark(lambda, 0, offset, T, 0);
kb = kBak_stark(lambda, 0, offset, T, 0);
verifyEqual(testCase, kf(:, 2), repmat(kf(1, 2), size(kf, 1), 1), 'RelTol', 1e-12);
verifyEqual(testCase, kb(:, 2), repmat(kb(1, 2), size(kb, 1), 1), 'RelTol', 1e-12);
% In an isotropic film the linear term enters to second order in F
F = [0 1e6 2e6];
k = marcus_equation_stark(0.01, lambda, -offset, T, F, 1.5e-9, 0, 1);
verifyEqual(testCase, (k(3) - k(1))/(k(2) - k(1)), 4, 'RelTol', 1e-3);
verifyGreaterThan(testCase, k(2), k(1));
end

function testMLJReducesToClassicalMarcus(testCase)
% With S = 0 and sigma = 0 the vibronic/disorder rates are the classical
% orientation-averaged Marcus rates, in both directions
F = [0 1e5 1e7 5e7];
for offset = [0.05 0.3]
    for stark = [1.5 0; 0 8.5e5; 1.5 8.5e5; 3 1e4]'
        [kf, kb] = marcus_mlj_stark_rates(0.01, 0.5, offset, 300, F, stark(1)*1e-9, stark(2), 0, 0.17, 0);
        verifyEqual(testCase, kf, marcus_equation_stark(0.01, 0.5, -offset, 300, F(:), stark(1)*1e-9, stark(2), 1), 'RelTol', 1e-9);
        verifyEqual(testCase, kb, marcus_equation_stark(0.01, 0.5, offset, 300, F(:), stark(1)*1e-9, stark(2), -1), 'RelTol', 1e-9);
    end
end
end

function testMLJZeroFieldDetailedBalance(testCase)
% The vibronic/disorder tables keep k_bak/k = exp(-offset/kT)/RCTE at zero field
kB = physconst().kB_eV;
for opts = {{'huang_rhys', 1}, {'disorder', 0.08}, {'huang_rhys', 1.5, 'mode_energy', 0.15, 'disorder', 0.05}}
    for offset = [0.05 0.2]
        [E, k, k_bak] = marcus_rate_tables(0.4, 1.5, offset, 300, 0.1, 8.5e5, opts{1}{:});
        verifyEqual(testCase, E(1), 0);
        verifyEqual(testCase, k_bak(1)/k(1), exp(-offset/(kB*300))/0.1, 'RelTol', 1e-9);
    end
end
end

function testMLJDisorderAverage(testCase)
% At zero field the disorder-averaged rate is the classical rate averaged
% over Gaussian CT energies whose mean lies sigma^2/(2kT) above the free energy
kT = physconst().kB_eV*300;
sigma = 0.08; offset = 0.1; lambda = 0.4;
kf = marcus_mlj_stark_rates(0.01, lambda, offset, 300, 0, 0, 0, 0, 0.17, sigma);
g = @(d) exp(-d.^2/(2*sigma^2))/(sqrt(2*pi)*sigma);
ref = integral(@(d) marcus_plain(0.01, lambda, -offset + sigma^2/(2*kT) + d, 300).*g(d), ...
    -1, 1, 'RelTol', 1e-12, 'AbsTol', 0);
verifyEqual(testCase, kf, ref, 'RelTol', 1e-9);
end

function testMLJVibronicSum(testCase)
% At zero field without disorder the rate is the Franck-Condon weighted sum
% of classical Marcus rates over quanta of the high-frequency mode
S = 1.2; hw = 0.17; offset = 0.3; lambda = 0.2;
kf = marcus_mlj_stark_rates(0.01, lambda, offset, 300, 0, 0, 0, S, hw, 0);
ref = 0;
for n = 0:40
    ref = ref + exp(-S)*S^n/factorial(n)*marcus_plain(0.01, lambda, -offset + n*hw, 300);
end
verifyEqual(testCase, kf, ref, 'RelTol', 1e-10);
end

function testMLJDeviceConsistency(testCase)
% The device uses the vibronic/disorder zero-field rates consistently with
% the detailed balance of deviceparams
[DP, ~] = build_MarcusTransfer_device(0.1, 10, 0.5, 1.5, 1.8, 'verbose', false, ...
    'huang_rhys', 1, 'disorder', 0.05);
L = DP.Layers{2};
verifyEqual(testCase, L.kdisexc, L.marcus.k(1));
verifyEqual(testCase, L.kforEx/L.kdisexc, L.marcus.k_bak(1)/L.marcus.k(1), 'RelTol', 1e-3);
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

function testJVJscAtLowMobility(testCase)
% At low mobility the first sample of a J-V sweep carries a large spurious
% current from the time derivative in calcJ. JV_new must give the
% steady-state short-circuit current, which cannot exceed the radiative limit.
[DP, Prec] = build_MarcusTransfer_device(0.2, 10, 0.5, 1.5, 1.4, 'mobility', 1e-4, 'verbose', false);
DP.Layers{2}.marcus.weight = 0;
DV = device(DP);
DV.Prec = Prec;
DV = device.runsolJsc(DV, 1);
DV = device.runsolJV(DV, 1, 0, 1.1);
Jsc = dfplot.JV_new(DV.sol_JV, 0);
J = dfana.calcJ(DV.sol_Jsc);
Jsc_steady = -J.tot(end, end)*1e3;
verifyEqual(testCase, Jsc, Jsc_steady, 'RelTol', 1e-3);
verifyLessThan(testCase, Jsc, Prec.results.Jscrad);
end

function k = marcus_plain(Hab, lambda, deltaG, T)
% Marcus rate without field (s^-1), element-wise in deltaG
pc = physconst();
kT = pc.kB_eV*T;
k = (2*pi/pc.hbar)*(Hab*pc.q)^2/sqrt(4*pi*lambda*kT*pc.q^2)*exp(-(lambda + deltaG).^2/(4*lambda*kT));
end

function c = genbinom(r, k)
% Binomial coefficient r over k for integer r of any sign
c = prod(r - (0:k-1))/factorial(k);
end

function Prec = example_prec()
% Recombination parameters of examples/ex05_recombination_and_spectra.m
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
