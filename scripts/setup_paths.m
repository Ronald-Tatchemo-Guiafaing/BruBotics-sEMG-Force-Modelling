function setup_paths()
%SETUP_PATHS  Add toolbox + config folders to the MATLAB path.
%
% Call this once at the start of every demo script.
% It looks for config/paths.m (your local copy of paths_example.m).

    here = fileparts(mfilename('fullpath'));
    repo = fileparts(here);                          % repo root
    addpath(fullfile(repo, 'toolbox', 'function'));  % Hyser open functions
    addpath(fullfile(repo, 'config'));
    addpath(here);

    if ~exist('paths.m', 'file')
        error(['Missing config/paths.m. Copy config/paths_example.m to ' ...
               'config/paths.m and set DATASET_ROOT.']);
    end
end
