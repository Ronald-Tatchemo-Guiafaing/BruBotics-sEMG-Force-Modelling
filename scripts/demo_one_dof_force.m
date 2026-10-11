% demo_one_dof_force.m
% =============================================================================
% ONE-DoF finger-force estimation from HD-sEMG (Hyser)
% =============================================================================
% What this script does (plain language):
%   1) Loads forearm EMG + finger force for ONE finger (one degree of freedom).
%   2) Builds simple features on short windows (RMS, WL, ZC, SSC).
%   3) Trains a linear lag model (SIFiR) on one trial, tests on another.
%   4) Plots measured vs estimated force and prints the error (RMSE).
%
% Why it matters for BruBotics:
%   Tip-force sensing on hand-held laparoscopy tools is hard without a sensor
%   at the tip. Forearm EMG is a candidate proxy. This demo is the baseline
%   pipeline from Jiang et al. (Hyser, IEEE TNSRE 2021), Table V family.
%
% Requirements:
%   - MATLAB
%   - Hyser dataset on disk (see config/paths_example.m)
%   - First run: copy paths_example.m -> paths.m
% =============================================================================

clear; close all; clc;
setup_paths;
paths;   % loads DATASET_ROOT and OUTPUT_ROOT

%% --- User choices (safe to edit) -------------------------------------------
subject = '01';      % Hyser subject id as two digits: '01' ... '20'
session = 1;         % 1 or 2
finger  = 2;         % 1=thumb ... 5=little (2 = index)
train_trial = 1;     % which trial teaches the model
test_trial  = 2;     % which trial we evaluate on

%% --- Fixed processing parameters (match the Hyser paper defaults) ----------
thresh     = 0.0004; % amplitude threshold used by ZC / SSC features
window_len = 0.02;   % window length in seconds (20 ms)
step_len   = 0.02;   % hop between windows (20 ms → no overlap)
f_cutoff   = 10;     % Hz, force smoothing cutoff
fs_emg     = 2048;   % EMG sampling rate
fs_force   = 100;    % force sampling rate
Q          = 20;     % number of past windows used by the FIR regressor
D          = 1;      % SIFiR order setting used by the toolbox
Tol        = 0.05;   % SIFiR tolerance
pca_active = 1;      % 1 = reduce feature dimension with PCA
dim        = 200;    % PCA components kept

%% --- Load signals ----------------------------------------------------------
% force: 5 channels (one per finger), EMG: 256 HD-sEMG channels
force_all = load_1dof(DATASET_ROOT, subject, session, 'force');
emg_all   = load_1dof(DATASET_ROOT, subject, session, 'preprocess');

% Keep only the selected finger (cell array of 3 trials)
force_all = force_all(finger, :);
emg_all   = emg_all(finger, :);

% Normalize force by MVC so error is in units of normalized MVC
mvc = get_mvc(DATASET_ROOT, subject, num2str(session));
force_norm = normalize_force(force_all, mvc);
force_win  = preprocess_force(force_norm, window_len, step_len, f_cutoff, fs_force, fs_emg);

%% --- Features per trial ----------------------------------------------------
feature = cell(1, 3);
force_gt = cell(1, 3);
for v = 1:3
    emg = emg_all{1, v};
    rms = get_rms(emg, window_len, step_len, fs_emg);
    wl  = get_wl(emg, window_len, step_len, fs_emg);
    zc  = get_zc(emg, window_len, step_len, thresh, fs_emg);
    ssc = get_ssc(emg, window_len, step_len, thresh, fs_emg);
    feature{1, v} = [rms, wl, zc, ssc]';          % rows = windows
    force_gt{1, v} = force_win{1, v}(:, finger); % target force for this finger
end

%% --- Train / test split ----------------------------------------------------
force_train   = force_gt(1, train_trial);
force_test    = force_gt(1, test_trial);
feature_train = feature(1, train_trial);
feature_test  = feature(1, test_trial);

[feature_train_n, feature_test_n] = feature_normalize( ...
    feature_train, feature_test, pca_active, dim);

%% --- Fit SIFiR and evaluate ------------------------------------------------
x_plus = e_sifir_trn(feature_train_n, force_train, [Q D Tol 0], [2/window_len, 2/window_len]);
[Err, force_estimate] = e_sifir_tst( ...
    x_plus, feature_test_n, force_test, [Q D Tol 0], [2/window_len, 2/window_len]);

fprintf('One-DoF RMSE (norm. MVC) = %.6f\n', Err);

%% --- Plot ------------------------------------------------------------------
ft = force_test{1};
if iscell(force_estimate), fe = force_estimate{1}; else, fe = force_estimate; end

figure('Color', 'w');
plot(ft, 'k', 'LineWidth', 1.1); hold on;
plot(fe, 'Color', [0.61 0.16 0.12], 'LineWidth', 0.9);
legend('Measured', 'Estimated', 'Location', 'best');
title(sprintf('One-DoF force estimation | subject %s finger %d | RMSE = %.4f', ...
    subject, finger, Err));
xlabel('Window index'); ylabel('Force (normalized MVC)');
grid on; box off;

%% --- Save outputs ----------------------------------------------------------
out_img = fullfile(OUTPUT_ROOT, 'images');
out_log = fullfile(OUTPUT_ROOT, 'logs');
if ~exist(out_img, 'dir'), mkdir(out_img); end
if ~exist(out_log, 'dir'), mkdir(out_log); end
saveas(gcf, fullfile(out_img, sprintf('demo_1dof_s%s_f%d_err%.4f.png', subject, finger, Err)));
fid = fopen(fullfile(out_log, 'demo_1dof_last_run.txt'), 'w');
fprintf(fid, 'subject=%s session=%d finger=%d train=%d test=%d Err=%.6f\n', ...
    subject, session, finger, train_trial, test_trial, Err);
fclose(fid);
disp('Done. Figure and log written under OUTPUT_ROOT.');
