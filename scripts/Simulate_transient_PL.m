addpath(genpath(pwd)); % add folders to path

Prec                        = paramsRec;                    % initiliase the recombination parameters (default values)
offset                      = 0.25;                  % eV    % energy difference between the excited state and the CT state
tickness                    = 10 * 1e-9;           % m     % thickness of the active layer
Prec.params.Ex.DG0          = 1.36; % [0.8,2.5 ] energy of the Ex state                
Prec.params.CT.DG0          = Prec.params.Ex.DG0 - offset; % energy of the CT state
Prec.params.Ex.f            = 2.56; % [1e-1, 10]%controls the strength of the optical transition from the Ex to ground
Prec.params.CT.f            = 2e-2;%[1e-4, 1e-1] %controls the strength of the optical transition from the CT to ground

Prec.params.Ex.L0           = 0.06;  %[0.05,0.2] % low frequency reorganisation energy % strongly affects the spectral width of the emission 
Prec.params.Ex.Li           = 0.045; %[0.05,0.2] % high frequency reorganisation energy % strongly affects the ratio between the vibronic peak emission
Prec.params.CT.L0           = 0.05;  %[0.05,0.2]
Prec.params.CT.Li           = 0.04;   %[0.05,0.2]
Prec.params.RCTE            = 1e-2; % [1e-2,10] % ratio of CT to Exiton density of state


%%
figure
for Grate=5e25
    
% Generate a device with the defined parameters
% Parameters are from Prec which is defined above and from the PINDevice file, which is loaded below

activelayer = 2;        % Active Layer Index                % integer ( no need to change) 
%NC          = 2e19;     % Number of Charge Carriers         % cm^-3
Kfor        = 1e-11;   %[1e-8,1e-12] % Rate Constant CS to CT            % cm^3 / s
kdis        = 1e9;     %[1e9,1e12] % Rate Constant CT dissociation     % 1 / s
kdisex      = 1e9;     %[1e9,1e12] % Rate Constatn Ex dissociation     % 1 / s
%mobility    = 5e-4;     % Charge Carrier Mobility           % cm^2 / V / s
%Generate the deviceparams class
deviceParameterFile = 'DeviceParameters_Default.xlsx';
DP = deviceparams(['parameters\',deviceParameterFile]);


%experiment parameter

Background_Ex_Gen_rate=1e10; %1sun would be around 1e22 % in cm-3 s-1
%laser pulse properties
Laser_Ex_gen_rate_gauss=Grate; % in cm-3 s-1
Laser_Ex_gen_rate_exp=Grate*1e-6; % in cm-3 s-1

laser_peak= 2.5; % in ns
gaussianwidth=5;% in ns width of the gaussian
exponentialdecay=1e-9;%decay of the exponential component of the laser pulse in s

exp_length= 5001; % in ns
Temperature=300;%[30,350] % in Kelvin 


exp_name=['G rate = ' num2str(Laser_Ex_gen_rate,'%1.1e')];%,'%1.1e')];%
%doing the calculations 

Prec.const.T                = Temperature; % temperature in Kelvin
Prec                        = paramsRec.calcall(Prec, tickness); % Update the Recombination Parameters (pass thickness)

krecCT  = Prec.params.CT.results.knr +Prec.params.CT.results.krTot; % recombination rate constants based on the parameters above 
krecex  = Prec.params.Ex.results.knr +Prec.params.Ex.results.krTot;
DP = DP.generateDeviceparams(2e19, activelayer, 5e-4, kdis, kdisex, Prec, Kfor, 0);

%DP.simulate_TCSPC(Prec,Background_Ex_Gen_rate,Laser_Ex_gen_rate,laser_width,exp_length,exp_name)
 [time,PL_emission,wavelength]=DP.simulate_TCSPC_gaussianlaserpulse(Prec,Background_Ex_Gen_rate,Laser_Ex_gen_rate_gauss,Laser_Ex_gen_rate_exp,...
     gaussianwidth,exponentialdecay,laser_peak,exp_length,exp_name);
%simulate_TCSPC_gaussianlaserpulse(DP,Prec,Background_Ex_Gen_rate,Laser_Ex_gen_rate,...
 %               gaussianwidth,exponentialdecay,laserwidth,exp_length,legendname)
end