function kCTLE_stark_vars = kBak_stark()
% kBak_stark - Calculate back electron transfer rates using Marcus theory with Stark effect
%
% Returns:
%   kCTLE_stark_vars - Structure containing field-dependent back transfer rates

Hab = 0.01;       % Electronic coupling matrix element (eV)
T = 298;          % Temperature (K)

% Define the range of lambda and deltaG values
lambda_values = 0.2:0.1:0.8; %eV If the step is smaller than 0.1, it will overwrite..
RCT_values = 0.5:0.5:10; %nm
RCT_values = RCT_values/1e9; %convert to m
F_values = 0:1e5:5e7; %V/m
deltaG_values = 0.00:0.05:0.45;

% Create a structure to hold the k_LE2CTs
kCTLE_stark_vars = struct();

% Preallocate the output matrix for efficiency
ket_matrix = zeros(length(F_values), length(deltaG_values));

for lambda_nums = 1:length(lambda_values)
    lambda = lambda_values(lambda_nums);
    lambda_str = strrep(sprintf('%02.0f', lambda*10), '.', ''); % Format Reorganization energy to two digits, remove decimal
    for RCT_nums = 1:length(RCT_values)
        RCT = RCT_values(RCT_nums);
        % Extract the numeric parts for the variable name
        RCT_str = strrep(sprintf('%02.0f', RCT*1e10), '.', ''); % Format transfer distance to two digits, remove decimal, actu
    
        % Construct the variable name
        kLECT_name = ['kCTLE' lambda_str RCT_str];
    
        
        % Calculate ket using the Marcus equation with  F and deltaG
        % arrays
        % Assign the value to the field within the structure        
        for F_nums = 1:length(F_values)
            for deltaG_nums = 1:length(deltaG_values)
              F = -F_values(F_nums);
              deltaG = + deltaG_values(deltaG_nums);
              
              % Calculate ket using the Marcus equation
              ket = marcus_equation_stark(Hab, lambda, deltaG, T, F, RCT);
              ket_matrix(F_nums, deltaG_nums) = 0.1*ket;
            end
        end
            
        kCTLE = [F_values' ket_matrix];
        kCTLE_stark_vars.(kLECT_name)=kCTLE;
    end
end

end
