function tests = smokeTest
% Smoke tests for the main simulation entry points.
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

function testDeviceParamsLoad(testCase)
DP = deviceparams(fullfile('parameters', 'DeviceParameters_Default.xlsx'));
verifyGreaterThan(testCase, DP.layers_num, 0);
end

function testTransferMatrixReadsOpticalData(testCase)
[Xpos, Gx] = TransferMatrix_generation(100, 'PBDB-T_ITIC', 1);
verifyNotEmpty(testCase, Xpos);
verifyEqual(testCase, numel(Gx), numel(Xpos));
verifyTrue(testCase, all(isfinite(Gx)));
verifyGreaterThan(testCase, sum(Gx), 0);
end

function testExternalModel(testCase)
VV = linspace(0, 1.2, 25);
JJ = external_model(VV, 0.05, 10, 0.5, 1.5, 1.8, 0.001);
verifySize(testCase, JJ, size(VV));
verifyTrue(testCase, all(isfinite(JJ)));
% Under 1 sun the short-circuit current is negative
verifyLessThan(testCase, JJ(1), 0);
end
