classdef deviceparams 
    % deviceparams - Device parameters for OPV simulation
    %
    % IMPORTANT NOTE ON THICKNESS PARAMETER:
    % Device thickness is stored in Layers{}.tp (in centimeters).
    % This is the SINGLE SOURCE OF TRUTH for thickness.
    % When calling paramsRec.calcall(), convert to meters: tickness_m = tp * 1e-2
    % See docs/THICKNESS_PARAMETER.md for complete documentation.
    
    properties
        physical_const
        Layers
        solveropt
        pulse_properties
        light_properties
        Time_properties
        Xgrid_properties
        layers_num
        Experiment_prop
        External_prop
        layer_colour = [1,1,1;1,1,1;1,1,1;1,1,1;1,1,1;1,1,1];
        results
        
    end
    methods
        function  DP = deviceparams(Excelfilename) 
                % Deviceparams creates an object containg all the parameters
                % of the OPV device.
                % DP = deviceparams(Excelfilename)
                % The excel files determines the parameters in DP.layers.
                % All other parameters are determined within this constructor
                % function. 
                % INPUT:  Path to an exelfile
                % OUTPUT: Object of the class deviceparams, containing
                % the parameters specified inside the constructor and in
                % the excel spreadsheat.
                
                % Physical constants
                physical_const.kB = 8.6173324e-5;    % Boltzmann constant [eV K^-1]
                physical_const.k = 1.380649e-23;     % Boltzmann constant [J K^-1] (CODATA 2018)
                physical_const.T = 300;              % Temperature [K]
                physical_const.kBT = physical_const.kB * physical_const.T;  % Thermal energy [eV] - cached calculation
                physical_const.epp0 = 552434;        % e^2 eV^-1 cm^-1 -Checked (02-11-15)
                physical_const.q = 1;                % in e
                physical_const.e = 1.602176634e-19;  % Charge of an electron in Coulombs (CODATA 2018)
                physical_const.h = 6.62607015e-34;   % Planck constant [J s] (CODATA 2018)
                physical_const.hbar = 1.054571817e-34; % Reduced Planck constant [J s] = h/(2π)
                physical_const.c = 2.99792458e8;     % Speed of light in vacuum [m s^-1]
                physical_const.epsilon0 = 8.8541878128e-12; % Vacuum permittivity [F m^-1] (CODATA 2018)
                physical_const.me = 9.1093837015e-31; % Electron mass [kg] (CODATA 2018)
                
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
                Experiment_prop.BC =2;                  % Boundary Conditions. Must be set to one for first solution % BC=2 perfect contact %BC=3 includes finite surface recombination and series resitance
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
                % external circuit properties and surface extraction
                % coefficient (surface recombination properties)
                External_prop.Rseries=1e6; % the resitance is area normalised 
                External_prop.sn_l=1e8;%left Electron extraction/surface recombination coefficient in cm s^-1
                External_prop.sn_r=1e8;%right Electron extraction/surface recombination coefficient in cm s^-1
                External_prop.sp_l=1e8;%left hole extraction/surface recombination coefficient in cm s^-1
                External_prop.sp_r=1e8;%right hole extraction/surface recombination coefficient in cm s^-1
                DP.physical_const = physical_const;
                DP.External_prop=External_prop;
                DP=readlayers(DP,Excelfilename);
                DP.solveropt = solveropt;
                DP.pulse_properties = pulse_properties;
                DP.light_properties = light_properties;
                DP.Time_properties = Time_properties;
                DP.Experiment_prop=Experiment_prop;
                DP=UpdateLayers(DP);
                DP = Xgrid(DP);
                DP=update_time(DP);
                DP=Timemesh(DP);
                if DP.light_properties.OM == 2
                    DP=Transfer_matrix_generation_profile(DP);
                end
                DP.External_prop.leftboundary_fermi_energy=DP.Layers{1}.Phi;
                DP.External_prop.Rightboundary_fermi_energy=DP.Layers{end}.Phi;
                DP=update_boundary_charge_densities(DP);
        end
        function DP = Xgrid(DP)
            x=0;
            for ii=1:1:DP.layers_num
                if(ii==1)
                    bulk_layer_thickness=DP.Layers{ii}.tp-DP.Layers{ii}.tinterR-DP.Layers{ii}.XiL-DP.Layers{ii}.tinterL-DP.Layers{ii}.XiR;
                    
                    x=0:DP.Layers{ii}.XipL:DP.Layers{ii}.XiL;
                    if isempty(x)
                        x=[x,0:DP.Layers{ii}.epointsL:DP.Layers{ii}.tinterL];
                        
                    else
                        x=[x,max(x)+DP.Layers{ii}.epointsL:DP.Layers{ii}.epointsL:max(x)+DP.Layers{ii}.tinterL];
                        
                    end
                    if isempty(x)
                        x=[x,0:DP.Layers{ii}.pp:bulk_layer_thickness];
                        
                    else
                        x=[x,max(x)+DP.Layers{ii}.pp:DP.Layers{ii}.pp:max(x)+bulk_layer_thickness];
                        
                    end
                    x=[x,max(x)+DP.Layers{ii}.epointsR:DP.Layers{ii}.epointsR:max(x)+DP.Layers{ii}.tinterR];
                    x=[x,max(x)+DP.Layers{ii}.XipR:DP.Layers{ii}.XipR:max(x)+DP.Layers{ii}.XiR];
                    DP.Layers{1}.XL=0;
                    DP.Layers{1}.XR=max(x);
                    
                else
                    bulk_layer_thickness=DP.Layers{ii}.tp-DP.Layers{ii}.tinterR-+DP.Layers{ii}.XiL-DP.Layers{ii}.tinterL-+DP.Layers{ii}.XiR;
                    if bulk_layer_thickness<0
                        bulk_layer_thickness=DP.Layers{ii}.tp;
                        if bulk_layer_thickness < 1e-7
                            error('layer is thinner than 1 nm , the drift diffusion equation are not valid' )
                        end
                        disp(['Warning: the layer number' num2str(ii) ' is thinner than the interface layer properties set in the excel file \n , the interface layers will be neglected'])
                        DP.Layers{ii}.XL=max(x)+0.5e-7;
                        x=[x,max(x)+1e-7:0.5e-7:max(x)+bulk_layer_thickness];
                        DP.Layers{ii}.XR=max(x);
                    else
                        DP.Layers{ii}.XL=max(x)+DP.Layers{ii}.XipL;
                        x=[x,max(x)+DP.Layers{ii}.XipL:DP.Layers{ii}.XipL:DP.Layers{ii}.XiL];
                        x=[x,max(x)+DP.Layers{ii}.epointsL:DP.Layers{ii}.epointsL:max(x)+DP.Layers{ii}.tinterL];
                        x=[x,max(x)+DP.Layers{ii}.pp:DP.Layers{ii}.pp:max(x)+bulk_layer_thickness];
                        x=[x,max(x)+DP.Layers{ii}.epointsR:DP.Layers{ii}.epointsR:max(x)+DP.Layers{ii}.tinterR];
                        x=[x,max(x)+DP.Layers{ii}.XipR:DP.Layers{ii}.XipR:max(x)+DP.Layers{ii}.XiR];
                        DP.Layers{ii}.XR=max(x);
                    end
                end
            end
            DP.Xgrid_properties=x;
        end
        function DP=readlayers(DP,filename)
            % Readlayers takes a deviceparams object and the filename of an
            % excel sheet as input. It saves all the layer properties to
            % the deviceparams and gives the updated object as output. 

            delimiterIn = ',';
            headerlinesIn = 0;
            data = importdata(filename,delimiterIn,headerlinesIn);
            DP.layers_num=length(data.data(:,1));
            % Use physical_const.epp0 instead of duplicating the constant
            for ii=1:1:DP.layers_num
                DP.Layers{ii}.epp=data.data(ii,1)*DP.physical_const.epp0; % Dielectric constant
                DP.Layers{ii}.EA = data.data(ii,2);        % Conduction band energy
                DP.Layers{ii}.IP = data.data(ii,3);     % Valence band energy
                DP.Layers{ii}.PhiCV = data.data(ii,4);   % n doping
                DP.Layers{ii}.PhiAV = data.data(ii,5);     % p doping
                DP.Layers{ii}.N0C=data.data(ii,6);      % effective Density Of States at the conduction band
                DP.Layers{ii}.N0V=data.data(ii,7);      % effective Density Of States at the Valence band
                DP.Layers{ii}.muee=data.data(ii,8);        %mobility
                DP.Layers{ii}.mupp=data.data(ii,9);        %mobility
%                 DP.Layers{ii}.krad  = data.data(ii,10); % [cm3 s-1] Bulk Radiative Recombination coefficient [nominally 1e-10]
%                 DP.Layers{ii}.taun = data.data(ii,11);   % [s] SRH time constant for electrons
%                 DP.Layers{ii}.taup = data.data(ii,12);
%                 DP.Layers{ii}.Ete = data.data(ii,13);  % ((EA-IP)/2+IP)-0.2;      % Deep trap energy- currently a guess!
%                 DP.Layers{ii}.Eth = data.data(ii,14);
%                 DP.Layers{ii}.NTA = data.data(ii,15);
%                 DP.Layers{ii}.NTD = data.data(ii,16);
                DP.Layers{ii}.tp =data.data(ii,17)*1e-7;   %  DP.layers thickness in cm
                DP.Layers{ii}.pp =data.data(ii,18)*1e-7;       % spacing for the layer in the middle in cm 
                DP.Layers{ii}.tinterL = data.data(ii,19)*1e-7;      % Interfacial region thickness
                DP.Layers{ii}.epointsL = data.data(ii,20)*1e-7;        % spacing for the region at the interface with the left layer
                DP.Layers{ii}.XiL =data.data(ii,21)*1e-7;            % thin region to replace the abrupt change in the layer properties with a linear change
                DP.Layers{ii}.XipL =data.data(ii,22)*1e-7;               % No. of points for electrode [for l
                DP.Layers{ii}.tinterR = data.data(ii,23)*1e-7;      % Interfacial region thickness
                DP.Layers{ii}.epointsR = data.data(ii,24)*1e-7;         % No. of points for electrode [for log mesh]
                DP.Layers{ii}.XiR =data.data(ii,25)*1e-7;            % Interfacial region thickness Heterojunction
                DP.Layers{ii}.XipR =data.data(ii,26)*1e-7; 
%                 DP.Layers{ii}.wr =data.data(ii,27)*1e-7;%ND/(ND+NA)*sqrt(2*eppp/q*Vbi*(1/ND));%50e-7;  %((-ti*NA*q) + ((NA^0.5)*(q^0.5)*(((ti^2)*NA*q) + (4*eppi*Vbi))^0.5))/(2*NA*q);
%                 DP.Layers{ii}.wl =data.data(ii,28)*1e-7;%ND/(ND+NA)*sqrt(2*eppp/q*Vbi*(1/ND));%50e-7;  %((-ti*NA*q) + ((NA^0.5)*(q^0.5)*(((ti^2)*NA*q) + (4*eppi*Vbi))^0.5))/(2*NA*q);
                DP.Layers{ii}.int=data.data(ii,29);
                DP.Layers{ii}.kdisexc=data.data(ii,30);
                DP.Layers{ii}.kdis=data.data(ii,31);
                DP.Layers{ii}.kfor=data.data(ii,32);
                DP.Layers{ii}.krec=data.data(ii,33);
                DP.Layers{ii}.kforEx=data.data(ii,34);
                DP.Layers{ii}.krecexc=data.data(ii,35);
            end
        end
        function DP=UpdateLayers(DP)
            % Cache kBT for performance
            kBT = DP.physical_const.kBT;
            
            for ii=1:1:DP.layers_num
                DP.Layers{ii}.PhiC = DP.Layers{ii}.EA -DP.Layers{ii}.PhiCV;       %n doping
                DP.Layers{ii}.PhiA = DP.Layers{ii}.IP + DP.Layers{ii}.PhiAV;     % p doping
                
                DP.Layers{ii}.Eg = DP.Layers{ii}.EA-DP.Layers{ii}.IP;                      % Band Gap
                if  DP.Experiment_prop.mobset == 0
                    
                    DP.Layers{ii}.mue = 0;     % electron mobility
                    DP.Layers{ii}.mup = 0;     % hole mobility
                else
                    DP.Layers{ii}.mue = DP.Layers{ii}.muee;     % electron mobility
                    DP.Layers{ii}.mup = DP.Layers{ii}.mupp;     % hole mobility
                end
                % Doping concentration and band bending
                DP.Layers{ii}.ni    = sqrt(DP.Layers{ii}.N0C*DP.Layers{ii}.N0V)*(exp(-DP.Layers{ii}.Eg/(2*kBT)));          % Intrinsic carrier density
                
                DP.Layers{ii}.n0 = DP.Layers{ii}.ni;   % Background density electrons in etl/n-type
                DP.Layers{ii}.p0 = DP.Layers{ii}.ni;     % Background density holes in etl/n-type
                DP.Layers{ii}.c0 =DP.Layers{ii}.n0*1e-1 ;
                DP.Layers{ii}.Phi=0;
                DP.Layers{ii}.ND = 0;%obj.Layers.layer{i}.N0C*exp((obj.Layers.layer{i}.PhiC-obj.Layers.layer{i}.EA)/(obj.Layers.kB*obj.Layers.T));
                DP.Layers{ii}.NA = 0;%obj.Layers.layer{i}.N0V*exp((obj.Layers.layer{i}.IP-obj.Layers.layer{i}.PhiA)/(obj.Layers.kB*obj.Layers.T));
                if (DP.Layers{ii}.PhiCV>0)
                    DP.Layers{ii}.n0 = DP.Layers{ii}.N0C*exp((DP.Layers{ii}.PhiC-DP.Layers{ii}.EA)/kBT);     % Background density electrons in etl/n-type
                    DP.Layers{ii}.p0 = DP.Layers{ii}.N0V*exp((DP.Layers{ii}.IP-DP.Layers{ii}.PhiC)/kBT);     % Background density holes in etl/n-type
                    DP.Layers{ii}.c0 =DP.Layers{ii}.p0*1e-1  ;
                    DP.Layers{ii}.Phi=DP.Layers{ii}.PhiC;
                    DP.Layers{ii}.ND = DP.Layers{ii}.N0C*exp((DP.Layers{ii}.PhiC-DP.Layers{ii}.EA)/kBT);
                    DP.Layers{ii}.NA = 0;%obj.Layers.layer{i}.N0V*exp((obj.Layers.layer{i}.IP-obj.Layers.layer{i}.PhiA)/(obj.Layers.kB*obj.Layers.T));
                elseif (DP.Layers{ii}.PhiAV>0)
                    DP.Layers{ii}.n0 = DP.Layers{ii}.N0C*exp((DP.Layers{ii}.PhiA-DP.Layers{ii}.EA)/kBT);     % Background density electrons in etl/n-type
                    DP.Layers{ii}.p0 = DP.Layers{ii}.N0V*exp((DP.Layers{ii}.IP-DP.Layers{ii}.PhiA)/kBT);     % Background density holes in etl/n-type
                    DP.Layers{ii}.c0 =DP.Layers{ii}.n0*1e-1 ;
                    DP.Layers{ii}.Phi=DP.Layers{ii}.PhiA;
                    DP.Layers{ii}.ND = 0;%obj.Layers.layer{i}.N0C*exp((obj.Layers.layer{i}.PhiC-obj.Layers.layer{i}.EA)/(obj.Layers.kB*obj.Layers.T));
                    DP.Layers{ii}.NA = DP.Layers{ii}.N0V*exp((DP.Layers{ii}.IP-DP.Layers{ii}.PhiA)/kBT);
                else
                    
                    DP.Layers{ii}.n0 = DP.Layers{ii}.ni;   % Background density electrons in etl/n-type
                    DP.Layers{ii}.p0 = DP.Layers{ii}.ni;     % Background density holes in etl/n-type
                    DP.Layers{ii}.c0 =DP.Layers{ii}.n0*1e-1 ;
                    DP.Layers{ii}.Phi=0;
                    DP.Layers{ii}.ND = 0;%obj.Layers.layer{i}.N0C*exp((obj.Layers.layer{i}.PhiC-obj.Layers.layer{i}.EA)/(obj.Layers.kB*obj.Layers.T));
                    DP.Layers{ii}.NA = 0;%obj.Layers.layer{i}.N0V*exp((obj.Layers.layer{i}.IP-obj.Layers.layer{i}.PhiA)/(obj.Layers.kB*obj.Layers.T));
                end
                % Intrinsic Fermi Energy
                DP.Layers{ii}.Ei = 0.5*((DP.Layers{ii}.EA+DP.Layers{ii}.IP));
                % Traps properties
%                 DP.Layers{ii}.nt =  DP.Layers{ii}.ni*exp(( DP.Layers{ii}.Ete- DP.Layers{ii}.Ei)/kBT);     % Density of CB electrons when Fermi level at trap state energy
%                 DP.Layers{ii}.pt =  DP.Layers{ii}.ni*exp(( DP.Layers{ii}.Ei- DP.Layers{ii}.Eth)/kBT);     % Density of VB holes when Fermi level at trap state energy
%                 DP.Layers{ii}.en=1/DP.Layers{ii}.NTA/DP.Layers{ii}.taun*DP.Layers{ii}.nt;
%                 DP.Layers{ii}.Cn=1/DP.Layers{ii}.NTA/DP.Layers{ii}.taun;
%                 DP.Layers{ii}.ep=1/DP.Layers{ii}.NTD/DP.Layers{ii}.taup*DP.Layers{ii}.pt;
%                 DP.Layers{ii}.Cp=1/DP.Layers{ii}.NTD/DP.Layers{ii}.taup;
                %density of CT and Exciton at equilibrium
                DP.Layers{ii}.CT0=DP.Layers{ii}.ni *DP.Layers{ii}.ni *DP.Layers{ii}.kfor/DP.Layers{ii}.kdis;
                DP.Layers{ii}.Ex0=DP.Layers{ii}.CT0*DP.Layers{ii}.kforEx/DP.Layers{ii}.kdisexc;

                %%%%%%%%%%%%heterojunction section
                if(ii>1)
                    DP.Layers{ii}.DEAL=(DP.Layers{ii}.EA-DP.Layers{ii-1}.EA)/2/DP.Layers{ii}.XiL;
                    DP.Layers{ii}.DIPL=(DP.Layers{ii}.IP-DP.Layers{ii-1}.IP)/2/DP.Layers{ii}.XiL;
                    DP.Layers{ii}.DN0CL=(log(DP.Layers{ii}.N0C/DP.Layers{ii-1}.N0C))/2/DP.Layers{ii}.XiL;
                    DP.Layers{ii}.DN0VL=(log(DP.Layers{ii}.N0V/DP.Layers{ii-1}.N0V))/2/DP.Layers{ii}.XiL;
                    
                end
                if(ii<DP.layers_num)
                    DP.Layers{ii}.DEAR=(DP.Layers{ii+1}.EA-DP.Layers{ii}.EA)/2/DP.Layers{ii}.XiR;
                    DP.Layers{ii}.DIPR=(DP.Layers{ii+1}.IP-DP.Layers{ii}.IP)/2/DP.Layers{ii}.XiR;
                    DP.Layers{ii}.DN0CR=(log(DP.Layers{ii+1}.N0C/DP.Layers{ii}.N0C))/2/DP.Layers{ii}.XiR;
                    DP.Layers{ii}.DN0VR=(log(DP.Layers{ii+1}.N0V/DP.Layers{ii}.N0V))/2/DP.Layers{ii}.XiR;
                end
                
            end
            if(DP.layers_num==1)
                DP.Experiment_prop.Vbi=2;
                DP.Layers{1}.n0 = DP.Layers{1}.N0C*exp(-0.1/kBT);     % Background density electrons in etl/n-type
                DP.Layers{1}.p0 = DP.Layers{1}.N0V*exp(-0.1/kBT);     % Background density holes in etl/n-type
                
            else
                DP.Experiment_prop.Vbi=DP.Layers{DP.layers_num}.Phi-DP.Layers{1}.Phi;
            end
        end
        function DP=update_time(DP)
            DP.Time_properties.t0 = DP.Time_properties.tmax/1000;
            if DP.Experiment_prop.BC==5
                DP.Time_properties.t0 = DP.Time_properties.tmax/1000;
            end
            if DP.pulse_properties.pulseon==1
                DP.Time_properties.t0 = DP.pulse_properties.pulselen/100;
            end
            DP=Timemesh(DP);
        end
        function DP=Timemesh(DP)           
            % Time mesh
            if DP.Time_properties.tmesh_type == 1
                DP.Time_properties.tmesh =  [linspace(0,DP.Time_properties.tmax,DP.Time_properties.tpoints)];
                DP.Time_properties.tmesh= abs(DP.Time_properties.tmesh);
                DP.solveropt.options = odeset('MaxOrder',5,'MaxStep',DP.Time_properties.t0*100,'InitialStep',DP.Time_properties.t0*10,'RelTol',DP.solveropt.RelTol,'AbsTol',DP.solveropt.AbsTol,'NonNegative',[1 1 1 0 1],'Stats','on') ;
                
            elseif DP.Time_properties.tmesh_type == 2
                if DP.pulse_properties.pulseon == 1 && DP.pulse_properties.tstart>DP.Time_properties.t0 && DP.pulse_properties.pulselen<DP.Time_properties.tmax
                    % Tweak solver options - limit maximum time step size during integration.
                    
                    DP.solveropt.options = odeset('MaxOrder',5,'MaxStep',DP.Time_properties.t0*1000,'InitialStep',DP.Time_properties.t0,'RelTol',DP.solveropt.RelTol,'AbsTol',DP.solveropt.AbsTol,'NonNegative',[1 1 1 0 1],'Stats','on') ;
                    
                    DP.Time_properties.tmesh = [logspace(log10(DP.Time_properties.t0),log10(DP.pulse_properties.tstart),DP.Time_properties.tpoints/20) - DP.Time_properties.t0...
                        ,logspace(log10(DP.pulse_properties.tstart+DP.Time_properties.t0/100),log10(2*DP.pulse_properties.tstart+DP.Time_properties.t0/100),DP.Time_properties.tpoints*9.5/20)-DP.Time_properties.t0,...
                        logspace(log10(2*DP.pulse_properties.tstart+2*DP.Time_properties.t0/100),log10(DP.Time_properties.tmax),DP.Time_properties.tpoints*9.5/20)-DP.Time_properties.t0];
                    
                else
                    DP.Time_properties.tmesh = logspace(log10(DP.Time_properties.t0),log10(DP.Time_properties.tmax),DP.Time_properties.tpoints) - DP.Time_properties.t0;
                    % Tweak solver options - limit maximum time step size during integration.
                    
                    DP.solveropt.options = odeset('MaxOrder',5,'MaxStep',DP.Time_properties.t0*10,'InitialStep',DP.Time_properties.t0,'RelTol',DP.solveropt.RelTol,'AbsTol',DP.solveropt.AbsTol,'NonNegative',[1 1 1 0 1],'Stats','on') ;
                end
            end

        end
        function DP=generationProfile(DP)
        % Generation

            if DP.light_properties.OM == 1 && DP.light_properties.Int ~= 0 %OM = Optical Model
                % Beer-Lambert - Currently requires solution in the workspace
                Gx1S = evalin('base', 'BL1Sun');                    % 1 Sun generation profile
                Gx1S = Gx1S';
                GxLas = evalin('base', 'BL638');
                GxLas = GxLas';

            elseif DP.light_properties.OM == 2 && DP.light_properties.Int ~= 0
                % Call Transfer Matrix code: [Gx1, Gx2] = TMPC1(layers, thicknesses, activeLayer1, activeLayer2)
                [Gx1S, GxLas] = TMPC1({'SiO2' 'P3HT' 'SiO2'}, [pp pii pn], 2, 2);
                Gx1S = Gx1S';
                GxLas = GxLas';

            end
        end
        function DP=update_boundary_charge_densities(DP)
            kBT = DP.physical_const.kBT;  % Use cached thermal energy
            DP.External_prop.nleft = DP.Layers{1}.N0C*exp((DP.External_prop.leftboundary_fermi_energy-DP.Layers{1}.EA)/kBT);     % Background density electrons in etl/n-type
            DP.External_prop.pleft = DP.Layers{1}.N0V*exp((-DP.External_prop.leftboundary_fermi_energy+DP.Layers{1}.IP)/kBT);     % Background density electrons in etl/n-type
            DP.External_prop.nright = DP.Layers{end}.N0C*exp((DP.External_prop.Rightboundary_fermi_energy-DP.Layers{end}.EA)/kBT);     % Background density electrons in etl/n-type
            DP.External_prop.pright = DP.Layers{end}.N0V*exp((-DP.External_prop.Rightboundary_fermi_energy+DP.Layers{end}.IP)/kBT);     % Background density electrons in etl/n-type
            
        end
        function DP=generateDeviceparams(DP,NC,activelayer,mobility,kdis,kdisex,Prec,varargin)
            %additional input are either Beff, the bimolecular reformation
            %rate constant, or the lifetime of the free charge carrier
            %either varargin={Beff,0} or {Tq,1}
            %             DP=pnParamsHCT;
            %input parameters
            DP.physical_const.T=Prec.const.T;
            DP.physical_const.kBT = DP.physical_const.kB * DP.physical_const.T;  % Update cached kBT when temperature changes
            tickness=DP.Layers{activelayer}.tp;%in cm
            kbT=DP.physical_const.kBT;  % Use cached kBT
            q=DP.physical_const.e;
            offsetLECT=Prec.params.Ex.DG0-Prec.params.CT.DG0;
            krecex=Prec.params.Ex.results.knr+Prec.params.Ex.results.krTot;
            krecCT=Prec.params.CT.results.knr+Prec.params.CT.results.krTot;
            RCTE=Prec.params.RCTE;
            CT0=Prec.results.R0rad/q/1e3/(Prec.params.CT.results.krTot+Prec.params.Ex.results.krTot*exp(-offsetLECT/kbT)/RCTE);

            %%%%%%%%%%%%estimated value
            %             ECS=Vocexp./idealityfactor+kbT*log(Beff_ref*(Tq1exp_ref./Tq1exp).^2)-kbT*log(idealityfactor.*Jsc./NC^2/tickness/q/1e3);%in eV
            %in cm-3s-1
            try
                switch  varargin{2}
                    case 0
%                         Beff=varargin{1};
                        kfor=varargin{1};
                        ni=sqrt(CT0*kdis/kfor);
                        ECS=2*kbT*log(NC/ni);
                    case 1
                        Tq1exp=varargin{1};
                        Beff_ref=1e-11;%in cm-3s-1
                        Tq1exp_ref=6e-7; %in s
                        Beff=Beff_ref.*(Tq1exp_ref./Tq1exp).^2;%%in cm-3s-1
                        kfor=Beff.*kdis./krecCT;%(mobility+mobility)/DP.Layers{2}.epp;%;kdis=krecCT*kfor/Beff;
                        ni=sqrt(CT0*kdis/kfor);
                        ECS=2*kbT*log(NC/ni);
                    case 2
                        ECS=varargin{1};
                        ni=NC*exp(-ECS/2/kbT);
                        kfor=(CT0*kdis/ni^2);
                    case 3
                        kfor=varargin{1};
                        Hab_CT_dis=varargin{3};
                        marcusrate=varargin{4};
                        L0_CT_dis=varargin{5};
                        offset_CTCS=0.3;
                        kdis=marcusrate(Hab_CT_dis,L0_CT_dis,offset_CTCS);
                        kdis0=kdis*10;
                        while kdis0~=kdis
                            kdis0=kdis;
                            ni=sqrt(CT0*kdis/kfor);
                            ECS=2*kbT*log(NC/ni);
                            offset_CTCS=Prec.params.CT.DG0-ECS;
                            kdis=marcusrate(Hab_CT_dis,L0_CT_dis,offset_CTCS);
                        end
                    case 4
                        ECS=varargin{1};
                        Hab_CT_dis=varargin{3};
                        marcusrate=varargin{5};
                        L0_CT_dis=varargin{4};
                        Hab_LE_dis=varargin{6};
                        L0_LE_dis=varargin{7};
                        offset_CTCS=Prec.params.CT.DG0-ECS;
                        kdis=marcusrate(Hab_CT_dis,L0_CT_dis,offset_CTCS);
                        kdisex=marcusrate(Hab_LE_dis,L0_LE_dis,offsetLECT);
                        ni=NC*exp(-ECS/2/kbT);
                        kfor=(CT0*kdis/ni^2);
                              
                end
                
              
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                kforEx=kdisex.*exp(-offsetLECT/kbT)/Prec.params.RCTE;
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                DP.Layers{2}.krec=krecCT;%1e9;%krecm(jj);
                DP.Layers{2}.kdis=kdis;%3.4e10;
                DP.Layers{2}.kfor=kfor;%3.3e-9;%kbieff(kk)*p.layer{1, 2}.kdis/p.layer{2}.krec;
                DP.Layers{2}.kdisexc=kdisex;
                DP.Layers{2}.muee=mobility;%mueM(mm);
                DP.Layers{2}.mupp=mobility;%mueM(mm);
                DP.Layers{2}.IP=-ECS;
                DP.Layers{1}.IP=-ECS;
                DP.Layers{3}.IP=-ECS;
                DP.Layers{2}.krecexc=krecex;
                DP.Layers{2}.kforEx=kforEx;
                DP.Layers{2}.N0V=NC;
                DP.Layers{1}.N0V=NC;
                DP.Layers{3}.N0V=NC;
                DP.Layers{2}.N0C=NC;
                DP.Layers{1}.N0C=NC;
                DP.Layers{3}.N0C=NC;
                DP.Layers{2}.N0V=NC;
                DP.Layers{1}.N0V=NC;
                DP.Layers{3}.N0V=NC;
                DP.Layers{2}.r0=0; %R0 for field dependence is 1 nm

                DP.Experiment_prop.discretetrap=0;
                DP=UpdateLayers(DP);
                DP = Xgrid(DP);
                DP=update_time(DP);
                DP=Timemesh(DP);
                DP.results.J0 = CT0*tickness*q*1e3 * (Prec.params.CT.results.knr + (Prec.params.Ex.results.knr) * exp(-offsetLECT/kbT) / Prec.params.RCTE) + Prec.results.J0rad;
                DP.results.DVnr = -kbT*log(Prec.results.J0rad / DP.results.J0);
                DP.results.Voc = Prec.results.Vocrad - DP.results.DVnr;
                DP.results.Vocrad=Prec.results.Vocrad;
                DP.light_properties.Genstrength  =Prec.results.Jscrad/tickness/q/1e3;%for uniform generation in cm-3 one sun equivalent
                if DP.light_properties.OM == 2
                    DP=Transfer_matrix_generation_profile(DP);
                end
                DP.External_prop.leftboundary_fermi_energy=DP.Layers{1}.Phi;
                DP.External_prop.Rightboundary_fermi_energy=DP.Layers{end}.Phi;
                DP=update_boundary_charge_densities(DP);
            catch ME
                disp(" check that you provided varargin={Beff,0} or {Tq,1}");

                rethrow(ME)
                
            end

        end
        function DP=Transfer_matrix_generation_profile(DP)
            %need to check that the name of the Nk file corresponds to the
            %name of the device here
            name='PBDB-T_ITIC';
            activelayer=2;
            Lightintensity=DP.light_properties.Int;
            tickness=DP.Layers{activelayer}.tp*1e7;%in nm
            [Xpos,Gx]=TransferMatrix_generation(tickness,name,Lightintensity);
            
            DP.light_properties.Gensprofile_pos=Xpos*1e-7+DP.Layers{activelayer}.XL;
            DP.light_properties.Gensprofile_signal=Gx;
        end
        function Dudt=kineticmodel(DP,activelayer,u,Gen_ex,Gen_CT,Ginj)
            kk=activelayer;
            Dudt=[DP.Layers{kk}.kdis*(u(3))- DP.Layers{kk}.kfor*((u(1)*u(2)))+Ginj;
                DP.Layers{kk}.kdis*(u(3))- DP.Layers{kk}.kfor*((u(1)*u(2)))+Ginj;
                Gen_CT+DP.Layers{kk}.kdisexc*(u(4))+DP.Layers{kk}.kfor*((u(1)*u(2)))-(DP.Layers{kk}.kdis*u(3)+DP.Layers{kk}.krec*(u(3)-DP.Layers{kk}.CT0))-DP.Layers{kk}.kforEx*(u(3));
                Gen_ex-DP.Layers{kk}.kdisexc*(u(4))-DP.Layers{kk}.krecexc*(u(4)-DP.Layers{kk}.Ex0)+DP.Layers{kk}.kforEx*(u(3));];%abs
        end
        function [t,y]=solveKineticmodel(DP,Gen_ex,Gen_CT,Ginj)
            kk=2;
            tspan = [0 5];
            u0 = [DP.Layers{kk}.ni,DP.Layers{kk}.ni,DP.Layers{kk}.CT0,DP.Layers{kk}.Ex0];
%             Gen_ex=Gen;
%             Gen_CT=0;
            [t,y] = ode15s(@(t,u) kineticmodel(DP,kk,u,Gen_ex,Gen_CT,Ginj), tspan, u0);

        end
        function [X,Y]=simulateTAS(DP,G,Gpulse,fighandle)
            kk=2;
            tspan = [0 1e-1];
            u0 = [DP.Layers{kk}.ni,DP.Layers{kk}.ni,DP.Layers{kk}.CT0,DP.Layers{kk}.Ex0];            
            [t,yeq] = ode15s(@(t,u) kineticmodel(DP,kk,u,G,0,0), tspan, u0);
            tspan = [0 0.2e-12];
            u0 = yeq(end,:);
            [t,y] = ode15s(@(t,u) kineticmodel(DP,kk,u,G+Gpulse,0,0), tspan, u0);
            tspan = [0 10E-9];
            u0 = y(end,:);
            [t,y] = ode15s(@(t,u) kineticmodel(DP,kk,u,G,0,0), tspan, u0);
            figure(fighandle)
%             subplot(2,2,4)
%             semilogx(t*1e12,(y-yeq(end,:))./max(y-yeq(end,:)),'-o')
           
            semilogx(t*1e12,(y(:,1)+y(:,3)-yeq(end,1)-yeq(end,3))./max((y(:,1)+y(:,3)-yeq(end,1)-yeq(end,3))),'-o',"DisplayName","GSB model");
             hold on
            time=logspace(-2,4,100);
            X=time;
            %             Y=(y(:,1)+y(:,3)-yeq(end,1)-yeq(end,3))./max((y(:,1)+y(:,3)-yeq(end,1)-yeq(end,3)));
            Y=interp1(t*1e12,(y(:,1)+y(:,3)-yeq(end,1)-yeq(end,3))./max((y(:,1)+y(:,3)-yeq(end,1)-yeq(end,3))),time);
            
            xlim([1 max(tspan*1e12)])
            xlabel("Time [units?]")
            ylabel("TAS (?)")
            legend

        end
        function [X,Y,Z]=simulate_EL(DP,Prec,fighandle)
            [t,y]=solveKineticmodel(DP,0,0,1e25);
            CTsum=y(end,3);
            Exsum=y(end,4);
            
            krE=Prec.params.CT.results.krE*CTsum+Prec.params.Ex.results.krE*Exsum;
            figure(fighandle)
            subplot(3,1,3)
            semilogy(Prec.const.Edistribution,krE/max(krE),'DisplayName',"Total",'Color',[1,0,0],'LineWidth',2)
            hold on
            semilogy(Prec.const.Edistribution,Prec.params.CT.results.krE*CTsum/max(krE),'--','DisplayName',"CT contribution",'Color',[1, 0.66, 0.59])
            semilogy(Prec.const.Edistribution,Prec.params.Ex.results.krE*Exsum/max(krE),'DisplayName',"Ex contribution",'Color',[1, 0.66, 0.59])
            X=(Prec.const.Edistribution)';
            Y=(krE/max(krE))';
            Z=(Prec.params.CT.results.krE*CTsum/max(krE))';
            
            xlabel('Energy [eV]')
            ylabel('El Emission  [a.u]')
            ylim([1*1e-4, 1])
            xlim([0.5,2])
            legend
            
        end
        function [X,Y,Z]=simulate_EL_notnorm(DP,Prec,label)
            [t,y]=solveKineticmodel(DP,0,1e20);
            CTsum=y(end,3);
            Exsum=y(end,4);
            
            krE=Prec.params.CT.results.krE*CTsum+Prec.params.Ex.results.krE*Exsum;
            semilogy(Prec.const.Edistribution,krE,"DisplayName",label);
            hold on

            X=(Prec.const.Edistribution)';
            Y=(krE/max(krE))';
            Z=(Prec.params.CT.results.krE*CTsum/max(krE))';
            
            xlabel('Energy [eV]')
            ylabel('El Emission  [a.u]')
            ylim([max(krE)*1e-3, max(krE)])            
        end
        function simulate_EL_explore_norm(DP,Prec,fighandle,legendname)
            [t,y]=solveKineticmodel(DP,0,1e20);
            CTsum=y(end,3);
            Exsum=y(end,4);
            
            krE=Prec.params.CT.results.krE*CTsum+Prec.params.Ex.results.krE*Exsum;
            figure(fighandle)
            subplot(1,2,2)
            semilogy(Prec.const.Edistribution,krE/max(krE),"DisplayName",legendname)
            hold on
%             semilogy(Prec.const.Edistribution,Prec.params.CT.results.krE*CTsum/max(krE))
%             semilogy(Prec.const.Edistribution,Prec.params.Ex.results.krE*Exsum/max(krE))
%             
            xlabel('Energy [eV]')
            ylabel('El Emission  [a.u]')
            ylim([1*1e-2, 1])
            xlim([1,2])
            
        end
        function simulate_EL_explore(DP,Prec,fighandle,legendname)
            [t,y]=solveKineticmodel(DP,0,1e20);
            CTsum=y(end,3);
            Exsum=y(end,4);
            
            krE=Prec.params.CT.results.krE*CTsum+Prec.params.Ex.results.krE*Exsum;
            figure(fighandle)
            subplot(2,2,3)
            semilogy(Prec.const.Edistribution,krE,"DisplayName",legendname)
            hold on
%             semilogy(Prec.const.Edistribution,Prec.params.CT.results.krE*CTsum/max(krE))
%             semilogy(Prec.const.Edistribution,Prec.params.Ex.results.krE*Exsum/max(krE))
%             
            xlabel('Energy [eV]')
            ylabel('El Emission  [a.u]')
%             ylim([1*1e-2, 1])
            xlim([1,2])
            
        end
        function simulate_PL_explore(DP,Prec,fighandle,legendname)
            [t,y]=solveKineticmodel(DP,1e25,0);
            CTsum=y(end,3);
            Exsum=y(end,4);
            
            krE=Prec.params.CT.results.krE*CTsum+Prec.params.Ex.results.krE*Exsum;
            figure(fighandle)
            subplot(2,2,2)
            semilogy(Prec.const.Edistribution,krE,"DisplayName",legendname)
            hold on
%             semilogy(Prec.const.Edistribution,Prec.params.CT.results.krE*CTsum/max(krE))
%             semilogy(Prec.const.Edistribution,Prec.params.Ex.results.krE*Exsum/max(krE))
%             
            xlabel('Energy [eV]')
            ylabel('Pl Emission  [a.u]')
%             ylim([1*1e-2, 1])
            xlim([1,2])            
        end
        function simulate_PL_explore_norm(DP,Prec,fighandle,legendname)
            [t,y]=solveKineticmodel(DP,1e25,0);
            CTsum=y(end,3);
            Exsum=y(end,4);
            
            krE=Prec.params.CT.results.krE*CTsum+Prec.params.Ex.results.krE*Exsum;
            figure(fighandle)
            subplot(1,2,1)
            semilogy(Prec.const.Edistribution,krE/max(krE),"DisplayName",legendname)
            hold on
%             semilogy(Prec.const.Edistribution,Prec.params.CT.results.krE*CTsum/max(krE))
%             semilogy(Prec.const.Edistribution,Prec.params.Ex.results.krE*Exsum/max(krE))
%             
            xlabel('Energy [eV]')
            ylabel('Pl Emission  [a.u]')
            ylim([1*1e-2, 1])
            xlim([1,2])            
        end
        function simulate_TCSPC(DP,Prec,Background_Ex_Gen_rate,Laser_Ex_gen_rate,laser_width,exp_length,legendname)
            %laser_width and exp_length in ns
            % 
            
            kk=2;% active layer number
            % Get the equilibrium solution first
            tspan = [0 1e-1];
            u0 = [DP.Layers{kk}.ni,DP.Layers{kk}.ni,DP.Layers{kk}.CT0,DP.Layers{kk}.Ex0];            
            [t,yeq] = ode15s(@(t,u) kineticmodel(DP,kk,u,Background_Ex_Gen_rate,0), tspan, u0);
            u0 = yeq(end,:);
            % run the solution with the laser on
            tspan_laser = [0 laser_width*1e-9];
            [t_Laser,y_Laser] = ode15s(@(t,u) kineticmodel(DP,kk,u,Background_Ex_Gen_rate+Laser_Ex_gen_rate,0), tspan_laser, u0);
            u0 = y_Laser(end,:);
            CTsum_Laser=y_Laser(:,3);
            Exsum_Laser=y_Laser(:,4);
            krE_Laser=Prec.params.CT.results.krE.*CTsum_Laser+Prec.params.Ex.results.krE.*Exsum_Laser;
            % run the solution after the laser pulse
            tspan = [0 exp_length*1e-9];           
            [t,y] = ode15s(@(t,u) kineticmodel(DP,kk,u,Background_Ex_Gen_rate,0), tspan, u0);
            CTsum=y(:,3);
            Exsum=y(:,4);
            krE=Prec.params.CT.results.krE.*CTsum+Prec.params.Ex.results.krE.*Exsum;
            [Maxlum,Peakpos]=max(krE');
            [Maxlum_Laser,Peakpos_Laser]=max(krE_Laser');
            ccdens_Laser=y_Laser(:,1);%/Laser_Ex_gen_rate/laser_width;     
            ccdens=y(:,1);%/Laser_Ex_gen_rate/laser_width;
            t=t_Laser(end)+t;
            
            time=[t_Laser*1e9;t*1e9];
%             figure
            subplot(2,3,1)
             title('normalised PL peak intensity')
            semilogy(time,[(Maxlum_Laser)./max(Maxlum_Laser),(Maxlum)./max(Maxlum)],"DisplayName",legendname)
            hold on
%             semilogy(t*1e9,(Maxlum)./max(Maxlum))
            xlabel('Time [ns]')
            ylabel('normalised TCPSC signal  [a.u]')
            ylim([1e-6 1])
                        legend()

            subplot(2,3,2)
            title('absolute PL peak intensity')
            semilogy(time,[(Maxlum_Laser),(Maxlum)],"DisplayName",legendname)
            hold on
%             semilogy(t*1e9,(Maxlum)./max(Maxlum))
            xlabel('Time [ns]')
            ylabel('TCPSC signal  [a.u]')
             ylim([Maxlum(end) 1.1*max(max([(Maxlum_Laser),(Maxlum)]))])
                         legend()

             
                        subplot(2,3,3)
            title('normalised PL against wavelength')
            colormap cool
            PL_emission=[krE_Laser;krE];
            for tt=logspace(0,log(max(time)*0.99)/log(10),6)
            semilogy(Prec.const.Edistribution,PL_emission(find(time>tt,1),:)/max(PL_emission(find(time>tt,1),:)),"DisplayName",[legendname ' @ ' num2str(tt,'%1.1e') ' ns'])
            hold on
            end
            hold off
%             semilogy(t*1e9,(Maxlum)./max(Maxlum))
            xlabel('energy in [eV]')
            ylabel('TCPSC signal  [a.u]')
            ylim([1e-4 1.1])
            legend()
%             ylim([1e-6 1])
            subplot(2,3,4)
                        title('PL peak  energy')

            semilogx(time,[Prec.const.Edistribution(Peakpos_Laser),Prec.const.Edistribution(Peakpos)],"DisplayName",legendname)
            hold on
%             semilogx(t*1e9,Prec.const.Edistribution(Peakpos))
            xlabel('Time [ns]')
            ylabel('Peak pos[eV]')
            xlim([1e-1 max(t*1e9)])
                        legend()

                        subplot(2,3,5)
                        title('charge carrier density evolution')
            semilogx(time,[ccdens_Laser;ccdens],"DisplayName",legendname)
            hold on 
%             semilogx(t*1e9,ccdens)
            xlim([1e-1 max(t*1e9)])
            xlabel('Time [ns]')
            ylabel('Charge carrier density  [a.u]')
                        legend()

            subplot(2,3,6)
            title('charge carrier density normalised per laser intensity')
            semilogx(time,[ccdens_Laser/Laser_Ex_gen_rate/laser_width;ccdens/Laser_Ex_gen_rate/laser_width],"DisplayName",legendname)
            hold on 
%             semilogx(t*1e9,ccdens)
            xlim([1e-1 max(t*1e9)])
            xlabel('Time [ns]')
            ylabel('Charge carrier density /pulse intensity [a.u]')
                        legend()
                        

        end
        function [time,PL_emission,wavelength]=simulate_TCSPC_wavelength(DP,Prec,Background_Ex_Gen_rate,Laser_Ex_gen_rate,laser_width,exp_length,legendname)
            %laser_width and exp_length in ns
            % 
            
            kk=2;% active layer number
            % Get the equilibrium solution first
            tspan = [0 1e-1];
            u0 = [DP.Layers{kk}.ni,DP.Layers{kk}.ni,DP.Layers{kk}.CT0,DP.Layers{kk}.Ex0];            
            [t,yeq] = ode15s(@(t,u) kineticmodel(DP,kk,u,Background_Ex_Gen_rate,0), tspan, u0);
            u0 = yeq(end,:);
            % run the solution with the laser on
            tspan_laser = [0 laser_width*1e-9];
            laser_ex_gen_func= @(t) Laser_Ex_gen_rate*exp(-t/1e-6);
            [t_Laser,y_Laser] = ode15s(@(t,u) kineticmodel(DP,kk,u,Background_Ex_Gen_rate+laser_ex_gen_func(t),0), tspan_laser, u0);
            u0 = y_Laser(end,:);
            CTsum_Laser=y_Laser(:,3);
            Exsum_Laser=y_Laser(:,4);
            krE_Laser=Prec.params.CT.results.krE.*CTsum_Laser+Prec.params.Ex.results.krE.*Exsum_Laser;
            % run the solution after the laser pulse
            tspan = [0 exp_length*1e-9];           
            [t,y] = ode15s(@(t,u) kineticmodel(DP,kk,u,Background_Ex_Gen_rate,0), tspan, u0);
            CTsum=y(:,3);
            Exsum=y(:,4);
            krE=Prec.params.CT.results.krE.*CTsum+Prec.params.Ex.results.krE.*Exsum;
            [Maxlum,Peakpos]=max(krE');
            [Maxlum_Laser,Peakpos_Laser]=max(krE_Laser');
            ccdens_Laser=y_Laser(:,1);%/Laser_Ex_gen_rate/laser_width;     
            ccdens=y(:,1);%/Laser_Ex_gen_rate/laser_width;
            t=t_Laser(end)+t;
            PL_emission=[krE_Laser;krE(2:end,:)];
            Enegy_distr=Prec.const.Edistribution;
            time=[t_Laser*1e9;t(2:end)*1e9];
%             figure
            subplot(1,3,1)
            title('PL intensity')
            for wavelength=900:500:1200
                energy=1240./wavelength;
                Ydata=PL_emission(:,find(Enegy_distr>energy,1));
            loglog(time,Ydata,"DisplayName",[num2str(wavelength) ' nm'])
                hold on
            end
            hold on
%             semilogy(t*1e9,(Maxlum)./max(Maxlum))
            xlabel('Time [ns]')
            ylabel('TCPSC signal  [a.u]')
            %              ylim([Maxlum(end) 1.1*max(max([(Maxlum_Laser),(Maxlum)]))])
            legend()
            subplot(1,3,2)
            title('PL intensity')
            for wavelength=900:500:1200
                energy=1240./wavelength;
                Ydata=PL_emission(:,find(Enegy_distr>energy,1));
                plot(time(time>50),Ydata(time>50)./max(Ydata(time>80)),"DisplayName",[num2str(wavelength) ' nm'])
                hold on
            end
            hold on
            %             semilogy(t*1e9,(Maxlum)./max(Maxlum))
            xlabel('Time [ns]')
            ylabel('TCPSC signal  [a.u]')
%              ylim([Maxlum(end) 1.1*max(max([(Maxlum_Laser),(Maxlum)]))])
                         legend()

               subplot(1,3,3)
            title('normalised PL against wavelength')
            colormap cool
            for tt=logspace(0,log(max(time)*0.99)/log(10),6)
            semilogy(1240./Prec.const.Edistribution,PL_emission(find(time>tt,1),:)/max(PL_emission(find(time>tt,1),:)),"DisplayName",[legendname ' @ ' num2str(tt,'%1.1e') ' ns'])
            hold on
            end
            hold off
%             semilogy(t*1e9,(Maxlum)./max(Maxlum))
            xlabel('wavelength in [nm]')
            ylabel('TCPSC signal  [a.u]')
            ylim([1e-4 1.1])
            legend()

        end
        function [time,PL_emission,wavelength]=simulate_TCSPC_gaussianlaserpulse(DP,Prec,Background_Ex_Gen_rate,Laser_Ex_gen_rate_gauss,Laser_Ex_gen_rate_exp,...
                gaussianwidth,exponentialdecay,laser_peak,exp_length,legendname)
            %laser_width and exp_length in ns
            % 
            
            kk=2;% active layer number
            % Get the equilibrium solution first
            tspan = [0 1e-1];
            u0 = [DP.Layers{kk}.ni,DP.Layers{kk}.ni,DP.Layers{kk}.CT0,DP.Layers{kk}.Ex0];            
            [t,yeq] = ode15s(@(t,u) kineticmodel(DP,kk,u,Background_Ex_Gen_rate,0), tspan, u0);
            u0 = yeq(end,:);
            % run the solution with the laser on
            tspan_laser = [0 exp_length*1e-9];
            laser_ex_gen_func= @(t) Laser_Ex_gen_rate_exp*exp(-t/exponentialdecay)+Laser_Ex_gen_rate_gauss*exp(-(t-laser_peak*1e-9).^2./(gaussianwidth*1e-9)^2);
            [t_Laser,y_Laser] = ode15s(@(t,u) kineticmodel(DP,kk,u,Background_Ex_Gen_rate+laser_ex_gen_func(t),0), tspan_laser, u0);
            u0 = y_Laser(end,:);
            CTsum_Laser=y_Laser(:,3);
            Exsum_Laser=y_Laser(:,4);
            krE_Laser=Prec.params.CT.results.krE.*CTsum_Laser+Prec.params.Ex.results.krE.*Exsum_Laser;
            % run the solution after the laser pulse
            [Maxlum_Laser,Peakpos_Laser]=max(krE_Laser');
            ccdens_Laser=y_Laser(:,1);%/Laser_Ex_gen_rate/laser_width;     
            PL_emission=[krE_Laser];
            Enegy_distr=Prec.const.Edistribution;
            time=[t_Laser*1e9];
%             figure
            subplot(1,3,1)
            title('PL intensity')
            for wavelength=900:500:1200
                energy=1240./wavelength;
                Ydata=PL_emission(:,find(Enegy_distr>energy,1));
            loglog(time,Ydata,"DisplayName",[num2str(wavelength) ' nm'])
                hold on
            end
            hold on
%             semilogy(t*1e9,(Maxlum)./max(Maxlum))
            xlabel('Time [ns]')
            ylabel('TCPSC signal  [a.u]')
            xlim([1e-1,exp_length])
            %              ylim([Maxlum(end) 1.1*max(max([(Maxlum_Laser),(Maxlum)]))])
            legend()
            subplot(1,3,2)
            title('PL intensity')
            for wavelength=900:500:1200
                energy=1240./wavelength;
                Ydata=PL_emission(:,find(Enegy_distr>energy,1));
                loglog(time,Ydata./max(Ydata),"DisplayName",[num2str(wavelength) ' nm'])
                hold on
            end
            hold on
            loglog(time,laser_ex_gen_func(time*1e-9)./max(laser_ex_gen_func(time*1e-9)),'*-',"DisplayName",'normalised laser pulse intensity')

            %             semilogy(t*1e9,(Maxlum)./max(Maxlum))
            xlabel('Time [ns]')
            ylabel('TCPSC signal normalised [a.u]')
                        xlim([1e-1,exp_length])

             ylim([1e-7 1.1])
                         legend()

               subplot(1,3,3)
            title('normalised PL against wavelength')
             clist = colormap(jet(6));
             jj=0;
            for tt=logspace(0,log(max(time)*0.99)/log(10),6)
                jj=jj+1;
            semilogy(1240./Prec.const.Edistribution,PL_emission(find(time>tt,1),:)/max(PL_emission(find(time>tt,1),:)),"DisplayName",[legendname ' @ ' num2str(tt,'%1.1e') ' ns']...
                ,'color',clist(jj,:,:))
            hold on
            end
            hold off
%             semilogy(t*1e9,(Maxlum)./max(Maxlum))
            xlabel('wavelength in [nm]')
            ylabel('TCPSC signal  [a.u]')
            ylim([1e-4 1.1])
            legend()

        end
        function [X,Y,Z]=simulate_PL(DP,Prec,fighandle)
            [t,y]=solveKineticmodel(DP,1e25,0,0);
            CTsum=y(end,3);
            Exsum=y(end,4);
            figure(fighandle)
            subplot(3,1,2)
            krE=Prec.params.CT.results.krE*CTsum+Prec.params.Ex.results.krE*Exsum;
            
            semilogy(Prec.const.Edistribution,krE/max(krE),'DisplayName',"Total contribution",'Color',[1,0,0],'LineWidth',2)
            hold on
            semilogy(Prec.const.Edistribution,Prec.params.CT.results.krE*CTsum/max(krE),'--','DisplayName',"CT contribution",'Color',[1, 0.66, 0.59])
            semilogy(Prec.const.Edistribution,Prec.params.Ex.results.krE*Exsum/max(krE),'DisplayName',"Ex contribution",'Color',[1, 0.66, 0.59])
            X=(Prec.const.Edistribution)';
            Y=(krE/max(krE))';
            Z=(Prec.params.CT.results.krE*CTsum/max(krE))';
            xlabel('Energy [eV]')
            ylabel('PL Emission  [a.u]')
            ylim([1*1e-4, 1])
            xlim([0.5,2])
            legend
            
        end
        function res=simulateTASfit(DP,time,G,Gpulse,kdisCT,kdisEx,varargin)
            kk=2;
            DP.Layers{kk}.kdis=kdisCT;
            DP.Layers{kk}.kdisexc=kdisEx;
            if nargin>=7
                DP.Layers{kk}.krec=varargin{1};
            end
            DP=UpdateLayers(DP);
            tspan = [0 1e-1];
            u0 = [DP.Layers{kk}.ni,DP.Layers{kk}.ni,DP.Layers{kk}.CT0,DP.Layers{kk}.Ex0];
            [t,yeq] = ode15s(@(t,u) kineticmodel(DP,kk,u,G,0), tspan, u0);
            tspan = [0 0.2e-12];
            u0 = yeq(end,:);
            [t,y] = ode15s(@(t,u) kineticmodel(DP,kk,u,G+Gpulse,0), tspan, u0);
            tspan = [0 10e-9];
            u0 = y(end,:);
            [t,y] = ode15s(@(t,u) kineticmodel(DP,kk,u,G,0), tspan, u0);
            res=interp1(t*1e12,(y(:,1)+y(:,3)-yeq(end,1)-yeq(end,3))./max((y(:,1)+y(:,3)-yeq(end,1)-yeq(end,3))),time);
        end
        function [fitresult, gof] = FitTASdata(DP,expdata,G,Gpulse,varargin)
            %CREATEFIT(DATAX,DATAY)
            % Fit: 'untitled fit 1'.
            time=logspace(0,4,1000)-1;
            datay=(expdata.TAS(:,2)-min(expdata.TAS(:,2)))/max(smooth(expdata.TAS(:,2),5)-min(expdata.TAS(:,2)));
            signal=interp1(expdata.TAS(:,1),datay,time);
            [xData, yData] = prepareCurveData( time, signal );
            % Set up fittype and options.
%             G=2e10;
%             Gpulse=1e25;
            if nargin==4
                
                ft = fittype( @(kdisCT,kdisEx,x) DP.simulateTASfit(x,G,Gpulse,10^(kdisCT),10^(kdisEx)) );
                opts = fitoptions( 'Method', 'NonlinearLeastSquares' );
                opts.Display = 'iter';
                varrnumber=2;
                opts.Lower = 7*ones(1,varrnumber);
                opts.StartPoint = 9*ones(1,varrnumber);
                opts.Upper = 13*ones(1,varrnumber);
            else
                ft = fittype( @(kdisCT,kdisEx,krecCT,x) DP.simulateTASfit(x,G,Gpulse,10^(kdisCT),10^(kdisEx),10^(krecCT)) );
                opts = fitoptions( 'Method', 'NonlinearLeastSquares' );
                opts.Display = 'iter';
                varrnumber=3;
                opts.Lower = 7*ones(1,varrnumber);
                opts.StartPoint = 9*ones(1,varrnumber);
                opts.Upper = 13*ones(1,varrnumber);
            end
            % Fit model to data.
            [fitresult, gof] = fit( xData, yData, ft, opts );
            
            
            % Plot fit with data.
%             figure( 'Name', 'untitled fit 1' );
            h = plot(fitresult, xData, yData );%fitresult,
            legend( h, 'datay vs. datax', 'untitled fit 1', 'Location', 'NorthEast' );
            % Label axes
            title('TAS fitting')
            axis([0.1 6000 0 1.1])
            xlabel('TIme / ps')
            ylabel('Normalised signal /A.U')
            set(gca, 'XScale', 'log')
            legend('boxoff')
            hold off
        end
        function resultssum=PPPCequation(DP,G,Gpump,pppcfactordis,pppcfactorform,pppcfactorexcdis,pppcfactorexcref)

            kk=2;%active layer
            timpulsepoints=logspace(-0.5,3,30)*1e-12;
            laserlength=0.3e-12;
            t_0=1000e-12;
            tspan = [0 1e-1];
            tmax=2e-8;
            u0 = [DP.Layers{kk}.ni,DP.Layers{kk}.ni,DP.Layers{kk}.CT0,DP.Layers{kk}.Ex0];
            [t,yeq] = ode15s(@(t,u) kineticmodel(DP,kk,u,G,0), tspan, u0);
            for timepusleid=1:1:length(timpulsepoints)
                timepusle=timpulsepoints(timepusleid);
                timebefore=logspace(-13,log(timepusle)/log(10),30);
                during=logspace(log(timepusle)/log(10),log(timepusle+laserlength)/log(10),30);
                timeafter=logspace(log(timepusle+laserlength)/log(10),log(tmax)/log(10),30);
                
                time=[timebefore,during(2:end),timeafter(2:end)];
                tspan = [0 1e-12];
                u0 = yeq(end,:);
                [t,y] = ode15s(@(t,u) kineticmodel(DP,kk,u,G+Gpump,0), tspan, u0);
                u0 = y(end,:);
                tspan = time;

                [t,resultsafterpumpall] = ode15s(@(t,u) kineticmodel(DP,kk,u,G,0), tspan, u0);
                
                [t,resultsbefore] = ode15s(@(t,u) kineticmodel(DP,kk,u,G,0), timebefore, u0);
                u0=resultsbefore(end,:);
                
                DP_during=DP;
                pppcfactorform_tpulse=max(pppcfactorform*(t_0-timepusle)/t_0,0);
                DP_during.Layers{kk}.kdisexc=(DP.Layers{kk}.kdisexc*(1+pppcfactorexcdis));
                DP_during.Layers{kk}.kforEx=DP.Layers{kk}.kforEx*(1+pppcfactorexcref);
                DP_during.Layers{kk}.kdis=(DP.Layers{kk}.kdis*(1+pppcfactordis));
                DP_during.Layers{kk}.kfor=(DP.Layers{kk}.kfor*exp(pppcfactorform_tpulse));
                [t,resultsduringpulse] = ode15s(@(t,u) kineticmodel(DP_during,kk,u,G,0), during, u0);
                u0=resultsduringpulse(end,:);
                [t,resultsafterpulse] = ode15s(@(t,u) kineticmodel(DP,kk,u,G,0), timeafter, u0);
                
                ncSpush=resultsafterpulse(end,1);%sum(resultsafterpulse.CS)+sum(resultsduringpulse.CS)+sum(resultsbefore.CS);
                
                ppcsignal(timepusleid)=(ncSpush-resultsafterpumpall(end,1));
                if timepusleid==1
                disp(num2str(DP_during.Layers{kk}.kforEx))
                end
            end
            
            resultssum.normsignal=ppcsignal/max(abs(ppcsignal));
            % ppcsignal(:,2)=ppcsignal(:,2);
            resultssum.signal=ppcsignal;
            resultssum.time=timpulsepoints;
            resultssum.CG_nopulse=resultsafterpumpall(end,1);
            
            
            figure(30)
           
            semilogx(timpulsepoints,resultssum.signal./resultssum.CG_nopulse,'*')
             hold on
             xlim([1e-13,1e-9])
%                    figure(31)
%            
%             semilogx(timpulsepoints,resultssum.normsignal,'*')
%              hold on
%              xlim([1e-12,1e-9])
            % delete(gcp('nocreate'))
              
    end
end
end

