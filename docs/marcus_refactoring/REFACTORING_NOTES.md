# MarcusTransfer_JV Refactoring

This document explains the refactoring of `MarcusTransfer_JV_0620_334.m` into a more organized workflow.

## Changes Made

### 1. Refactored `functions/kDis_stark.m`
- **Before**: A script that generated `kLECT_stark_vars` in the workspace
- **After**: A function that returns `kLECT_stark_vars` structure
- **Usage**: `kLECT_stark_vars = kDis_stark();`

### 2. Refactored `functions/kBak_stark.m`
- **Before**: A script that generated `kCTLE_stark_vars` in the workspace
- **After**: A function that returns `kCTLE_stark_vars` structure
- **Usage**: `kCTLE_stark_vars = kBak_stark();`

### 3. Created `functions/run_MarcusTransfer_JV.m`
- **Purpose**: Encapsulates the simulation workflow previously in `MarcusTransfer_JV_0620_334.m`
- **Inputs**:
  - `lifetime_ex`: Exciton lifetime in picoseconds (ps)
  - `offset`: Energy offset between excited state and CT state in eV (valid range: 0.00 to 0.45 in steps of 0.05)
- **Outputs**:
  - `JJ`: Current density array (mA/cm²)
  - `VV`: Voltage array (V)
- **Usage**: `[JJ, VV] = run_MarcusTransfer_JV(lifetime_ex, offset);`

### 4. Key Improvements
- **Removed FOR loop**: The function now processes a single offset value instead of looping through multiple values
- **No figure generation**: The function returns data only, allowing the caller to decide how to visualize or save results
- **Proper k_values selection**: The function correctly selects `k_values` and `k_bak_values` based on the input `offset` parameter
- **Better encapsulation**: All parameters are now function arguments or internal to the function
- **Easier to test**: Each component can be tested independently

## How the Offset-to-Column Mapping Works

The original script used a FOR loop with offset calculated as:
```matlab
offset = 0.05*ii - 0.05;  % ii from 1 to 10
```

This created offsets: 0.00, 0.05, 0.10, ..., 0.45

The column index used was `ii+1`, giving columns 2-11 for offsets 0.00-0.45.

The new function reverses this calculation:
```matlab
column_index = round((offset + 0.05)/0.05) + 1;
```

This ensures the same column is selected for a given offset value.

## Example Usage

See `example_run_MarcusTransfer.m` for complete examples:

```matlab
% Add paths
addpath(genpath(pwd));

% Single simulation
lifetime_ex = 10;  % ps
offset = 0.05;     % eV
[JJ, VV] = run_MarcusTransfer_JV(lifetime_ex, offset);

% Plot results
figure;
plot(VV, JJ);
xlabel('Voltage [V]');
ylabel('Current Density [mA/cm^2]');

% Multiple simulations (replacing the original FOR loop)
offsets = 0.00:0.05:0.45;
for i = 1:length(offsets)
    [JJ, VV] = run_MarcusTransfer_JV(10, offsets(i));
    % Process or save results as needed
    % ...
end
```

## Migration from Old Code

**Old approach** (MarcusTransfer_JV_0620_334.m):
```matlab
% Required running kDis_stark.m and kBak_stark.m scripts first
% Then run the main script which looped through offsets
for ii=1:1:num_iterations
    offset = 0.05*ii-0.05;
    % ... simulation code ...
    % Results plotted in figure
end
```

**New approach**:
```matlab
% Everything is encapsulated
[JJ, VV] = run_MarcusTransfer_JV(lifetime_ex, offset);
% You control what to do with the results
```

## Benefits

1. **Modularity**: Each component is now a self-contained function
2. **Reusability**: Functions can be called from any script or function
3. **Testability**: Easier to write unit tests for each component
4. **Flexibility**: Caller decides how to use the data (plot, save, analyze, etc.)
5. **Clarity**: Clear input/output contract for each function
6. **No side effects**: Functions don't modify global workspace or create figures unexpectedly
