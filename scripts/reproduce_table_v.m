% reproduce_table_v.m
% =============================================================================
% Reproduce Hyser Table V (one-DoF EMG → force RMSE)
% =============================================================================
% Plain language:
%   For each subject, session, finger and trial we do leave-one-trial-out
%   cross-validation. The error is RMSE in normalized MVC units, then
%   reported as %%MVC (×100) like Table V in Jiang et al., TNSRE 2021.
%
% WARNING: all 20 subjects × 2 sessions is LONG (hours). Start with
%   SUBJECTS = {'01'} for a smoke test.
% =============================================================================

clear; close all; clc;
setup_paths; paths;

%% --- Who to run ------------------------------------------------------------
% Full paper reproduction:
% SUBJECTS = {'01','02','03','04','05','06','07','08','09','10', ...
%             '11','12','13','14','15','16','17','18','19','20'};
SUBJECTS = {'01'};   % default: quick check; expand when you have time

%% --- Fixed parameters (paper defaults) -------------------------------------
thresh = 0.0004; window_len = 0.02; step_len = 0.02; f_cutoff = 10;
fs_emg = 2048; fs_force = 100; Q = 20; D = 1; Tol = 0.05; ii = 0;
pca_active = 1; dim = 200;

out_log = fullfile(OUTPUT_ROOT, 'logs');
out_mat = fullfile(OUTPUT_ROOT, 'mats');
if ~exist(out_log, 'dir'), mkdir(out_log); end
if ~exist(out_mat, 'dir'), mkdir(out_mat); end

n_subj = numel(SUBJECTS);
% Err(finger, trial, subject, session)
Err = nan(5, 3, n_subj, 2);
t0 = tic;

fprintf('START Table V  n_subj=%d  %s\n', n_subj, datestr(now));
for i = 1:n_subj
    for session = 1:2
        fprintf('Subject %s session %d ...\n', SUBJECTS{i}, session);
        force_c = load_1dof(DATASET_ROOT, SUBJECTS{i}, session, 'force');
        emg_c   = load_1dof(DATASET_ROOT, SUBJECTS{i}, session, 'preprocess');
        mvc = get_mvc(DATASET_ROOT, SUBJECTS{i}, num2str(session));
        force_norm = normalize_force(force_c, mvc);
        force_win  = preprocess_force(force_norm, window_len, step_len, f_cutoff, fs_force, fs_emg);

        feature = cell(5, 3);
        force_gt = cell(5, 3);
        for u = 1:5
            for v = 1:3
                emg = emg_c{u, v};
                rms = get_rms(emg, window_len, step_len, fs_emg);
                wl  = get_wl(emg, window_len, step_len, fs_emg);
                zc  = get_zc(emg, window_len, step_len, thresh, fs_emg);
                ssc = get_ssc(emg, window_len, step_len, thresh, fs_emg);
                feature{u, v} = [rms'; wl'; zc'; ssc'];
                force_gt{u, v} = force_win{u, v}(:, u);
            end
        end

        for u = 1:5
            for v = 1:3
                force_test = force_gt(u, v);
                force_train = force_gt(u, :); force_train(:, v) = [];
                feature_test = feature(u, v);
                feature_train = feature(u, :); feature_train(:, v) = [];
                [ftr, fte] = feature_normalize(feature_train, feature_test, pca_active, dim);
                x_plus = e_sifir_trn(ftr, force_train, [Q D Tol ii], [2/window_len 2/window_len]);
                [Err(u, v, i, session), ~] = e_sifir_tst( ...
                    x_plus, fte, force_test, [Q D Tol ii], [2/window_len 2/window_len]);
            end
        end
    end
    fprintf('  done subject %s  elapsed %.1f min\n', SUBJECTS{i}, toc(t0)/60);
    save(fullfile(out_mat, 'Err_TABLE_V_CHECKPOINT.mat'), 'Err', 'SUBJECTS');
end

% Mean over CV folds and sessions → %%MVC
T = 100 * squeeze(mean(mean(Err, 2), 4)); % 5 x n_subj or vector if n_subj==1
if isvector(T), T = T(:)'; end            % n_subj x 5
if size(T, 2) ~= 5, T = T'; end

finger_mean = mean(T, 1);
finger_std  = std(T, 0, 1);
grand_mean  = mean(T(:));
grand_std   = std(T(:));

save(fullfile(out_mat, 'Err_TABLE_V.mat'), 'Err', 'T', 'finger_mean', ...
    'finger_std', 'grand_mean', 'grand_std', 'SUBJECTS');

fid = fopen(fullfile(out_log, 'TABLE_V.txt'), 'w');
fprintf(fid, 'TABLE V  RMSE (%%MVC)  leave-one-trial-out\n');
fprintf(fid, 'Date: %s\n\n', datestr(now));
fprintf(fid, 'Subject\tThumb\tIndex\tMiddle\tRing\tLittle\n');
for i = 1:size(T, 1)
    fprintf(fid, '%s\t%.2f\t%.2f\t%.2f\t%.2f\t%.2f\n', SUBJECTS{i}, T(i,:));
end
fprintf(fid, 'Average\t%.2f\t%.2f\t%.2f\t%.2f\t%.2f\n', finger_mean);
fprintf(fid, 'Grand Average\t%.2f ± %.2f\n', grand_mean, grand_std);
fclose(fid);

disp('DONE Table V');
disp(finger_mean);
