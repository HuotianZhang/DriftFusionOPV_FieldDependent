function tests = examplesTest
% Runs every script in examples/ so that the examples keep working.
% Run from MATLAB with:  results = runtests('tests'); assertSuccess(results)
tests = functiontests(localfunctions);
end

function setupOnce(testCase)
import matlab.unittest.fixtures.CurrentFolderFixture
import matlab.unittest.fixtures.PathFixture
repo = fileparts(fileparts(mfilename('fullpath')));
testCase.applyFixture(CurrentFolderFixture(repo));
testCase.applyFixture(PathFixture(repo, 'IncludingSubfolders', true));
testCase.TestData.dir = fullfile(repo, 'examples');
end

function teardown(~)
close all force
end

function testEx01FirstJVCurve(testCase)
run_example(testCase, 'ex01_first_jv_curve.m');
end

function testEx02ParameterSweep(testCase)
run_example(testCase, 'ex02_parameter_sweep.m');
end

function testEx03StarkEffect(testCase)
run_example(testCase, 'ex03_stark_effect.m');
end

function testEx04DeviceSimulation(testCase)
run_example(testCase, 'ex04_device_simulation.m');
end

function testEx05RecombinationAndSpectra(testCase)
run_example(testCase, 'ex05_recombination_and_spectra.m');
end

function testEx06FitMeasuredJV(testCase)
run_example(testCase, 'ex06_fit_measured_jv.m');
end

function run_example(testCase, name)
file = fullfile(testCase.TestData.dir, name);
verifyTrue(testCase, isfile(file), name);
verifyWarningFree(testCase, @() run_script(file), name);
end

function run_script(script_file__)
% Own workspace, so the script cannot overwrite the test's variables
run(script_file__);
end
