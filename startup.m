% Adds the code folders of this repository to the MATLAB path
root = fileparts(mfilename('fullpath'));
addpath(root, fullfile(root, 'classes'), fullfile(root, 'functions'), ...
    fullfile(root, 'scripts'), fullfile(root, 'resourceFiles'));
clear root
