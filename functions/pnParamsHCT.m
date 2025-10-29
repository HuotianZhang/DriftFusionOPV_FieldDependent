function [params] = pnParamsHCT(~)

if nargin>0
    
else
    
    %Physical constants (CODATA 2018 values)
    
    physical_const.kB = 8.6173324e-5;    % Boltzmann constant [eV K^-1]
    physical_const.T = 300;              % Temperature [K]
    physical_const.epp0 = 552434;        % e^2 eV^-1 cm^-1 -Checked (02-11-15)
    physical_const.q = 1;                % in e
    physical_const.e = 1.602176634e-19;  % Charge of an electron in Coulombs (CODATA 2018)
    
    % Solver options
    solveropt.AbsTol=1e-6;
    solveropt.RelTol=1e-3;
    % Define geometry of the system (m=0 1D, m=1 cylindrical polar coordinates,
    % m=2 spherical polar coordinates).
    solveropt.m = 0;
    
    % Time mesh properties
    Time_properties.tmesh_type = 2;
    Time_properties.tmax = 5e-5;        % Time
    Time_properties.t0 = Time_properties.tmax/1000;
    Time_properties.tpoints = 1000;
    
    
    % back ground light properties
    light_properties.Int =3;             % Bias Light intensity
    % OM = Optical Model
    % 0 = Uniform Generation
    % 1 = Beer-Lamber (Requires pre calculation using Igor code & gen profile in base workspace)
    % 2 = Transfer Matrix (Stanford)
    light_properties.OM  =0;
    light_properties.Genstrength  =2.5e21;%for uniform generation in cm-3
    
    % Pulse of  light properties
    pulse_properties.pulseon =0;         % Switch pulse on for TPV
    pulse_properties.pulselen = 2e-10;    % Transient pulse length
    pulse_properties.tstart=1e-10;
    pulse_properties.pulseint =5;        % Transient pulse intensity- for BL and TM models, 100 mW/cm2 assumed
    
    %electrical properties for the experiment
    Experiment_prop.Vapp =0;            % Applied bias
    Experiment_prop.Vtransient=0.01;
    Experiment_prop.wAC=1e3;
    Experiment_prop.fastrec = 0;        % Can be used to accelerate finding initial conditions
    Experiment_prop.BC =4;                  % Boundary Conditions. Must be set to one for first solution % BC=5 Impedance measurement
    Experiment_prop.figson =1;              % Toggle figures on/off
    Experiment_prop.side = 1;                % illumination side 1 = EE, 2 = SE
    Experiment_prop.calcJ =1;              % Calculates Currents- slows down solving calcJ = 1, calculates DD currents at every position, calcJ = 2, calculates DD at boundary.
    Experiment_prop.mobset =1;             % Switch on/off electron hole mobility- MUST BE SET TO ZERO FOR INITIAL SOLUTION
    Experiment_prop.symm=0;
    Experiment_prop.equilibrium=0;
    Experiment_prop.discretetrap=1;
    Experiment_prop.V_fun_type = 'constant';
    Experiment_prop.V_fun_arg(1) = 0;
    Experiment_prop.V_fun_arg(2) = 1;
    Experiment_prop.V_fun_arg(3) = Time_properties.tmax;
    Excelfilename='PINDevice.xlsx';
    
    params= deviceparams(physical_const,solveropt,...
        pulse_properties,light_properties,Time_properties,Experiment_prop,Excelfilename);
    
    
end
end