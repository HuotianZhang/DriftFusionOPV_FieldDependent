function k_field = calc_field_dependent_rate(k0, q, E_field, r0, kB, T)
% CALC_FIELD_DEPENDENT_RATE Calculate field-dependent dissociation rate
%
% Syntax:
%   k_field = calc_field_dependent_rate(k0, q, E_field, r0, kB, T)
%
% Description:
%   Calculates field-dependent rate constant using the Poole-Frenkel effect.
%   This consolidates the repeated pattern: k = k0 * exp(q*|E|*r0/(kB*T))
%   Used for field-dependent dissociation of CT states and excitons.
%
% Inputs:
%   k0      - Base rate constant (s^-1)
%   q       - Elementary charge (C)
%   E_field - Electric field magnitude (V/m or gradient)
%   r0      - Characteristic separation distance (m)
%   kB      - Boltzmann constant (J/K)
%   T       - Temperature (K)
%
% Outputs:
%   k_field - Field-dependent rate constant (s^-1)
%
% Example:
%   kdis = calc_field_dependent_rate(params.Layers{kk}.kdis, q, abs(DuDx(4)), r0_CT, kB, T);
%
% Theory:
%   The Poole-Frenkel effect describes field-enhanced dissociation:
%   k(E) = k0 * exp(q*E*r0 / (kB*T))
%   where r0 is the charge-transfer separation distance.
%
% See also: pndriftHCT, pndriftHCT_forMarcus

    k_field = k0 * exp(q * abs(E_field) * r0 / (kB * T));
end
