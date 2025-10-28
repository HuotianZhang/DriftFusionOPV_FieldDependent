function p = configure_voltage_sweep(p, Vstart, Vend, tmax)
% CONFIGURE_VOLTAGE_SWEEP Set up voltage sweep experiment parameters
%
% Syntax:
%   p = configure_voltage_sweep(p, Vstart, Vend, tmax)
%
% Description:
%   Configures parameters for a voltage sweep experiment (JV curve).
%   This consolidates repeated voltage sweep configuration code.
%
% Inputs:
%   p      - Parameter structure
%   Vstart - Starting voltage (V)
%   Vend   - Ending voltage (V)
%   tmax   - Maximum simulation time (s)
%
% Outputs:
%   p      - Updated parameter structure with voltage sweep settings
%
% Example:
%   p = configure_voltage_sweep(p, 0, 1.2, 1e-1);
%
% See also: configure_solver_params, device

    p.Experiment_prop.V_fun_type = 'sweep';
    p.Experiment_prop.V_fun_arg(1) = Vstart;
    p.Experiment_prop.V_fun_arg(2) = Vend;
    p.Experiment_prop.V_fun_arg(3) = tmax;
end
