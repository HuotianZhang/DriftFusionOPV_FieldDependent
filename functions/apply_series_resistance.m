function [VV_corrected, JJ_corrected] = apply_series_resistance(VV_ideal, JJ_ideal, Rs)
    % APPLY_SERIES_RESISTANCE Correct J-V characteristics for series resistance
    %
    % This function calculates the corrected voltage and current density 
    % when a photovoltaic diode is connected in series with a resistance.
    %
    % INPUTS:
    %   VV_ideal    - Ideal voltage points (V) - column or row vector
    %   JJ_ideal    - Ideal current density (mA/cm²) - same size as VV_ideal
    %   Rs          - Series resistance (kΩ·cm²) - optional, default = 0.005
    %
    % OUTPUTS:
    %   VV_corrected - Corrected voltage points (V) accounting for series resistance
    %   JJ_corrected - Corrected current density (mA/cm²) - same as input (conservation)
    %
    % PHYSICS:
    %   For a diode with series resistance:
    %   V_terminal = V_diode - I * Rs
    %   where I = J * Area, but since we work with current density:
    %   V_terminal = V_diode - J * Rs (when Rs is in kΩ·cm² and J in mA/cm²)
    %
    % USAGE:
    %   [V_out, J_out] = apply_series_resistance(V_in, J_in);          % Uses default Rs = 0.005
    %   [V_out, J_out] = apply_series_resistance(V_in, J_in, 0.01);    % Uses Rs = 0.01 kΩ·cm²
    %
    % Author: Huotian Zhang
    % Date: October 2025
    
    % Set default series resistance if not provided
    if nargin < 3
        Rs = 0.005; % Default series resistance in kΩ·cm²
    end
    
    % Input validation
    if length(VV_ideal) ~= length(JJ_ideal)
        error('VV_ideal and JJ_ideal must have the same length');
    end
    
    if Rs < 0
        error('Series resistance must be non-negative');
    end
    
    % Ensure column vectors for consistent processing
    VV_ideal = VV_ideal(:);
    JJ_ideal = JJ_ideal(:);
    
    % Apply series resistance correction
    % Terminal voltage = Ideal diode voltage - Current * Series resistance
    % Note: Current density J is typically negative for photovoltaic operation
    % Rs is in kΩ·cm², J is in mA/cm², so Rs*J gives voltage drop in V
    VV_corrected = VV_ideal + JJ_ideal * Rs;
    
    % Current density remains the same (current conservation)
    JJ_corrected = JJ_ideal;
    
    % Ensure output vectors have same orientation as input
    if size(VV_ideal, 1) == 1  % Input was row vector
        VV_corrected = VV_corrected.';
        JJ_corrected = JJ_corrected.';
    end
    
    % Optional: Display information about the correction
    if Rs > 0
        voltage_drop_range = [min(JJ_ideal * Rs), max(JJ_ideal * Rs)];
        fprintf('Series resistance correction applied: Rs = %.4f kΩ·cm²\n', Rs);
        fprintf('Voltage drop range: [%.3f, %.3f] V\n', voltage_drop_range(1), voltage_drop_range(2));
    end
    
end