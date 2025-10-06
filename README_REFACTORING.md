# Refactored Marcus Transfer J-V Simulation

This directory contains the refactored version of the Marcus Transfer J-V simulation workflow, originally implemented in `MarcusTransfer_JV_0620_334.m`.

## Quick Start

```matlab
% Add all subdirectories to the MATLAB path
addpath(genpath(pwd));

% Run a single simulation
lifetime_ex = 10;  % Exciton lifetime in picoseconds
offset = 0.05;     % Energy offset in eV
[JJ, VV] = run_MarcusTransfer_JV(lifetime_ex, offset);

% Plot the results
figure;
plot(VV, JJ, 'LineWidth', 2);
xlabel('Voltage [V]');
ylabel('Current Density [mA/cm^2]');
title('J-V Characteristic');
grid on;
```

## What's New?

The refactoring addresses all requirements from the problem statement:

1. ✅ **Removed FOR loop**: Instead of a hardcoded loop, users now call the function with specific parameters
2. ✅ **Function-based workflow**: The main workflow is now `run_MarcusTransfer_JV(lifetime_ex, offset)`
3. ✅ **Refactored helper functions**: `kDis_stark()` and `kBak_stark()` are now proper functions
4. ✅ **Correct parameter selection**: Automatic selection of `k_values` and `k_bak_values` based on offset
5. ✅ **Data-only output**: Returns only J-V data (JJ, VV); no automatic figure generation

## Files

- **`functions/run_MarcusTransfer_JV.m`**: Main simulation function
- **`functions/kDis_stark.m`**: Calculates field-dependent dissociation rates
- **`functions/kBak_stark.m`**: Calculates field-dependent back transfer rates
- **`example_run_MarcusTransfer.m`**: Example usage with multiple scenarios
- **`REFACTORING_SUMMARY.md`**: Detailed before/after comparison
- **`REFACTORING_NOTES.md`**: Technical documentation

## Usage Examples

### Single Simulation
```matlab
[JJ, VV] = run_MarcusTransfer_JV(10, 0.05);
```

### Multiple Offsets (replacing the original FOR loop)
```matlab
offsets = 0.00:0.05:0.45;
results = cell(length(offsets), 1);

for i = 1:length(offsets)
    [JJ, VV] = run_MarcusTransfer_JV(10, offsets(i));
    results{i} = struct('JJ', JJ, 'VV', VV, 'offset', offsets(i));
    
    % Optional: save or plot individual results
    % plot(VV, JJ, 'DisplayName', sprintf('offset=%.2f', offsets(i)));
end
```

### Parameter Sweep
```matlab
lifetimes = [5, 10, 15, 20];
offsets = [0.00, 0.10, 0.20, 0.30];

for lt = lifetimes
    for off = offsets
        [JJ, VV] = run_MarcusTransfer_JV(lt, off);
        % Process results...
    end
end
```

## Function Signature

```matlab
function [JJ, VV] = run_MarcusTransfer_JV(lifetime_ex, offset)
```

**Inputs:**
- `lifetime_ex`: Exciton lifetime in picoseconds (e.g., 10)
- `offset`: Energy offset in eV, valid range 0.00-0.45 in steps of 0.05

**Outputs:**
- `JJ`: Current density array (mA/cm²)
- `VV`: Voltage array (V)

## Validation

To verify the refactoring produces equivalent results:

```matlab
% Run with same parameters as original script
lifetime_ex = 10;
offset = 0.05;
[JJ_new, VV_new] = run_MarcusTransfer_JV(lifetime_ex, offset);

% Compare with original results if available
% (Original script would have generated figures and saved results)
```

## Documentation

- See `REFACTORING_SUMMARY.md` for a detailed comparison of old vs. new workflows
- See `REFACTORING_NOTES.md` for technical implementation details
- See `example_run_MarcusTransfer.m` for working code examples

## Original Workflow (Preserved)

The original script `MarcusTransfer_JV_0620_334.m` is still available in the repository for reference and backward compatibility.

## Questions or Issues?

Refer to the documentation files or examine the well-commented source code in `functions/run_MarcusTransfer_JV.m`.
