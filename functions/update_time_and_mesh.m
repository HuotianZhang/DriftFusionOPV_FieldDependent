function p = update_time_and_mesh(p, tmax, tmesh_type, tpoints)
% UPDATE_TIME_AND_MESH Update time properties and regenerate time mesh
%
% Syntax:
%   p = update_time_and_mesh(p, tmax, tmesh_type, tpoints)
%
% Description:
%   Updates time properties and regenerates the time mesh.
%   This consolidates the repeated pattern of setting time properties
%   followed by calling update_time() and Timemesh().
%
% Inputs:
%   p          - Parameter structure
%   tmax       - Maximum simulation time (s) (optional)
%   tmesh_type - Time mesh type (optional)
%   tpoints    - Number of time points (optional)
%
% Outputs:
%   p          - Updated parameter structure with new time mesh
%
% Example:
%   p = update_time_and_mesh(p, 1e-3, 2, 1000);
%   p = update_time_and_mesh(p);  % Just regenerate with existing settings
%
% See also: update_time, Timemesh, configure_pulse_properties

    % Update time properties if provided
    if nargin >= 2 && ~isempty(tmax)
        p.Time_properties.tmax = tmax;
    end
    if nargin >= 3 && ~isempty(tmesh_type)
        p.Time_properties.tmesh_type = tmesh_type;
    end
    if nargin >= 4 && ~isempty(tpoints)
        p.Time_properties.tpoints = tpoints;
    end
    
    % Apply the standard update sequence
    p = update_time(p);
    p = Timemesh(p);
end
