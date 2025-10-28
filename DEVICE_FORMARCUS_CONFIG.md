# device_forMarcus Configuration Guide

## Overview

The `device_forMarcus` class has been refactored to replace hardcoded simulation time values with configurable class properties. This allows users to easily customize simulation times without modifying the code.

## Configurable Properties

All time properties are in **seconds** unless otherwise noted.

### Properties

| Property | Default Value | Description |
|----------|---------------|-------------|
| `tmax_eq` | `1e-2` | Time for equilibrium simulation |
| `tmax_JV_dark` | `1e0` | Time for dark JV sweep |
| `tmax_JV_light` | `1e-1` | Time for light JV sweep |
| `tmax_Voc_1` | `1e-2` | Time for first Voc equilibration |
| `tmax_Voc_2` | `1e-2` | Time for second Voc equilibration |
| `tmax_TPV` | `5e-5` | Time for TPV (Transient Photo-Voltage) measurement |
| `tmax_TAS` | `10e-9` | Time for TAS (Transient Absorption Spectroscopy) measurement (note: 10e-9 = 1e-8, kept as original) |
| `tmax_transient` | `1e-2` | Time for current transient |
| `V_pulse_rise` | `1e-4` | Voltage pulse rise time |

## Usage Examples

### Basic Usage (Using Default Values)

```matlab
% Create device with default time settings
DP = deviceparams('parameters/DeviceParameters_Default.xlsx');
DV = device_forMarcus(DP);
```

The default values maintain backward compatibility with existing code.

### Customizing Simulation Times

```matlab
% Create device
DP = deviceparams('parameters/DeviceParameters_Default.xlsx');
DV = device_forMarcus(DP);

% Customize simulation times before running simulations
DV.tmax_JV_dark = 2e0;      % Increase dark JV time to 2 seconds
DV.tmax_JV_light = 5e-1;    % Increase light JV time to 0.5 seconds
DV.tmax_TPV = 1e-4;         % Increase TPV measurement time

% Now run simulations with custom times
Gen = 1;
DV = device_forMarcus.runsolJsc(DV, Gen);
DV = device_forMarcus.runsolJV(DV, Gen, 0, 1.2);
```

### Setting Times for Specific Experiments

#### For longer equilibration times:
```matlab
DV.tmax_eq = 5e-2;          % 50 ms instead of default 10 ms
DV.tmax_Voc_1 = 5e-2;
DV.tmax_Voc_2 = 5e-2;
```

#### For faster TPV measurements:
```matlab
DV.tmax_TPV = 1e-5;         % 10 microseconds
```

#### For very fast TAS measurements:
```matlab
DV.tmax_TAS = 1e-9;         % 1 nanosecond
```

## Method-Specific Time Properties

Each simulation method uses specific time properties:

- **`device_forMarcus()`** constructor: Uses `tmax_eq`
- **`runsolJV()`**: Uses `tmax_JV_dark` (when Gen==0) or `tmax_JV_light` (when Gen>0)
- **`runsolVoc()`**: Uses `tmax_Voc_1` and `tmax_Voc_2` sequentially
- **`runsolTPV()`**: Uses `tmax_TPV`
- **`runsolTAS()`**: Uses `tmax_TAS`
- **`current_transient()`**: Uses `tmax_transient` and `V_pulse_rise`

## Benefits of This Refactoring

1. **Maintainability**: All time constants are defined in one place
2. **Flexibility**: Easy to adjust simulation times for different experiments
3. **Documentation**: Clear property names with comments explain each parameter
4. **Backward Compatibility**: Default values maintain existing behavior
5. **Configurability**: Users can customize times without modifying class code

## Migration from Old Code

If you have existing code that relied on the hardcoded values, **no changes are required**. The default values are identical to the previous hardcoded values.

If you previously modified the source code to change time values, you can now do this through properties:

**Before:**
```matlab
% Had to modify device_forMarcus.m source code
% Line 72: p.Time_properties.tmax=1e0;  % Changed to 2e0
```

**After:**
```matlab
% Set property after creating the device
DV.tmax_JV_dark = 2e0;
```

## Notes

- All properties have sensible defaults based on typical simulation requirements
- Times are in seconds and use scientific notation (e.g., `1e-2` = 0.01 seconds = 10 ms)
- The properties can be modified at any time before calling the respective simulation methods
- Changes to properties do not affect simulations that have already been run
