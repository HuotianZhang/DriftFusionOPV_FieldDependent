# Documentation Index: pndriftHCT_forMarcus.m

This directory contains comprehensive documentation for understanding and using the `pndriftHCT_forMarcus.m` function, which solves drift-diffusion equations for organic photovoltaic devices with Marcus theory field-dependent charge transfer.

## Quick Start

**New to this function?** Start here:
1. Read the [Quick Reference Guide](pndriftHCT_forMarcus_quick_reference.md) for syntax and common usage
2. Browse the [Workflow Diagrams](pndriftHCT_forMarcus_workflow.md) for visual understanding
3. Consult the [Complete Explanation](pndriftHCT_forMarcus_explanation.md) for detailed theory

## Documentation Files

### 1. Quick Reference Guide
**File:** `pndriftHCT_forMarcus_quick_reference.md`  
**Purpose:** Fast lookup for developers  
**Contents:**
- Function call syntax (0, 1, or 2 arguments)
- State variable indices and units
- How to access solution data
- Key equation summaries
- Boundary condition types table
- Common parameter modifications
- Typical simulation workflow
- Performance tips and troubleshooting

**Best for:** Experienced users who need a quick reminder

### 2. Workflow Diagrams
**File:** `pndriftHCT_forMarcus_workflow.md`  
**Purpose:** Visual understanding of function flow  
**Contents:**
- Overall function execution flow
- PDE function (pdex4pde) internal logic
- Boundary condition function (pdex4bc) flow
- Initial condition function (pdex4ic) flow
- State variable data flow
- Device layer structure visualization
- Rate constant dependency diagrams
- Marcus theory implementation flowchart
- Solver iteration process

**Best for:** Visual learners and those debugging the code

### 3. Complete Explanation
**File:** `pndriftHCT_forMarcus_explanation.md`  
**Purpose:** Comprehensive reference  
**Contents:**
- Overview and purpose
- Mathematical model (5 coupled PDEs)
  - Drift-diffusion equations for electrons and holes
  - Charge transfer state dynamics
  - Poisson's equation for electric potential
  - Exciton generation and recombination
- Field-dependent rate constants (Marcus theory)
- Function structure and subfunctions
- Detailed parameter descriptions
- Usage examples with code
- Numerical methods
- Differences from standard pndriftHCT.m
- Performance considerations
- Common applications
- Limitations and troubleshooting

**Best for:** Deep understanding, new users, and reference material

## What is pndriftHCT_forMarcus.m?

This MATLAB function simulates charge carrier transport in organic photovoltaic (OPV) devices by solving coupled partial differential equations (PDEs) for:

1. **Electrons (n)** - Free electron density
2. **Holes (p)** - Free hole density  
3. **Charge Transfer States (CT)** - Intermediate bound electron-hole pairs
4. **Electric Potential (V)** - Electrostatic potential distribution
5. **Excitons (Ex)** - Bound electron-hole pairs (singlet or triplet)

The function uses MATLAB's `pdepe` solver with three key subfunctions:
- `pdex4pde`: Defines the PDEs (drift, diffusion, generation, recombination)
- `pdex4ic`: Sets initial conditions
- `pdex4bc`: Enforces boundary conditions

## Key Features

### Marcus Theory Implementation
- **Field-dependent CT dissociation**: Uses `exp(q·E·r₀_CT/kT)` dependence
- **Field-dependent exciton dissociation**: Interpolates from pre-calculated rate tables
- **Enhanced CT-exciton coupling**: Includes Marcus back-transfer rates

### Flexible Device Modeling
- **Multi-layer support**: Model heterojunctions and graded interfaces
- **Multiple boundary conditions**: 5 types (zero current, selective, non-selective, finite SRV, open circuit)
- **Optical models**: Uniform generation, transfer matrix, or Beer-Lambert
- **Time-dependent voltage**: Constant, sweep, sinusoidal, square wave, etc.

### Robust Numerics
- **Adaptive time stepping**: Automatically adjusts based on solution dynamics
- **Spatial mesh refinement**: Finer mesh at interfaces where needed
- **Tolerances control**: Balance accuracy vs. computation time

## Common Use Cases

1. **J-V Characteristics**
   - Sweep voltage from short circuit to open circuit
   - Extract current density from carrier fluxes
   - Calculate fill factor and efficiency

2. **Transient Photovoltage (TPV)**
   - Apply light pulse to device
   - Monitor voltage decay
   - Extract carrier lifetimes

3. **Impedance Spectroscopy**
   - Apply small AC voltage perturbation
   - Extract frequency-dependent impedance
   - Analyze charge transport and recombination

4. **Parameter Optimization**
   - Vary material parameters (mobility, rate constants)
   - Find optimal device design
   - Understand limiting factors

5. **Field Dependence Studies**
   - Investigate effect of electric field on charge separation
   - Validate Marcus theory predictions
   - Compare with experimental measurements

## How to Use This Documentation

### For Quick Tasks
→ Use the [Quick Reference Guide](pndriftHCT_forMarcus_quick_reference.md)
- Need to change voltage? → See "Common Parameter Modifications"
- Want to extract data? → See "Accessing Solution Data"
- Solver not working? → See "Troubleshooting Quick Fixes"

### For Understanding Flow
→ Use the [Workflow Diagrams](pndriftHCT_forMarcus_workflow.md)
- How does the function execute? → See "Overall Function Flow"
- What happens at each time step? → See "PDE Function Internal Flow"
- How are boundaries handled? → See "Boundary Condition Function Flow"
- Where does field dependence come in? → See "Marcus Theory Implementation"

### For Deep Knowledge
→ Use the [Complete Explanation](pndriftHCT_forMarcus_explanation.md)
- Need mathematical details? → See "Mathematical Model"
- What are all the parameters? → See "Key Parameters Structure"
- How does it differ from pndriftHCT.m? → See "Differences from pndriftHCT.m"
- Solver not converging? → See "Troubleshooting" section

## Example Usage Pattern

```matlab
% 1. Read Quick Reference to understand syntax
%    → Know that you can call with 0, 1, or 2 arguments

% 2. Check Workflow Diagram for typical sequence
%    → See that you should start from equilibrium

% 3. Consult Complete Explanation for parameter details
%    → Understand what r0_CT and r0_Ex mean

% 4. Implement your simulation
params = pnParamsHCT();
params.Layers{2}.r0_CT = 3e-9;  % From Complete Explanation
sol_eq = pndriftHCT_forMarcus();  % From Quick Reference

% 5. If issues arise, check Troubleshooting sections
%    → Quick Reference for common fixes
%    → Complete Explanation for detailed diagnostics
```

## Related Functions

- **pnParamsHCT.m** - Generates default parameter structure
- **pndriftHCT.m** - Original version without Marcus theory
- **fun_gen.m** - Creates voltage/generation functions
- **deviceparams.m** - Device parameter class
- **EquilibratePNHCT_forMarcus.m** - Finds equilibrium solution

## Authors and History

- **Original drift-diffusion code**: Piers Barnes, Phil Calado
- **Marcus theory implementation**: Huotian Zhang
- **Based on**: DriftFusion code by Mohammed Azzouzi

## Getting Help

1. **Check the documentation**: Use the index above to find relevant sections
2. **Examine example scripts**: Look at `Example_workflow.m` in the repository root
3. **Review parameter files**: Check `.xlsx` files in `parameters/` directory
4. **Test with simple cases**: Start with uniform generation and constant voltage
5. **Compare with pndriftHCT.m**: See if issue is Marcus-specific or general

## Documentation Statistics

- **Total lines**: ~1042 across all documentation files
- **Main explanation**: 443 lines
- **Quick reference**: 182 lines  
- **Workflow diagrams**: 428 lines
- **Coverage**: Complete function with all subfunctions, parameters, and use cases

## Contributing to Documentation

If you find errors or want to add examples:
1. Check existing documentation to avoid duplication
2. Add examples to the Quick Reference if they're common patterns
3. Add diagrams to the Workflow document if they clarify flow
4. Add detailed explanations to the Complete Explanation
5. Update this README to reference new content

---

**Last Updated:** 2025  
**Function Version:** As of commit including Marcus theory field dependence  
**MATLAB Version:** Tested with R2016 and later (requires pdepe and interpolation functions)
