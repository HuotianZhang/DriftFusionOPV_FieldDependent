# Testing Checklist for pndriftHCT_forMarcus.m Optimizations

## Pre-Testing Setup

- [ ] MATLAB installed and accessible
- [ ] Repository cloned and up to date
- [ ] All dependencies available (pnParamsHCT, fun_gen, etc.)

## Functional Testing

### Test 1: Basic Execution
```matlab
% Test that the function runs without errors
params = pnParamsHCT();
try
    sol = pndriftHCT_forMarcus(struct('sol', 0), params);
    fprintf('✅ Test 1 PASSED: Function executes without errors\n');
catch ME
    fprintf('❌ Test 1 FAILED: %s\n', ME.message);
end
```

- [ ] Function executes without errors
- [ ] Returns solstruct with expected fields (sol, x, t, params, tspan)

### Test 2: Solution Structure Validation
```matlab
% Verify solution structure is correct
params = pnParamsHCT();
sol = pndriftHCT_forMarcus(struct('sol', 0), params);

assert(isfield(sol, 'sol'), 'Missing sol field');
assert(isfield(sol, 'x'), 'Missing x field');
assert(isfield(sol, 't'), 'Missing t field');
assert(isfield(sol, 'params'), 'Missing params field');
assert(size(sol.sol, 3) == 5, 'Should have 5 state variables');
fprintf('✅ Test 2 PASSED: Solution structure is valid\n');
```

- [ ] All required fields present
- [ ] Solution array has correct dimensions (time × space × 5)

### Test 3: Physical Validity
```matlab
% Check for physical validity of results
params = pnParamsHCT();
sol = pndriftHCT_forMarcus(struct('sol', 0), params);

% Extract final state
n = sol.sol(end, :, 1);   % Electrons
p = sol.sol(end, :, 2);   % Holes
CT = sol.sol(end, :, 3);  % CT states
V = sol.sol(end, :, 4);   % Potential
Ex = sol.sol(end, :, 5);  % Excitons

assert(all(n >= 0), 'Negative electron density detected');
assert(all(p >= 0), 'Negative hole density detected');
assert(all(CT >= 0), 'Negative CT density detected');
assert(all(Ex >= 0), 'Negative exciton density detected');
fprintf('✅ Test 3 PASSED: All densities are non-negative\n');
```

- [ ] No negative carrier densities
- [ ] Potential values are reasonable

### Test 4: Boundary Conditions
```matlab
% Test different boundary condition types
params = pnParamsHCT();

for bc_type = 0:4
    params.Experiment_prop.BC = bc_type;
    try
        sol = pndriftHCT_forMarcus(struct('sol', 0), params);
        fprintf('✅ BC Type %d: PASSED\n', bc_type);
    catch ME
        fprintf('❌ BC Type %d: FAILED - %s\n', bc_type, ME.message);
    end
end
```

- [ ] BC = 0 (Zero current) works
- [ ] BC = 1 (Selective contacts) works
- [ ] BC = 2 (Non-selective) works
- [ ] BC = 3 (Finite SRV) works
- [ ] BC = 4 (Open circuit) works

### Test 5: Sequential Solving
```matlab
% Test using previous solution as initial condition
params = pnParamsHCT();
params.Experiment_prop.V_fun_arg(1) = 0;
sol_eq = pndriftHCT_forMarcus(struct('sol', 0), params);

params.Experiment_prop.V_fun_arg(1) = 0.5;
sol_05V = pndriftHCT_forMarcus(sol_eq, params);

assert(~isempty(sol_05V.sol), 'Sequential solving failed');
fprintf('✅ Test 5 PASSED: Sequential solving works\n');
```

- [ ] Can use previous solution as initial condition
- [ ] Solution converges at different voltages

## Performance Testing

### Test 6: Execution Time Measurement
```matlab
% Measure execution time
params = pnParamsHCT();
params.Time_properties.tpoints = 200;  % Adjust as needed

tic;
sol = pndriftHCT_forMarcus(struct('sol', 0), params);
elapsed_time = toc;

fprintf('Execution time: %.2f seconds\n', elapsed_time);
fprintf('Time points: %d, Space points: %d\n', ...
    length(sol.t), length(sol.x));
```

- [ ] Execution time recorded
- [ ] Time: _______ seconds

**Note**: Compare with original version if available to measure speedup.

### Test 7: Memory Usage
```matlab
% Check memory usage (optional)
params = pnParamsHCT();
m1 = memory;
sol = pndriftHCT_forMarcus(struct('sol', 0), params);
m2 = memory;
mem_used = (m2.MemUsedMATLAB - m1.MemUsedMATLAB) / 1024^2;  % MB
fprintf('Memory used: %.2f MB\n', mem_used);
```

- [ ] Memory usage reasonable (< 500 MB for typical simulation)

## Regression Testing (If Original Version Available)

### Test 8: Numerical Equivalence
```matlab
% Compare results with original version
% Requires saving original as pndriftHCT_forMarcus_original.m

params = pnParamsHCT();
params.Time_properties.tpoints = 100;

% Original version
sol_original = pndriftHCT_forMarcus_original(struct('sol', 0), params);

% Optimized version
sol_optimized = pndriftHCT_forMarcus(struct('sol', 0), params);

% Compare
max_diff = max(abs(sol_original.sol(:) - sol_optimized.sol(:)));
rel_diff = max_diff / max(abs(sol_original.sol(:)));

fprintf('Maximum absolute difference: %.2e\n', max_diff);
fprintf('Maximum relative difference: %.2e\n', rel_diff);

if max_diff < 1e-10
    fprintf('✅ Test 8 PASSED: Results are numerically identical\n');
else
    fprintf('⚠️  Test 8 WARNING: Results differ by %.2e\n', max_diff);
end
```

- [ ] Maximum difference < 1e-10 (machine precision)
- [ ] Results are numerically equivalent

### Test 9: Performance Comparison
```matlab
% Compare execution times
params = pnParamsHCT();
params.Time_properties.tpoints = 200;

% Original
tic;
sol_original = pndriftHCT_forMarcus_original(struct('sol', 0), params);
time_original = toc;

% Optimized
tic;
sol_optimized = pndriftHCT_forMarcus(struct('sol', 0), params);
time_optimized = toc;

speedup = time_original / time_optimized;
improvement = (1 - time_optimized/time_original) * 100;

fprintf('Original time: %.2f s\n', time_original);
fprintf('Optimized time: %.2f s\n', time_optimized);
fprintf('Speedup: %.2fx\n', speedup);
fprintf('Improvement: %.1f%%\n', improvement);

if speedup > 1.05
    fprintf('✅ Test 9 PASSED: Significant speedup achieved\n');
elseif speedup > 1.0
    fprintf('✅ Test 9 PASSED: Modest speedup achieved\n');
else
    fprintf('⚠️  Test 9 WARNING: No speedup detected\n');
end
```

- [ ] Speedup measured: ____x
- [ ] Performance improvement: ____%

## Integration Testing

### Test 10: device_forMarcus Integration
```matlab
% Test with device_forMarcus class
try
    params = pnParamsHCT();
    DV = device_forMarcus.device_forMarcus(params);
    fprintf('✅ Test 10 PASSED: device_forMarcus integration works\n');
catch ME
    fprintf('❌ Test 10 FAILED: %s\n', ME.message);
end
```

- [ ] Works with device_forMarcus class
- [ ] No interface changes required

## Edge Cases

### Test 11: Field-Dependent Features
```matlab
% Test with field-dependent parameters
params = pnParamsHCT();
params.Layers{2}.r0_CT = 3e-9;   % Enable CT field dependence
params.Layers{2}.r0_Ex = 0.5;    % Enable exciton field dependence

try
    sol = pndriftHCT_forMarcus(struct('sol', 0), params);
    fprintf('✅ Test 11 PASSED: Field-dependent features work\n');
catch ME
    fprintf('❌ Test 11 FAILED: %s\n', ME.message);
end
```

- [ ] Field-dependent CT dissociation works
- [ ] Field-dependent exciton dissociation works

### Test 12: Transfer Matrix Optical Model
```matlab
% Test with Transfer Matrix optical model (if available)
params = pnParamsHCT();
params.light_properties.OM = 2;

% Note: This requires Gensprofile_pos and Gensprofile_signal to be defined
% Skip if transfer matrix data not available
```

- [ ] Transfer Matrix optical model works (if applicable)
- [ ] N/A if transfer matrix data not available

## Final Checklist

### Code Quality
- [ ] No warnings during execution
- [ ] Code is readable and well-commented
- [ ] Documentation is comprehensive

### Performance
- [ ] Executes faster than original (or comparable)
- [ ] Memory usage is reasonable
- [ ] Scales well with mesh size

### Correctness
- [ ] All functional tests pass
- [ ] Results are physically valid
- [ ] Backward compatible with existing code

### Documentation
- [ ] Read OPTIMIZATION_SUMMARY.md
- [ ] Read docs/pndriftHCT_forMarcus_optimizations.md
- [ ] Read docs/BEFORE_AFTER_COMPARISON.md

## Summary

Total tests run: _____
Tests passed: _____
Tests failed: _____
Tests skipped: _____

Overall assessment: ________________

## Issues Found

List any issues discovered during testing:

1. 
2. 
3. 

## Recommendations

Based on testing results:

1. 
2. 
3. 

---

**Tester Name**: ________________
**Date**: ________________
**MATLAB Version**: ________________
**Platform**: ________________
