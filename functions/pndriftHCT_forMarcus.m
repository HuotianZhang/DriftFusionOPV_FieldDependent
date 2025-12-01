function solstruct = pndriftHCT_forMarcus(varargin)
localtime = cputime;
% Look up pdepe solver
% Requires v2struct toolbox for unpacking parameters structure
% IMPORTANT! Currently uses parameters from pnParamsHCT - all variables must be
% declared in pdex4pde (line ~ 80)
%
% A routine to test solving the diffusion and drift equations using the
% matlab pde solver. 
%
% This version defines 
% u1    electrons
% u2    holes
% u3    charge transfer states
% u4    electric potential
% u5    exciton
%
% Piers Barnes last modified (09/01/2016)
% Phil Calado last modified (07/07/2016)
% Huotian Zhang last modified (09/10/2023)
% Huotian Zhang last modified (04/11/2024)
% Huotian Zhang last modified (23/07/2025)
% This version allows a previous solution to be used as the input
% conditions. If there is no input argument asssume default flat background
% condtions. If there is one argument, assume it is the previous solution
% to be used as the initial conditions. If there are two input arguments,
% assume that first are the x points from the previous solution, and the
% second is the previous solution.
%
% set(0,'DefaultLineLinewidth',2);
% set(0,'DefaultAxesFontSize',24);
% set(0,'DefaultFigurePosition', [600, 400, 640, 400]);


% Fit the data to a low-degree polynomial (e.g., degree 2 or 3)
% degree = 2;  % Adjust degree based on data complexity
% p_coeffs = polyfit(E_values, k_values, degree);

if isempty(varargin)
    params = pnParamsHCT;                         % Calls Function EParams and stores in sturcture 'params'
    xmesh = params.Xgrid_properties;
    
elseif length(varargin) == 1
    % Call input parameters function
    icsol = varargin{1, 1}.sol;
    xmesh = varargin{1, 1}.x;
    params = pnParamsHCT;                         % Calls Function EParams and stores in sturcture 'params'
elseif length(varargin) == 2
    if varargin{1, 1}.sol == 0                      %varargin{1} is DV.sol_eq  
        params = varargin{2};                       %varargin{2} is DV.sol_eq.params
        xmesh = params.Xgrid_properties;
    else
        icsol = varargin{1, 1}.sol;                 %initial condition calculated from 'deviceparams' - '
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
% sol = pdepe(m(symmetry constant),pdefun(main function),icfun(initial condition),bcfun(boundary condition),xmesh (spatial mesh),tspan) solves a system of parabolic and elliptic PDEs with one spatial variable x and time t. At least one equation must be parabolic. The scalar m represents the symmetry of the problem (slab, cylindrical, or spherical). The equations being solved are coded in pdefun, the initial value is coded in icfun, and the boundary conditions are coded in bcfun. The ordinary differential equations (ODEs) resulting from discretization in space are integrated to obtain approximate solutions at the times specified in tspan. The pdepe function returns values of the solution on a mesh provided in xmesh.
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
        kB=params.physical_const.kB;
        T=params.physical_const.T;
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
        
        for kk=1:1:params.layers_num
            if(x<=params.Layers{kk}.XR && x>=params.Layers{kk}.XL )
                break;
            end
        end

%%%%%%%%%% This is the beginning of g. g should be the generation rate
        %if side == 1
        % Uniform Generation
                % OM = Optical Model
                % 0 = Uniform Generation
                % 1 = Beer-Lamber (Requires pre calculation using Igor code & gen profile in base workspace)
                % 2 = Transfer Matrix (Stanford)

        if params.light_properties.OM == 0% 0 = Uniform Generation
            if params.light_properties.Int ~= 0
                g = params.light_properties.Int*params.light_properties.Genstrength ;
            else
                g = 0;
            end
            % Add pulse
            if params.pulse_properties.pulseon == 1
                if  t >= params.pulse_properties.tstart && t < params.pulse_properties.pulselen + params.pulse_properties.tstart %&& x<=params.Layers{kk}.XL+4*params.Layers{kk}.tinterR
                    g = g+params.pulse_properties.pulseint*params.light_properties.Genstrength ;
                end
            end
        elseif params.light_properties.OM == 2 % 2 = Transfer Matrix (Stanford)
            if params.Layers{kk}.int ~= 0 && params.light_properties.Int ~= 0
                g = interp1(params.light_properties.Gensprofile_pos,params.light_properties.Gensprofile_signal,x) ;
                if isnan(g)
                    g=0;
                end
            else
                g = 0;
            end
            % Add pulse  % kept similar to a uniform pulse 
            if params.pulse_properties.pulseon == 1
                if  t >= params.pulse_properties.tstart && t < params.pulse_properties.pulselen + params.pulse_properties.tstart %&& x<=params.Layers{kk}.XL+4*params.Layers{kk}.tinterR
                    g = g+params.pulse_properties.pulseint*params.light_properties.Genstrength ;
                end
            end
        else % 1 = Beer-Lamber (Requires pre calculation using Igor code & gen profile in base workspace)
            g = 0;
            
        end
        
        if params.Layers{kk}.int==0
            g=0;
        end
%%%%%%%%%% This is the end of g

        % Prefactors set to 1 for time dependent components - can add other
        % functions if you want to include the multiple trappng model
        c = [1 %dn/dt
            1  %dp/dt
            1  %dCT/dt
            0  %dV/dt
            1];%dLE/dt
 
%%%%%%%%%% This is the beginning of f
        f = [  (params.Layers{kk}.mue*((u(1))*(-DuDx(4))+kB*T*DuDx(1))); %*d/dx n
            (params.Layers{kk}.mup*((u(2))*DuDx(4)+kB*T*DuDx(2)));     %*d/dx p
            0;                                                         %*d/dx CT
            DuDx(4);                                                   %*d/dx V (V/cm)
            0;];                                                       %*d/dx LE
        if(x<params.Layers{kk}.XL+params.Layers{kk}.XiL && kk>1 && x>params.Layers{kk}.XL)
            f = [(params.Layers{kk}.mue*((u(1))*(-DuDx(4)+((-1)^sim)*params.Layers{kk}.DEAL-((-1)^sim)*params.Layers{kk}.DN0CL*kB*T)+kB*T*DuDx(1)));
                (params.Layers{kk}.mup*((u(2))*(DuDx(4)-((-1)^sim)*params.Layers{kk}.DIPL-((-1)^sim)*params.Layers{kk}.DN0VL*kB*T)+kB*T*DuDx(2)));
                0;
                DuDx(4);
                0;];
        end
        if(x>params.Layers{kk}.XR-params.Layers{kk}.XiR && kk<params.layers_num && x<params.Layers{kk}.XR )
            
            f = [(params.Layers{kk}.mue*((u(1))*(-DuDx(4)+((-1)^sim)*params.Layers{kk}.DEAR-((-1)^sim)*params.Layers{kk}.DN0CR*kB*T)+kB*T*DuDx(1)));
                (params.Layers{kk}.mup*((u(2))*(DuDx(4)-((-1)^sim)*params.Layers{kk}.DIPR-((-1)^sim)*params.Layers{kk}.DN0VR*kB*T)+kB*T*DuDx(2)));
                0;
                DuDx(4);
                0;];
            
        end
%%%%%%%%%% This is the end of f

%%%%%%%%%% This is the beginning of s
        
        % switch params.Experiment_prop.V_fun_type
        %     case 'constant'
        %         Vapp = params.Experiment_prop.V_fun_arg(1);
        %     otherwise
        %         Vapp = Vapp_fun(params.Experiment_prop.V_fun_arg, t);
        % end
        %E_field = abs(Vapp-params.Experiment_prop.Vbi)/1e-7;%1e-7 original params.Layers{3}.XR=1.9e-5
        E_field = abs(DuDx(4))/1e-2;%1e-7 original params.Layers{3}.XR=1.9e-5

        if isfield(params.Layers{kk},'r0_Ex') %% if there is r0_Ex, use it to calculate field dependence of exciton dissociation
            r0_Ex=params.Layers{kk}.r0_Ex;
            % kdisexc=params.Layers{kk}.kdisexc*exp(q*abs(DuDx(4))*r0_Ex/(kB*T));
            %kdisexc=params.Layers{kk}.kdisexc*exp(q*abs(DuDx(4))*r0_Ex/(kB*T));
            interpolated_k = interp1(params.physical_const.E_values, params.physical_const.k_values, E_field, 'linear', 'extrap');
            interpolated_k_bak = interp1(params.physical_const.E_values, params.physical_const.k_bak_values, E_field, 'linear', 'extrap');
        else
            r0_Ex=0;
            interpolated_k=1;
            interpolated_k_bak=1;
        end

        if isfield(params.Layers{kk},'r0_CT')%% if there is r0_Ex
            % , use it to calculate field dependence of CT dissociation
            r0_CT=params.Layers{kk}.r0_CT;%start with r0=3nm
        else
            r0_CT=0;
        end

        % if isfield(params.Layers{kk},'offset')%% if there is offset, use it to calculate field dependence of exciton dissociation
        % % else
        % % end
        % 
        % % 
        % % 
        % % 
        % % Interpolate to find the corresponding k value
        %     % offset=params.Layers{kk}.offset;
        %     % E_internal = offset*1e9;%5e7;
        %     % k_equi_factor = Integrate_k(E_field, E_internal);%calculate Braun factor (sphere internal field and one direction external field)
        %     %kdis=params.Layers{kk}.kdis*exp(q*abs(Vapp-params.Experiment_prop.Vbi)/params.Layers{3}.XR*r0_CT/(kB*T)); %try to add field dependence in the form kdis=kdis0*exp(q*dudx(4)*r0/(kB*T)). If r0 = 0, kdis = kdis0.
        %     %kdisexc=params.Layers{kk}.kdisexc*exp(q*abs(Vapp-params.Experiment_prop.Vbi)/params.Layers{3}.XR*r0_Ex/(kB*T));
        %     kdisexc=params.Layers{kk}.kdisexc*k_equi_factor;
        % else
        %     kdisexc=params.Layers{kk}.kdisexc;
        %     % kdis=params.Layers{kk}.kdis*exp(q*abs(Vapp-params.Experiment_prop.Vbi)/params.Layers{3}.XR*r0_CT/(kB*T)); %try to add field dependence in the form kdis=kdis0*exp(q*dudx(4)*r0/(kB*T)). If r0 = 0, kdis = kdis0.
        
        kdisexc=params.Layers{kk}.kdisexc*(1-r0_Ex)+interpolated_k*r0_Ex;%polyval(p_coeffs, E_field);%params.Layers{kk}.kdisexc;
        kbT=params.physical_const.kB*params.physical_const.T;
        kdis=params.Layers{kk}.kdis*exp(q*E_field*r0_CT/kbT);


        offsetLECT=params.Layers{2}.offset;
        % kforEx=kdisexc.*exp(-offsetLECT/kbT)/params.Layers{2}.RCTE;
        kforEx=kdisexc*exp(-offsetLECT/kbT)/params.Layers{2}.RCTE*(1-r0_Ex)+interpolated_k_bak*r0_Ex;%from marcus with field
        %kforEx=params.Layers{kk}.kforEx*(1-r0_Ex)+interpolated_k_bak*r0_Ex;%from marcus with field
        % end
        % kdis=params.Layers{kk}.kdis*exp(q*abs(Vapp-params.Experiment_prop.Vbi)/params.Layers{3}.XR*r0_CT/(kB*T)); %try to add field dependence in the form kdis=kdis0*exp(q*dudx(4)*r0/(kB*T)). If r0 = 0, kdis = kdis0.

        % s = [kdis*u(3)- params.Layers{kk}.kfor*((u(1)*u(2)));
        %     kdis*u(3)- params.Layers{kk}.kfor*((u(1)*u(2)));
        %     kdisexc*(u(5))+params.Layers{kk}.kfor*((u(1)*u(2)))-(kdis*u(3)+params.Layers{kk}.krec*(u(3)-params.Layers{kk}.CT0))-params.Layers{kk}.kforEx*(u(3));
        %     (q/params.Layers{kk}.epp)*(-u(1)+u(2)-params.Layers{kk}.NA+params.Layers{kk}.ND);
        %     g-kdisexc*(u(5))-params.Layers{kk}.krecexc*(u(5)-params.Layers{kk}.Ex0)+params.Layers{kk}.kforEx*(u(3));];%abs

        % s = [kdis*u(3)- params.Layers{kk}.kfor*((u(1)*u(2)));%try to add field dependence in the form kdis=kdis0*exp(q*dudx(4)*r0/(kB*T)); 
        %     kdis*u(3)- params.Layers{kk}.kfor*((u(1)*u(2)));%start with r0=3nm
        %     kdisexc*(u(5))+params.Layers{kk}.kfor*((u(1)*u(2)))-(kdis*u(3)+params.Layers{kk}.krec*(u(3)-params.Layers{kk}.CT0))-params.Layers{kk}.kforEx*(u(3));
        %     (q/params.Layers{kk}.epp)*(-u(1)+u(2)-params.Layers{kk}.NA+params.Layers{kk}.ND);
        %     g-kdisexc*(u(5))-params.Layers{kk}.krecexc*(u(5)-params.Layers{kk}.Ex0)+params.Layers{kk}.kforEx*(u(3));];%abs


        s = [kdis*(u(3))- params.Layers{kk}.kfor*(((u(1))*(u(2))));
            kdis*(u(3))- params.Layers{kk}.kfor*(((u(1))*(u(2))));
            kdisexc*(u(5))+params.Layers{kk}.kfor*(((u(1))*(u(2))))-(kdis*(u(3))+params.Layers{kk}.krec*(u(3)-params.Layers{kk}.CT0))-kforEx*(u(3));
            (q/params.Layers{kk}.epp)*(-u(1)+u(2)-params.Layers{kk}.NA+params.Layers{kk}.ND);
            g-kdisexc*(u(5))-params.Layers{kk}.krecexc*(u(5)-params.Layers{kk}.Ex0)+kforEx*(u(3));];%abs
%         if x>1.5e-5
%             pause(0.1)
%         end 
%%%%%%%%%% This is the end of s

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
        for ii=1:1:params.layers_num
            if(x<params.Layers{ii}.XR)
                break;
            end
        end
        if length(varargin) == 0 | varargin{1, 1}.sol == 0
            
            u0 = [params.Layers{ii}.n0;
                params.Layers{ii}.p0;
                params.Layers{ii}.CT0; %density of CT and Exciton at equilibrium
                (x/xmax)*params.Experiment_prop.Vbi;
                params.Layers{ii}.Ex0;]; %density of CT and Exciton at equilibrium
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


