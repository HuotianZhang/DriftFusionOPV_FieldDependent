# Quick Reference: New Helper Functions

## Overview
This guide provides a quick reference for the new helper functions created during the code refactoring. These functions replace repeated code patterns throughout the codebase.

## Function Quick Reference

### 📊 Parameter Configuration

#### configure_solver_params(p, AbsTol, RelTol)
```matlab
% Set solver tolerances
p = configure_solver_params(p, 1e-6, 1e-3);
```

#### configure_voltage_sweep(p, Vstart, Vend, tmax)
```matlab
% Setup JV voltage sweep
p = configure_voltage_sweep(p, 0, 1.2, 1e-1);
```

#### configure_pulse_properties(p, pulseon, tmax, pulselen, tstart, pulseint, tpoints)
```matlab
% Setup pulse experiment (TPV/TAS)
p = configure_pulse_properties(p, 1, 5e-5, 2e-6, 1e-6, 200, 1000);
```

#### update_time_and_mesh(p, tmax, tmesh_type, tpoints)
```matlab
% Update time properties and regenerate mesh
p = update_time_and_mesh(p, 1e-3, 2, 1000);

% Or just regenerate with current settings
p = update_time_and_mesh(p);
```

### 🔬 Physics Calculations

#### calc_field_dependent_rate(k0, q, E_field, r0, kB, T)
```matlab
% Calculate field-dependent dissociation rate (Poole-Frenkel)
kdis = calc_field_dependent_rate(params.Layers{kk}.kdis, q, DuDx(4), r0_CT, kB, T);
```

#### calc_generation_rate(x, t, params, layer)
```matlab
% Calculate carrier generation with pulse support
g = calc_generation_rate(x, t, params, params.Layers{kk});
```

### 🎯 Utility Functions

#### find_layer_index(x, params)
```matlab
% Find which layer contains position x
kk = find_layer_index(x, params);
layer_props = params.Layers{kk};
```

## Common Usage Patterns

### Pattern 1: Setting up a JV simulation
```matlab
% Old way (9 lines)
p.solveropt.AbsTol=1e-6;
p.solveropt.RelTol=1e-3;
p.Time_properties.tmax=1e-1;
p.Time_properties.tmesh_type=1;
p.Experiment_prop.V_fun_type = 'sweep';
p.Experiment_prop.V_fun_arg(1) = Vstart;
p.Experiment_prop.V_fun_arg(2) = Vend;
p.Experiment_prop.V_fun_arg(3) = p.Time_properties.tmax;
p=update_time(p);

% New way (3 lines)
p = configure_solver_params(p, 1e-6, 1e-3);
p = configure_voltage_sweep(p, Vstart, Vend, 1e-1);
p = update_time_and_mesh(p, 1e-1, 1, []);
```

### Pattern 2: Setting up a TPV experiment
```matlab
% Old way (7 lines)
p.pulse_properties.pulseon=1;
p.Time_properties.tmax = 5e-5;
p.pulse_properties.pulselen = 2e-6;
p.pulse_properties.tstart=1e-6;
p.pulse_properties.pulseint = 2*Gen;
p.Time_properties.tpoints = 1000;
p=update_time(p);

% New way (2 lines)
p = configure_pulse_properties(p, 1, 5e-5, 2e-6, 1e-6, 2*Gen, 1000);
p = update_time_and_mesh(p);
```

### Pattern 3: PDE calculations with generation and field effects
```matlab
% Inside pdex4pde function

% Find layer (old: 5 lines, new: 1 line)
kk = find_layer_index(x, params);

% Calculate generation (old: 45 lines, new: 1 line)
g = calc_generation_rate(x, t, params, params.Layers{kk});

% Calculate field-dependent rates (old: 2 lines each, new: clearer)
if isfield(params.Layers{kk}, 'r0_CT')
    r0_CT = params.Layers{kk}.r0_CT;
    kdis = calc_field_dependent_rate(params.Layers{kk}.kdis, q, DuDx(4), r0_CT, kB, T);
else
    r0_CT = 0;
    kdis = params.Layers{kk}.kdis;
end
```

## Migration Guide

### If you're updating existing code:

1. **Replace solver setup:**
   ```matlab
   % Replace this pattern:
   p.solveropt.AbsTol=1e-6;
   p.solveropt.RelTol=1e-3;
   
   % With:
   p = configure_solver_params(p, 1e-6, 1e-3);
   ```

2. **Replace time mesh updates:**
   ```matlab
   % Replace this pattern:
   p = update_time(p);
   p = Timemesh(p);
   
   % With:
   p = update_time_and_mesh(p);
   ```

3. **Replace layer finding:**
   ```matlab
   % Replace this pattern:
   for kk=1:1:params.layers_num
       if(x<=params.Layers{kk}.XR && x>=params.Layers{kk}.XL)
           break;
       end
   end
   
   % With:
   kk = find_layer_index(x, params);
   ```

## Benefits Summary

| Aspect | Before | After |
|--------|--------|-------|
| Lines of duplicated code | ~230 | 0 |
| Update locations for common changes | 40+ | 1 per pattern |
| Documentation | Sparse | Comprehensive |
| Code clarity | Moderate | High |
| Maintainability | Challenging | Excellent |

## Need More Details?

See `REFACTORING_REPEATED_PATTERNS.md` for:
- Complete documentation of each function
- Detailed before/after examples
- Usage guidelines
- Testing recommendations

## Questions?

Each helper function has comprehensive documentation in its header. Use MATLAB's `help` command:
```matlab
help configure_solver_params
help calc_generation_rate
help find_layer_index
% etc.
```
