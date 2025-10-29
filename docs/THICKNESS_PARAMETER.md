# Thickness Parameter - Developer Documentation

## Overview

This document explains how the thickness parameter is managed in the DriftFusionOPV codebase after resolving the circular dependency issue.

## Problem Resolved

**Previous Issue:** The thickness parameter was defined in two places:
- `Prec.params.tickness` (in meters) in `paramsRec` class
- `DP.Layers{}.tp` (in centimeters) in `deviceparams` class

This created a circular dependency where:
1. Scripts would set `Prec.params.tickness`
2. Call `paramsRec.calcall(Prec)` which used `Prec.params.tickness`
3. Copy the value to `DP.Layers{activelayer}.tp` by multiplying by 100
4. Methods in `deviceparams` would read from `DP.Layers{}.tp`

This was confusing and error-prone as thickness had to be kept synchronized between both locations.

## Solution

**Single Source of Truth:** Thickness is now defined ONLY in `deviceparams.Layers{}.tp` (in centimeters).

### Key Changes

1. **Removed default thickness from paramsRec:**
   - Line 26 in `classes/paramsRec.m` previously set `params.tickness=1e-7`
   - This has been removed with a comment explaining the change

2. **Modified paramsRec methods to accept thickness:**
   - `paramsRec.absorptionSIm(Prec, tickness)` - now requires thickness parameter (in meters)
   - `paramsRec.calcall(Prec, tickness)` - now requires thickness parameter (in meters)

3. **Updated all calling code:**
   - Scripts now define thickness as a local variable
   - Pass thickness to `calcall()` when needed
   - Store thickness in `DP.Layers{activelayer}.tp` (converted to cm)

## Usage Guide

### For Script Writers

When writing a new script that uses both `paramsRec` and `deviceparams`:

```matlab
% Step 1: Define thickness in meters as a local variable
tickness = 100 * 1e-9;  % m - 100 nm thickness

% Step 2: Initialize paramsRec and set other parameters
Prec = paramsRec;
Prec.params.Ex.DG0 = 1.8;
% ... other parameters ...

% Step 3: Calculate all recombination parameters (pass thickness)
Prec = paramsRec.calcall(Prec, tickness);

% Step 4: Initialize deviceparams
DP = deviceparams('parameters/DeviceParameters_Default.xlsx');

% Step 5: Store thickness in deviceparams (convert m to cm)
activelayer = 2;
DP.Layers{activelayer}.tp = tickness * 100;  % [cm] = [m] * 100

% Step 6: Generate device parameters
DP = DP.generateDeviceparams(NC, activelayer, mobility, kdis, kdisex, Prec, ...);
```

### Unit Conventions

**Important:** Be careful with units!

- **In paramsRec methods:** Thickness is in **meters (m)**
  - `paramsRec.calcall(Prec, tickness)` expects meters
  - `paramsRec.absorptionSIm(Prec, tickness)` expects meters

- **In deviceparams:** Thickness is in **centimeters (cm)**
  - `DP.Layers{}.tp` is stored in centimeters
  - Convert: `DP.Layers{activelayer}.tp = tickness * 100`

### Common Patterns

#### Pattern 1: Fixed thickness
```matlab
tickness = 100 * 1e-9;  % 100 nm in meters
Prec = paramsRec.calcall(Prec, tickness);
DP.Layers{activelayer}.tp = tickness * 100;
```

#### Pattern 2: Variable thickness (e.g., thickness sweep)
```matlab
for thickness_nm = [10, 50, 100, 200]
    tickness = thickness_nm * 1e-9;  % Convert nm to m
    Prec = paramsRec.calcall(Prec, tickness);
    DP.Layers{activelayer}.tp = tickness * 100;
    % ... run simulation ...
end
```

#### Pattern 3: Reading thickness from device
```matlab
% If you need thickness for calculations after device creation
tickness_cm = DP.Layers{activelayer}.tp;  % in cm
tickness_m = tickness_cm * 1e-2;  % convert to m
```

## API Reference

### paramsRec.calcall(Prec, tickness)

Calculate all recombination parameters including absorption spectrum.

**Parameters:**
- `Prec` (paramsRec): paramsRec object with all parameters set
- `tickness` (double): Device thickness in meters (m)

**Returns:**
- `Prec` (paramsRec): Updated paramsRec object with calculated results

**Example:**
```matlab
Prec = paramsRec;
tickness = 100 * 1e-9;  % 100 nm
Prec = paramsRec.calcall(Prec, tickness);
```

### paramsRec.absorptionSIm(Prec, tickness)

Calculate absorption spectrum and radiative properties.

**Parameters:**
- `Prec` (paramsRec): paramsRec object with CT and Ex parameters
- `tickness` (double): Device thickness in meters (m)

**Returns:**
- `Prec` (paramsRec): Updated paramsRec object with absorption results

**Note:** This is typically called by `calcall()` and doesn't need to be called directly.

## Migration Guide

If you have existing code that uses `Prec.params.tickness`:

1. **Find all instances:**
   ```bash
   grep -rn "Prec.params.tickness" your_script.m
   ```

2. **Replace with local variable:**
   ```matlab
   # Before:
   Prec.params.tickness = 100 * 1e-9;
   Prec = paramsRec.calcall(Prec);
   
   # After:
   tickness = 100 * 1e-9;
   Prec = paramsRec.calcall(Prec, tickness);
   ```

3. **Update DP.Layers assignment:**
   ```matlab
   # Before:
   DP.Layers{activelayer}.tp = Prec.params.tickness * 100;
   
   # After:
   DP.Layers{activelayer}.tp = tickness * 100;
   ```

## Rationale

### Why this design?

1. **Single Source of Truth:** Thickness is now unambiguously stored in `deviceparams.Layers{}.tp`
2. **No Data Duplication:** Eliminates the need to synchronize thickness between two objects
3. **Clear Data Flow:** 
   - Thickness flows from script → paramsRec methods (as parameter)
   - Thickness stored in deviceparams for device simulation
4. **Explicit Dependencies:** Methods that need thickness must receive it as a parameter
5. **Better Documentation:** The parameter requirement is self-documenting in the function signature

### Design Trade-offs

**Advantages:**
- Eliminates circular dependency
- Clear ownership of thickness parameter
- Easier to track where thickness is used
- Prevents synchronization bugs

**Considerations:**
- Requires updating existing code
- Must pass thickness to `calcall()` explicitly
- Need to be careful with unit conversions (m vs cm)

## Testing

When making changes related to thickness:

1. Verify units are correct (m for paramsRec, cm for deviceparams)
2. Ensure thickness is passed to `calcall()`
3. Check that absorption calculations use the correct thickness
4. Test with different thickness values to ensure consistency

## Examples

See these example files for reference:
- `Example_workflow.m` - Basic workflow
- `MarcusTransfer_JV_0620_334.m` - Marcus transfer simulation
- `scripts/Test_tickness_080422.m` - Thickness sweep example

## Questions or Issues?

If you encounter problems with thickness parameters:
1. Check that you're using the correct units (m vs cm)
2. Verify thickness is passed to `calcall()`
3. Ensure thickness is set in `DP.Layers{activelayer}.tp`
4. Review this documentation and the examples
