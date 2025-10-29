function p = configure_solver_params(p, AbsTol, RelTol)
% CONFIGURE_SOLVER_PARAMS Set solver tolerance parameters
%
% Syntax:
%   p = configure_solver_params(p, AbsTol, RelTol)
%
% Description:
%   Configures solver absolute and relative tolerance parameters.
%   This consolidates repeated solver parameter setup code.
%
% Inputs:
%   p       - Parameter structure
%   AbsTol  - Absolute tolerance for solver (default: 1e-6)
%   RelTol  - Relative tolerance for solver (default: 1e-3)
%
% Outputs:
%   p       - Updated parameter structure with solver options set
%
% Example:
%   p = configure_solver_params(p, 1e-6, 1e-3);
%
% See also: pndriftHCT, device

    if nargin < 3
        RelTol = 1e-3;
    end
    if nargin < 2
        AbsTol = 1e-6;
    end
    
    p.solveropt.AbsTol = AbsTol;
    p.solveropt.RelTol = RelTol;
end
