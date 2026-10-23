# DriftFusion for OPV with Field-Dependent Charge Transfer

DriftFusion code developed by Mohammed Azzouzi as part of his PhD Thesis at Imperial College London, with Marcus theory field-dependent charge transfer implementation by Huotian Zhang.

## Quick Start

### Setup

Run `startup.m` (in the repository root) to add the code folders to the MATLAB path. Data files are located relative to the repository root, so the scripts work from any current folder. No toolboxes are needed beyond base MATLAB (`pdepe` is part of it).

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
% Optional device parameters, e.g. for fitting
JJ = external_model(VV, offset, lifetime_ex, lambda, RCT, E_gap, R_s, 'thickness', 120, 'mobility', 1e-3);
```

- `example_external_model.m` – usage of `external_model`
- `example_run_MarcusTransfer.m` – usage of the lower-level `run_MarcusTransfer_JV`

## Repository Structure

```
├── startup.m                     % Adds the code folders to the MATLAB path
├── Example_workflow.m            % Basic tutorial
├── example_external_model.m      % external_model example
├── example_run_MarcusTransfer.m  % run_MarcusTransfer_JV example
├── classes/                      % Core classes (deviceparams, paramsRec, device, dfana, dfplot, ...)
├── functions/                    % Solver and helpers (pndriftHCT, external_model, marcus_rate_tables, ...)
├── scripts/                      % Research / analysis scripts (incl. legacy MarcusTransfer_JV_0620_334.m)
├── parameters/                   % Device parameter files (.xlsx)
├── optical_data/                 % n,k data for the transfer-matrix optical model
├── resourceFiles/                % AM1.5 spectrum
├── tests/                        % Tests (run automatically by GitHub Actions)
└── docs/                         % Documentation (see below)
```

## Testing

- `tests/smokeTest.m`: device parameters, transfer-matrix optical data and `external_model` load and run.
- `tests/physicsTest.m`: detailed balance between the Marcus forward/back rates and the device parameters, the Laguerre recurrence, `recombinationResults`, `generateDeviceparams` on the requested active layer, boundary condition `BC = 1`, and the series-resistance interpolation in `external_model`.
- `tests/simulationTest.m`: J-V simulations of four Marcus devices and the `Example_workflow` device, checked against recorded Jsc/Voc/FF and for physical consistency (radiative limits, ideal-diode FF limit, zero dark current at equilibrium, quasi-equilibrium Voc, trends with offset, exciton lifetime and field dependence).

Run them from MATLAB:

```matlab
results = runtests('tests'); assertSuccess(results)
```

The same tests run on GitHub Actions (`.github/workflows/matlab-tests.yml`) for pull requests and pushes to the default branch that change `.m` files, `parameters/`, `optical_data/` or `resourceFiles/`; they can also be started manually from the Actions tab.

## Documentation

| Topic | Location |
|---|---|
| Parameter list | [`docs/List_of_Parameters.docx`](docs/List_of_Parameters.docx) |
| `external_model.m` interface | [Quick Start](docs/external_model/EXTERNAL_MODEL_QUICKSTART.md) |
| Drift-diffusion solver, field-dependent and Marcus rates, workflow | [`docs/solver.md`](docs/solver.md) |

## Citation

If you use this software, please cite it using the metadata in [`CITATION.cff`](CITATION.cff).

## Authors and Contributors

- **Original DriftFusion code:** Mohammed Azzouzi (Imperial College London)
- **Drift-diffusion implementation:** Piers Barnes, Phil Calado
- **Marcus theory implementation:** Huotian Zhang
- **Recent optimizations and refactoring:** GitHub Copilot (2025)
