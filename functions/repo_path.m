function p = repo_path(varargin)
% repo_path - Absolute path of a file or folder in this repository
%
%   p = repo_path('parameters', 'DeviceParameters_Default.xlsx')

root = fileparts(fileparts(mfilename('fullpath')));
p = fullfile(root, varargin{:});

end
