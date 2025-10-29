function g = calc_generation_rate(x, t, params, layer)
% CALC_GENERATION_RATE Calculate carrier generation rate at position and time
%
% Syntax:
%   g = calc_generation_rate(x, t, params, layer)
%
% Description:
%   Calculates the carrier generation rate including both steady-state
%   and pulse contributions. Handles both uniform and optical transfer
%   matrix generation profiles.
%   This consolidates the repeated generation calculation pattern.
%
% Inputs:
%   x      - Spatial position (m)
%   t      - Time (s)
%   params - Parameter structure
%   layer  - Current layer structure (params.Layers{kk})
%
% Outputs:
%   g      - Generation rate (m^-3 s^-1)
%
% Example:
%   kk = find_layer_index(x, params);
%   g = calc_generation_rate(x, t, params, params.Layers{kk});
%
% Notes:
%   - Handles uniform generation (OM = 0) and transfer matrix (OM = 2)
%   - Automatically adds pulse contribution if pulse is enabled
%   - Returns 0 if layer doesn't absorb (layer.int == 0)
%
% See also: pndriftHCT, pndriftHCT_forMarcus, find_layer_index

    g = 0;
    
    % Calculate base generation rate based on optical model
    if params.light_properties.OM == 0
        % Uniform generation
        if params.light_properties.Int ~= 0
            g = params.light_properties.Int * params.light_properties.Genstrength;
        end
    elseif params.light_properties.OM == 2
        % Transfer Matrix generation profile
        if layer.int ~= 0 && params.light_properties.Int ~= 0
            g = interp1(params.light_properties.Gensprofile_pos, ...
                       params.light_properties.Gensprofile_signal, x);
            if isnan(g)
                g = 0;
            end
        end
    end
    
    % Add pulse contribution if enabled
    if params.pulse_properties.pulseon == 1
        pulse_start = params.pulse_properties.tstart;
        pulse_end = params.pulse_properties.pulselen + pulse_start;
        if t >= pulse_start && t < pulse_end
            g = g + params.pulse_properties.pulseint * params.light_properties.Genstrength;
        end
    end
    
    % Override if layer doesn't absorb light
    if layer.int == 0
        g = 0;
    end
end
