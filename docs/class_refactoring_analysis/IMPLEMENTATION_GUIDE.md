# Implementation Guide for Refactoring
## Step-by-Step Code Changes

This document provides specific, actionable code changes based on the analysis in `REFACTORING_ANALYSIS.md`.

---

## Phase 1: Fix Physical Constants (Priority 1)

### Change 1.1: Add Constant Properties to deviceparams
**File:** `classes/deviceparams.m`
**Action:** Add these constant properties at the top of the class

```matlab
classdef deviceparams 
    properties (Constant)
        % Universal physical constants - SINGLE SOURCE OF TRUTH
        KB = 8.6173324e-5;              % Boltzmann constant [eV K^-1]
        H_PLANCK = 6.62607015e-34;      % Planck constant [J⋅s]
        ELECTRON_CHARGE_C = 1.602176634e-19;  % Elementary charge [C]
        C_LIGHT = 2.99792458e8;         % Speed of light [m/s]
        EPS0_SI = 8.854187817e-12;      % Vacuum permittivity [F/m]
        EPP0 = 552434;                  % e^2 eV^-1 cm^-1 (for compatibility)
    end
    
    properties
        physical_const
        % ... existing properties ...
```

### Change 1.2: Initialize physical_const Using Constants
**File:** `classes/deviceparams.m`
**Location:** Constructor (around line 31)
**Replace:**
```matlab
% OLD:
physical_const.kB = 8.6173324e-5;
physical_const.T = 300;
physical_const.epp0 = 552434;
physical_const.q = 1;
physical_const.e = 1.61917e-19;
```

**With:**
```matlab
% NEW:
physical_const.kB = deviceparams.KB;
physical_const.T = 300;  % Temperature [K] - can be changed per simulation
physical_const.epp0 = deviceparams.EPP0;
physical_const.q = 1;  % in units of e
physical_const.e = deviceparams.ELECTRON_CHARGE_C;
physical_const.h = deviceparams.H_PLANCK;
physical_const.c = deviceparams.C_LIGHT;
physical_const.eps0_SI = deviceparams.EPS0_SI;
% Derived thermal energy
physical_const.kBT = physical_const.kB * physical_const.T;
```

### Change 1.3: Remove Hardcoded epp0 in readlayers
**File:** `classes/deviceparams.m`
**Location:** Line 167 in readlayers method
**Replace:**
```matlab
% OLD:
epp0 = 552434;
```

**With:**
```matlab
% NEW:
epp0 = DP.physical_const.epp0;
```

### Change 1.4: Use kBT Throughout UpdateLayers
**File:** `classes/deviceparams.m`
**Location:** UpdateLayers method (lines 206-289)
**Replace all instances of:**
```matlab
DP.physical_const.kB*DP.physical_const.T
```

**With:**
```matlab
DP.physical_const.kBT
```

**Examples:**
- Line 221: `DP.physical_const.kBT`
- Line 230: `DP.physical_const.kBT`
- Line 231: `DP.physical_const.kBT`
- etc.

---

## Phase 2: Fix paramsRec Constants (Priority 1 continued)

### Change 2.1: Modify paramsRec Constructor
**File:** `classes/paramsRec.m`
**Location:** Constructor (lines 8-58)

**Replace:**
```matlab
% OLD:
function Prec=paramsRec
    const.kb=8.6173324e-5;
    const.me=9.1e-31;
    const.h=6.62e-34;
    const.e=1.6e-19;
    const.T=300;
    const.Edistribution=0.5:0.005:3;
    const.c=300e6;
    const.eps0=4*pi*8.85e-12*6.242e+18;
```

**With:**
```matlab
% NEW:
function Prec=paramsRec(physical_const_in)
    % Accept physical constants from deviceparams
    % If not provided, use defaults for standalone testing
    if nargin < 1
        % Default values for standalone use
        const.kb = 8.6173324e-5;
        const.T = 300;
        const.h = 6.62607015e-34;
        const.e = 1.602176634e-19;
        const.c = 2.99792458e8;
        const.me = 9.1093837015e-31;  % electron mass [kg]
        const.eps0 = 8.854187817e-12 * 1.602176634e-19;  % in eV units
    else
        % Use provided constants from deviceparams
        const.kb = physical_const_in.kB;
        const.T = physical_const_in.T;
        const.h = physical_const_in.h;
        const.e = physical_const_in.e;
        const.c = physical_const_in.c;
        const.me = 9.1093837015e-31;  % not in deviceparams yet
        const.eps0 = physical_const_in.eps0_SI * physical_const_in.e;
    end
    const.Edistribution=0.5:0.005:3;
    % Remove duplicate: const.kb=8.6173324e-5; (was on line 23)
```

### Change 2.2: Remove Hardcoded kb in Methods
**File:** `classes/paramsRec.m`
**Location:** Line 115 in FC_em method

**Replace:**
```matlab
% OLD:
kb=8.6173324e-5;
```

**With:**
```matlab
% NEW:
kb = const.kb;
```

---

## Phase 3: Fix Thickness Property (Priority 2)

### Change 3.1: Remove thickness from paramsRec
**File:** `classes/paramsRec.m`
**Location:** Line 26
**Action:** REMOVE this line:
```matlab
params.tickness=1e-7;  % DELETE THIS LINE
```

### Change 3.2: Update absorptionSIm to Accept Thickness
**File:** `classes/paramsRec.m`
**Location:** absorptionSIm method (line 270)

**Replace:**
```matlab
% OLD:
function Prec=absorptionSIm(Prec)
    % ...
    for E=Einterp
        AbsLJ(int) = 1-exp(-2*Prec.params.tickness*alphaLJ(int));
```

**With:**
```matlab
% NEW:
function Prec=absorptionSIm(Prec, thickness)
    % Accept thickness as parameter
    % Use default if not provided (for backward compatibility)
    if nargin < 2
        thickness = 1e-7;  % default 100 nm
        warning('paramsRec:NoThickness', 'Thickness not provided, using default 1e-7 m');
    end
    % ...
    for E=Einterp
        AbsLJ(int) = 1-exp(-2*thickness*alphaLJ(int));
```

### Change 3.3: Update calcall to Pass Thickness
**File:** `classes/paramsRec.m`
**Location:** calcall method (line 322)

**Replace:**
```matlab
% OLD:
function Prec=calcall(Prec)
    Prec = paramsRec.update(Prec);
    Prec = paramsRec.calcFCWD(Prec);
    Prec = paramsRec.absorptionSIm(Prec);
    Prec = paramsRec.Calcrates(Prec);
end
```

**With:**
```matlab
% NEW:
function Prec=calcall(Prec, thickness)
    % Accept thickness as parameter
    Prec = paramsRec.update(Prec);
    Prec = paramsRec.calcFCWD(Prec);
    Prec = paramsRec.absorptionSIm(Prec, thickness);
    Prec = paramsRec.Calcrates(Prec);
end
```

### Change 3.4: Update generateDeviceparams
**File:** `classes/deviceparams.m`
**Location:** Line 358 in generateDeviceparams

**Replace:**
```matlab
% OLD:
tickness=DP.Layers{activelayer}.tp;
```

**With:**
```matlab
% NEW:
thickness=DP.Layers{activelayer}.tp;  % Use consistent spelling
```

And update all references from `tickness` to `thickness` in this method.

---

## Phase 4: Add Helper Methods (Priority 5)

### Change 4.1: Add kBT Update Method to deviceparams
**File:** `classes/deviceparams.m`
**Location:** After UpdateLayers method

**Add new method:**
```matlab
function DP = updateThermalEnergy(DP)
    % Update thermal energy after temperature change
    % Call this whenever DP.physical_const.T is modified
    DP.physical_const.kBT = DP.physical_const.kB * DP.physical_const.T;
end
```

### Change 4.2: Add Time Properties Helper to device_forMarcus
**File:** `classes/device_forMarcus.m`
**Location:** Add as a new static method

**Add:**
```matlab
methods (Static, Access = private)
    function p = setTimeProperties(p, tmax, tmesh_type, tpoints)
        % Helper to set time properties and update meshes
        % INPUTS:
        %   p - params structure
        %   tmax - maximum time
        %   tmesh_type - mesh type (1 or 2)
        %   tpoints - (optional) number of time points
        
        p.Time_properties.tmax = tmax;
        p.Time_properties.tmesh_type = tmesh_type;
        if nargin >= 4
            p.Time_properties.tpoints = tpoints;
        end
        p = update_time(p);
        p = Timemesh(p);
    end
end
```

### Change 4.3: Use Helper in runsolJsc
**File:** `classes/device_forMarcus.m`
**Location:** runsolJsc method (lines 46-50)

**Replace:**
```matlab
% OLD:
p.light_properties.Int=Gen;
p.Time_properties.tmesh_type = 2;
p.Time_properties.tpoints = 1000;
p=update_time(p);
p=Timemesh(p);
```

**With:**
```matlab
% NEW:
p.light_properties.Int=Gen;
p = device_forMarcus.setTimeProperties(p, p.Time_properties.tmax, 2, 1000);
```

### Change 4.4: Add Density Calculation Helper to deviceparams
**File:** `classes/deviceparams.m`
**Location:** Add as private static method

**Add:**
```matlab
methods (Static, Access = private)
    function density = calculateDensity(N0, energyDiff, kBT)
        % Calculate carrier density using Boltzmann distribution
        % density = N0 * exp(energyDiff / kBT)
        density = N0 * exp(energyDiff / kBT);
    end
end
```

### Change 4.5: Use Density Helper in UpdateLayers
**File:** `classes/deviceparams.m`
**Location:** UpdateLayers method (lines 230-231)

**Replace:**
```matlab
% OLD:
DP.Layers{ii}.n0 = DP.Layers{ii}.N0C*exp((DP.Layers{ii}.PhiC-DP.Layers{ii}.EA)/DP.physical_const.kBT);
DP.Layers{ii}.p0 = DP.Layers{ii}.N0V*exp((DP.Layers{ii}.IP-DP.Layers{ii}.PhiC)/DP.physical_const.kBT);
```

**With:**
```matlab
% NEW:
kBT = DP.physical_const.kBT;
DP.Layers{ii}.n0 = deviceparams.calculateDensity(DP.Layers{ii}.N0C, ...
    DP.Layers{ii}.PhiC - DP.Layers{ii}.EA, kBT);
DP.Layers{ii}.p0 = deviceparams.calculateDensity(DP.Layers{ii}.N0V, ...
    DP.Layers{ii}.IP - DP.Layers{ii}.PhiC, kBT);
```

---

## Phase 5: Add Input Validation (Priority 6)

### Change 5.1: Validate Excel File in deviceparams
**File:** `classes/deviceparams.m`
**Location:** Beginning of constructor (after line 29)

**Add:**
```matlab
% Validate input
if ~isfile(Excelfilename)
    error('deviceparams:FileNotFound', ...
        'Parameter file not found: %s', Excelfilename);
end
```

### Change 5.2: Validate Layer Index in generateDeviceparams
**File:** `classes/deviceparams.m`
**Location:** Beginning of generateDeviceparams (after line 351)

**Add:**
```matlab
% Validate inputs
if activelayer < 1 || activelayer > DP.layers_num
    error('deviceparams:InvalidLayer', ...
        'Active layer %d is out of range [1, %d]', ...
        activelayer, DP.layers_num);
end
if NC <= 0
    error('deviceparams:InvalidNC', ...
        'Number of charge carriers NC must be positive, got %g', NC);
end
```

---

## Phase 6: Fix Workflow (Update User Scripts)

### Change 6.1: Update MarcusTransfer_JV_0620_334.m
**File:** `MarcusTransfer_JV_0620_334.m`

**Replace lines 41-60:**
```matlab
% OLD:
Prec = paramsRec;
result_struct(ii).offset = offset;
Prec.params.tickness = 100 * 1e-9;  % m
% ... more parameter settings ...
Prec.const.T = 300;
Prec = paramsRec.calcall(Prec);
```

**With:**
```matlab
% NEW:
% Create deviceparams first to get physical constants
DP_temp = deviceparams(['parameters\', deviceParameterFile]);
thickness = 100 * 1e-9;  % m - Define thickness once

% Create paramsRec with physical constants from deviceparams
Prec = paramsRec(DP_temp.physical_const);
result_struct(ii).offset = offset;
% Set parameters (no thickness here anymore)
% ... parameter settings ...
Prec = paramsRec.calcall(Prec, thickness);  % Pass thickness
```

**Replace line 83:**
```matlab
% OLD:
DP.Layers{activelayer}.tp = Prec.params.tickness * 100;
```

**With:**
```matlab
% NEW:
DP.Layers{activelayer}.tp = thickness * 100;  % Convert m to cm
```

---

## Testing Strategy

### Test 1: Verify Constants Are Consistent
```matlab
% Create instances
DP = deviceparams('parameters/DeviceParameters_Default.xlsx');
Prec = paramsRec(DP.physical_const);

% Check constants match
assert(Prec.const.kb == DP.physical_const.kB, 'kB mismatch');
assert(Prec.const.T == DP.physical_const.T, 'T mismatch');
assert(Prec.const.h == DP.physical_const.h, 'h mismatch');
disp('Constants test PASSED');
```

### Test 2: Verify kBT Calculation
```matlab
DP = deviceparams('parameters/DeviceParameters_Default.xlsx');
expected = DP.physical_const.kB * DP.physical_const.T;
assert(abs(DP.physical_const.kBT - expected) < 1e-10, 'kBT mismatch');
disp('kBT test PASSED');
```

### Test 3: Verify Thickness Flow
```matlab
thickness = 100e-9;  % m
DP = deviceparams('parameters/DeviceParameters_Default.xlsx');
Prec = paramsRec(DP.physical_const);
DP.Layers{2}.tp = thickness * 100;  % cm
Prec = paramsRec.calcall(Prec, thickness);
% Verify absorption uses correct thickness
assert(isfield(Prec.results, 'AbsLJ'), 'Absorption not calculated');
disp('Thickness flow test PASSED');
```

---

## Migration Checklist

- [ ] Phase 1: Add constant properties to deviceparams
- [ ] Phase 1: Update deviceparams constructor to use constants
- [ ] Phase 1: Remove hardcoded epp0 in readlayers
- [ ] Phase 1: Replace kB*T with kBT throughout UpdateLayers
- [ ] Phase 2: Update paramsRec constructor to accept constants
- [ ] Phase 2: Remove hardcoded constants in paramsRec methods
- [ ] Phase 3: Remove thickness from paramsRec
- [ ] Phase 3: Update absorptionSIm to accept thickness parameter
- [ ] Phase 3: Update calcall to pass thickness
- [ ] Phase 4: Add helper methods to deviceparams
- [ ] Phase 4: Add helper methods to device_forMarcus
- [ ] Phase 4: Use helpers throughout code
- [ ] Phase 5: Add input validation
- [ ] Phase 6: Update workflow scripts
- [ ] Test: Run all validation tests
- [ ] Test: Compare outputs with original code
- [ ] Document: Update README with changes

---

## Rollback Plan

If issues arise, changes can be rolled back phase-by-phase:
1. Each phase is independent
2. Commit after each phase
3. Can revert to any previous phase
4. Keep original code in comments for 1-2 releases

---

## Performance Benchmarks

Before changes:
```matlab
tic; 
% Run simulation
toc
```

After changes:
```matlab
tic;
% Run simulation with optimizations
toc
```

Expected improvement: 5-10% faster due to cached kBT and reduced function calls.
