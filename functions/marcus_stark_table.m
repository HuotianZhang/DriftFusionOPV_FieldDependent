function table = marcus_stark_table(lambda, RCT, deltaG, field_sign, T)
% marcus_stark_table - Marcus transfer rate versus electric field, with the
% Stark shift of the CT state
%
% Inputs:
%   lambda     - Reorganization energy of the LE<->CT transfer (eV)
%   RCT        - Charge transfer distance (nm)
%   deltaG     - Free energy change of the transfer (eV): -offset for
%                LE->CT, +offset for CT->LE
%   field_sign - +1 for LE->CT, -1 for CT->LE (the Stark shift of the CT
%                energy enters the two directions with opposite sign)
%   T          - Temperature (K)
%
% Returns:
%   table - [F, k]: field F (V/m) in the first column, rate k (s^-1) in the
%           second. The Marcus rate is scaled by 0.1, equivalent to an
%           electronic coupling of sqrt(0.1)*Hab.

Hab = 0.01;              % Electronic coupling matrix element (eV)
F_values = (0:1e5:5e7)'; % V/m
RCT_m = RCT * 1e-9;

ket = zeros(size(F_values));
for ii = 1:numel(F_values)
    ket(ii) = 0.1*marcus_equation_stark(Hab, lambda, deltaG, T, field_sign*F_values(ii), RCT_m);
end
table = [F_values ket];

end
