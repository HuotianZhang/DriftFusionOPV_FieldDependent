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
            try
                DV.sol_Jsc==0;
                DV.sol_Jsc=pndriftHCT_forMarcus(DV.sol_eq,p);
            catch
                DV.sol_Jsc=[DV.sol_Jsc,pndriftHCT_forMarcus(DV.sol_eq,p)];
            end
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
                try
                    DV.sol_JV==0;
                    DV.sol_JV=pndriftHCT_forMarcus(DV.sol_eq,p);
                catch
                    DV.sol_JV=[DV.sol_JV,pndriftHCT_forMarcus(DV.sol_eq,p)];
                end
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
                        try
                            DV.sol_JV==0;
                            DV.sol_JV=pndriftHCT_forMarcus(sol_Jsc,p);
                        catch
                            DV.sol_JV=[DV.sol_JV,pndriftHCT_forMarcus(sol_Jsc,p)];
                        end
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
            p.Time_properties.tmax=1e-2;%-5
            p=update_time(p);
            disp('Getting equilibrium for Symmetric model 1 ')
            ssol_eq=pndriftHCT_forMarcus(ssol_eq,p);
            p.Time_properties.tmax=1e-2;%-3
            p=update_time(p);
            disp('Getting equilibrium for Symmetric model 2 ')
            try
                DV.ssol_Voc==0;
                DV.ssol_Voc=pndriftHCT_forMarcus(ssol_eq,p);
                
            catch
                DV.ssol_Voc=[DV.ssol_Voc,pndriftHCT_forMarcus(ssol_eq,p)];
            end
            % % % % % % % %
        end
        function DV=runsolTPV(DV,Gen)
            for ssol_Voc = DV.ssol_Voc
                if Gen==ssol_Voc.params.light_properties.Int
                    p=ssol_Voc.params;
                    p.pulse_properties.pulseon=1;
                    p.Time_properties.tmax = 5e-5;        % Time
                    p.pulse_properties.pulselen = 2e-6;
                    p.pulse_properties.tstart=1e-6;
                    p.pulse_properties.pulseint =2*Gen;
                    p.Time_properties.tpoints = 1000;
                    p=update_time(p);
                    disp('Doing TPV ')
                    try
                        DV.ssol_TPV==0;
                        DV.ssol_TPV=pndriftHCT_forMarcus(ssol_Voc,p);
                    catch
                        DV.ssol_TPV=[DV.ssol_TPV,pndriftHCT_forMarcus(ssol_Voc,p)];
                        
                    end
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
                    p.Time_properties.tmax = 10e-9;        % Time
                    p.pulse_properties.pulselen = 2e-13;
                    p.pulse_properties.tstart=1e-12;
                    p.pulse_properties.pulseint =500;
                    p.Time_properties.tpoints = 1000;
                    p=update_time(p);
                    disp('Doing TAS ')
                    try
                        DV.ssol_TAS==0;
                        DV.ssol_TAS=pndriftHCT_forMarcus(ssol_Voc,p);
                    catch
                        DV.ssol_TAS=[DV.ssol_TAS,pndriftHCT_forMarcus(ssol_Voc,p)];
                        
                    end
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
                    try
                        DV.sol_Vpulse==0;
                        DV.sol_Vpulse=pndriftHCT_forMarcus(sol_JV,p);
                    catch
                        DV.sol_Vpulse=[DV.sol_Vpulse,pndriftHCT_forMarcus(sol_JV,p)];
                    end
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
end