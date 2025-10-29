%% Test script for device_forMarcus refactoring
% This script demonstrates that the refactored device_forMarcus class
% maintains backward compatibility and allows for configuration
%
% Note: This is a demonstration script. Actual testing requires MATLAB
% and the full DriftFusion environment to be set up.

%% Test 1: Default values are correctly set
fprintf('Test 1: Verifying default property values\n');
DV_test = device_forMarcus;

assert(DV_test.tmax_eq == 1e-2, 'tmax_eq default value incorrect');
assert(DV_test.tmax_JV_dark == 1e0, 'tmax_JV_dark default value incorrect');
assert(DV_test.tmax_JV_light == 1e-1, 'tmax_JV_light default value incorrect');
assert(DV_test.tmax_Voc_1 == 1e-2, 'tmax_Voc_1 default value incorrect');
assert(DV_test.tmax_Voc_2 == 1e-2, 'tmax_Voc_2 default value incorrect');
assert(DV_test.tmax_TPV == 5e-5, 'tmax_TPV default value incorrect');
assert(DV_test.tmax_TAS == 10e-9, 'tmax_TAS default value incorrect');
assert(DV_test.tmax_transient == 1e-2, 'tmax_transient default value incorrect');
assert(DV_test.V_pulse_rise == 1e-4, 'V_pulse_rise default value incorrect');

fprintf('  ✓ All default values correct\n\n');

%% Test 2: Properties can be modified
fprintf('Test 2: Verifying properties can be modified\n');
DV_test.tmax_eq = 5e-2;
DV_test.tmax_JV_dark = 2e0;
DV_test.tmax_JV_light = 3e-1;

assert(DV_test.tmax_eq == 5e-2, 'tmax_eq modification failed');
assert(DV_test.tmax_JV_dark == 2e0, 'tmax_JV_dark modification failed');
assert(DV_test.tmax_JV_light == 3e-1, 'tmax_JV_light modification failed');

fprintf('  ✓ All properties can be modified\n\n');

%% Test 3: Multiple instances have independent properties
fprintf('Test 3: Verifying instances have independent properties\n');
DV1 = device_forMarcus;
DV2 = device_forMarcus;

DV1.tmax_eq = 1e-1;
DV2.tmax_eq = 1e-3;

assert(DV1.tmax_eq == 1e-1, 'DV1 tmax_eq incorrect');
assert(DV2.tmax_eq == 1e-3, 'DV2 tmax_eq incorrect');
assert(DV1.tmax_eq ~= DV2.tmax_eq, 'Instances are not independent');

fprintf('  ✓ Each instance has independent properties\n\n');

%% Test 4: Documentation example
fprintf('Test 4: Running documentation example\n');
% This demonstrates the usage pattern from the documentation
DV_example = device_forMarcus;

% Customize times
DV_example.tmax_JV_dark = 2e0;
DV_example.tmax_JV_light = 5e-1;
DV_example.tmax_TPV = 1e-4;

% Verify the values
assert(DV_example.tmax_JV_dark == 2e0, 'Example configuration failed');
assert(DV_example.tmax_JV_light == 5e-1, 'Example configuration failed');
assert(DV_example.tmax_TPV == 1e-4, 'Example configuration failed');

fprintf('  ✓ Documentation example works correctly\n\n');

%% Summary
fprintf('========================================\n');
fprintf('All tests passed successfully!\n');
fprintf('========================================\n');
fprintf('\nThe refactoring maintains:\n');
fprintf('  • Backward compatibility (default values unchanged)\n');
fprintf('  • Configurability (properties can be modified)\n');
fprintf('  • Instance independence (each object has its own values)\n');
fprintf('\nNext steps:\n');
fprintf('  1. Run full integration tests with actual device parameters\n');
fprintf('  2. Verify simulation results match previous implementation\n');
fprintf('  3. Test with different parameter combinations\n');
