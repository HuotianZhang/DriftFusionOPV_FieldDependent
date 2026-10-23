function solstruct = pndriftHCT(varargin)
% Solves the drift-diffusion equations with MATLAB's pdepe.
%
%   solstruct = pndriftHCT(sol0, params)
%
% sol0 is a previous solution used as the initial condition, or a struct
% with sol0.sol = 0 to start from the flat background conditions in params
% (a deviceparams object). Variables:
% u1    electrons
% u2    holes
% u3    charge transfer states
% u4    electric potential
% u5    exciton
%
% Field dependence of the rate constants (per layer, all optional):
%   Layers{kk}.r0_CT   CT dissociation, kdis*exp(q*F*r0_CT/kT), r0_CT in cm
%   Layers{kk}.r0_Ex   exciton dissociation, kdisexc*exp(q*F*r0_Ex/kT), r0_Ex in cm
%   Layers{kk}.marcus  Marcus LE<->CT rate tables (see marcus_rate_tables):
%                      fields E (V/m), k, k_bak (s^-1) and weight (0..1);
%                      kdisexc and kforEx are weight*table + (1-weight)*constant
% with F the field magnitude |dV/dx| in V/cm.
%
% Piers Barnes last modified (09/01/2016)
% Phil Calado last modified (07/07/2016)
% Huotian Zhang: Marcus field-dependent LE<->CT rates (2023-2025)

if nargin ~= 2
    error('pndriftHCT:nargin', 'Call pndriftHCT(sol0, params); use struct(''sol'',0) as sol0 to start from the background conditions');
end
if isequal(varargin{1}.sol, 0)
    params = varargin{2};
    xmesh = params.Xgrid_properties;
else
    icsol = varargin{1}.sol;
    xmesh = varargin{1}.x;
    params = varargin{2};
end

icx = xmesh;
xmax=max(xmesh);
%% Voltage function
Vapp_fun = fun_gen(params.Experiment_prop.V_fun_type);

%% Marcus rate interpolants, built once per call
marcus_w = zeros(1, params.layers_num);
marcus_k = cell(1, params.layers_num);
marcus_kbak = cell(1, params.layers_num);
for ii = 1:params.layers_num
    if isfield(params.Layers{ii}, 'r0_Ex') && params.Layers{ii}.r0_Ex > 1e-4
        error('pndriftHCT:r0_Ex', ['Layer %d: r0_Ex = %g, but r0_Ex is a distance in cm. ' ...
            'For Marcus LE<->CT rates set Layers{%d}.marcus (see build_MarcusTransfer_device).'], ii, params.Layers{ii}.r0_Ex, ii);
    end
    if isfield(params.Layers{ii}, 'marcus') && params.Layers{ii}.marcus.weight > 0
        M = params.Layers{ii}.marcus;
        marcus_w(ii) = M.weight;
        marcus_k{ii} = griddedInterpolant(M.E(:), M.k(:), 'linear', 'linear');
        marcus_kbak{ii} = griddedInterpolant(M.E(:), M.k_bak(:), 'linear', 'linear');
    end
end

% Call solver - inputs with '@' are function handles to the subfunctions
% below for the: equation, initial conditions, boundary conditions
sol = pdepe(params.solveropt.m,@pdex4pde,@pdex4ic,@pdex4bc,xmesh,params.Time_properties.tmesh,params.solveropt.options);
SizesSol=size(sol);
solstruct.params = params;  solstruct.tspan=params.Time_properties.tmesh ;solstruct.x = xmesh; solstruct.t = params.Time_properties.tmesh(1:SizesSol(1));solstruct.sol = sol;

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
        %if side == 1
        % Uniform Generation
        if params.light_properties.OM == 0
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
        elseif params.light_properties.OM == 2
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
        else
            g = 0;
            
        end
        
        if params.Layers{kk}.int==0
            g=0;
        end
        % Prefactors set to 1 for time dependent components - can add other
        % functions if you want to include the multiple trappng model
        c = [1
            1
            1
            0
            1];
        
        f = [  (params.Layers{kk}.mue*((u(1))*-DuDx(4)+kB*T*DuDx(1)));
            (params.Layers{kk}.mup*((u(2))*DuDx(4)+kB*T*DuDx(2)));
            0;
            DuDx(4);
            0;];
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
        L=params.Layers{kk};
        E_field=abs(DuDx(4));   % V/cm
        r0_CT=0;
        r0_Ex=0;
        if isfield(L,'r0_CT')
            r0_CT=L.r0_CT;
        end
        if isfield(L,'r0_Ex')
            r0_Ex=L.r0_Ex;
        end
        kdis=L.kdis*exp(q*E_field*r0_CT/(kB*T));
        kdisexc=L.kdisexc*exp(q*E_field*r0_Ex/(kB*T));
        kforEx=L.kforEx;
        w=marcus_w(kk);
        if w>0
            E_Vm=E_field/1e-2;
            kdisexc=kdisexc*(1-w)+marcus_k{kk}(E_Vm)*w;
            kforEx=kforEx*(1-w)+marcus_kbak{kk}(E_Vm)*w;
        end
        s = [kdis*u(3)- L.kfor*((u(1)*u(2)));
            kdis*u(3)- L.kfor*((u(1)*u(2)));
            kdisexc*(u(5))+L.kfor*((u(1)*u(2)))-(kdis*u(3)+L.krec*(u(3)-L.CT0))-kforEx*(u(3));
            (q/L.epp)*(-u(1)+u(2)-L.NA+L.ND);
            g-kdisexc*(u(5))-L.krecexc*(u(5)-L.Ex0)+kforEx*(u(3));];

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
                
                pr = [(ur(1)-params.Layers{end}.n0);0;0;-ur(4)+params.Experiment_prop.Vbi-Vapp;0;];
                
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


