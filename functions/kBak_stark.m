function kCTLE = kBak_stark(lambda, RCT, offset)
% kBak_stark - Calculate back electron transfer rates using Marcus theory with Stark effect
%
% Inputs:
%   lambda  - Reorganization energy (eV)
%   RCT     - Charge transfer distance (nm)
%   offset  - Energy offset between excited state and CT state (eV)
%
% Returns:
%   kCTLE - Matrix where first column is electric field (V/m) and second column is rates (s^-1)
%
% Example:
%   kCTLE = kBak_stark(0.5, 1.5, 0.05);

Hab = 0.01;       % Electronic coupling matrix element (eV)
T = 298;          % Temperature (K)

% Define the range of electric field values
F_values = 0:1e5:5e7; %V/m

% Convert RCT from nm to m
RCT_m = RCT * 1e-9;

% Calculate deltaG from offset (for back transfer, deltaG = +offset)
deltaG = +offset;

% Preallocate the output array for efficiency
ket_array = zeros(length(F_values), 1);

% Calculate ket using the Marcus equation for each field value
for F_nums = 1:length(F_values)
    F = -F_values(F_nums);  % Note: negative field for back transfer
    
    % Calculate ket using the Marcus equation
    ket = marcus_equation_stark(Hab, lambda, deltaG, T, F, RCT_m);
    ket_array(F_nums) = 0.1*ket;
end

% Return as [F_values, k_values]
kCTLE = [F_values' ket_array];

end
