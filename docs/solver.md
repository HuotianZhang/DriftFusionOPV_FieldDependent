# Drift-diffusion solver (`pndriftHCT`)

`functions/pndriftHCT.m` solves the coupled drift-diffusion equations with MATLAB's `pdepe` for a multi-layer device described by a `deviceparams` object. The same solver handles constant, exponential (Braun-type) and Marcus field-dependent LE↔CT rates.

```matlab
sol = pndriftHCT(sol0, DP)
```

- `sol0`: previous solution used as the initial condition, or `struct('sol', 0)` to start from the background densities in `DP`
- `DP`: `deviceparams` object
- `sol`: struct with `params`, `x`, `t` and `sol` (time × position × variable)

In practice the solver is called through the `device` class (below).

## Variables

| | Variable | Unit |
|---|---|---|
| u1 | electron density *n* | cm⁻³ |
| u2 | hole density *p* | cm⁻³ |
| u3 | CT state density | cm⁻³ |
| u4 | electrostatic potential *V* | V |
| u5 | exciton (LE) density | cm⁻³ |

## Equations

`pdepe` form: c ∂u/∂t = ∂f/∂x + s. Positions are in cm, energies in eV, so the field *F* = |∂V/∂x| is in V/cm.

Fluxes (bulk; graded interface regions add the band-offset terms `DEAL`, `DIPL`, `DN0CL`, … from `UpdateLayers`):

```
f1 = μe (−n ∂V/∂x + kT ∂n/∂x)
f2 = μh ( p ∂V/∂x + kT ∂p/∂x)
f3 = 0,  f4 = ∂V/∂x,  f5 = 0
```

Sources:

```
s1 = s2 = kdis·CT − kfor·n·p
s3 = kdisexc·Ex + kfor·n·p − kdis·CT − krec·(CT − CT0) − kforEx·CT
s4 = (q/ε)(−n + p − NA + ND)
s5 = g − kdisexc·Ex − krecexc·(Ex − Ex0) + kforEx·CT
```

`CT0 = ni²·kfor/kdis` and `Ex0 = CT0·kforEx/kdisexc` are the equilibrium densities, so with field-independent rates all net rates vanish in the dark at equilibrium. With field-dependent rates the built-in field leaves a small imbalance; in the reference devices the resulting dark current at equilibrium is below 1e-9 mA/cm² (`tests/simulationTest.m`).

## Field dependence

Per layer, all optional:

| Field | Effect |
|---|---|
| `Layers{k}.r0_CT` | `kdis = kdis0·exp(q·F·r0_CT/kT)`, `r0_CT` in **cm** (1 nm = 1e-7) |
| `Layers{k}.r0_Ex` | `kdisexc = kdisexc0·exp(q·F·r0_Ex/kT)`, `r0_Ex` in **cm** |
| `Layers{k}.marcus` | Marcus LE↔CT rates: struct with `E` (V/m), `k`, `k_bak` (s⁻¹) and `weight` (0…1) |

With `marcus.weight = w`, `kdisexc = (1−w)·kdisexc0 + w·k(F)` and `kforEx = (1−w)·kforEx0 + w·k_bak(F)`. The tables are interpolated linearly; `tests/simulationTest.m` checks that the fields reached in the reference devices stay inside the 0–5×10⁷ V/m table range.

Older code used `r0_Ex = 1` as a switch for the Marcus rates. That value now means 1 cm and the solver stops with an error pointing to `marcus`.

## Marcus rates with Stark shift

`marcus_rate_tables(lambda, RCT, offset, T, RCTE)` returns the tables for `Layers{k}.marcus`. It uses `marcus_stark_table` (wrapped by `kDis_stark` for LE→CT and `kBak_stark` for CT→LE):

```
k(F) = 0.1 · (2π/ħ) |Hab|² (4πλkT)^(−1/2) · exp(−(λ + ΔG + ΔE_CT(F))² / (4λkT))
ΔE_CT(F) = −½ α_CT F|F|,   α_CT = α_TCNQ (RCT / d_TCNQ)⁴
```

with ΔG = −offset and +F for LE→CT, ΔG = +offset and −F for CT→LE, and Hab = 0.01 eV. The back rate is divided by RCTE, so at zero field `k_bak/k = exp(−offset/kT)/RCTE`, the same detailed balance that `generateDeviceparams` uses for `kforEx`. Pass the device temperature as `T`.

`lambda` is the reorganization energy of the LE→CT electron transfer. It is a different quantity from `L0`/`Li` in `paramsRec`, which set the line shapes of the optical LE→ground and CT→ground transitions, so the two are set independently.

## Boundary conditions (`DP.Experiment_prop.BC`)

| BC | Contacts |
|---|---|
| 0 | zero flux for carriers; used for the first equilibrium step |
| 1 | holes fixed at the left contact, electrons at the right |
| 2 | electrons and holes fixed at both contacts (perfect contacts); default |
| 3 | finite surface recombination velocities and series resistance (`External_prop`) |
| 4 | open circuit for the symmetric device used by `runsolVoc` (both contacts take layer 1's densities because the device is mirrored) |

## Workflow

```matlab
startup                                   % adds the code folders to the path
[DP, Prec] = build_MarcusTransfer_device(0.05, 10, 0.5, 1.5, 1.8);   % or set up DP yourself
DV = device(DP);                          % equilibrium (EquilibratePNHCT)
DV = device.runsolJsc(DV, 1);             % 1 sun, short circuit
DV = device.runsolJV(DV, 1, 0, 1.4);      % voltage sweep 0 -> 1.4 V
[Jsc, Voc, FF, JJ, VV] = dfplot.JV_new(DV.sol_JV, 1);
```

`external_model(VV, offset, lifetime_ex, lambda, RCT, E_gap, R_s, ...)` wraps these steps and returns J on the voltage grid `VV`; optional name-value arguments set the device parameters (see `help build_MarcusTransfer_device`).

- `DP.solveropt.verbose = false` silences progress messages and `pdepe` statistics (`external_model` is quiet by default).
- `DP.results.Voc` is the Voc expected when LE, CT and free carriers are in quasi-equilibrium at open circuit, `kT·ln(Jscrad/J0)`. Call `DP = DP.recombinationResults(Prec, activelayer)` after changing `krec` or `krecexc`.
