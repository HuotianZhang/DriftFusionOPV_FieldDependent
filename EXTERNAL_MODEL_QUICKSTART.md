# Quick Start Guide for external_model.m

## What is external_model.m?

`external_model.m` is a new function that provides a simple interface to run Marcus transfer J-V (current-voltage) simulations. It replaces simple polynomial fitting equations (like `Y = k02 * X.^2 + k20`) with physics-based Marcus transfer calculations.

## Basic Usage

### Minimal Example

```matlab
% Add all subdirectories to path
addpath(genpath(pwd));

% Define your voltage array
VV = linspace(0, 1.2, 50);  % 50 points from 0 to 1.2 V

% Define parameters
offset = 0.05;       % Energy offset (eV)
lifetime_ex = 10;    % Exciton lifetime (ps)
lambda = 0.5;        % Reorganization energy (eV)
RCT = 1.5;           % Charge transfer distance (nm)

% Run the simulation
JJ = external_model(VV, offset, lifetime_ex, lambda, RCT);

% Plot the results
plot(VV, JJ, 'LineWidth', 2);
xlabel('Voltage [V]');
ylabel('Current Density [mA/cm^2]');
title('J-V Characteristic');
grid on;
```

## Function Signature

```matlab
function JJ = external_model(VV, offset, lifetime_ex, lambda, RCT)
```

### Input Parameters

| Parameter | Type | Description | Example |
|-----------|------|-------------|---------|
| `VV` | vector | Voltage array (V) | `linspace(0, 1.2, 50)` |
| `offset` | scalar | Energy offset (eV) | `0.05` |
| `lifetime_ex` | scalar | Exciton lifetime (ps) | `10` |
| `lambda` | scalar | Reorganization energy (eV) | `0.5` |
| `RCT` | scalar | Charge transfer distance (nm) | `1.5` |

### Output

| Output | Type | Description |
|--------|------|-------------|
| `JJ` | vector | Current density (mA/cm²) corresponding to VV |

## Common Use Cases

### 1. Single J-V Curve

```matlab
VV = linspace(0, 1.2, 50);
JJ = external_model(VV, 0.05, 10, 0.5, 1.5);
plot(VV, JJ);
```

### 2. Comparing Different Offsets

```matlab
VV = linspace(0, 1.2, 50);
offsets = [0.00, 0.05, 0.10, 0.15];

figure;
hold on;
for i = 1:length(offsets)
    JJ = external_model(VV, offsets(i), 10, 0.5, 1.5);
    plot(VV, JJ, 'DisplayName', sprintf('offset = %.2f eV', offsets(i)));
end
legend('Location', 'best');
xlabel('Voltage [V]');
ylabel('Current Density [mA/cm^2]');
title('Effect of Energy Offset on J-V Curve');
grid on;
```

### 3. Comparing Different Lifetimes

```matlab
VV = linspace(0, 1.2, 50);
lifetimes = [5, 10, 15, 20];

figure;
hold on;
for i = 1:length(lifetimes)
    JJ = external_model(VV, 0.05, lifetimes(i), 0.5, 1.5);
    plot(VV, JJ, 'DisplayName', sprintf('\\tau = %d ps', lifetimes(i)));
end
legend('Location', 'best');
xlabel('Voltage [V]');
ylabel('Current Density [mA/cm^2]');
title('Effect of Exciton Lifetime on J-V Curve');
grid on;
```

### 4. Parameter Sweep

```matlab
VV = linspace(0, 1.2, 30);
offsets = [0.00, 0.05, 0.10];
lambdas = [0.3, 0.5, 0.7];

figure;
subplot_idx = 1;
for i = 1:length(lambdas)
    subplot(1, 3, subplot_idx);
    hold on;
    for j = 1:length(offsets)
        JJ = external_model(VV, offsets(j), 10, lambdas(i), 1.5);
        plot(VV, JJ, 'DisplayName', sprintf('offset=%.2f', offsets(j)));
    end
    title(sprintf('\\lambda = %.1f eV', lambdas(i)));
    xlabel('Voltage [V]');
    ylabel('Current Density [mA/cm^2]');
    legend('Location', 'best');
    grid on;
    subplot_idx = subplot_idx + 1;
end
```

## Parameter Guidelines

### Typical Ranges

- **offset**: 0.0 to 0.5 eV (energy difference between excited state and CT state)
- **lifetime_ex**: 1 to 100 ps (typical exciton lifetimes)
- **lambda**: 0.3 to 0.7 eV (typical reorganization energies)
- **RCT**: 0.5 to 3.0 nm (typical charge transfer distances)

### Physical Meaning

- **offset**: Controls the driving force for charge separation
- **lifetime_ex**: Determines how long excitons live before recombination
- **lambda**: Represents the energy penalty for nuclear reorganization
- **RCT**: Distance over which charge transfer occurs

## Advanced Usage

### Using run_MarcusTransfer_JV Directly

If you need both JJ and VV outputs, use `run_MarcusTransfer_JV` directly:

```matlab
VV_input = linspace(0, 1.2, 50);
[JJ, VV_output] = run_MarcusTransfer_JV(VV_input, 0.05, 10, 0.5, 1.5);
```

Or with a scalar voltage (will simulate from 0 to that value):

```matlab
[JJ, VV_output] = run_MarcusTransfer_JV(1.2, 0.05, 10, 0.5, 1.5);
```

## Example Scripts

Two complete example scripts are provided:

1. **`example_external_model.m`**: Demonstrates basic usage of external_model
2. **`example_run_MarcusTransfer.m`**: Shows usage of run_MarcusTransfer_JV

Run them with:
```matlab
run example_external_model
```
or
```matlab
run example_run_MarcusTransfer
```

## Troubleshooting

### Error: "Undefined function or variable 'deviceparams'"

Make sure to add all subdirectories to the path:
```matlab
addpath(genpath(pwd));
```

### Simulation takes too long

The simulation can be slow for some parameter combinations. Consider:
- Reducing the number of voltage points
- Starting with a smaller voltage range
- Using default/typical parameter values first

### Results look unexpected

Check that:
- All parameters are in the correct units (see function documentation)
- The voltage array is reasonable (typically 0 to 1.5 V for organic PV)
- Parameter values are within typical ranges

## More Information

For detailed information about the refactoring and implementation, see:
- `EXTERNAL_MODEL_REFACTORING.md` - Comprehensive documentation
- Function help: `help external_model` or `help run_MarcusTransfer_JV`
