# DriftFusion for OPV with Field-Dependent Charge Transfer

DriftFusion code developed by Mohammed Azzouzi as part of his PhD Thesis at Imperial College London, with Marcus theory field-dependent charge transfer implementation by Huotian Zhang.

## Quick Start

### Setup

1. Install the symbolic math package
2. Run `startup.m` to add folders to the path

### Basic Tutorial

1. Open `Example_workflow.m`
2. Modify the parameters in the Example_workflow to tune the Prec (Recombination Parameters)
3. Inside the "parameters" folder, make a copy of the default parameters and give it an appropriate name
4. Modify the parameters in your deviceParameter file in the "parameters" folder
5. Adjust the parameters in the .xlsx files:
   - `parameters_def`
   - `PINDevice.xlsx`

## Recent Updates

### 🆕 New Features

#### External Model Interface (Latest)
A simplified interface for running Marcus transfer J-V simulations:
- **[Quick Start Guide](EXTERNAL_MODEL_QUICKSTART.md)** - Get started with `external_model.m`
- **[Technical Documentation](EXTERNAL_MODEL_REFACTORING.md)** - Detailed refactoring notes
- **[Changes Summary](CHANGES_SUMMARY.txt)** - Complete list of modifications

**Key improvements:**
- Simple function interface: `JJ = external_model(VV, offset, lifetime_ex, lambda, RCT)`
- Flexible voltage input (vector or scalar)
- Configurable Marcus theory parameters (lambda, RCT)
- Physics-based replacement for polynomial fitting

#### Marcus Transfer Refactoring
Complete refactoring of the Marcus Transfer J-V simulation workflow:
- **[Refactoring Overview](README_REFACTORING.md)** - Main refactoring documentation
- **[Summary of Changes](REFACTORING_SUMMARY.md)** - Before/after comparison
- **[Technical Notes](REFACTORING_NOTES.md)** - Implementation details

**Key changes:**
- Function-based workflow replacing procedural scripts
- Modular `kDis_stark()` and `kBak_stark()` functions
- Flexible parameter input and data-only output
- Example scripts: `example_run_MarcusTransfer.m`, `example_external_model.m`

### ⚡ Performance Optimizations

#### pndriftHCT_forMarcus.m Optimization
Significant performance improvements to the core drift-diffusion solver:
- **[Optimization Summary](OPTIMIZATION_SUMMARY.md)** - Complete overview
- **[README: Optimization](docs/README_OPTIMIZATION.md)** - Quick reference
- **[Technical Details](docs/pndriftHCT_forMarcus_optimizations.md)** - Detailed optimizations
- **[Before/After Comparison](docs/BEFORE_AFTER_COMPARISON.md)** - Code comparison

**Performance gains:**
- 5-15% speedup from parameter caching
- 26% code reduction (~100 lines of commented code removed)
- Improved readability and maintainability
- 100% backward compatible

### 🐛 Bug Fixes

#### Logical Operator Fix
Fixed critical bug in `pndriftHCT_forMarcus.m`:
- **[Bug Fix Documentation](BUGFIX_LOGICAL_OPERATOR.md)** - Details and solution
- **Issue:** Logical OR operator `||` error with array operands
- **Solution:** Changed to bitwise OR operator `|` on line 223
- **Impact:** Fixes runtime error when using previous solutions as initial conditions

### 📋 Testing

- **[Testing Checklist](TESTING_CHECKLIST.md)** - Comprehensive testing guide for optimizations

## Documentation

### Core Function Documentation
- **[pndriftHCT_forMarcus.m](docs/README.md)** - Complete documentation index
  - [Quick Reference](docs/pndriftHCT_forMarcus_quick_reference.md) - Syntax and common usage
  - [Workflow Diagrams](docs/pndriftHCT_forMarcus_workflow.md) - Visual understanding
  - [Complete Explanation](docs/pndriftHCT_forMarcus_explanation.md) - Detailed theory and implementation

### Quick Navigation

**For New Users:**
1. Start with [External Model Quick Start](EXTERNAL_MODEL_QUICKSTART.md)
2. Review the [Refactoring Overview](README_REFACTORING.md)
3. Check the [pndriftHCT Quick Reference](docs/pndriftHCT_forMarcus_quick_reference.md)

**For Developers:**
1. Review [Refactoring Summary](REFACTORING_SUMMARY.md) for code structure
2. Check [Optimization Details](docs/pndriftHCT_forMarcus_optimizations.md) for performance
3. See [Technical Notes](REFACTORING_NOTES.md) for implementation details

**For Troubleshooting:**
1. Check [Bug Fix Documentation](BUGFIX_LOGICAL_OPERATOR.md)
2. Review [Testing Checklist](TESTING_CHECKLIST.md)
3. Consult function documentation in `docs/` folder

## Authors and Contributors

- **Original DriftFusion code:** Mohammed Azzouzi (Imperial College London)
- **Drift-diffusion implementation:** Piers Barnes, Phil Calado
- **Marcus theory implementation:** Huotian Zhang
- **Recent optimizations and refactoring:** GitHub Copilot (2025)


