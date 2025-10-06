# Workflow Diagram: pndriftHCT_forMarcus.m

## Overall Function Flow

```
┌─────────────────────────────────────────────────────────────┐
│                  pndriftHCT_forMarcus(varargin)             │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
        ┌─────────────────────────────────────────┐
        │   Parse Input Arguments (varargin)      │
        │   - No args: Default parameters         │
        │   - 1 arg: Use previous solution        │
        │   - 2 args: Custom params + prev sol    │
        └─────────────────────────────────────────┘
                              │
                              ▼
        ┌─────────────────────────────────────────┐
        │   Load/Create Parameters                │
        │   - Physical constants (kB, T, q)       │
        │   - Device layers                       │
        │   - Experiment settings (V, BC, light)  │
        │   - Solver options (tolerances)         │
        └─────────────────────────────────────────┘
                              │
                              ▼
        ┌─────────────────────────────────────────┐
        │   Setup Spatial Mesh (xmesh)            │
        │   - From params.Xgrid_properties        │
        │   - Non-uniform allowed                 │
        │   - Refined at interfaces               │
        └─────────────────────────────────────────┘
                              │
                              ▼
        ┌─────────────────────────────────────────┐
        │   Setup Time Mesh (tmesh)               │
        │   - From params.Time_properties         │
        │   - Linear, log, or custom              │
        └─────────────────────────────────────────┘
                              │
                              ▼
        ┌─────────────────────────────────────────┐
        │   Generate Voltage Function             │
        │   Vapp_fun = fun_gen(V_fun_type)        │
        │   - constant, sweep, sin, square, etc.  │
        └─────────────────────────────────────────┘
                              │
                              ▼
        ┌─────────────────────────────────────────────────────┐
        │   Call MATLAB pdepe Solver                          │
        │   sol = pdepe(m, @pdex4pde, @pdex4ic,              │
        │                @pdex4bc, xmesh, tmesh, options)     │
        └─────────────────────────────────────────────────────┘
                              │
                    ┌─────────┴─────────┐
                    ▼                   ▼
        ┌───────────────────┐   ┌──────────────────┐
        │   @ pdex4pde      │   │  @ pdex4ic       │
        │   (Main PDE)      │   │  (Initial Cond)  │
        └───────────────────┘   └──────────────────┘
                    │                   │
                    └─────────┬─────────┘
                              ▼
                    ┌──────────────────┐
                    │  @ pdex4bc       │
                    │  (Boundary Cond) │
                    └──────────────────┘
                              │
                              ▼
        ┌─────────────────────────────────────────┐
        │   Package Results in solstruct          │
        │   - solstruct.sol (time×space×5)        │
        │   - solstruct.x (spatial mesh)          │
        │   - solstruct.t (time mesh)             │
        │   - solstruct.params                    │
        └─────────────────────────────────────────┘
                              │
                              ▼
                    [Return solstruct]
```

## PDE Function (pdex4pde) Internal Flow

```
┌─────────────────────────────────────────────────────────────┐
│              pdex4pde(x, t, u, DuDx)                        │
│  Called at each (x,t) point during time integration        │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
        ┌─────────────────────────────────────────┐
        │   Handle Symmetry (if symm=1)           │
        │   Reflect x about midpoint if needed    │
        └─────────────────────────────────────────┘
                              │
                              ▼
        ┌─────────────────────────────────────────┐
        │   Determine Layer (kk)                  │
        │   Find which layer contains point x     │
        │   Use params.Layers{kk} properties      │
        └─────────────────────────────────────────┘
                              │
                              ▼
        ┌─────────────────────────────────────────┐
        │   Calculate Generation Rate (g)         │
        │   - Uniform: g = Int × Genstrength      │
        │   - Transfer Matrix: interpolate        │
        │   - Add pulse if active                 │
        └─────────────────────────────────────────┘
                              │
                              ▼
        ┌─────────────────────────────────────────┐
        │   Set Time Derivative Coeffs (c)        │
        │   c = [1, 1, 1, 0, 1]                   │
        │   (c=0 for equilibrium)                 │
        └─────────────────────────────────────────┘
                              │
                              ▼
        ┌─────────────────────────────────────────┐
        │   Calculate Electric Field              │
        │   E_field = |DuDx(4)|/1e-2              │
        └─────────────────────────────────────────┘
                              │
                              ▼
        ┌─────────────────────────────────────────┐
        │   Compute Field-Dependent Rates         │
        │   - kdis(E) = kdis₀·exp(q·E·r₀_CT/kT)  │
        │   - kdisexc(E) via Marcus interpolation │
        │   - kforEx(E) via Marcus interpolation  │
        └─────────────────────────────────────────┘
                              │
                              ▼
        ┌─────────────────────────────────────────┐
        │   Build Flux Terms (f)                  │
        │   - Bulk: drift + diffusion             │
        │   - Interface: add band offsets         │
        │   - f(3)=0, f(5)=0 (no CT/Ex transport) │
        └─────────────────────────────────────────┘
                              │
                              ▼
        ┌─────────────────────────────────────────┐
        │   Build Source Terms (s)                │
        │   s(1,2): kdis·CT - kfor·n·p            │
        │   s(3): CT generation/recombination     │
        │   s(4): Poisson (charge density)        │
        │   s(5): Exciton generation/recomb       │
        └─────────────────────────────────────────┘
                              │
                              ▼
                    [Return c, f, s]
```

## Boundary Condition Function (pdex4bc) Flow

```
┌─────────────────────────────────────────────────────────────┐
│            pdex4bc(xl, ul, xr, ur, t)                       │
│  Called at each time step to enforce BCs                   │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
        ┌─────────────────────────────────────────┐
        │   Evaluate Voltage Function             │
        │   Vapp = Vapp_fun(V_fun_arg, t)         │
        └─────────────────────────────────────────┘
                              │
                              ▼
        ┌─────────────────────────────────────────┐
        │   Switch on BC Type                     │
        │   (params.Experiment_prop.BC)           │
        └─────────────────────────────────────────┘
                              │
        ┌─────────────────────┴────────────────────────┐
        │                                               │
        ▼                                               ▼
    BC = 0                                          BC = 1
  Zero Current                                  Selective Contacts
        │                                               │
        ▼                                               ▼
    BC = 2                                          BC = 3
Non-Selective                                Finite SRV + Rseries
        │                                               │
        └─────────────────────┬────────────────────────┘
                              ▼
                          BC = 4
                       Open Circuit
                              │
                              ▼
        ┌─────────────────────────────────────────┐
        │   Calculate Series Resistance (if BC=3) │
        │   J = e·(sp·Δp - sn·Δn)                 │
        │   Vres = -J·Rseries                     │
        └─────────────────────────────────────────┘
                              │
                              ▼
        ┌─────────────────────────────────────────┐
        │   Set pl, ql, pr, qr Arrays             │
        │   Left BC:  pl + ql·flux = 0            │
        │   Right BC: pr + qr·flux = 0            │
        └─────────────────────────────────────────┘
                              │
                              ▼
                  [Return pl, ql, pr, qr]
```

## Initial Condition Function (pdex4ic) Flow

```
┌─────────────────────────────────────────────────────────────┐
│                    pdex4ic(x)                               │
│  Called once per spatial point to set t=0 values           │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
        ┌─────────────────────────────────────────┐
        │   Determine Layer at Position x         │
        │   Find ii where x < Layers{ii}.XR       │
        └─────────────────────────────────────────┘
                              │
                              ▼
        ┌─────────────────────────────────────────┐
        │   Check for Previous Solution           │
        │   (varargin input)                      │
        └─────────────────────────────────────────┘
                              │
        ┌─────────────────────┴────────────────────┐
        │                                           │
        ▼                                           ▼
   No Previous                               Previous Solution
   Solution                                   Exists
        │                                           │
        ▼                                           ▼
  Equilibrium IC                        Interpolate Previous
  u0 = [n₀, p₀, CT₀,                   u0 = interp1(icx,
        x·Vbi/xmax, Ex₀]                           icsol, x)
        │                                           │
        └─────────────────────┬────────────────────┘
                              ▼
                        [Return u0]
```

## Data Flow: State Variables

```
                    Time Integration Loop
                    ═════════════════════
    t=0                                           t=tmax
     ↓                                               ↓
┌────────┐  ┌────────┐  ┌────────┐            ┌────────┐
│ u(t=0) │→ │ u(t=1) │→ │ u(t=2) │→ ... →     │u(t=end)│
└────────┘  └────────┘  └────────┘            └────────┘
     ↓           ↓           ↓                      ↓
  5 vars      5 vars      5 vars               5 vars
  @ each      @ each      @ each               @ each
  x point     x point     x point              x point

At each spatial point x:
┌───────────────────────────────────────────┐
│  u(1) - Electrons        [cm⁻³]           │
│  u(2) - Holes            [cm⁻³]           │
│  u(3) - CT States        [cm⁻³]           │
│  u(4) - Potential        [V]              │
│  u(5) - Excitons         [cm⁻³]           │
└───────────────────────────────────────────┘
```

## Layer Structure

```
Device Geometry (1D):
═══════════════════════════════════════════════════════════

Left Contact        Layer 1         Layer 2         Layer 3        Right Contact
    ║               ┌─────────────────────────────────────────┐          ║
    ║               │                                         │          ║
    ▼               │                                         │          ▼
  x=0          XL₁  ┊  XR₁    XL₂    ┊    XR₂    XL₃  ┊  XR₃       x=xmax
                    │                                         │
    BC              │         Interface regions               │          BC
    ▼               │         (band offsets)                  │          ▼
                    └─────────────────────────────────────────┘

Each layer has:
- XL, XR: Left and right boundaries
- XiL, XiR: Interface region widths
- Material properties: μₑ, μₚ, n₀, p₀, etc.
- Rate constants: kfor, kdis, kdisexc, etc.
```

## Rate Constant Dependencies

```
Field-Independent                    Field-Dependent
═════════════════                    ════════════════

    kfor                                kdis(E)
      ↓                                    ↓
Bimolecular CT          CT Dissociation ← E_field
   Formation                               │
                                           └→ kdisexc(E)
    krec                                      ↓
      ↓                              Exciton Dissociation
  CT Recombination                           ↓
                                         kforEx(E)
    krecexc                                  ↓
      ↓                              CT ← Exciton Transfer
Exciton Recombination

Where: E_field = |∂V/∂x|/1e-2  [V/cm]
```

## Marcus Theory Implementation

```
┌─────────────────────────────────────────────────────────┐
│           Field-Dependent Rate Constants                │
└─────────────────────────────────────────────────────────┘
                         │
           ┌─────────────┴─────────────┐
           │                           │
           ▼                           ▼
    ┌──────────────┐          ┌──────────────┐
    │  CT States   │          │  Excitons    │
    │   (kdis)     │          │  (kdisexc)   │
    └──────────────┘          └──────────────┘
           │                           │
           ▼                           ▼
    kdis = kdis₀·           kdisexc = kdisexc₀·(1-r₀)
      exp(q·E·r₀/kT)           + k_Marcus·r₀
           │                           │
           │                           ▼
           │                   ┌──────────────────┐
           │                   │  Lookup Table    │
           │                   │  Interpolation   │
           │                   │  (E_values,      │
           │                   │   k_values)      │
           │                   └──────────────────┘
           │                           │
           └───────────┬───────────────┘
                       ▼
              Applied in Source Term s
              ═══════════════════════
              s(1,2) = kdis·CT - kfor·n·p
              s(3) = kdisexc·Ex + ... - kdis·CT
              s(5) = g - kdisexc·Ex + kforEx·CT
```

## Solver Iteration (Simplified)

```
For each time step t:
  │
  ├─> For each spatial point x:
  │     │
  │     ├─> Call pdex4pde(x, t, u, DuDx)
  │     │     - Compute c, f, s at (x,t)
  │     │
  │     └─> Return to solver
  │
  ├─> Call pdex4bc for boundaries
  │     - Apply left and right BCs
  │
  ├─> Solve discretized system
  │     - Method of lines
  │     - ODE integration
  │
  ├─> Update u(t+Δt)
  │     - Adaptive time stepping
  │
  └─> Check convergence
        - Compare with tolerances
        - Adjust Δt if needed
```

---

This workflow demonstrates how `pndriftHCT_forMarcus.m` solves the coupled drift-diffusion equations with Marcus theory for field-dependent charge transfer in organic photovoltaic devices.
