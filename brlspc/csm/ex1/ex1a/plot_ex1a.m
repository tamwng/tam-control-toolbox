% plot_ex1a.m
% Loads saved results and generates standardized figures and a CSV table.

clear; clc; close all;

resdir = 'results';
figdir = 'figs';
tbldir = 'tables';
if ~exist(figdir,'dir'), mkdir(figdir); end
if ~exist(tbldir,'dir'), mkdir(tbldir); end

% Expected files (edit if you change sigma/degree)
files = { ...
  fullfile(resdir,'ex1a_linear_seed42.mat'), ...
  fullfile(resdir,'ex1a_poly_deg2_seed42.mat'), ...
  fullfile(resdir,'ex1a_rbf_sig1p0_seed42.mat')};

S = load_all(files);

% ---- Figure 1: tracking and input ----
T = numel(S{1}.series.y);
t = (1:T).';
figure('Name','Ex1a Tracking','Color','w');
subplot(2,1,1); hold on;
plot(t, S{1}.series.r, 'k-', 'LineWidth', 1.0);
for i=1:numel(S)
    plot(t, S{i}.series.y, 'LineWidth', 1.0);
end
xlabel('k'); ylabel('Output');
legend(['Ref', legend_names(S)], 'Location','best');
title('Example 1a: Closed-loop output'); xlim([1 T]);

subplot(2,1,2); hold on;
for i=1:numel(S)
    plot(t, S{i}.series.u, 'LineWidth', 1.0);
end
xlabel('k'); ylabel('Input');
legend(legend_names(S), 'Location','best');
title('Applied input'); xlim([1 T]);

saveas(gcf, fullfile(figdir,'ex1a_tracking.pdf'));

% ---- Figure 2: diagnostics ----
figure('Name','Ex1a Diagnostics','Color','w');
subplot(1,2,1); hold on;
for i=1:numel(S)
    plot(t, S{i}.series.log10_ew, 'LineWidth', 1.0);
end
xlabel('k'); ylabel('log_{10} EWMA(e_k^2)');
legend(legend_names(S), 'Location','best');
title('Prediction-error power'); xlim([1 T]);

subplot(1,2,2); cla; hold on;
% parameter error only for linear
i_lin = find(strcmpi(extract_types(S),'linear'),1,'first');
if ~isempty(i_lin) && ~isempty(S{i_lin}.series.theta_hist)
    % theta_hist length equals number of RLS updates; align k indices
    k0 = find(~isnan(S{i_lin}.series.e),1,'first');
    param_err = vecnorm(S{i_lin}.series.theta_hist - ...
                        S{i_lin}.cfg_to_true(:), 2, 1).';
    plot(k0:(k0+numel(param_err)-1), param_err, 'LineWidth', 1.0);
    xlabel('k'); ylabel('||\theta_k - \theta^\star||_2');
    title('Parameter error (linear kernel)');
else
    axis off; text(0.1,0.5,'Parameter error shown for linear kernel only.','FontSize',10);
end
saveas(gcf, fullfile(figdir,'ex1a_diagnostics.pdf'));

% ---- CSV table with Phase-II metrics ----
write_metrics_csv(S, fullfile(tbldir,'ex1a_phaseII_metrics.csv'));

disp('Done.');

%% -------------------- Local helpers --------------------
function S = load_all(files)
    S = cell(size(files));
    for i=1:numel(files)
        tmp = load(files{i}, 'Results');
        R = tmp.Results;
        % stash true theta for plotting convenience
        R.cfg_to_true = [1.5; -0.7; 0.5; 0.3];
        S{i} = R;
    end
end

function names = legend_names(S)
    names = strings(1, numel(S));
    for i=1:numel(S)
        names(i) = spec_name(S{i}.spec);
    end
    names = cellstr(names);
end

function t = extract_types(S)
    t = strings(1,numel(S));
    for i=1:numel(S)
        t(i) = string(lower(S{i}.spec.type));
    end
end

function s = spec_name(spec)
    switch lower(spec.type)
        case 'linear'
            s = 'Linear';
        case 'poly'
            s = sprintf('Poly-2');
        case 'rbf'
            s = sprintf('RBF(\\sigma=%g)', spec.sigma);
        otherwise
            s = 'Unknown';
    end
end

function write_metrics_csv(S, path)
    fid = fopen(path,'w');
    fprintf(fid, 'Method,RMSE_PhaseII,IAE_PhaseII,TV_u,Peak_u,Final_log10_EWMA_e2\n');
    for i=1:numel(S)
        M = S{i}.metrics;
        fprintf(fid, '%s,%.6g,%.6g,%.6g,%.6g,%.6g\n', ...
            spec_name(S{i}.spec), M.RMSE_PhaseII, M.IAE_PhaseII, ...
            M.TV_u, M.Peak_u, M.Final_log10_EWMA_e2);
    end
    fclose(fid);
end
