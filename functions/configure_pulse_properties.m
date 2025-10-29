function p = configure_pulse_properties(p, pulseon, tmax, pulselen, tstart, pulseint, tpoints)
% CONFIGURE_PULSE_PROPERTIES Set up pulse experiment parameters
%
% Syntax:
%   p = configure_pulse_properties(p, pulseon, tmax, pulselen, tstart, pulseint, tpoints)
%
% Description:
%   Configures parameters for pulse experiments (TPV, TAS).
%   This consolidates repeated pulse property configuration code.
%
% Inputs:
%   p        - Parameter structure
%   pulseon  - Enable pulse (1) or disable (0)
%   tmax     - Maximum simulation time (s)
%   pulselen - Pulse length (s)
%   tstart   - Pulse start time (s)
%   pulseint - Pulse intensity
%   tpoints  - Number of time points (default: 1000)
%
% Outputs:
%   p        - Updated parameter structure with pulse settings
%
% Example:
%   p = configure_pulse_properties(p, 1, 5e-5, 2e-6, 1e-6, 200, 1000);
%
% See also: configure_solver_params, configure_voltage_sweep, device

    if nargin < 7
        tpoints = 1000;
    end
    
    p.pulse_properties.pulseon = pulseon;
    p.Time_properties.tmax = tmax;
    p.pulse_properties.pulselen = pulselen;
    p.pulse_properties.tstart = tstart;
    p.pulse_properties.pulseint = pulseint;
    p.Time_properties.tpoints = tpoints;
end
