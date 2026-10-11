% demo_emg_decomposition.m
% =============================================================================
% HD-sEMG motor-unit decomposition quality (SIL)
% =============================================================================
% Plain language:
%   We try to separate the raw EMG into motor-unit sources (blind source
%   separation / FastICA). SIL (silhouette index) tells us how clean each
%   source is. Sources above ~0.6 are usually kept.
%
% This supports the physiology side of the BruBotics modelling work.
% =============================================================================

clear; close all; clc;
setup_paths; paths;

%% --- User choices ----------------------------------------------------------
subject = '01';
session = 1;
finger  = 2;     % which 1-DoF finger recording to decompose
sample  = 1;     % trial index
muscle_idx = 1;  % 1 = first 128-channel grid, 2 = second grid

%% --- Fixed parameters ------------------------------------------------------
fs_emg = 2048;
R = 4;            % extension factor for FastICA preprocessing
M = 40;           % number of sources requested
threshold = 0.6;  % SIL acceptance threshold

%% --- Load raw EMG (not the preprocessed force-regression stream) -----------
emg_all = load_1dof(DATASET_ROOT, subject, session, 'raw');
emg_trial = emg_all{finger, sample};
emg = emg_trial(:, (muscle_idx-1)*128 + 1 : muscle_idx*128);

%% --- Decomposition pipeline (toolbox) --------------------------------------
[emg_extend, ~] = SimEMGProcessing(emg, 'R', R, 'WhitenFlag', 'On', 'SNR', 'Inf');
[s, ~, SpikeTraintemp] = FastICA(emg_extend, M, fs_emg);
[SpikeTrain, GoodIndex] = MUReplicasRemoval(SpikeTraintemp, s, fs_emg);
sGood = s(:, GoodIndex);
SIL = SILCal(sGood, fs_emg);

keep = (SIL > threshold) & (SIL < 0.99);
NumMU = numel(SIL(keep));
MeanSIL = mean(SIL(keep));

fprintf('NumMU = %d\n', NumMU);
fprintf('MeanSIL = %.6f\n', MeanSIL);

%% --- Plot + save -----------------------------------------------------------
out_img = fullfile(OUTPUT_ROOT, 'images');
out_log = fullfile(OUTPUT_ROOT, 'logs');
out_mat = fullfile(OUTPUT_ROOT, 'mats');
if ~exist(out_img, 'dir'), mkdir(out_img); end
if ~exist(out_log, 'dir'), mkdir(out_log); end
if ~exist(out_mat, 'dir'), mkdir(out_mat); end

figure('Color', 'w');
plot(SIL, 'ko-', 'LineWidth', 1.1, 'MarkerFaceColor', 'w');
yline(threshold, '--', 'Color', [0.4 0.4 0.4]);
xlabel('Source index'); ylabel('Silhouette index (SIL)');
title(sprintf('HD-sEMG decomposition | subject %s finger %d | MU=%d mean SIL=%.3f', ...
    subject, finger, NumMU, MeanSIL));
box off; grid on;
saveas(gcf, fullfile(out_img, 'demo_emg_decomposition_SIL.png'));

save(fullfile(out_mat, 'demo_decomp_subject01.mat'), ...
    'NumMU', 'MeanSIL', 'SIL', 'M', 'subject', 'finger');
fid = fopen(fullfile(out_log, 'demo_emg_decomposition_last.txt'), 'w');
fprintf(fid, 'subject=%s finger=%d M=%d NumMU=%d MeanSIL=%.6f\n', ...
    subject, finger, M, NumMU, MeanSIL);
fclose(fid);
disp('Done decomposition demo.');
