function kCTLE = kBak_stark(lambda, RCT, offset, T, delta_alpha)
% kBak_stark - Marcus CT->LE (back transfer) rates versus electric field, with Stark effect
%
% Inputs:
%   lambda      - Reorganization energy (eV)
%   RCT         - Electron-hole separation of the CT state (nm); CT dipole e*RCT
%   offset      - Energy offset between excited state and CT state (eV)
%   T           - Temperature (K); pass the device temperature so that
%                 forward/back rates obey detailed balance
%   delta_alpha - Polarizability volume change LE -> CT (Angstrom^3)
%
% Returns:
%   kCTLE - Matrix where first column is electric field (V/m) and second column is rates (s^-1)
%
% Example:
%   kCTLE = kBak_stark(0.5, 1.5, 0.05, 300, 8.5e5);

kCTLE = marcus_stark_table(lambda, RCT, +offset, -1, T, delta_alpha);

end
