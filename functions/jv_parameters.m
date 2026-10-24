function pv = jv_parameters(V, J)
% jv_parameters - Solar-cell figures of merit from a J-V curve under 1 sun
%
% Inputs:
%   V - Voltage (V), strictly increasing
%   J - Current density (mA/cm^2), negative where the cell delivers power
%       (the sign convention of external_model and dfplot.JV_new)
%
% Output: struct pv with fields
%   Jsc  - Short-circuit current density (mA/cm^2), positive
%   Voc  - Open-circuit voltage (V); NaN if J does not change sign within V
%   FF   - Fill factor
%   PCE  - Power conversion efficiency (%) for 100 mW/cm^2 illumination (AM1.5G)
%   Vmpp - Voltage at the maximum power point (V)
%   Jmpp - Current density at the maximum power point (mA/cm^2)
%
% Example:
%   V = linspace(0, 1.4, 141);
%   J = external_model(V, 0.05, 10, 0.5, 1.5, 1.8, 0);
%   pv = jv_parameters(V, J)

V = V(:);
J = J(:);
validateattributes(V, {'numeric'}, {'real', 'increasing'}, mfilename, 'V', 1);
if numel(J) ~= numel(V)
    error('jv_parameters:size', 'V and J must have the same number of elements.');
end

pv.Jsc = -interp1(V, J, 0, 'linear', 'extrap');

k = find(J(1:end-1) < 0 & J(2:end) >= 0, 1);
if isempty(k)
    pv.Voc = NaN;
else
    pv.Voc = V(k) - J(k)*(V(k+1) - V(k))/(J(k+1) - J(k));
end

P = -V.*J;                 % delivered power density (mW/cm^2)
[Pmax, i] = max(P);
pv.FF = Pmax/(pv.Voc*pv.Jsc);
pv.PCE = Pmax;             % percent of 100 mW/cm^2
pv.Vmpp = V(i);
pv.Jmpp = J(i);

end
