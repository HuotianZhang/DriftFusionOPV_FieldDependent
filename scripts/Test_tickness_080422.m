%% SET PARAMETERS and make Device
% Set and adjust the Recombination Parameters
addpath(genpath(pwd)); % add folders to path

Prec                        = paramsRec;                    % initiliase the recombination parameters (default values)
offset                      = 0.25;                  % eV    % energy difference between the excited state and the CT state
tickness                    = 10 * 1e-9;           % m     % thickness of the active layer
Prec.params.Ex.DG0          = 1.36;                 
Prec.params.CT.DG0          = Prec.params.Ex.DG0 - offset;
Prec.params.Ex.f            = 2.56;
Prec.params.CT.f            = 2e-4;
Prec.params.Ex.sigma        = 0.01;
Prec.params.CT.sigma        = 0.01;
Prec.params.Ex.numbrestate  = 1;
Prec.params.CT.numbrestate  = 1;
Prec.params.Ex.L0           = 0.06;  %0.10
Prec.params.Ex.Li           = 0.045; %0.15   %0.04-0.150
Prec.params.CT.L0           = 0.07;  %0.18  %CT smoothing
Prec.params.CT.Li           = 0.1;   %0.15
Prec.params.RCTE            = 1e-2;
Prec.params.Excitondesnity  = 5e27;
Prec.params.Vstar           = 0.000;
Prec.const.T                = 300;
Prec                        = paramsRec.calcall(Prec, tickness); % Update the Recombination Parameters (pass thickness)

krecCT  = Prec.params.CT.results.knr;
krecex  = Prec.params.Ex.results.knr;
Voc     = Prec.results.Vocrad - Prec.results.Dvnr;

% Generate a device with the defined parameters
% Parameters are from Prec which is defined above and from the PINDevice file, which is loaded below

activelayer = 2;        % Active Layer Index                % integer
NC          = 2e19;     % Number of Charge Carriers         % cm^-3
Kfor        = 1e-10;    % Rate Constant CS to CT            % cm^3 / s
kdis        = 1e11;     % Rate Constant CT dissociation     % 1 / s
kdisex      = 1e12;     % Rate Constatn Ex dissociation     % 1 / s
mobility    = 5e-4;     % Charge Carrier Mobility           % cm^2 / V / s

deviceParameterFile = uigetfile('parameters\DeviceParameters_Default.xlsx');
if isequal(deviceParameterFile,0)
    deviceParameterFile = 'DeviceParameters_Default.xlsx';
end
%deviceParameterFile = 'DeviceParameters_Default.xlsx';
DP = deviceparams(['parameters\',deviceParameterFile]);
%%
clear tableres

Thickness_list=[10,20,40,60,80,100,200,400];
count=0;
for tickness_active_layer=Thickness_list
tickness        = tickness_active_layer * 1e-9;           % m     % thickness of the active layer
Prec.params.Excitondesnity  = 5e27;
Prec                        = paramsRec.calcall(Prec, tickness); % Update the Recombination Parameters (pass thickness)

DP.light_properties.OM      = 0; %to consider the transfer matrix generation profile
DP.Time_properties.tpoints  = 100;
DP.Layers{activelayer}.tp   = tickness * 100; % [cm] = [m] * 100 - Store thickness in deviceparams

DP = DP.generateDeviceparams(NC, activelayer, mobility, kdis, kdisex, Prec, Kfor, 0);
% clear NC activelayer Tq1exp mobility kdis kdisex

%% run dd model
    Vstart  = 0;
    Vend    = 1.5;
    tic
    DP.Layers{2}.r0=0; %R0 for field dependence is 1 nm

    DV2=device(DP);
    DV2.Prec=Prec;
    toc

    % for different suns
    suns = [1];
    countsuns=0;
    for Gen=suns
        count=count+1;
        countsuns=countsuns+1;
        tic
        DV2=device.runsolJsc(DV2,Gen);
        toc
        
        tic
        DV2=device.runsolJV(DV2,Gen,Vstart,Vend);
        toc

        [Jsc,Voc,FF,JJ,VV]=dfplot.JV_new(DV2.sol_JV(countsuns),1,0,num2str(tickness_active_layer));
        tableres(count).Voc=Voc;
        tableres(count).JJ=JJ;
        tableres(count).VV=VV;
        tableres(count).FF=FF;
        tableres(count).Jsc=Jsc;
        tableres(count).Gen=Gen;
        tableres(count).mobility=mobility;
        tableres(count).AL_thickness=tickness_active_layer;
        tableres(count).temp=temp;
        tableres(count).Kfor=Kfor;
        tableres(count).Jscrad=Prec.results.Jscrad;
        pause(0.1)
    end
end
%%
% tableres=struct2table(tableres);
figure
plot(tableres.AL_thickness,tableres.Jsc,'*','DisplayName',"Jsc from DD")
hold on
plot(tableres.AL_thickness,tableres.Jscrad,'*','DisplayName',"Ideal Jsc from Prec")
            xlabel('Tickness [nm]')
            ylabel('current density  [mA cm-2 ]')
legend