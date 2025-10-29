function solstruct = pndriftHCT(varargin)
localtime = cputime;
% Look up pdepe solver
% Requires v2struct toolbox for unpacking parameters structure
% IMPORTANT! Currently uses parameters from pnParamsH - all variables must be
% declared in pnDrift (line 52)

% A routine to test solving the diffusion and drift equations using the
% matlab pde solver. This version defines electrons as u1 and holes as u2,
% and ions as u3. u4 is the electric potential.
%
% Piers Barnes last modified (09/01/2016)
% Phil Calado last modified (07/07/2016)

% This version allows a previous solution to be used as the input
% conditions. If there is no input argument asssume default flat background
% condtions. If there is one argument, assume it is the previous solution
% to be used as the initial conditions. If there are two input arguments,
% assume that first are the x points from the previous solution, and the
% second is the previous solution.

% set(0,'DefaultLineLinewidth',2);
% set(0,'DefaultAxesFontSize',24);
% set(0,'DefaultFigurePosition', [600, 400, 640, 400]);

if isempty(varargin)
    params = pnParamsHCT;                         % Calls Function EParams and stores in sturcture 'params'
    xmesh = params.Xgrid_properties;
    
elseif length(varargin) == 1
    % Call input parameters function
    icsol = varargin{1, 1}.sol;
    xmesh = varargin{1, 1}.x;
    params = pnParamsHCT;                         % Calls Function EParams and stores in sturcture 'params'
elseif length(varargin) == 2
    if varargin{1, 1}.sol == 0
        params = varargin{2};
        xmesh = params.Xgrid_properties;
    else
        icsol = varargin{1, 1}.sol;
        xmesh = varargin{1, 1}.x;
        params = varargin{2};
    end
    
end

% define solution mesh either logarithmically or linearly spaced points
% Define the x points to give the initial

icx = xmesh;
% genspace = linspace(0,tn+tp,pii);


xmax=max(xmesh);
%% Voltage function
Vapp_fun = fun_gen(params.Experiment_prop.V_fun_type);

% Call solver - inputs with '@' are function handles to the subfunctions
% below for the: equation, initial conditions, boundary conditions
sol = pdepe(params.solveropt.m,@pdex4pde,@pdex4ic,@pdex4bc,xmesh,params.Time_properties.tmesh,params.solveropt.options);

% assignin('base', 'sol', sol);
SizesSol=size(sol);
solstruct.params = params;  solstruct.tspan=params.Time_properties.tmesh ;solstruct.x = xmesh; solstruct.t = params.Time_properties.tmesh(1:SizesSol(1));solstruct.sol = sol;
% solstruct = DriftanalyseCT(solstruct);
% solstruct.timespent=timespent;
% assignin('base', 'sol', solstruct);
% if params.Experiment_prop.figson==1
%     driftplotCT(solstruct);
% end
% % --------------------------------------------------------------------------
% Set up partial differential equation (pdepe) (see MATLAB pdepe help for details of c, f, and s)
    function [c,f,s] = pdex4pde(x,t,u,DuDx)
        sim=0;
        kBT=params.physical_const.kBT;
        q=params.physical_const.q;
        if params.Experiment_prop.symm==1
            if x>=xmax/2
                x=xmax -x;
                sim=1;
                if(x<0)
                    x=0;
                end
            end
        end
        
        % Find which layer contains position x
        kk = find_layer_index(x, params);
        
        % Calculate generation rate
        g = calc_generation_rate(x, t, params, params.Layers{kk});
        % Prefactors set to 1 for time dependent components - can add other
        % functions if you want to include the multiple trappng model
        c = [1
            1
            1
            0
            1];
        
        f = [  (params.Layers{kk}.mue*((u(1))*-DuDx(4)+kBT*DuDx(1)));
            (params.Layers{kk}.mup*((u(2))*DuDx(4)+kBT*DuDx(2)));
            0;
            DuDx(4);
            0;];
        if(x<params.Layers{kk}.XL+params.Layers{kk}.XiL && kk>1 && x>params.Layers{kk}.XL)
            f = [(params.Layers{kk}.mue*((u(1))*(-DuDx(4)+((-1)^sim)*params.Layers{kk}.DEAL-((-1)^sim)*params.Layers{kk}.DN0CL*kBT)+kBT*DuDx(1)));
                (params.Layers{kk}.mup*((u(2))*(DuDx(4)-((-1)^sim)*params.Layers{kk}.DIPL-((-1)^sim)*params.Layers{kk}.DN0VL*kBT)+kBT*DuDx(2)));
                0;
                DuDx(4);
                0;];
        end
        if(x>params.Layers{kk}.XR-params.Layers{kk}.XiR && kk<params.layers_num && x<params.Layers{kk}.XR )
            
            f = [(params.Layers{kk}.mue*((u(1))*(-DuDx(4)+((-1)^sim)*params.Layers{kk}.DEAR-((-1)^sim)*params.Layers{kk}.DN0CR*kBT)+kBT*DuDx(1)));
                (params.Layers{kk}.mup*((u(2))*(DuDx(4)-((-1)^sim)*params.Layers{kk}.DIPR-((-1)^sim)*params.Layers{kk}.DN0VR*kBT)+kBT*DuDx(2)));
                0;
                DuDx(4);
                0;];
            
        end
        % Calculate field-dependent dissociation rates
        if isfield(params.Layers{kk},'r0_Ex')
            r0_Ex=params.Layers{kk}.r0_Ex;%start with r0=3nm
            kdisexc = calc_field_dependent_rate(params.Layers{kk}.kdisexc, q, DuDx(4), r0_Ex, kB, T);
        else
            r0_Ex=0;
            kdisexc = params.Layers{kk}.kdisexc;
        end
        if isfield(params.Layers{kk},'r0_CT')
            r0_CT=params.Layers{kk}.r0_CT;%start with r0=3nm
            kdis = calc_field_dependent_rate(params.Layers{kk}.kdis, q, DuDx(4), r0_CT, kB, T);
        else
            r0_CT=0;
            kdis = params.Layers{kk}.kdis;
        end
        s = [kdis*u(3)- params.Layers{kk}.kfor*((u(1)*u(2)));%try to add field dependence in the form kdis=kdis0*exp(q*dudx(4)*r0/(kB*T)); 
            kdis*u(3)- params.Layers{kk}.kfor*((u(1)*u(2)));%start with r0=3nm
            kdisexc*(u(5))+params.Layers{kk}.kfor*((u(1)*u(2)))-(kdis*u(3)+params.Layers{kk}.krec*(u(3)-params.Layers{kk}.CT0))-params.Layers{kk}.kforEx*(u(3));
            (q/params.Layers{kk}.epp)*(-u(1)+u(2)-params.Layers{kk}.NA+params.Layers{kk}.ND);
            g-kdisexc*(u(5))-params.Layers{kk}.krecexc*(u(5)-params.Layers{kk}.Ex0)+params.Layers{kk}.kforEx*(u(3));];%abs
%         if x>1.5e-5
%             pause(0.1)
%         end 
        
        if params.Experiment_prop.equilibrium==1
        c = [0
            0
            0
            0
            0];
        end
        
        
    end
% --------------------------------------------------------------------------

% Define initial conditions.
    function u0 = pdex4ic(x)
        % Find which layer contains position x
        ii = find_layer_index(x, params);
        if length(varargin) == 0 | varargin{1, 1}.sol == 0
            
            u0 = [params.Layers{ii}.n0;
                params.Layers{ii}.p0;
                params.Layers{ii}.CT0;
                (x/xmax)*params.Experiment_prop.Vbi;
                params.Layers{ii}.Ex0;];
        elseif length(varargin) == 1
            % insert previous solution and interpolate the x points
            Vapp0=varargin{1, 1}.params.Vapp;
            u0 = [abs(interp1(icx,icsol(end,:,1),x));
                abs(interp1(icx,icsol(end,:,2),x));
                abs(interp1(icx,icsol(end,:,3),x));
                interp1(icx,icsol(end,:,4),x);
                abs(interp1(icx,icsol(end,:,5),x));];
        elseif   max(max(max(varargin{1, 1}.sol))) ~= 0
            % insert previous solution and interpolate the x points
            u0 = [  abs(interp1(icx,icsol(end,:,1),x));
                abs(interp1(icx,icsol(end,:,2),x));
                abs( interp1(icx,icsol(end,:,3),x));
                interp1(icx,icsol(end,:,4),x);
                abs( interp1(icx,icsol(end,:,5),x));];
        end
    end

% --------------------------------------------------------------------------

% --------------------------------------------------------------------------

% Define boundary condtions, refer pdepe help for the precise meaning of p
% and you l and r refer to left and right.
% in this example I am controlling the flux through the boundaries using
% the difference in concentration from equilibrium and the extraction
% coefficient.
    function [pl,ql,pr,qr] = pdex4bc(xl,ul,xr,ur,t)
        switch params.Experiment_prop.V_fun_type
            case 'constant'
                Vapp = params.Experiment_prop.V_fun_arg(1);
            otherwise
                Vapp = Vapp_fun(params.Experiment_prop.V_fun_arg, t);
        end
%                 disp("time"+num2str(t)+"Vapp "+num2str(Vapp));

        % Zero current
        switch params.Experiment_prop.BC
            case 0
                pl = [0;0;0;-ul(4);0;];
                
                ql = [1;1;1;0;1;];
                
                pr = [0;0;0;-ur(4)+params.Experiment_prop.Vbi-Vapp;0;];
                
                qr = [1;1;1;0;1;];
            case 1
                
                % Fixed charge at the boundaries- contact in equilibrium with etl and htl
                pl = [0;(ul(2)- params.Layers{1}.p0); 0;-ul(4);0;];
                ql = [1;0;1;0;1;];
                
                pr = [(ur(1)-params.Layers{layers}.n0);0;0;-ur(4)+params.Experiment_prop.Vbi-Vapp;0;];
                
                qr = [0;1;1;0;1;];
                
                % Non- selective contacts - equivalent to infinite surface recombination
                % velocity for minority carriers
            case 2
                pl = [(ul(1)- params.Layers{1}.n0);(ul(2)-params.Layers{1}.p0); 0;-ul(4);0;];
                ql = [0;0;1;0;1;];
                
                pr = [(ur(1)- params.Layers{end}.n0);(ur(2)-params.Layers{end}.p0);0;
                    -ur(4)+params.Experiment_prop.Vbi-Vapp;0;];
                
                qr = [0;0;1;0;1;];
                
                  % finitee surface recombination and series resitance
                % velocity for minority carriers
            case 3
                % Calculate series resistance voltage Vres
                if params.External_prop.Rseries == 0
                    Vres = 0;
                else
                    J = params.physical_const.e*(params.External_prop.sp_r*(ur(2)-params.External_prop.pright) ...
                        -params.External_prop.sn_r*(ur(1)- params.External_prop.nright));
                    
                    Vres = -J*params.External_prop.Rseries;
                    
                end
                
                pl = [-params.External_prop.sn_l*(ul(1)- params.External_prop.nleft);-params.External_prop.sp_l*(ul(2)-params.External_prop.pleft); 0;-ul(4);0;];
                ql = [1;1;1;0;1;];
                
                pr = [params.External_prop.sn_r*(ur(1)- params.External_prop.nright );params.External_prop.sp_r*(ur(2)-params.External_prop.pright );0;
                    -ur(4)+params.Experiment_prop.Vbi-Vapp-Vres;0;];
                
                qr = [1;1;1;0;1;];
                % Open Circuit. Problem - doesn't give zero field at the rh boundary even
                % though it should
            case  4
                pl = [ul(1)-params.Layers{1}.n0;ul(2)-params.Layers{1}.p0;
                    0;
                    ul(4);
                    0;];
                
                ql = [0;
                    0;
                    1;
                    0;
                    1;];
                
                pr = [ur(1) - params.Layers{1}.n0;
                    ur(2) - params.Layers{1}.p0;
                    0;
                    ur(4);
                    0;];
                
                qr = [0;
                    0;
                    1;
                    0;
                    1;];
                
                
        end
        
    end

end


