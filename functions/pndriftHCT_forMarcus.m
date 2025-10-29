function solstruct = pndriftHCT_forMarcus(varargin)
% PNDRIFTHCT_FORMARCUS Solves drift-diffusion equations for OPV devices with Marcus theory
%
% This version defines 
% u1    electrons
% u2    holes
% u3    charge transfer states
% u4    electric potential
% u5    exciton
%
% Piers Barnes last modified (09/01/2016)
% Phil Calado last modified (07/07/2016)
% Huotian Zhang last modified (09/10/2023)
% Huotian Zhang last modified (04/11/2024)
% Huotian Zhang last modified (23/07/2025)
%
% OPTIMIZED VERSION: Improved performance through caching and code cleanup

if isempty(varargin)
    params = pnParamsHCT;                         % Calls Function EParams and stores in sturcture 'params'
    xmesh = params.Xgrid_properties;
    
elseif length(varargin) == 1
    % Call input parameters function
    icsol = varargin{1, 1}.sol;
    xmesh = varargin{1, 1}.x;
    params = pnParamsHCT;                         % Calls Function EParams and stores in sturcture 'params'
elseif length(varargin) == 2
    if varargin{1, 1}.sol == 0                      %varargin{1} is DV.sol_eq  
        params = varargin{2};                       %varargin{2} is DV.sol_eq.params
        xmesh = params.Xgrid_properties;
    else
        icsol = varargin{1, 1}.sol;                 %initial condition calculated from 'deviceparams' - '
        xmesh = varargin{1, 1}.x;
        params = varargin{2};                       
    end
    
end

icx = xmesh;
xmax = max(xmesh);

% Voltage function
Vapp_fun = fun_gen(params.Experiment_prop.V_fun_type);

% Precompute constants and layer boundaries for optimization
% This avoids repeated field access in the nested pdex4pde function
layers_num = params.layers_num;
physical_const = params.physical_const;
experiment_prop = params.Experiment_prop;
light_prop = params.light_properties;
pulse_prop = params.pulse_properties;

% Precompute layer boundaries for faster layer determination
layer_XL = zeros(1, layers_num);
layer_XR = zeros(1, layers_num);
for kk = 1:layers_num
    layer_XL(kk) = params.Layers{kk}.XL;
    layer_XR(kk) = params.Layers{kk}.XR;
end

% Call pdepe solver
sol = pdepe(params.solveropt.m, @pdex4pde, @pdex4ic, @pdex4bc, ...
            xmesh, params.Time_properties.tmesh, params.solveropt.options);

% Package results
SizesSol = size(sol);
solstruct.params = params;
solstruct.tspan = params.Time_properties.tmesh;
solstruct.x = xmesh;
solstruct.t = params.Time_properties.tmesh(1:SizesSol(1));
solstruct.sol = sol;

% --------------------------------------------------------------------------
% Nested functions (subfunctions)
% --------------------------------------------------------------------------
% PDE Definition Function
    function [c, f, s] = pdex4pde(x, t, u, DuDx)
        % Cache frequently used constants to avoid repeated field access
        kbT = physical_const.kBT;  % Use precomputed thermal energy
        q = physical_const.q;
        
        sim = 0;
        x_orig = x;
        
        % Handle symmetry if enabled
        if experiment_prop.symm == 1
            if x >= xmax/2
                x = xmax - x;
                sim = 1;
                if x < 0
                    x = 0;
                end
            end
        end
        
        % Determine which layer contains point x
        kk = find_layer_index(x, params);
        
        % Cache current layer properties to reduce struct access
        layer = params.Layers{kk};
        
        % Calculate generation rate
        g = calc_generation_rate(x, t, params, layer);
        
        % Time derivative coefficients
        c = [1; 1; 1; 0; 1];  % [dn/dt, dp/dt, dCT/dt, dV/dt, dEx/dt]
        
        % Flux terms (f) - drift and diffusion
        f = [(layer.mue * (u(1) * (-DuDx(4)) + kbT * DuDx(1)));  % Electron flux
             (layer.mup * (u(2) * DuDx(4) + kbT * DuDx(2)));     % Hole flux
             0;                                                   % CT (no transport)
             DuDx(4);                                             % Electric field
             0];                                                  % Exciton (no transport)
        
        % Adjust flux at layer interfaces (left boundary)
        if x < layer.XL + layer.XiL && kk > 1 && x > layer.XL
            sim_factor = (-1)^sim;
            f(1) = layer.mue * (u(1) * (-DuDx(4) + sim_factor * layer.DEAL - sim_factor * layer.DN0CL * kbT) + kbT * DuDx(1));
            f(2) = layer.mup * (u(2) * (DuDx(4) - sim_factor * layer.DIPL - sim_factor * layer.DN0VL * kbT) + kbT * DuDx(2));
        end
        
        % Adjust flux at layer interfaces (right boundary)
        if x > layer.XR - layer.XiR && kk < layers_num && x < layer.XR
            sim_factor = (-1)^sim;
            f(1) = layer.mue * (u(1) * (-DuDx(4) + sim_factor * layer.DEAR - sim_factor * layer.DN0CR * kbT) + kbT * DuDx(1));
            f(2) = layer.mup * (u(2) * (DuDx(4) - sim_factor * layer.DIPR - sim_factor * layer.DN0VR * kbT) + kbT * DuDx(2));
        end
        
        % Calculate electric field magnitude
        E_field = abs(DuDx(4)) / 1e-2;  % [V/cm]
        
        % Field-dependent rate constants (Marcus theory)
        % Check for field-dependent exciton dissociation
        if isfield(layer, 'r0_Ex')
            r0_Ex = layer.r0_Ex;
            interpolated_k = interp1(physical_const.E_values, physical_const.k_values, E_field, 'linear', 'extrap');
            interpolated_k_bak = interp1(physical_const.E_values, physical_const.k_bak_values, E_field, 'linear', 'extrap');
        else
            r0_Ex = 0;
            interpolated_k = 1;
            interpolated_k_bak = 1;
        end
        
        % Check for field-dependent CT dissociation
        if isfield(layer, 'r0_CT')
            r0_CT = layer.r0_CT;
        else
            r0_CT = 0;
        end
        
        % Calculate field-dependent rates
        kdisexc = layer.kdisexc * (1 - r0_Ex) + interpolated_k * r0_Ex;
        kdis = calc_field_dependent_rate(layer.kdis, q, E_field, r0_CT, kB, T);
        
        % Calculate back transfer rate (CT to exciton)
        offsetLECT = params.Layers{2}.offset;
        kforEx = kdisexc * exp(-offsetLECT / kbT) / params.Layers{2}.RCTE * (1 - r0_Ex) + interpolated_k_bak * r0_Ex;
        
        % Source/sink terms (s) - generation and recombination
        s = [kdis * u(3) - layer.kfor * (u(1) * u(2));  % Electron generation/recombination
             kdis * u(3) - layer.kfor * (u(1) * u(2));  % Hole generation/recombination
             kdisexc * u(5) + layer.kfor * (u(1) * u(2)) - (kdis * u(3) + layer.krec * (u(3) - layer.CT0)) - kforEx * u(3);  % CT dynamics
             (q / layer.epp) * (-u(1) + u(2) - layer.NA + layer.ND);  % Poisson equation
             g - kdisexc * u(5) - layer.krecexc * (u(5) - layer.Ex0) + kforEx * u(3)];  % Exciton dynamics
        
        % Override for equilibrium calculation
        if experiment_prop.equilibrium == 1
            c = [0; 0; 0; 0; 0];
        end
    end

% --------------------------------------------------------------------------
% Initial Conditions Function
    function u0 = pdex4ic(x)
        % Determine which layer contains point x
        ii = find_layer_index(x, params);
        
        % Set initial conditions based on input arguments
        if length(varargin) == 0 | varargin{1, 1}.sol == 0
            % Default equilibrium initial conditions
            u0 = [params.Layers{ii}.n0;
                  params.Layers{ii}.p0;
                  params.Layers{ii}.CT0;
                  (x / xmax) * experiment_prop.Vbi;
                  params.Layers{ii}.Ex0];
        elseif length(varargin) == 1
            % Interpolate from previous solution
            u0 = [abs(interp1(icx, icsol(end, :, 1), x));
                  abs(interp1(icx, icsol(end, :, 2), x));
                  abs(interp1(icx, icsol(end, :, 3), x));
                  interp1(icx, icsol(end, :, 4), x);
                  abs(interp1(icx, icsol(end, :, 5), x))];
        elseif max(max(max(varargin{1, 1}.sol))) ~= 0
            % Interpolate from previous solution (alternative case)
            u0 = [abs(interp1(icx, icsol(end, :, 1), x));
                  abs(interp1(icx, icsol(end, :, 2), x));
                  abs(interp1(icx, icsol(end, :, 3), x));
                  interp1(icx, icsol(end, :, 4), x);
                  abs(interp1(icx, icsol(end, :, 5), x))];
        end
    end

% --------------------------------------------------------------------------
% Boundary Conditions Function
    function [pl, ql, pr, qr] = pdex4bc(xl, ul, xr, ur, t)
        % Evaluate applied voltage
        switch experiment_prop.V_fun_type
            case 'constant'
                Vapp = experiment_prop.V_fun_arg(1);
            otherwise
                Vapp = Vapp_fun(experiment_prop.V_fun_arg, t);
        end
        
        % Apply boundary conditions based on BC type
        switch experiment_prop.BC
            case 0
                % Zero current (Neumann BC)
                pl = [0; 0; 0; -ul(4); 0];
                ql = [1; 1; 1; 0; 1];
                pr = [0; 0; 0; -ur(4) + experiment_prop.Vbi - Vapp; 0];
                qr = [1; 1; 1; 0; 1];
                
            case 1
                % Selective contacts
                pl = [0; ul(2) - params.Layers{1}.p0; 0; -ul(4); 0];
                ql = [1; 0; 1; 0; 1];
                pr = [ur(1) - params.Layers{layers_num}.n0; 0; 0; -ur(4) + experiment_prop.Vbi - Vapp; 0];
                qr = [0; 1; 1; 0; 1];
                
            case 2
                % Non-selective contacts
                pl = [ul(1) - params.Layers{1}.n0; ul(2) - params.Layers{1}.p0; 0; -ul(4); 0];
                ql = [0; 0; 1; 0; 1];
                pr = [ur(1) - params.Layers{end}.n0; ur(2) - params.Layers{end}.p0; 0; -ur(4) + experiment_prop.Vbi - Vapp; 0];
                qr = [0; 0; 1; 0; 1];
                
            case 3
                % Finite surface recombination + series resistance
                ext_prop = params.External_prop;
                if ext_prop.Rseries == 0
                    Vres = 0;
                else
                    J = physical_const.e * (ext_prop.sp_r * (ur(2) - ext_prop.pright) - ext_prop.sn_r * (ur(1) - ext_prop.nright));
                    Vres = -J * ext_prop.Rseries;
                end
                
                pl = [-ext_prop.sn_l * (ul(1) - ext_prop.nleft); -ext_prop.sp_l * (ul(2) - ext_prop.pleft); 0; -ul(4); 0];
                ql = [1; 1; 1; 0; 1];
                pr = [ext_prop.sn_r * (ur(1) - ext_prop.nright); ext_prop.sp_r * (ur(2) - ext_prop.pright); 0; -ur(4) + experiment_prop.Vbi - Vapp - Vres; 0];
                qr = [1; 1; 1; 0; 1];
                
            case 4
                % Open circuit
                pl = [ul(1) - params.Layers{1}.n0; ul(2) - params.Layers{1}.p0; 0; ul(4); 0];
                ql = [0; 0; 1; 0; 1];
                pr = [ur(1) - params.Layers{1}.n0; ur(2) - params.Layers{1}.p0; 0; ur(4); 0];
                qr = [0; 0; 1; 0; 1];
        end
    end

end


