function kk = find_layer_index(x, params)
% FIND_LAYER_INDEX Find which layer contains the spatial position x
%
% Syntax:
%   kk = find_layer_index(x, params)
%
% Description:
%   Determines which layer of the device contains the given spatial position.
%   This consolidates the repeated layer-finding loop pattern.
%
% Inputs:
%   x      - Spatial position (m)
%   params - Parameter structure containing layer definitions
%
% Outputs:
%   kk     - Layer index (1 to params.layers_num)
%
% Example:
%   kk = find_layer_index(x, params);
%   layer_properties = params.Layers{kk};
%
% Notes:
%   - Assumes layers are defined with XL (left boundary) and XR (right boundary)
%   - Returns the first layer where XL <= x <= XR
%   - If no layer contains x, returns the last checked layer index
%
% See also: pndriftHCT, pndriftHCT_forMarcus

    kk = 1;
    for k = 1:params.layers_num
        if x >= params.Layers{k}.XL && x <= params.Layers{k}.XR
            kk = k;
            break;
        end
    end
end
