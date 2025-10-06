# Explanation: pndriftHCT_forMarcus.m

## Documentation Navigation

- **[Quick Reference Guide](pndriftHCT_forMarcus_quick_reference.md)** - Fast lookup for syntax, equations, and parameters
- **[Workflow Diagrams](pndriftHCT_forMarcus_workflow.md)** - Visual flow charts and data flow diagrams
- **This Document** - Complete detailed explanation

---

## Overview

`pndriftHCT_forMarcus.m` is a MATLAB function that solves coupled drift-diffusion equations for organic photovoltaic (OPV) devices using Marcus theory for charge transfer. It simulates the behavior of charge carriers (electrons, holes), charge transfer states (CT), excitons, and electric potential in semiconductor devices with field-dependent dissociation rates.

## Purpose

This function is designed to:
- Solve time-dependent partial differential equations (PDEs) for charge transport in OPV devices
- Model Marcus electron transfer theory with electric field dependence
- Simulate the dynamics of electrons, holes, charge transfer states, excitons, and electric potential
- Support multi-layer device structures with customizable boundary conditions

## Mathematical Model

### State Variables (u1-u5)

The function solves for 5 coupled state variables across space (x) and time (t):

1. **u(1) - Electrons (n)**: Free electron density [cm⁻³]
2. **u(2) - Holes (p)**: Free hole density [cm⁻³]
3. **u(3) - Charge Transfer States (CT)**: CT state density [cm⁻³]
4. **u(4) - Electric Potential (V)**: Electrostatic potential [V]
5. **u(5) - Excitons (Ex)**: Exciton density [cm⁻³]

### Governing Equations

The function implements the drift-diffusion model using MATLAB's `pdepe` solver, which requires equations in the form:

```
c(x,t,u,∂u/∂x) ∂u/∂t = x^(-m) ∂/∂x[x^m f(x,t,u,∂u/∂x)] + s(x,t,u,∂u/∂x)
```

Where:
- **c**: Capacitance/time derivative coefficient matrix
- **f**: Flux terms (diffusion and drift)
- **s**: Source/sink terms (generation, recombination)
- **m**: Symmetry parameter (0=slab, 1=cylindrical, 2=spherical)

#### 1. Time Derivative Coefficients (c)

```matlab
c = [1    % ∂n/∂t
     1    % ∂p/∂t
     1    % ∂CT/∂t
     0    % ∂V/∂t (elliptic equation, no time derivative)
     1]   % ∂Ex/∂t
```

For equilibrium calculations, all c coefficients are set to 0.

#### 2. Flux Terms (f) - Drift and Diffusion

**Bulk equations:**
```matlab
f(1) = μₑ·n·(-∂V/∂x) + kᵦT·μₑ·∂n/∂x    % Electron flux
f(2) = μₚ·p·(∂V/∂x) + kᵦT·μₚ·∂p/∂x     % Hole flux
f(3) = 0                                 % CT states (no spatial transport)
f(4) = ∂V/∂x                            % Electric field
f(5) = 0                                 % Excitons (no spatial transport)
```

Where:
- μₑ, μₚ = electron and hole mobilities [cm²/V·s]
- kᵦT = thermal energy [eV]
- The drift terms include the electric field (-∂V/∂x for electrons, +∂V/∂x for holes)
- The diffusion terms follow Einstein relation (D = μkᵦT)

**Interface equations:**
At layer interfaces (left and right boundaries of each layer), additional energetic offset terms are included:

```matlab
f(1) = μₑ·n·(-∂V/∂x + DEAL - DN0CL·kᵦT) + kᵦT·μₑ·∂n/∂x    % Left interface
f(2) = μₚ·p·(∂V/∂x - DIPL - DN0VL·kᵦT) + kᵦT·μₚ·∂p/∂x    % Left interface
```

These terms account for band offsets at heterojunctions.

#### 3. Source/Sink Terms (s) - Generation and Recombination

**Electron and Hole rates:**
```matlab
s(1) = kdis·CT - kfor·n·p    % Electron generation/recombination
s(2) = kdis·CT - kfor·n·p    % Hole generation/recombination
```

**Charge Transfer State rate:**
```matlab
s(3) = kdisexc·Ex + kfor·n·p - (kdis·CT + krec·(CT-CT₀)) - kforEx·CT
```
Where:
- kdisexc·Ex: Exciton dissociation to CT
- kfor·n·p: Bimolecular formation of CT from free carriers
- kdis·CT: CT dissociation to free carriers
- krec·(CT-CT₀): CT recombination
- kforEx·CT: CT to exciton back-transfer

**Poisson's Equation:**
```matlab
s(4) = (q/εᵣε₀)·(-n + p - Nₐ + Nᴅ)    % Charge density
```
Where:
- q = elementary charge
- εᵣε₀ = permittivity
- Nₐ, Nᴅ = acceptor and donor doping densities

**Exciton rate:**
```matlab
s(5) = g - kdisexc·Ex - krecexc·(Ex-Ex₀) + kforEx·CT
```
Where:
- g: Photogeneration rate
- kdisexc·Ex: Exciton dissociation
- krecexc·(Ex-Ex₀): Exciton recombination
- kforEx·CT: CT to exciton back-transfer

### Field-Dependent Rate Constants

A key feature of this function is the implementation of Marcus theory for field-dependent charge transfer:

#### CT Dissociation (kdis)
```matlab
kdis = kdis₀ · exp(q·E·r₀_CT/(kᵦT))
```
Where:
- E = |∂V/∂x|/1e-2 is the electric field magnitude [V/cm]
- r₀_CT is the CT pair separation distance [cm]

#### Exciton Dissociation (kdisexc)
```matlab
kdisexc = kdisexc₀·(1 - r₀_Ex) + interpolated_k·r₀_Ex
```
Where interpolated_k is obtained from pre-calculated Marcus rate tables.

#### CT to Exciton Transfer (kforEx)
```matlab
kforEx = kdisexc·exp(-ΔE_LECT/(kᵦT))/RCTE·(1 - r₀_Ex) + interpolated_k_bak·r₀_Ex
```
Where:
- ΔE_LECT = offset between exciton and CT states [eV]
- RCTE = ratio parameter

## Function Structure

### Main Function: `pndriftHCT_forMarcus(varargin)`

#### Input Arguments (varargin)

The function accepts 0, 1, or 2 input arguments:

**Case 1: No arguments**
```matlab
solstruct = pndriftHCT_forMarcus()
```
- Uses default parameters from `pnParamsHCT()`
- Starts with equilibrium initial conditions

**Case 2: One argument (previous solution)**
```matlab
solstruct = pndriftHCT_forMarcus(previous_solstruct)
```
- Uses previous solution as initial condition
- Useful for sequential simulations or parameter sweeps
- Automatically interpolates if mesh sizes differ

**Case 3: Two arguments (previous solution + custom parameters)**
```matlab
solstruct = pndriftHCT_forMarcus(previous_solstruct, custom_params)
```
- Uses custom parameter structure
- Can start from equilibrium (if previous_solstruct.sol == 0) or previous solution

#### Output Structure (solstruct)

```matlab
solstruct.params  % Parameter structure used
solstruct.tspan   % Time mesh
solstruct.x       % Spatial mesh
solstruct.t       % Actual time points solved
solstruct.sol     % Solution array (time × space × variables)
```

The solution array dimensions:
- 1st dimension: time points
- 2nd dimension: spatial points
- 3rd dimension: state variables (1=n, 2=p, 3=CT, 4=V, 5=Ex)

### Subfunctions

#### 1. `pdex4pde(x, t, u, DuDx)` - Main PDE Definition

**Purpose**: Defines the PDEs at each spatial point and time

**Inputs**:
- x: Current spatial position [cm]
- t: Current time [s]
- u: State vector [n, p, CT, V, Ex] at (x,t)
- DuDx: Spatial derivatives [∂n/∂x, ∂p/∂x, ∂CT/∂x, ∂V/∂x, ∂Ex/∂x]

**Outputs**:
- c: Time derivative coefficients
- f: Flux terms
- s: Source/sink terms

**Key operations**:
1. Determines which layer the point x belongs to
2. Calculates generation rate g based on optical model
3. Computes field-dependent rate constants
4. Applies different flux equations at interfaces vs bulk
5. Returns c, f, s arrays for the PDE solver

#### 2. `pdex4ic(x)` - Initial Conditions

**Purpose**: Sets initial values for all state variables at position x

**Returns equilibrium values**:
```matlab
u0 = [n₀, p₀, CT₀, (x/xmax)·Vbi, Ex₀]
```

Or interpolates from previous solution if provided.

#### 3. `pdex4bc(xl, ul, xr, ur, t)` - Boundary Conditions

**Purpose**: Defines boundary conditions at left (xl) and right (xr) boundaries

**Boundary condition form**:
```
p(x,t,u) + q(x,t)·f(x,t,u,∂u/∂x) = 0
```

**Available BC types** (controlled by `params.Experiment_prop.BC`):

**BC = 0: Zero current (Neumann)**
```matlab
Left:  ∂u/∂x = 0, V = 0
Right: ∂u/∂x = 0, V = Vbi - Vapp
```

**BC = 1: Selective contacts**
- Left: n flux = 0, p = p₀, V = 0
- Right: p flux = 0, n = n₀, V = Vbi - Vapp

**BC = 2: Non-selective contacts**
- Both contacts: n = n₀, p = p₀
- Equivalent to infinite surface recombination

**BC = 3: Finite surface recombination + series resistance**
```matlab
J = e·(sp_r·(p-pright) - sn_r·(n-nright))
Vres = -J·Rseries
Left:  flux ∝ sn_l·(n-nleft), sp_l·(p-pleft)
Right: flux ∝ sn_r·(n-nright), sp_r·(p-pright), V = Vbi - Vapp - Vres
```

**BC = 4: Open circuit**
- Fixed carrier densities at both contacts
- Floating potential

## Generation Rate (g)

Three optical models are supported:

### OM = 0: Uniform Generation
```matlab
g = Int × Genstrength
```
Constant throughout device.

### OM = 2: Transfer Matrix
```matlab
g = interp1(position_array, generation_profile, x)
```
Uses pre-calculated optical generation profile from transfer matrix method.

### OM = 1: Beer-Lambert
Not implemented (g = 0).

### Pulse Addition
For transient simulations:
```matlab
if t ∈ [tstart, tstart + pulselen]:
    g = g + pulseint × Genstrength
```

## Spatial Mesh (xmesh)

The spatial mesh is constructed from `params.Xgrid_properties`:
- Non-uniform mesh possible
- Finer mesh at interfaces
- Supports multi-layer structures
- Each layer has left boundary (XL) and right boundary (XR)

## Time Mesh (tmesh)

From `params.Time_properties.tmesh`:
- Can be linear, logarithmic, or custom
- Determined by tmesh_type, tmax, t0, tpoints

## Solver Options

Uses MATLAB's `pdepe` with options from `params.solveropt.options`:
```matlab
AbsTol = 1e-6    % Absolute tolerance
RelTol = 1e-3    % Relative tolerance
m = 0            % Slab geometry
```

## Key Parameters Structure

### Physical Constants (`params.physical_const`)
- kB: Boltzmann constant [eV/K]
- T: Temperature [K]
- q: Elementary charge [e]
- e: Elementary charge [C]
- E_values, k_values: Marcus rate lookup tables

### Layer Properties (`params.Layers{i}`)
- n0, p0: Equilibrium electron/hole densities [cm⁻³]
- CT0, Ex0: Equilibrium CT/exciton densities [cm⁻³]
- mue, mup: Electron/hole mobilities [cm²/V·s]
- kfor: CT formation rate constant [cm³/s]
- kdis: CT dissociation rate constant [s⁻¹]
- kdisexc: Exciton dissociation rate constant [s⁻¹]
- krec: CT recombination rate constant [s⁻¹]
- krecexc: Exciton recombination rate constant [s⁻¹]
- r0_CT: CT separation distance for field dependence [cm]
- r0_Ex: Exciton parameter for field dependence (0-1)
- offset: Energy offset between exciton and CT [eV]
- RCTE: Ratio parameter
- NA, ND: Acceptor/donor doping [cm⁻³]
- epp: Relative permittivity
- XL, XR: Layer boundaries [cm]
- int: Light absorption flag (0 or 1)

### Experiment Properties (`params.Experiment_prop`)
- V_fun_type: Voltage function type ('constant', 'sweep', 'sin', etc.)
- V_fun_arg: Voltage function parameters
- Vbi: Built-in potential [V]
- BC: Boundary condition type (0-4)
- equilibrium: Equilibrium flag (0 or 1)
- symm: Symmetry flag for symmetric devices

## Typical Usage Example

```matlab
% 1. Create parameters
params = pnParamsHCT();

% 2. Modify parameters as needed
params.Experiment_prop.V_fun_arg(1) = 0.5;  % Set voltage to 0.5V
params.Layers{2}.r0_CT = 3e-9;              % Set CT separation to 3nm
params.Layers{2}.r0_Ex = 0.5;               % Enable field-dependent exciton

% 3. Run equilibrium simulation
sol_eq = pndriftHCT_forMarcus();

% 4. Use equilibrium as starting point for voltage sweep
params.Experiment_prop.V_fun_type = 'sweep';
params.Experiment_prop.V_fun_arg = [0, 1.2, 1e-3];  % 0 to 1.2V in 1ms
sol_sweep = pndriftHCT_forMarcus(sol_eq, params);

% 5. Access results
n = sol_sweep.sol(:,:,1);     % Electron density vs time and position
V = sol_sweep.sol(:,:,4);     % Potential vs time and position
```

## Numerical Method

The function uses MATLAB's `pdepe` solver, which:
1. **Spatial discretization**: Method of lines
   - Converts PDEs to ODEs in time
   - Second-order accurate spatial derivatives
   
2. **Time integration**: Implicit ODE solver
   - Adaptive time stepping
   - Built on `ode15s` (stiff ODE solver)
   - Suitable for stiff drift-diffusion equations

3. **Solution approach**:
   - Solves all 5 coupled equations simultaneously
   - Handles mixed parabolic-elliptic systems (Poisson equation is elliptic)
   - Automatically adjusts time steps based on error tolerances

## Differences from pndriftHCT.m

The `_forMarcus` version includes:
1. **Field-dependent rate constants** using Marcus theory
2. **Interpolation from pre-calculated rate tables** (E_values, k_values)
3. **Enhanced CT-exciton coupling** with field effects
4. **Support for r0_CT and r0_Ex parameters** to tune field dependence
5. **Modified source terms** incorporating Marcus electron transfer rates

## Performance Considerations

1. **Mesh refinement**: Finer meshes at interfaces improve accuracy but slow computation
2. **Time steps**: More time points capture dynamics but increase solve time
3. **Tolerances**: Tighter tolerances (smaller AbsTol/RelTol) improve accuracy but slow solving
4. **Layer count**: More layers increase computational cost
5. **Field dependence**: Computing field-dependent rates adds overhead

### Recent Performance Optimizations (2025)

The function has been optimized for better performance while maintaining 100% backward compatibility:

- **Parameter caching**: Frequently accessed struct fields are cached to reduce overhead
- **Layer boundary precomputation**: Layer boundaries are precomputed for faster layer determination
- **Thermal energy precomputation**: `kbT` is calculated once per PDE evaluation instead of multiple times
- **Layer properties caching**: Current layer struct is cached to reduce repeated cell array access
- **Code cleanup**: Removed ~100 lines of commented code for better readability

**Expected improvement**: 5-15% faster execution for typical simulations

See [pndriftHCT_forMarcus_optimizations.md](pndriftHCT_forMarcus_optimizations.md) for detailed optimization documentation.

## Common Applications

1. **J-V curve simulations**: Sweep voltage, extract current from carrier fluxes
2. **Transient photovoltage (TPV)**: Apply light pulse, monitor voltage decay
3. **Impedance spectroscopy**: Apply sinusoidal voltage, extract impedance
4. **Device optimization**: Vary material parameters, find optimal design
5. **Marcus theory validation**: Compare field-dependent rates with experiments

## References

The code builds on drift-diffusion modeling for organic semiconductors:
- Original authors: Piers Barnes, Phil Calado
- Modified by: Huotian Zhang (for Marcus theory implementation)
- Related to DriftFusion code by Mohammed Azzouzi

## Limitations

1. **1D only**: Cannot model lateral device variations
2. **Isothermal**: No temperature gradients
3. **No ion migration**: Fixed ionic charges only
4. **No trapping**: Simple free carrier model
5. **Continuum model**: Not suitable for ultra-thin layers (<5nm)

## Troubleshooting

**Solver fails to converge:**
- Reduce time step or increase tpoints
- Tighten tolerances (reduce AbsTol, RelTol)
- Start from equilibrium solution
- Check boundary conditions are physically reasonable

**Unphysical negative densities:**
- Usually indicates too-coarse mesh or too-large time steps
- Use equilibrium solution as initial condition
- Reduce voltage sweep rate

**Very slow execution:**
- Reduce spatial points (coarsen mesh)
- Reduce time points
- Relax tolerances slightly
- Use previous solution as starting point for similar simulations
