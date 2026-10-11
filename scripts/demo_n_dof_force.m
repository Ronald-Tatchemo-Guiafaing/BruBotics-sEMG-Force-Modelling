% demo_n_dof_force.m
% =============================================================================
% N-DoF (multi-finger) force estimation from HD-sEMG (Hyser)
% =============================================================================
% Plain language:
%   Same idea as the one-DoF demo, but the subject moves several fingers
%   together. We train one regressor per finger and report five RMSE values.
%
% This is closer to a real grasping / tool-use scenario than isolated 1-DoF.
% =============================================================================

clear; close all; clc;
setup_paths; paths;

%% --- User choices ----------------------------------------------------------
subject     = '01';
session     = 1;
combination = 2;   % Hyser N-DoF finger-combination index (see dataset docs)
train_trial = 1;
test_trial  = 2;

%% --- Fixed parameters (paper defaults) -------------------------------------
thresh = 0.0004; window_len = 0.02; step_len = 0.02; f_cutoff = 10;
fs_emg = 2048; fs_force = 100; Q = 20; D = 1; Tol = 0.05; ii = 0;
pca_active = 1; dim = 200;

%% --- Load ------------------------------------------------------------------
force_all = load_ndof(DATASET_ROOT, subject, session, 'force');
emg_all   = load_ndof(DATASET_ROOT, subject, session, 'preprocess');
force_all = force_all(combination, :);
emg_all   = emg_all(combination, :);

mvc = get_mvc(DATASET_ROOT, subject, num2str(session));
force_norm = normalize_force(force_all, mvc);
force_win  = preprocess_force(force_norm, window_len, step_len, f_cutoff, fs_force, fs_emg);

%% --- Features + five force targets -----------------------------------------
n_trial = size(emg_all, 2);
feature = cell(1, n_trial);
gt = cell(5, n_trial);   % rows: thumb..little
for v = 1:n_trial
    emg = emg_all{1, v};
    rms = get_rms(emg, window_len, step_len, fs_emg);
    wl  = get_wl(emg, window_len, step_len, fs_emg);
    zc  = get_zc(emg, window_len, step_len, thresh, fs_emg);
    ssc = get_ssc(emg, window_len, step_len, thresh, fs_emg);
    feature{1, v} = [rms'; wl'; zc'; ssc'];
    for f = 1:5
        gt{f, v} = force_win{1, v}(:, f);
    end
end

feature_train = feature(1, train_trial);
feature_test  = feature(1, test_trial);
[feature_train_n, feature_test_n] = feature_normalize(feature_train, feature_test, pca_active, dim);

%% --- One model per finger --------------------------------------------------
names = {'thumb','index','middle','ring','little'};
Err = zeros(1, 5);
est_index = [];
for f = 1:5
    force_train = gt(f, train_trial);
    force_test  = gt(f, test_trial);
    x_plus = e_sifir_trn(feature_train_n, force_train, [Q D Tol ii], [2/window_len 2/window_len]);
    [Err(f), fe] = e_sifir_tst(x_plus, feature_test_n, force_test, [Q D Tol ii], [2/window_len 2/window_len]);
    if f == 2
        if iscell(fe), est_index = fe{1}; else, est_index = fe; end
    end
    fprintf('Err_%s = %.6f\n', names{f}, Err(f));
end

%% --- Plot index finger + bar chart of all RMSE -----------------------------
out_img = fullfile(OUTPUT_ROOT, 'images');
out_log = fullfile(OUTPUT_ROOT, 'logs');
if ~exist(out_img, 'dir'), mkdir(out_img); end
if ~exist(out_log, 'dir'), mkdir(out_log); end

figure('Color', 'w');
plot(gt{2, test_trial}, 'k', 'LineWidth', 1.1); hold on;
plot(est_index, 'Color', [0.61 0.16 0.12], 'LineWidth', 0.9);
legend('Measured index', 'Estimated index');
title(sprintf('N-DoF index force | RMSE = %.4f', Err(2)));
xlabel('Window index'); ylabel('Force (normalized MVC)');
grid on; box off;
saveas(gcf, fullfile(out_img, 'demo_ndof_index.png'));

figure('Color', 'w');
barh(fliplr(Err), 'FaceColor', [0.3 0.3 0.3]);
set(gca, 'YTickLabel', fliplr(names));
xlabel('RMSE (normalized MVC)');
title(sprintf('N-DoF finger-wise RMSE | mean = %.4f', mean(Err)));
box off;
saveas(gcf, fullfile(out_img, 'demo_ndof_finger_rmse.png'));

fid = fopen(fullfile(out_log, 'demo_ndof_last.txt'), 'w');
for f = 1:5
    fprintf(fid, 'Err_%s=%.6f\n', names{f}, Err(f));
end
fclose(fid);
disp('Done N-DoF demo.');
