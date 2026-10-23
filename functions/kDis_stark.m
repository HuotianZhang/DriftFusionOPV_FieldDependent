function kLECT = kDis_stark(lambda, RCT, offset, T)
% kDis_stark - Marcus LE->CT (exciton dissociation) rates versus electric field, with Stark effect
%
% Inputs:
%   lambda  - Reorganization energy (eV)
%   RCT     - Charge transfer distance (nm)
%   offset  - Energy offset between excited state and CT state (eV)
%   T       - Temperature (K), optional (default 298). Pass the device
%             temperature so that forward/back rates obey detailed balance.
%
% Returns:
%   kLECT - Matrix where first column is electric field (V/m) and second column is rates (s^-1)
%
% Example:
%   kLECT = kDis_stark(0.5, 1.5, 0.05);

if nargin < 4
    T = 298;      % Temperature (K)
end
kLECT = marcus_stark_table(lambda, RCT, -offset, +1, T);

end
