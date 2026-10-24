# DriftFusion for OPV with Field-Dependent Charge Transfer

DriftFusion code developed by Mohammed Azzouzi as part of his PhD Thesis at Imperial College London, with Marcus theory field-dependent charge transfer implementation by Huotian Zhang.

## Quick Start

### Setup

Run `startup.m` (in the repository root) to add the code folders to the MATLAB path. Data files are located relative to the repository root, so the scripts work from any current folder. No toolboxes are needed beyond base MATLAB (`pdepe` is part of it).

### First steps

Start with the guided examples in [`examples/`](examples/README.md). Each one runs on its own and explains what it does:

| Script | Topic |
|---|---|
| `ex01_first_jv_curve.m` | Your first J-V curve; Jsc, Voc, FF and PCE |
| `ex02_parameter_sweep.m` | Effect of material and device parameters |
| `ex03_stark_effect.m` | Field-dependent LE↔CT transfer and the Stark controls |
| `ex04_device_simulation.m` | Step-by-step device simulation, internal profiles |
| `ex05_recombination_and_spectra.m` | LE/CT states from optical parameters, PL/EL spectra, custom parameter files |
| `ex06_fit_measured_jv.m` | Fitting a measured J-V curve |

The one-line interface used in most of them:

```matlab
startup                                                   % add the code folders to the path
V  = linspace(0, 1.4, 141);                               % V
J  = external_model(V, 0.2, 10, 0.5, 1.5, 1.8, 0);         % offset, lifetime_ex, lambda, RCT, E_gap, R_s -> J (mA/cm^2)
pv = jv_parameters(V, J)                                  % Jsc, Voc, FF, PCE
J  = external_model(V, 0.2, 10, 0.5, 1.5, 1.8, 0, 'mobility', 1e-3, 'thickness', 120);   % optional device parameters
```

To simulate your own device stack, copy `parameters/DeviceParameters_Default.xlsx`, edit the copy (see `docs/List_of_Parameters.docx`) and load it as in example 5.

## Repository Structure

```
├── startup.m                     % Adds the code folders to the MATLAB path
├── examples/                     % Guided examples for first-time users
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
- `tests/physicsTest.m`: detailed balance between the Marcus forward/back rates and the device parameters, the orientation-averaged Stark shift against numerical integration, the Laguerre recurrence, `recombinationResults`, `generateDeviceparams` on the requested active layer, boundary condition `BC = 1`, and the series-resistance interpolation in `external_model`.
- `tests/examplesTest.m`: runs every script in `examples/`.
- `tests/simulationTest.m`: J-V simulations of six Marcus devices (including each Stark term on its own) and the device of example 5, checked against recorded Jsc/Voc/FF and for physical consistency (radiative limits, ideal-diode FF limit, zero dark current at equilibrium, quasi-equilibrium Voc, trends with offset, exciton lifetime, field dependence and the quadratic Stark shift).

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
