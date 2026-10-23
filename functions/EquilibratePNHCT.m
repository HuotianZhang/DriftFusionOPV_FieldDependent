function y=EquilibratePNHCT(Vapp,p)

% Swicth off mobility and set time to short time step
%p=p1;
% p.discretetrap=0;
% EAN0=p.EAn;
%p.NI = a;
%p.Time_properties.tpoints = 50;

p.Experiment_prop.equilibrium=0;
p.Experiment_prop.symm=0;
p.Experiment_prop.mobset=1;
p.Experiment_prop.BC=0;
p.Experiment_prop.Vapp=Vapp;
p.Experiment_prop.figson = 0;
p.Experiment_prop.V_fun_type = 'constant';
p.Experiment_prop.V_fun_arg(1) = Vapp;
p.solveropt.AbsTol=1e-3;
p.solveropt.RelTol=1e-1;
p.pulse_properties.pulseon=0;
p.light_properties.Int=0;
for ii=1:1:p.layers_num
    p.Layers{ii}.krec  = 1; 
    p.Layers{ii}.kfor = 1e-15;   
    p.Layers{ii}.kdis = 1;
    p.Layers{ii}.krecex  = 1;
    p.Layers{ii}.kdisexc=1;
    p.Layers{ii}.kforEx=1;
end
sol.sol=0;
p=UpdateLayers(p);
p = Xgrid(p);
p=update_time(p);
p.Time_properties.tmax = 1e-9;
p.Time_properties.t0 = p.Time_properties.tmax/1e3;
p=Timemesh(p);
verbose = ~isfield(p.solveropt,'verbose') || p.solveropt.verbose;
% Run with initial solution
tic
if verbose, disp('first solution'), end
sol = pndriftHCT (sol,p);
if verbose, toc, end
tic
p.Experiment_prop.equilibrium=0;
p.Experiment_prop.BC=2;
p.solveropt.AbsTol=1e-6;
p.solveropt.RelTol=1e-3;
p.Time_properties.tmax = 1e-3;
p.Time_properties.t0 = p.Time_properties.tmax/1e3;
p=Timemesh(p);
if verbose, disp('second solution'), end
p.Experiment_prop.mobset=1;
p.Time_properties.tmax = 1e-6;
p.Time_properties.t0 = p.Time_properties.tmax/1e3;
sol_eq = pndriftHCT(sol, p);
p=UpdateLayers(p);
sol_eq = pndriftHCT(sol_eq, p);
y=sol_eq;
if verbose, toc, end

end
