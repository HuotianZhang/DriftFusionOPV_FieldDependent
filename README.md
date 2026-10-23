# DriftFusion for OPV with Field-Dependent Charge Transfer

DriftFusion code developed by Mohammed Azzouzi as part of his PhD Thesis at Imperial College London, with Marcus theory field-dependent charge transfer implementation by Huotian Zhang.

## Quick Start

### Setup

1. Install the Symbolic Math Toolbox
2. Set the MATLAB working directory to the repository root and run `startup.m` to add all folders to the path

> All scripts load files with paths relative to the repository root (`parameters/`, `optical_data/`, ...), so always run them with the repository root as the current folder.

### Basic Tutorial

1. Open `Example_workflow.m`
2. Modify the parameters in the Example_workflow to tune the Prec (Recombination Parameters)
3. Inside the `parameters` folder, make a copy of the default parameters and give it an appropriate name
4. Modify the parameters in your deviceParameter file in the `parameters` folder
5. See `docs/List_of_Parameters.docx` for a description of the parameters

### Marcus Transfer J-V Simulation

```matlab
% Simple interface: J-V curve for a given voltage vector
JJ = external_model(VV, offset, lifetime_ex, lambda, RCT, E_gap, R_s);
```

- `example_external_model.m` – usage of `external_model`
- `example_run_MarcusTransfer.m` – usage of the lower-level `run_MarcusTransfer_JV`

## Repository Structure

```
├── startup.m                     % Adds all folders to the MATLAB path
├── Example_workflow.m            % Basic tutorial
├── example_external_model.m      % external_model example
├── example_run_MarcusTransfer.m  % run_MarcusTransfer_JV example
├── classes/                      % Core classes (deviceparams, paramsRec, device, dfana, dfplot, ...)
├── functions/                    % Solvers and helpers (pndriftHCT_forMarcus, external_model, kDis_stark, ...)
├── scripts/                      % Research / analysis scripts (incl. legacy MarcusTransfer_JV_0620_334.m)
├── parameters/                   % Device parameter files (.xlsx)
├── optical_data/                 % n,k data for the transfer-matrix optical model
├── resourceFiles/                % AM1.5 spectrum
├── results/                      % Saved example outputs (.fig)
├── tests/                        % Smoke tests (run automatically by GitHub Actions)
└── docs/                         % Documentation (see below)
```

## Testing

`tests/smokeTest.m` checks that the device parameters, the transfer-matrix optical data and `external_model` load and run. Run it from MATLAB:

```matlab
results = runtests('tests'); assertSuccess(results)
```

The same tests run on GitHub Actions (`.github/workflows/matlab-tests.yml`) for every pull request and every push to the default branch.

## Documentation

| Topic | Location |
|---|---|
| Parameter list | [`docs/List_of_Parameters.docx`](docs/List_of_Parameters.docx) |
| `external_model.m` interface | [Quick Start](docs/external_model/EXTERNAL_MODEL_QUICKSTART.md) · [Technical notes](docs/external_model/EXTERNAL_MODEL_REFACTORING.md) · [Changes](docs/external_model/CHANGES_SUMMARY.txt) |
| Marcus transfer workflow refactoring | [Overview](docs/marcus_refactoring/README_REFACTORING.md) · [Summary](docs/marcus_refactoring/REFACTORING_SUMMARY.md) · [Notes](docs/marcus_refactoring/REFACTORING_NOTES.md) |
| `pndriftHCT_forMarcus.m` solver | [Index](docs/pndriftHCT_forMarcus/README.md) · [Quick reference](docs/pndriftHCT_forMarcus/pndriftHCT_forMarcus_quick_reference.md) · [Workflow](docs/pndriftHCT_forMarcus/pndriftHCT_forMarcus_workflow.md) · [Explanation](docs/pndriftHCT_forMarcus/pndriftHCT_forMarcus_explanation.md) |
| Solver optimizations & testing | [Summary](docs/pndriftHCT_forMarcus/OPTIMIZATION_SUMMARY.md) · [Details](docs/pndriftHCT_forMarcus/pndriftHCT_forMarcus_optimizations.md) · [Before/after](docs/pndriftHCT_forMarcus/BEFORE_AFTER_COMPARISON.md) · [Testing checklist](docs/pndriftHCT_forMarcus/TESTING_CHECKLIST.md) · [Logical operator bug fix](docs/pndriftHCT_forMarcus/BUGFIX_LOGICAL_OPERATOR.md) |
| Class refactoring analysis (proposals, not yet applied) | [Executive summary](docs/class_refactoring_analysis/ANALYSIS_COMPLETE.md) · [Index](docs/class_refactoring_analysis/DOCUMENTATION_INDEX.md) |

## Citation

If you use this software, please cite it using the metadata in [`CITATION.cff`](CITATION.cff).

## Authors and Contributors

- **Original DriftFusion code:** Mohammed Azzouzi (Imperial College London)
- **Drift-diffusion implementation:** Piers Barnes, Phil Calado
- **Marcus theory implementation:** Huotian Zhang
- **Recent optimizations and refactoring:** GitHub Copilot (2025)
