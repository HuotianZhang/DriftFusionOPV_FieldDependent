function [params] = pnParamsHCT(~)

if nargin>0
    
else
    % Simply call the deviceparams constructor with default Excel file
    % All physical constants and properties are now set inside deviceparams
    Excelfilename='PINDevice.xlsx';
    params = deviceparams(Excelfilename);
    
end
end