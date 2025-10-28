classdef device_forMarcus
    properties
        DP%device params
        Prec%parameter related to CT and Ex recombination
        sol_eq% equilibrium solution
        sol_Jsc=0;
        sol_JV=0;
        ssol_Voc=0;
        ssol_TPV=0;
        ssol_TAS=0;
        sol_Vpulse=0;
        
        % Configurable simulation time properties (magic numbers replaced)
        sim_time_Voc_eq1 = 1e-2;        % Time for Voc equilibration step 1 [s]
        sim_time_Voc_eq2 = 1e-2;        % Time for Voc equilibration step 2 [s]
        sim_time_TPV = 5e-5;            % Time for TPV simulation [s]
        sim_pulse_len_TPV = 2e-6;       % TPV pulse length [s]
        sim_pulse_start_TPV = 1e-6;     % TPV pulse start time [s]
        sim_time_TAS = 10e-9;           % Time for TAS simulation [s]
        sim_pulse_len_TAS = 2e-13;      % TAS pulse length [s]
        sim_pulse_start_TAS = 1e-12;    % TAS pulse start time [s]
        sim_pulse_int_TAS = 500;        % TAS pulse intensity multiplier
    end
    methods(Static)
        function DV=device_forMarcus(DP,varargin)%run solution at equilibrium
            if length(varargin)==1 %will ==1 when there is input after DP. There is no input in the example_workflow.
                DV.sol_eq=varargin{1};
            else
                DV.sol_eq=EquilibratePNHCT_forMarcus(0,DP); %applied voltage is 0
            end
            DP.light_properties.Int=0;
            DP.Experiment_prop.V_fun_type = 'constant';
            DP.Experiment_prop.V_fun_arg(1) = 0;
            DP.Experiment_prop.Vtransient=0;
            DP.Experiment_prop.wAC=0;
            DP.Experiment_prop.symm=0;
            DP.Experiment_prop.pulseon=0;
            DP.Time_properties.tmax=1e-2;
            DP.Time_properties.tmesh_type = 2;
            DP=UpdateLayers(DP);
            DP = Xgrid(DP);
            DP=update_time(DP);
            DP=Timemesh(DP);
            % p.discretetrap=1;
            DV.sol_eq=pndriftHCT_forMarcus(DV.sol_eq,DP);
            DV.DP=DP;
        end
%%%%%%%%use pndriftHCT_forMarcus to get Jsc          
        function DV=runsolJsc(DV,Gen,varargin)
            
            if nargin==3
                p=varargin{1};
            else
                p=DV.sol_eq.params;
                
            end
            p.light_properties.Int=Gen;%multiplied by Params.Genstrength
            p.Time_properties.tmesh_type = 2;
            p.Time_properties.tpoints = 1000;
            p=update_time(p);
            p=Timemesh(p);
            if p.light_properties.OM == 2
                p=Transfer_matrix_generation_profile(p);
            end
            %%%%%%%%%%%%%%%%%%%%%%
            disp('Getting JSC')
            DV.sol_Jsc = device_forMarcus.storeSolution(DV.sol_Jsc, pndriftHCT_forMarcus(DV.sol_eq,p));
        end
%%%%%%%%use pndriftHCT_forMarcus to get JV curve      
        function DV=runsolJV(DV,Gen,Vstart,Vend)
            
            %%%%%%%%%%%%%%%%%%%%%%
            if Gen==0
                p=DV.sol_eq.params;
                %%%%%%%%%%%%%%%%%%%Do JV%%%%%%%%%%%%%%
                p.solveropt.AbsTol=1e-6;
                p.solveropt.RelTol=1e-3;
                p.Time_properties.tmax=1e0;
                p.Time_properties.tmesh_type=1;
                p.Experiment_prop.V_fun_type = 'sweep';
                p.Experiment_prop.V_fun_arg(1) = Vstart;
                p.Experiment_prop.V_fun_arg(2) = Vend;
                p.Experiment_prop.V_fun_arg(3) = p.Time_properties.tmax;
                p=update_time(p);
  
                disp('Doing JV')
                DV.sol_JV = device_forMarcus.storeSolution(DV.sol_JV, pndriftHCT_forMarcus(DV.sol_eq,p));
            else
                for sol_Jsc = DV.sol_Jsc
                    if Gen==sol_Jsc.params.light_properties.Int
                        p=sol_Jsc.params;
                        %%%%%%%%%%%%%%%%%%%Do JV%%%%%%%%%%%%%%
                        p.solveropt.AbsTol=1e-6;
                        p.solveropt.RelTol=1e-3;
                        p.Time_properties.tmax=1e-1;
                        p.Experiment_prop.V_fun_type = 'sweep';
                        p.Experiment_prop.V_fun_arg(1) = Vstart;
                        p.Experiment_prop.V_fun_arg(2) = Vend;
                        p.Experiment_prop.V_fun_arg(3) = p.Time_properties.tmax;
                        p=update_time(p);
                        disp('Doing JV')
                        DV.sol_JV = device_forMarcus.storeSolution(DV.sol_JV, pndriftHCT_forMarcus(sol_Jsc,p));
                    else
                        disp('get the Jsc first')
                    end
                end
            end
            %%%%%%%%%%%%%%%%%%%%%%
        end
        function DV=runsolVoc(DV,Gen)
            ssol_eq=symmetricize(DV.sol_eq);
            p=DV.sol_eq.params;
            p.Experiment_prop.symm=1;
            p.Experiment_prop.pulseon=0;
            p.light_properties.Int=Gen;
            p.Experiment_prop.BC=4;
            p.Time_properties.tmax=DV.sim_time_Voc_eq1;  % Use configurable property
            p=update_time(p);
            disp('Getting equilibrium for Symmetric model 1 ')
            ssol_eq=pndriftHCT_forMarcus(ssol_eq,p);
            p.Time_properties.tmax=DV.sim_time_Voc_eq2;  % Use configurable property
            p=update_time(p);
            disp('Getting equilibrium for Symmetric model 2 ')
            DV.ssol_Voc = device_forMarcus.storeSolution(DV.ssol_Voc, pndriftHCT_forMarcus(ssol_eq,p));
            % % % % % % % %
        end
        function DV=runsolTPV(DV,Gen)
            for ssol_Voc = DV.ssol_Voc
                if Gen==ssol_Voc.params.light_properties.Int
                    p=ssol_Voc.params;
                    p.pulse_properties.pulseon=1;
                    p.Time_properties.tmax = DV.sim_time_TPV;           % Use configurable property
                    p.pulse_properties.pulselen = DV.sim_pulse_len_TPV;  % Use configurable property
                    p.pulse_properties.tstart = DV.sim_pulse_start_TPV;  % Use configurable property
                    p.pulse_properties.pulseint =2*Gen;
                    p.Time_properties.tpoints = 1000;
                    p=update_time(p);
                    disp('Doing TPV ')
                    DV.ssol_TPV = device_forMarcus.storeSolution(DV.ssol_TPV, pndriftHCT_forMarcus(ssol_Voc,p));
                else
                    disp('get the Voc first')
                    
                end
                %         reslts{kk}.TPV.Voc=ssol_T.Voc;
                %         reslts{kk}.TPV.t=ssol_T.t;
                %         reslts{kk}.TPV.nce=ssol_T.rhoctot;
                %         reslts{kk}.TPV.nCTtot=ssol_T.nCTtot;
                %         reslts{kk}.TPV.Extot=ssol_T.Extot;
            end
        end
        function DV=runsolTAS(DV,Gen)
            for ssol_Voc = DV.ssol_Voc
                if Gen==ssol_Voc.params.light_properties.Int
                    p=ssol_Voc.params;
                    p.pulse_properties.pulseon=1;
                    p.Time_properties.tmax = DV.sim_time_TAS;           % Use configurable property
                    p.pulse_properties.pulselen = DV.sim_pulse_len_TAS;  % Use configurable property
                    p.pulse_properties.tstart = DV.sim_pulse_start_TAS;  % Use configurable property
                    p.pulse_properties.pulseint = DV.sim_pulse_int_TAS;  % Use configurable property
                    p.Time_properties.tpoints = 1000;
                    p=update_time(p);
                    disp('Doing TAS ')
                    DV.ssol_TAS = device_forMarcus.storeSolution(DV.ssol_TAS, pndriftHCT_forMarcus(ssol_Voc,p));
                else
                    disp('get the Voc first')
                end
            end
        end
        function DV=current_transient(DV,Gen,V,Vstep,pulse_length)
            %%%%%%%%%%%%%%%%%%%%%%
            Success=0;
            for sol_JV= DV.sol_JV
                if Gen==sol_JV.params.light_properties.Int
                    p=sol_JV.params;
                    %%%%%%%%%%%%%%%%%%%apply voltage pulse%%%%%%%%%%%%%%
                    p.solveropt.AbsTol=1e-6;
                    p.solveropt.RelTol=1e-3;
                    p.Time_properties.tmax=1e-2;
                    p.Time_properties.tmesh_type=1;
                    p.Experiment_prop.V_fun_type = 'square_sweep';
                    p.Experiment_prop.V_fun_arg(1) = V;
                    p.Experiment_prop.V_fun_arg(2) = Vstep+V;
                    p.Experiment_prop.V_fun_arg(3) = 1e-4;%-4
                    p.Experiment_prop.V_fun_arg(4) = pulse_length;%length of pulse in us
                    p.Experiment_prop.V_fun_arg(5) = 1e-8;
                    p=update_time(p);
                    disp('Doing simulation')
                    finalpoint=find(dfana.calcVapp(sol_JV)>V,1);
                    vapp=dfana.calcVapp(sol_JV);
                    if  max(vapp>V)==1
                    p.Experiment_prop.V_fun_arg(1) = vapp(finalpoint);
                    
                    p.Experiment_prop.V_fun_arg(2) = Vstep+vapp(finalpoint);
                    p=update_time(p);
                    sol_JV.sol=sol_JV.sol(finalpoint,:,:);
                    DV.sol_Vpulse = device_forMarcus.storeSolution(DV.sol_Vpulse, pndriftHCT_forMarcus(sol_JV,p));
                    Success=1;
                    break; 
                    end
                end
            end
            if  Success==0
                 disp('get the JV at the right light intensity first and up to the right voltage')
            end
        end
    end
    methods(Static, Access=private)
        % Helper method to consolidate repeated try-catch pattern for storing solutions
        function result = storeSolution(existingSolution, newSolution)
            % Consolidates the repeated pattern of checking if solution exists
            % and either initializing or appending to solution array
            try
                existingSolution == 0;  % Check if initialized
                result = newSolution;
            catch
                result = [existingSolution, newSolution];
            end
        end
    end
end