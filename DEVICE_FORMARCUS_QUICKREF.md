# device_forMarcus Quick Reference Card

## Configurable Time Properties

| Property | Default | Units | Description |
|----------|---------|-------|-------------|
| `tmax_eq` | `1e-2` | s | Equilibrium simulation |
| `tmax_JV_dark` | `1e0` | s | Dark JV sweep |
| `tmax_JV_light` | `1e-1` | s | Light JV sweep |
| `tmax_Voc_1` | `1e-2` | s | Voc equilibration (step 1) |
| `tmax_Voc_2` | `1e-2` | s | Voc equilibration (step 2) |
| `tmax_TPV` | `5e-5` | s | TPV measurement |
| `tmax_TAS` | `10e-9` | s | TAS measurement |
| `tmax_transient` | `1e-2` | s | Current transient |
| `V_pulse_rise` | `1e-4` | s | Voltage pulse rise time |

## Quick Examples

### Default Usage (No Changes Required)
```matlab
DV = device_forMarcus(DP);
```

### Customize Single Property
```matlab
DV = device_forMarcus(DP);
DV.tmax_JV_dark = 2e0;  % 2 seconds
```

### Customize Multiple Properties
```matlab
DV = device_forMarcus(DP);
DV.tmax_JV_dark = 2e0;
DV.tmax_JV_light = 5e-1;
DV.tmax_TPV = 1e-4;
```

### Fast Simulation Preset
```matlab
DV = device_forMarcus(DP);
DV.tmax_eq = 5e-3;
DV.tmax_JV_dark = 5e-1;
DV.tmax_JV_light = 5e-2;
```

### Slow/Accurate Simulation Preset
```matlab
DV = device_forMarcus(DP);
DV.tmax_eq = 5e-2;
DV.tmax_JV_dark = 2e0;
DV.tmax_JV_light = 5e-1;
DV.tmax_Voc_1 = 5e-2;
DV.tmax_Voc_2 = 5e-2;
```

## Time Conversion Reference

| Notation | Value (s) | Description |
|----------|-----------|-------------|
| `1e0` | 1 | 1 second |
| `1e-1` | 0.1 | 100 milliseconds |
| `1e-2` | 0.01 | 10 milliseconds |
| `1e-3` | 0.001 | 1 millisecond |
| `1e-4` | 0.0001 | 100 microseconds |
| `5e-5` | 0.00005 | 50 microseconds |
| `1e-5` | 0.00001 | 10 microseconds |
| `1e-6` | 0.000001 | 1 microsecond |
| `10e-9` | 0.00000001 | 10 nanoseconds |
| `1e-9` | 0.000000001 | 1 nanosecond |

## Which Property Affects Which Method?

| Method | Properties Used |
|--------|----------------|
| `device_forMarcus()` | `tmax_eq` |
| `runsolJV()` (dark) | `tmax_JV_dark` |
| `runsolJV()` (light) | `tmax_JV_light` |
| `runsolVoc()` | `tmax_Voc_1`, `tmax_Voc_2` |
| `runsolTPV()` | `tmax_TPV` |
| `runsolTAS()` | `tmax_TAS` |
| `current_transient()` | `tmax_transient`, `V_pulse_rise` |

## More Information

- **Full Documentation**: See `DEVICE_FORMARCUS_CONFIG.md`
- **Technical Details**: See `REFACTORING_MAGIC_NUMBERS.md`
- **Unit Tests**: Run `test_device_forMarcus_refactoring.m`
