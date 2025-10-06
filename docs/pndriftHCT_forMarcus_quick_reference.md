# Quick Reference Guide: pndriftHCT_forMarcus.m

## Function Call Syntax

```matlab
% Case 1: Default parameters
solstruct = pndriftHCT_forMarcus()

% Case 2: Continue from previous solution
solstruct = pndriftHCT_forMarcus(previous_solstruct)

% Case 3: Custom parameters with previous solution
solstruct = pndriftHCT_forMarcus(previous_solstruct, custom_params)
```

## State Variables (Indices)

| Index | Variable | Description | Units |
|-------|----------|-------------|-------|
| 1 | n | Electron density | cm⁻³ |
| 2 | p | Hole density | cm⁻³ |
| 3 | CT | Charge transfer state density | cm⁻³ |
| 4 | V | Electric potential | V |
| 5 | Ex | Exciton density | cm⁻³ |

## Accessing Solution Data

```matlab
% Run simulation
sol = pndriftHCT_forMarcus();

% Extract variables
n_data = sol.sol(:,:,1);   % Electrons (time × space)
p_data = sol.sol(:,:,2);   % Holes (time × space)
CT_data = sol.sol(:,:,3);  % CT states (time × space)
V_data = sol.sol(:,:,4);   % Potential (time × space)
Ex_data = sol.sol(:,:,5);  % Excitons (time × space)

% Get meshes
x_mesh = sol.x;            % Spatial points [cm]
t_mesh = sol.t;            % Time points [s]

% Example: Plot final electron density profile
plot(sol.x, sol.sol(end,:,1))
xlabel('Position (cm)')
ylabel('Electron density (cm^{-3})')
```

## Key Equations Summary

### 1. Drift-Diffusion (Electrons & Holes)
```
∂n/∂t = ∂/∂x[μₑ·n·(-∂V/∂x) + kᵦT·μₑ·∂n/∂x] + kdis·CT - kfor·n·p
∂p/∂t = ∂/∂x[μₚ·p·(∂V/∂x) + kᵦT·μₚ·∂p/∂x] + kdis·CT - kfor·n·p
```

### 2. Charge Transfer States
```
∂CT/∂t = kdisexc·Ex + kfor·n·p - (kdis·CT + krec·(CT-CT₀)) - kforEx·CT
```

### 3. Poisson's Equation
```
∂²V/∂x² = -(q/εᵣε₀)·(n - p + Nₐ - Nᴅ)
```

### 4. Excitons
```
∂Ex/∂t = g - kdisexc·Ex - krecexc·(Ex-Ex₀) + kforEx·CT
```

### 5. Field-Dependent Rates
```
kdis = kdis₀ · exp(q·E·r₀_CT/(kᵦT))
kdisexc = kdisexc₀·(1-r₀_Ex) + k_Marcus·r₀_Ex
```

## Boundary Condition Types

| BC | Type | Description |
|----|------|-------------|
| 0 | Zero current | Neumann BC: ∂u/∂x = 0 |
| 1 | Selective | One carrier type fixed at each contact |
| 2 | Non-selective | Both carriers fixed (infinite SRV) |
| 3 | Finite SRV + Rs | Realistic contacts with series resistance |
| 4 | Open circuit | Floating potential |

## Common Parameter Modifications

### Set Voltage
```matlab
params.Experiment_prop.V_fun_type = 'constant';
params.Experiment_prop.V_fun_arg(1) = 0.8;  % 0.8V
```

### Enable Field Dependence
```matlab
params.Layers{2}.r0_CT = 3e-9;  % 3 nm CT separation
params.Layers{2}.r0_Ex = 0.5;   % 50% field-dependent exciton
```

### Change Light Intensity
```matlab
params.light_properties.Int = 1;  % 1 sun
params.light_properties.Genstrength = 2.5e21;  % cm⁻³/s
```

### Voltage Sweep
```matlab
params.Experiment_prop.V_fun_type = 'sweep';
params.Experiment_prop.V_fun_arg = [V_start, V_end, sweep_time];
```

### Add Light Pulse
```matlab
params.pulse_properties.pulseon = 1;
params.pulse_properties.pulselen = 2e-10;  % 200 ps
params.pulse_properties.tstart = 1e-10;    % Start at 100 ps
params.pulse_properties.pulseint = 5;      % Intensity
```

## Typical Simulation Workflow

```matlab
% 1. Setup
params = pnParamsHCT();

% 2. Modify device parameters
params.Layers{2}.r0_CT = 3e-9;
params.Layers{2}.mue = 1e-3;  % Mobility
params.Layers{2}.mup = 1e-3;

% 3. Equilibrium (dark, 0V)
params.Experiment_prop.V_fun_arg(1) = 0;
params.light_properties.Int = 0;
sol_eq = pndriftHCT_forMarcus(struct('sol', 0), params);

% 4. Short circuit under illumination
params.light_properties.Int = 1;  % 1 sun
sol_sc = pndriftHCT_forMarcus(sol_eq, params);

% 5. Sweep to find Voc
params.Experiment_prop.V_fun_type = 'sweep';
params.Experiment_prop.V_fun_arg = [0, 1.2, 1e-3];
sol_jv = pndriftHCT_forMarcus(sol_sc, params);

% 6. Calculate current density
% (Extract from carrier fluxes at boundaries)
```

## Optical Models

| OM | Name | Description |
|----|------|-------------|
| 0 | Uniform | Constant generation throughout device |
| 1 | Beer-Lambert | Not implemented (returns g=0) |
| 2 | Transfer Matrix | Position-dependent from optical simulation |

## Physical Constants

```matlab
kB = 8.6173324e-5;    % eV/K
T = 300;              % K
q = 1;                % e (elementary charge)
e = 1.61917e-19;      % C
```

## File Outputs

```matlab
solstruct.params      % Parameters used
solstruct.tspan       % Time mesh requested
solstruct.x           % Spatial mesh [cm]
solstruct.t           % Time points actually solved
solstruct.sol         % Solution array [time × space × variables]
```

## Performance Tips

✓ **Start from equilibrium** - Always use equilibrium solution as IC  
✓ **Sequential solving** - Chain solutions for parameter sweeps  
✓ **Coarse to fine** - Start with coarse mesh, refine if needed  
✓ **Reasonable tolerances** - AbsTol=1e-6, RelTol=1e-3 usually sufficient  
✗ **Avoid large jumps** - Don't jump from 0V to 1V instantly  
✗ **Don't over-resolve** - More points ≠ better results past certain threshold  

## Troubleshooting Quick Fixes

| Problem | Solution |
|---------|----------|
| Negative densities | Refine mesh, start from equilibrium |
| Slow convergence | Relax tolerances, reduce time points |
| Solver crash | Check BC compatibility, start from previous solution |
| Unphysical results | Check parameter units, verify mesh quality |

## Marcus Theory Features

This `_forMarcus` version adds:
- Field-dependent CT dissociation via `r0_CT` parameter
- Field-dependent exciton dissociation via `r0_Ex` parameter  
- Pre-calculated rate tables (`E_values`, `k_values`)
- Enhanced CT-exciton coupling with Marcus back-transfer

## Related Files

- `pnParamsHCT.m` - Default parameter generation
- `pndriftHCT.m` - Original version without Marcus theory
- `fun_gen.m` - Voltage function generator
- `deviceparams.m` - Device parameter class

---

For complete details, see [pndriftHCT_forMarcus_explanation.md](pndriftHCT_forMarcus_explanation.md)
