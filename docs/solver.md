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

`marcus_rate_tables(lambda, RCT, offset, T, RCTE, delta_alpha)` returns the tables for `Layers{k}.marcus`. It uses `marcus_stark_table` (wrapped by `kDis_stark` for LE→CT and `kBak_stark` for CT→LE), which evaluates `marcus_equation_stark` on fields 0–5×10⁷ V/m:

```
k(F) = 0.1 · (2π/ħ) |Hab|² (4πλkT)^(−1/2) · ⟨exp(−(λ + ΔG + σ·ΔE_CT(F, θ))² / (4λkT))⟩_θ
```

with ΔG = −offset and σ = +1 for LE→CT, ΔG = +offset and σ = −1 for CT→LE, and Hab = 0.01 eV. The back rate is divided by RCTE, so at zero field `k_bak/k = exp(−offset/kT)/RCTE`, the same detailed balance that `generateDeviceparams` uses for `kforEx`. Pass the device temperature as `T`.

### Stark shift of the CT state

In a field of magnitude F, a CT state whose dipole makes an angle θ with the field is shifted by

```
ΔE_CT(F, θ) = −|Δμ| F cos θ − ½ Δα F²,     |Δμ| = e·RCT
```

relative to the LE state, which is taken as unshifted. The two terms are the linear and quadratic Stark effects; |Δμ| and Δα are the change in dipole moment and in polarizability on going from LE to CT, the Liptay parameters measured by electroabsorption. The rate is averaged over isotropic orientations (cos θ uniform in [−1, 1]), which has a closed form in terms of error functions. Each orientation obeys detailed balance and both terms vanish at F = 0, so the zero-field rates and the equilibrium densities do not depend on the Stark parameters.

| Control | Quantity | Units | Default | Off |
|---|---|---|---|---|
| `RCT` (positional) | electron–hole separation of the CT state; CT dipole \|Δμ\| = e·RCT (1 nm ≙ 48.0 D) | nm | — | `0` |
| `'delta_alpha'` (name-value) | polarizability volume change LE → CT, Δα | Å³ | 8.5×10⁵ | `0` |
| `marcus.weight` | mixes the field-dependent rates with the zero-field ones | — | 1 | `0` |

- To use a dipole measured by electroabsorption, pass `RCT = |Δμ| / 48.0 D` (in nm).
- For an isotropic film the linear term averages out to first order. It raises the rates only through ⟨(|Δμ|F cos θ)²⟩ = (|Δμ|F)²/3, about 1 % at 10⁷ V/m for RCT = 1.5 nm, λ = 0.5 eV and offset 0.05 eV. The quadratic term shifts the CT level of every orientation. At the default Δα it lowers the CT level by 30 meV at 10⁷ V/m and raises the LE→CT rate by 64 % there.
- The default Δα keeps the quadratic shift of the earlier model, which took the polarizability of TCNQ (85 Å³ for a 1.5 Å dipole length) scaled by (RCT / 1.5 Å)⁴, at RCT = 1.5 nm. With RCT = 0 the model reduces to that earlier one for a 1.5 nm CT state. Set Δα from electroabsorption data where available.
- Setting both `RCT = 0` and `'delta_alpha', 0` gives field-independent LE↔CT rates, equivalent to `marcus.weight = 0`.

To change the Stark parameters of an existing device, rebuild the tables:

```matlab
[E, k, kb] = marcus_rate_tables(lambda, RCT, offset, Prec.const.T, Prec.params.RCTE, delta_alpha);
DP.Layers{2}.marcus = struct('E', E, 'k', k, 'k_bak', kb, 'weight', 1);
```

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

Runnable versions of this and the other routes are in [`examples/`](../examples/README.md).

`external_model(VV, offset, lifetime_ex, lambda, RCT, E_gap, R_s, ...)` wraps these steps and returns J on the voltage grid `VV`; optional name-value arguments set the device parameters (see `help build_MarcusTransfer_device`).

- `DP.solveropt.verbose = false` silences progress messages and `pdepe` statistics (`external_model` is quiet by default).
- `DP.results.Voc` is the Voc expected when LE, CT and free carriers are in quasi-equilibrium at open circuit, `kT·ln(Jscrad/J0)`. Call `DP = DP.recombinationResults(Prec, activelayer)` after changing `krec` or `krecexc`.
