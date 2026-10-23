classdef device
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
        function DV=device(DP,varargin)%run solution at equilibrium
            if length(varargin)==1
                DV.sol_eq=varargin{1};
            else
                DV.sol_eq=EquilibratePNHCT(0,DP);
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
            DV.sol_eq=pndriftHCT(DV.sol_eq,DP);
            DV.DP=DP;
        end
        
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
            device.say(p,'Getting JSC')
            DV.sol_Jsc=device.appendsol(DV.sol_Jsc,pndriftHCT(DV.sol_eq,p));
        end
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
  
                device.say(p,'Doing JV')
                DV.sol_JV=device.appendsol(DV.sol_JV,pndriftHCT(DV.sol_eq,p));
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
                        device.say(p,'Doing JV')
                        DV.sol_JV=device.appendsol(DV.sol_JV,pndriftHCT(sol_Jsc,p));
                    else
                        warning('device:missingSolution','get the Jsc first')
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
            p.Time_properties.tmax=1e-5;
            p=update_time(p);
            device.say(p,'Getting equilibrium for Symmetric model 1 ')
            ssol_eq=pndriftHCT(ssol_eq,p);
            p.Time_properties.tmax=1e-3;
            p=update_time(p);
            device.say(p,'Getting equilibrium for Symmetric model 2 ')
            DV.ssol_Voc=device.appendsol(DV.ssol_Voc,pndriftHCT(ssol_eq,p));
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
                    device.say(p,'Doing TPV ')
                    DV.ssol_TPV=device.appendsol(DV.ssol_TPV,pndriftHCT(ssol_Voc,p));
                else
                    warning('device:missingSolution','get the Voc first')
                    
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
                    device.say(p,'Doing TAS ')
                    DV.ssol_TAS=device.appendsol(DV.ssol_TAS,pndriftHCT(ssol_Voc,p));
                else
                    warning('device:missingSolution','get the Voc first')
                end
            end
        end
        function say(p,msg)
            % Progress message, unless p.solveropt.verbose is false
            if ~isfield(p.solveropt,'verbose') || p.solveropt.verbose
                disp(msg)
            end
        end
        function sols=appendsol(sols,sol)
            % Store a new solution, or append it to the earlier ones
            if isequal(sols,0) || isempty(sols)
                sols=sol;
            else
                sols=[sols,sol];
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
                    p.Time_properties.tmax=1e-5;
                    p.Time_properties.tmesh_type=1;
                    p.Experiment_prop.V_fun_type = 'square_sweep';
                    p.Experiment_prop.V_fun_arg(1) = V;
                    p.Experiment_prop.V_fun_arg(2) = Vstep+V;
                    p.Experiment_prop.V_fun_arg(3) = 1e-4;
                    p.Experiment_prop.V_fun_arg(4) = pulse_length;%length of pulse in us
                    p.Experiment_prop.V_fun_arg(5) = 1e-8;
                    p=update_time(p);
                    device.say(p,'Doing simulation')
                    finalpoint=find(dfana.calcVapp(sol_JV)>V,1);
                    vapp=dfana.calcVapp(sol_JV);
                    if  max(vapp>V)==1
                    p.Experiment_prop.V_fun_arg(1) = vapp(finalpoint);
                    
                    p.Experiment_prop.V_fun_arg(2) = Vstep+vapp(finalpoint);
                    p=update_time(p);
                    sol_JV.sol=sol_JV.sol(finalpoint,:,:);
                    DV.sol_Vpulse=device.appendsol(DV.sol_Vpulse,pndriftHCT(sol_JV,p));
                    Success=1;
                    break; 
                    end
                end
            end
            if  Success==0
                 warning('device:missingSolution','get the JV at the right light intensity first and up to the right voltage')
            end
        end
    end
end