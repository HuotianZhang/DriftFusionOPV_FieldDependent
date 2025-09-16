%% EXAMPLE WORKFLOW
% First Calculate the Recombination paramters of the CT and Exciton
% here we also calculate the absorption profile of the device and the
% emission spectra based on the properties of the states 

%% SET PARAMETERS and make Device
% Set and adjust the Recombination Parameters
addpath(genpath(pwd)); % add folders to path
num_iterations = 10;
result_struct(num_iterations) = struct('offset', [], 'lifetime', [], 'Jsc', [], 'Voc', [], 'FF', [], 'JJ', [], 'VV', []); % Preallocate struct array

% file_name = 'simulation_result.mat';
% file_name = 'simulation_0_result.mat';
file_name = 'simulation_Angle_result.mat';
field_name = 'kLECT0515';
lifetime_ex = 10; %eciton lifetime (ps)
lifetime_ex_str = strrep(sprintf('%04.0f', lifetime_ex), '.', '');
% full_name = [field_name 'd1eVd1nm' lifetime_ex_str 'ps_0_osclt2e_2'];
full_name = [field_name 'd1eVd1nm' lifetime_ex_str 'ps_kdis510_RCTE01_krec19_kfor2510_An'];
% full_name = [field_name 'd1eVd1nm' lifetime_ex_str 'ps_Angle'];
fighandle = figure('Name',full_name);
%data = load('data.mat');
% E_values = kLECT_vars.(field_name)(:, 1); % 
E_values = kLECT_stark_vars.(field_name)(:, 1); % 


for ii=1:1:num_iterations
%ii=ii+3;
fprintf('The current loop is: %d\n', ii); % Display as integer

k_values = kLECT_stark_vars.(field_name)(:, ii+1); %
k_bak_values = kCTLE_stark_vars.('kCTLE0515')(:, ii+1)*10;

Prec                        = paramsRec;                    % initiliase the recombination parameters (default values)
offset                      = 0.05*ii-0.05;  % eV    % energy difference between the excited state and the CT state
fprintf('The offset is: %.2f\n', offset);
result_struct(ii).offset = offset;
Prec.params.tickness        = 100 * 1e-9;           % m     % thickness of the active layer
Prec.params.Ex.DG0          = 1.4;                 
Prec.params.CT.DG0          = Prec.params.Ex.DG0 - offset;
Prec.params.Ex.f            = 2.56e-0;
Prec.params.CT.f            = 2e-4;
Prec.params.Ex.sigma        = 0.0001;
Prec.params.CT.sigma        = 0.0001;
Prec.params.Ex.numbrestate  = 1;
Prec.params.CT.numbrestate  = 1;
Prec.params.Ex.L0           = 0.1;  %0.10
Prec.params.Ex.Li           = 0.15; %0.15   %0.04-0.150
Prec.params.CT.L0           = 0.10;  %0.18  %CT smoothing
Prec.params.CT.Li           = 0.15;   %0.15
Prec.params.RCTE            = 1e-1;%ratio CT to S1
Prec.params.Excitondesnity  = 8e27;
Prec.params.Vstar           = 0.000;
Prec.const.T                = 300;
Prec                        = paramsRec.calcall(Prec); % Update the Recombination Parameters

krecCT  = Prec.params.CT.results.knr;
krecex  = Prec.params.Ex.results.knr;
Voc     = Prec.results.Vocrad - Prec.results.Dvnr;

% Generate a device with the defined parameters
% Parameters are from Prec which is defined above and from the PINDevice file, which is loaded below

activelayer = 2;        % Active Layer Index                % integer
NC          = 2e19;     % Number of Charge Carriers         % cm^-3
Kfor        = 2.5e-10;    % Rate Constant CS to CT            % cm^3 / s
kdis        = 5e10;     % Rate Constant CT dissociation     % 1 / s
kdisex      = k_values(1);     % Rate Constatn Ex dissociation     % 1 / s
mobility    = 5e-2;     % Charge Carrier Mobility           % cm^2 / V / s

deviceParameterFile = 'DeviceParameters_Default.xlsx';

%deviceParameterFile = 'DeviceParameters_Default.xlsx';
DP = deviceparams(['parameters\',deviceParameterFile]);

DP.light_properties.OM      = 0; %to consider the transfer matrix generation profile
DP.Time_properties.tpoints  = 100;
DP.Layers{activelayer}.tp   = Prec.params.tickness * 100; % [cm] = [m] * 100


    % DP.Layers{2}.r0_CT=0; %R0 for field dependence is 1 nm
    % DP.Layers{2}.r0_Ex=1; 
    DP.Layers{2}.krec=1e9; %manually defined CT decay rate (s^-1)
    % DP.Layers{2}.CT0=0.9; %manually defined CT decay rate (s^-1)
    % DP.Layers{2}.Ex0=1.9e-4; %manually defined CT decay rate (s^-1)
    % DP.Layers{2}.n0=3e10; %manually defined CT decay rate (s^-1)
    % DP.Layers{2}.p0=3e10; %manually defined CT decay rate (s^-1)
    DP.Layers{2}.krecexc=1/lifetime_ex*1e12; %exciton recombination rate s^-1
    DP.physical_const.E_values= E_values;
    DP.physical_const.k_values=k_values;
    DP.physical_const.k_bak_values=k_bak_values;
    DP.Layers{2}.offset=offset; %manually defined CT decay rate (s^-1)
    DP.Layers{2}.RCTE=Prec.params.RCTE; %manually defined CT decay rate (s^-1)



DP = DP.generateDeviceparams(NC, activelayer, mobility, kdis, kdisex, Prec, Kfor, 0);
clear NC activelayer Tq1exp mobility kdis kdisex

%% Run the JV scans here
    Vstart  = 0;
    Vend    = 1.2;
    tic %tic works with the toc function to measure elapsed time
    DP.Layers{2}.r0_CT=0; %R0 for field dependence is 1 nm
    DP.Layers{2}.r0_Ex=1; 
    DP.Layers{2}.krec=1e9; %manually defined CT decay rate (s^-1)
    % DP.Layers{2}.CT0=0.9e0; %manually defined CT decay rate (s^-1)
    % DP.Layers{2}.Ex0=1.9e-4; %manually defined CT decay rate (s^-1)
    % DP.Layers{2}.n0=3e12; %manually defined CT decay rate (s^-1)
    % DP.Layers{2}.p0=3e12; %manually defined CT decay rate (s^-1)
    DP.Layers{2}.krecexc=1/lifetime_ex*1e12; %exciton recombination rate s^-1
    DP.physical_const.E_values= E_values;
    DP.physical_const.k_values=k_values;
    result_struct(ii).lifetime = 1/DP.Layers{2}.krecexc;
    DV2=device_forMarcus(DP);
    DV2.Prec=Prec;
    toc

    % for different suns
    suns = [1];
    for Gen=suns
        tic
        DV2=device_forMarcus.runsolJsc(DV2,Gen);
        %DV2=device(DP);
        toc

        tic
        DV2=device_forMarcus.runsolJV(DV2,Gen,Vstart,Vend);
        toc
    end
    % plot JV
    figure(fighandle);
    %dfplot.JV_new(DV2.sol_JV(2),1)
    hold on;
    [result_struct(ii).Jsc,result_struct(ii).Voc,result_struct(ii).FF,result_struct(ii).JJ,result_struct(ii).VV] = dfplot.JV_new(DV2.sol_JV(end),1);
end
saveas(fighandle, [full_name '.fig']);
s_temp.(full_name) = result_struct;
%save(file_name,"-struct","s_temp","-append");
saveOrAppendParameters(file_name,s_temp);
clear("s_temp")
