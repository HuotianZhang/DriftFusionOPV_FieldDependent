function tests = convergenceTest
% Numerical accuracy of the reference simulation: mesh geometry, mesh
% refinement, solver tolerance, J-V sweep rate, and current continuity.
% Run from MATLAB with:  results = runtests('tests'); assertSuccess(results)
tests = functiontests(localfunctions);
end

function setupOnce(testCase)
import matlab.unittest.fixtures.CurrentFolderFixture
import matlab.unittest.fixtures.PathFixture
root = fileparts(fileparts(mfilename('fullpath')));
testCase.applyFixture(CurrentFolderFixture(root));
testCase.applyFixture(PathFixture(root, 'IncludingSubfolders', true));

% name, mesh, refinement factor, RelTol, J-V sweep time (s), mobility
% (cm^2/(V s)), boundary condition (2: fixed densities, default;
% 1: selective contacts)
cases = {
    'legacy',        'legacy', 1, 1e-3, 0.1, 5e-2, 2
    'exact',         'exact',  1, 1e-3, 0.1, 5e-2, 2
    'exact_mesh2',   'exact',  2, 1e-3, 0.1, 5e-2, 2
    'exact_mesh4',   'exact',  4, 1e-3, 0.1, 5e-2, 2
    'exact_tol',     'exact',  1, 1e-5, 0.1, 5e-2, 2
    'exact_slow',    'exact',  1, 1e-3, 1,   5e-2, 2
    'lowmu',         'exact',  1, 1e-3, 0.1, 1e-4, 2
    'lowmu_mesh2',   'exact',  2, 1e-3, 0.1, 1e-4, 2
    'bc1',           'legacy', 1, 1e-3, 0.1, 5e-2, 1
    'bc1_lowmu',     'exact',  1, 1e-3, 0.1, 1e-4, 1
    };
R = struct();
for c = 1:size(cases, 1)
    r = run_case(cases{c, 2:7});
    R.(cases{c, 1}) = r;
    fprintf(['CONV %-12s npts=%4d Jsc=%.6f Voc=%.6f FF=%.6f | flux: Jsc=%.6f Voc=%.6f FF=%.6f | ' ...
        'Jsc_calcJ=%.6f Jsc_flux=%.6f spread=%.3g | Voc: J_calcJ=%.4g J_flux=%.4g Jn_left=%.4g Jp_right=%.4g\n'], ...
        cases{c, 1}, r.npts, r.Jsc, r.Voc, r.FF, r.flux.Jsc, r.flux.Voc, r.flux.FF, r.Jsc_calcJ, ...
        r.Jsc_flux_right, r.spread, r.Jvoc_calcJ, r.Jvoc_flux, r.Jn_left_voc, r.Jp_right_voc);
end
testCase.TestData.R = R;
end

function testLegacyMeshThickness(testCase)
% The legacy mesh stops short of the layer ends; the exact mesh does not
[DPl, ~] = build_MarcusTransfer_device(0.2, 10, 0.5, 1.5, 1.8, 'verbose', false);
[DPe, ~] = build_MarcusTransfer_device(0.2, 10, 0.5, 1.5, 1.8, 'verbose', false, 'mesh', 'exact');
widths = @(DP) cellfun(@(L) L.XR - L.XL, DP.Layers)*1e7;   % nm
verifyEqual(testCase, widths(DPl), [48 95.9 46.9], 'AbsTol', 1e-6);
verifyEqual(testCase, widths(DPe), cellfun(@(L) L.tp, DPe.Layers)*1e7, 'AbsTol', 1e-6);
verifyEqual(testCase, DPe.Xgrid_properties(end), sum(cellfun(@(L) L.tp, DPe.Layers)), 'RelTol', 1e-12);
verifyTrue(testCase, all(diff(DPe.Xgrid_properties) > 0));
end

function testSharedBoundaryBelongsToLeftLayer(testCase)
% In the exact mesh adjacent layers share the boundary point; dfana.develop
% must give it the left layer's properties (as pndriftHCT does), also for
% the mirrored device of runsolVoc/runsolTPV (symm = 1)
[DP, ~] = build_MarcusTransfer_device(0.2, 10, 0.5, 1.5, 1.8, 'verbose', false, 'mesh', 'exact');
x = DP.Xgrid_properties;
i = find(abs(x - DP.Layers{1}.XR) < 1e-15);
verifyNumElements(testCase, i, 1);
sol = struct('params', DP, 'x', x, 't', 0);
dev = dfana.develop(sol);
verifyEqual(testCase, dev.muee(1, i), DP.Layers{1}.muee);
verifyEqual(testCase, dev.muee(1, i+1), DP.Layers{2}.muee);
xm = [x, 2*x(end) - fliplr(x(1:end-1))];
sol = struct('params', DP, 'x', xm, 't', 0);
sol.params.Experiment_prop.symm = 1;
dev = dfana.develop(sol);
verifyEqual(testCase, dev.muee(1, i), DP.Layers{1}.muee);
verifyEqual(testCase, dev.muee(1, numel(xm) + 1 - i), DP.Layers{1}.muee);
end

function testMeshConvergence(testCase)
% Refining the exact mesh 4x (2x at low mobility) moves Jsc by ~1e-5
% relative, Voc by < 0.1 mV and FF by < 1e-4
R = testCase.TestData.R;
verify_close(testCase, R.exact, R.exact_mesh4, 1e-4, 0.5e-3, 5e-4, 'mesh x4');
verify_close(testCase, R.lowmu, R.lowmu_mesh2, 1e-4, 0.5e-3, 5e-4, 'mesh x2, mobility 1e-4');
end

function testSolverTolerance(testCase)
R = testCase.TestData.R;
verify_close(testCase, R.exact, R.exact_tol, 1e-4, 0.5e-3, 5e-4, 'RelTol 1e-5');
end

function testSweepRate(testCase)
% A 10x slower J-V sweep (1.4 V/s) moves Voc by ~0.15 mV: the default sweep
% is quasi-static
R = testCase.TestData.R;
verify_close(testCase, R.exact, R.exact_slow, 1e-4, 1e-3, 1e-3, '10x slower sweep');
end

function testCurrentContinuity(testCase)
% At steady state the flux current is uniform across the device
R = testCase.TestData.R;
for name = fieldnames(R)'
    verifyLessThan(testCase, R.(name{1}).spread, 1e-3, name{1});
    verifyEqual(testCase, R.(name{1}).Jsc_flux_left, R.(name{1}).Jsc_flux_right, 'RelTol', 1e-3, name{1});
end
end

function testCalcJOmitsMinorityContactCurrents(testCase)
% calcJ sets the electron current at the hole contact and the hole current
% at the electron contact to zero, but the default boundary conditions
% (fixed densities, BC = 2) let minority carriers leave there. The flux
% current at the contact differs from calcJ by exactly these currents.
R = testCase.TestData.R;
for name = setdiff(fieldnames(R)', {'bc1', 'bc1_lowmu'})
    r = R.(name{1});
    verifyEqual(testCase, r.Jvoc_flux - r.Jvoc_calcJ, r.Jn_left_voc + r.Jp_right_voc, ...
        'RelTol', 2e-2, name{1});
end
% At short circuit and high mobility the minority currents are negligible
verifyEqual(testCase, R.exact.Jsc_calcJ, R.exact.Jsc_flux_right, 'RelTol', 1e-4);
end

function testSelectiveContacts(testCase)
% With selective contacts (BC 1) no minority carriers leave through the
% contacts, so calcJ and the flux current agree. At high mobility the
% default (BC 2 with calcJ) reproduces the selective-contact result; at
% mobility 1e-4 it overestimates Voc by ~18 mV.
R = testCase.TestData.R;
for name = {'bc1', 'bc1_lowmu'}
    r = R.(name{1});
    verifyLessThan(testCase, abs(r.Jn_left_voc) + abs(r.Jp_right_voc), 1e-3, name{1});
    verify_close(testCase, r, r.flux, 1e-4, 0.5e-3, 5e-4, [name{1} ', calcJ vs flux']);
end
verify_close(testCase, R.legacy, R.bc1, 1e-4, 0.5e-3, 5e-4, 'BC 2 (calcJ) vs BC 1, mobility 5e-2');
verifyGreaterThan(testCase, R.lowmu.Voc - R.bc1_lowmu.Voc, 0.01);
end

function verify_close(testCase, a, b, relJsc, absVoc, absFF, label)
verifyEqual(testCase, b.Jsc, a.Jsc, 'RelTol', relJsc, ['Jsc, ' label]);
verifyEqual(testCase, b.Voc, a.Voc, 'AbsTol', absVoc, ['Voc, ' label]);
verifyEqual(testCase, b.FF, a.FF, 'AbsTol', absFF, ['FF, ' label]);
end

function r = run_case(mesh, refine, reltol, tsweep, mobility, bc)
[DP, Prec] = build_MarcusTransfer_device(0.2, 10, 0.5, 1.5, 1.8, 'verbose', false, ...
    'mesh', mesh, 'mobility', mobility);
DP.Experiment_prop.BC = bc;
if refine ~= 1
    for k = 1:DP.layers_num
        for f = {'pp', 'epointsL', 'epointsR', 'XipL', 'XipR'}
            DP.Layers{k}.(f{1}) = DP.Layers{k}.(f{1})/refine;
        end
    end
end
DP.solveropt.RelTol = reltol;
DP.solveropt.AbsTol = 1e-6*reltol/1e-3;
DV = device(DP);
DV.Prec = Prec;
DV = device.runsolJsc(DV, 1);
% J-V sweep as in device.runsolJV, with the tolerance and sweep time of this case
p = DV.sol_Jsc.params;
p.solveropt.RelTol = reltol;
p.solveropt.AbsTol = 1e-6*reltol/1e-3;
p.Time_properties.tmax = tsweep;
p.Experiment_prop.V_fun_type = 'sweep';
p.Experiment_prop.V_fun_arg(1) = 0;
p.Experiment_prop.V_fun_arg(2) = 1.4;
p.Experiment_prop.V_fun_arg(3) = tsweep;
p = update_time(p);
p = Timemesh(p);
sol = pndriftHCT(DV.sol_Jsc, p);
[r.Jsc, r.Voc, r.FF] = dfplot.JV_new(sol, 0);
[r.flux.Jsc, r.flux.Voc, r.flux.FF] = dfplot.JV_new(sol, 0, 0, '', 'flux');
r.npts = numel(DV.sol_Jsc.x);

% Short circuit (steady state): calcJ at the right contact versus the flux
% current, which must be the same at every x
Jc = dfana.calcJ(DV.sol_Jsc);
Jf = dfana.calcJ_flux(DV.sol_Jsc);
jt = Jf.tot(end, :)*1e3;   % mA/cm^2
r.Jsc_calcJ = -Jc.tot(end, end)*1e3;
r.Jsc_flux_left = -jt(1);
r.Jsc_flux_right = -jt(end);
r.spread = (max(jt) - min(jt))/abs(median(jt));

% Near open circuit: minority-carrier currents at the contacts, which calcJ
% assumes to be zero
Jc = dfana.calcJ(sol);
Jf = dfana.calcJ_flux(sol);
V = dfana.calcVapp(sol);
[~, i] = min(abs(V - r.Voc));
r.Jvoc_calcJ = Jc.tot(i, end)*1e3;
r.Jvoc_flux = Jf.tot(i, end)*1e3;
r.Jn_left_voc = Jf.n(i, 1)*1e3;
r.Jp_right_voc = Jf.p(i, end)*1e3;
end
