%% J-V curves for a series of LE-CT offsets with field-dependent Marcus rates
% Runs build_MarcusTransfer_device for offsets 0 to 0.45 eV (E_gap = 1.4 eV),
% plots the J-V curves and stores Jsc, Voc, FF and the curves in file_name.
% Run from the repository root after startup.m.

num_iterations = 10;
result_struct(num_iterations) = struct('offset', [], 'lifetime', [], 'Jsc', [], 'Voc', [], 'FF', [], 'JJ', [], 'VV', []); % Preallocate struct array

file_name = 'simulation_Angle_result.mat';

% Fixed parameters for Marcus rate calculations
lambda = 0.5;  % eV - Reorganization energy
RCT = 1.5;     % nm - Electron-hole separation of the CT state (CT dipole e*RCT)
E_gap = 1.4;   % eV - Exciton energy

lifetime_ex = 10; %eciton lifetime (ps)
lifetime_ex_str = strrep(sprintf('%04.0f', lifetime_ex), '.', '');
full_name = ['kLECT0515d1eVd1nm' lifetime_ex_str 'ps_kdis510_RCTE01_krec19_kfor2510_An'];
fighandle = figure('Name',full_name);

Vstart  = 0;
Vend    = 1.2;
for ii=1:1:num_iterations
    offset = 0.05*ii-0.05;  % eV    % energy difference between the excited state and the CT state
    fprintf('The offset is: %.2f\n', offset);

    [DP, Prec] = build_MarcusTransfer_device(offset, lifetime_ex, lambda, RCT, E_gap);
    result_struct(ii).offset = offset;
    result_struct(ii).lifetime = 1/DP.Layers{2}.krecexc;

    DV2=device(DP);
    DV2.Prec=Prec;
    DV2=device.runsolJsc(DV2,1);
    DV2=device.runsolJV(DV2,1,Vstart,Vend);

    figure(fighandle);
    hold on;
    [result_struct(ii).Jsc,result_struct(ii).Voc,result_struct(ii).FF,result_struct(ii).JJ,result_struct(ii).VV] = dfplot.JV_new(DV2.sol_JV(end),1);
end
saveas(fighandle, [full_name '.fig']);
s_temp.(full_name) = result_struct;
if exist(file_name, 'file')
    save(file_name, '-struct', 's_temp', '-append');
else
    save(file_name, '-struct', 's_temp');
end
clear("s_temp")
