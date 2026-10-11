% paths_example.m
% ---------------------------------------------------------------------------
% Copy this file to paths.m (same folder) and edit DATASET_ROOT.
% paths.m is git-ignored so your local disk layout stays private.
% ---------------------------------------------------------------------------

% Folder that contains 1dof_dataset/, ndof_dataset/, mvc_dataset/, ...
% Example (Windows):
%   DATASET_ROOT = 'D:/data/Hyser_HD-sEMG_Dataset';
% Example (Linux/macOS):
%   DATASET_ROOT = '/home/you/data/Hyser_HD-sEMG_Dataset';

DATASET_ROOT = 'PUT_YOUR_HYSER_DATASET_PATH_HERE';

% Where figures / text logs from the demos are written
OUTPUT_ROOT = fullfile(getenv('USERPROFILE'), 'Desktop', 'BruBotics_Results');
