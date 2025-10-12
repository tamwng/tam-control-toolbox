close all; clc; clear;

clear; clc; close all; %% ---- Config ---- 
cfg.linewidth = 2.5; 
cfg.zoomN = 80; % zoom-in prefix length 
cfg.figdir = 'brlspc/csm/ex1/ex1a/figs'; 
cfg.tbldir = 'brlspc/csm/ex1/ex1a/tables'; 
cfg.resdir = 'brlspc/csm/ex1/ex1a/results'; 
cfg.files = { ... 
    fullfile(cfg.resdir,'ex1a_ones_seed42.mat'), ... 
    fullfile(cfg.resdir,'ex1a_linear_seed42.mat'), ... 
    fullfile(cfg.resdir,'ex1a_poly_deg2_seed42.mat'), ... 
    fullfile(cfg.resdir,'ex1a_rbf_sig1e+03_seed42.mat') }; 
if ~exist(cfg.figdir,'dir'), mkdir(cfg.figdir); end 
if ~exist(cfg.tbldir,'dir'), mkdir(cfg.tbldir); end

% --- Global aesthetics (put before plotting) ---
set(groot,'defaultTextInterpreter','latex')
set(groot,'defaultAxesTickLabelInterpreter','latex')
set(groot,'defaultLegendInterpreter','latex')

% colors = [ 0.121, 0.466, 0.705; % blue 
%     1.000, 0.498, 0.054; % orange 
%     0.172, 0.627, 0.172; % green 
%     0.580, 0.404, 0.741; % purple 
%     ];

colors = [
    0.121, 0.466, 0.705;   % blue
    1.000, 0.498, 0.054;   % orange
    0.172, 0.627, 0.172;   % green
    0.85  0.58  0.00;      % gold
    0.498, 0.498, 0.498;   % gray
    0.549, 0.337, 0.294;   % brown
    0.890, 0.467, 0.761;   % pink
    0.839, 0.153, 0.157;   % red
    0.580, 0.404, 0.741;   % purple
];

set(groot,'defaultAxesFontSize',14)
set(groot,'defaultTextFontSize',14)
set(groot,'defaultLegendFontSize',16)
set(groot,'defaultAxesLineWidth',0.9)
set(groot,'DefaultStairLineWidth',2.0)
set(groot,'defaultAxesTickDir','out')
set(groot,'defaultAxesBox','off')
set(groot,'defaultAxesColorOrder',colors)

%% ---- Load ---- 
S = load_all(cfg.files); 
T = numel(S{1}.series.y); 
t = (1:T).'; 
tZ = (1:min(cfg.zoomN,T)).'; 
names = legend_names(S);
cfg.Twarm = S{1,1}.cfg.Twarm;

%% Figure 1: Output (Full + Zoom)

% --- Figure size: single-column (≈8.6 cm) and compact height ---
f1 = figure('Units','centimeters','Position',[2 2 10 6],'Color','w');
% tiledlayout(2,1,'TileSpacing','compact','Padding','compact')

% Compute global y-lims for output
ymin = inf; ymax = -inf;
for i=1:numel(S)
    yi = S{i}.series.y; ymin = min(ymin, min(yi)); ymax = max(ymax, max(yi));
end
yspan = ymax - ymin; pad = 0.05*max(yspan,1e-9);
yl = [ymin-pad, ymax+pad];
styles = {'-','-','--','--'};   % RBF dashed

% Panel A: full
nexttile; hold on
for i=1:numel(S), stairs(t, S{i}.series.y,'LineStyle',styles{i}); end
stairs(t, S{1}.series.r,'k--')
xlabel('$k$'); ylabel('$y_k$')
xlim([1 T]); ylim(yl)
legend('off')
% legend([names,'Reference'],'NumColumns',2,'Location','southoutside'); legend boxoff
% blue patch
yL = ylim;
x_patch = [1 cfg.Twarm cfg.Twarm 1];
y_patch = [yL(1) yL(1) yL(2) yL(2)];
fill(x_patch, y_patch, [0.85 0.93 1.0], ...
     'EdgeColor','none','FaceAlpha',0.6);
uistack(findobj(gca,'Type','Stair'),'top'); % keep lines above

% Panel B: zoom (first 120)
f2 = figure('Name','Ex1a Output Zoom','Color','w');
set(f2,'Units','centimeters','Position',[2 2 10 6])
hold on
tZ = (1:min(cfg.zoomN,T)).';
nexttile; hold on
for i=1:numel(S), stairs(tZ, S{i}.series.y(1:numel(tZ)),'LineStyle',styles{i}); end
stairs(tZ, S{1}.series.r(1:numel(tZ)),'k--')
xlabel('$k$'); ylabel('$y_k$')
xlim([1 numel(tZ)]); ylim(yl)
legend('off')
% blue patch
yL = ylim;
x_patch = [1 cfg.Twarm cfg.Twarm 1];
y_patch = [yL(1) yL(1) yL(2) yL(2)];
fill(x_patch, y_patch, [0.85 0.93 1.0], ...
     'EdgeColor','none','FaceAlpha',0.6);
uistack(findobj(gca,'Type','Stair'),'top'); % keep lines above

% Panel C: Log error (full range, stair plot)
f3 = figure('Name','Ex1a Log Error','Color','w');
set(f3,'Units','centimeters','Position',[2 2 20 13])
hold on

lw = 0.9;                             % thinner linewidth
for i = 1:numel(S)
    r = S{i}.series.r(:);
    y = S{i}.series.y(:);
    e = abs(r - y);
    stairs(t, max(e, eps), 'LineStyle', styles{i});
end

set(gca, 'YScale', 'log', 'TickDir', 'out', 'Box', 'off');
xlabel('$k$'); ylabel('$|r_k - y_k|$');
xlim([1 T]);
legend boxoff;
grid on;
% blue patch
ylim([1e-14 1]);
yL = ylim;
x_patch = [1 cfg.Twarm cfg.Twarm 1];
y_patch = [yL(1) yL(1) yL(2) yL(2)];
fill(x_patch, y_patch, [0.85 0.93 1.0], ...
     'EdgeColor','none','FaceAlpha',0.6);
uistack(findobj(gca,'Type','Stair'),'top'); % keep lines above
legend([{'PRBS'}, names], 'NumColumns', 2, 'Location', 'southoutside');

% Vector export, exact size
exportgraphics(f1, fullfile(cfg.figdir,'ex1a_output.pdf'), 'ContentType','vector')
exportgraphics(f2, fullfile(cfg.figdir,'ex1a_output_zoom.pdf'), 'ContentType','vector')
exportgraphics(f3, fullfile(cfg.figdir, 'ex1a_log_error.pdf'), 'ContentType', 'vector');

%% ---- Figure 2: Input (full + zoom) ----
f2 = figure('Name','Ex1a Input','Color','w');
tiledlayout(2,1,'TileSpacing','compact','Padding','compact')

% 2A: full
nexttile; hold on
for i=1:numel(S), stairs(t, S{i}.series.u); end
xlabel('k'); ylabel('Input')
% title('Applied input (full range)')
xlim([1 T]); legend(names,'Location','best')

% 2B: zoom
nexttile; hold on
for i=1:numel(S), stairs(tZ, S{i}.series.u(1:numel(tZ))); end
xlabel('k'); ylabel('Input')
% title(sprintf('Applied input (zoom first %d steps)', numel(tZ)))
xlim([1 numel(tZ)]); legend(names,'Location','best')

saveas(f2, fullfile(cfg.figdir,'ex1a_input.pdf'))


%% ---- Figure 3: Diagnostics ----
f3 = figure('Name','Ex1a Diagnostics','Color','w');
tiledlayout(1,2,'TileSpacing','compact','Padding','compact')

% 3A: log10 EWMA(e^2)
nexttile; hold on
for i=1:numel(S), stairs(t, S{i}.series.log10_ew); end
xlabel('k'); ylabel('$\log_{10} EWMA(e_k^2)$')
% title('Prediction-error power'); xlim([1 T])
legend(names,'Location','best')

% 3B: parameter error for unit kernel (if present)
nexttile; hold on
i_unit = find(strcmpi(extract_types(S),'ones'),1,'first');
if ~isempty(i_unit) && ~isempty(S{i_unit}.series.theta_hist)
    k0 = find(~isnan(S{i_unit}.series.e),1,'first');
    th = S{i_unit}.series.theta_hist;
    theta_star = S{i_unit}.cfg_to_true(:);
    E = vecnorm(th(2:5,:) - theta_star,2,1).';
    kk = (k0:(k0+numel(E)-1)).';
    stairs(kk,E)
    xlabel('k'); ylabel('$||\theta_k - \theta^\ast||_2$')
    % title('Parameter error (unit kernel)')
else
    axis off; text(0.05,0.5,'Parameter error shown for unit kernel only.','FontSize',10)
end

saveas(f3, fullfile(cfg.figdir,'ex1a_diagnostics.pdf'))

%% ---- Metrics CSV (Phase II) ----
% recompute if missing; write tidy CSV
write_metrics_csv(S, fullfile(cfg.tbldir,'ex1a_phaseII_metrics.csv'))

disp('Done.')

%% ==================== Helpers ====================

function S = load_all(files)
    S = cell(size(files));
    for i=1:numel(files)
        R = load(files{i}, 'Results'); R = R.Results;
        % stash true theta for plotting convenience
        R.cfg_to_true = [1.5; -0.7; 0.5; 0.3];
        % ensure metrics exist; otherwise compute from series
        if ~isfield(R,'metrics') || isempty(R.metrics)
            R.metrics = compute_metrics_from_series(R.series, R.cfg);
        else
            % normalize field names if needed
            R.metrics = normalize_metric_names(R.metrics);
        end
        S{i} = R;
    end
end

function M = compute_metrics_from_series(series, cfg)
    % Phase-II window matches paper: [Twarm+1, Twarm+900] i.e., 51..950 for default cfg
    Tw = cfg.Twarm;
    idx2 = (Tw+1):(Tw+900);
    r = series.r(:); y = series.y(:); u = series.u(:);
    e = series.e(:);
    % Safety guards
    idx2 = idx2(idx2<=numel(y));
    n = numel(idx2);
    M.RMSE_PhaseII = sqrt(mean((r(idx2)-y(idx2)).^2));
    M.IAE_PhaseII  = sum(abs(r(idx2)-y(idx2)));
    M.TV_u         = sum(abs(diff(u)));
    M.Peak_u       = max(abs(u));
    % final EWMA(e^2) in log10 if available; else NaN
    if isfield(series,'log10_ew') && ~isempty(series.log10_ew)
        v = series.log10_ew(:);
        M.Final_log10_EWMA_e2 = v(find(~isnan(v),1,'last'));
    else
        M.Final_log10_EWMA_e2 = NaN;
    end
end

function M = normalize_metric_names(M)
    % Map alternate field names to CSV schema if needed
    if isfield(M,'rmse2'), M.RMSE_PhaseII = M.rmse2; end
    if isfield(M,'iae2'),  M.IAE_PhaseII  = M.iae2;  end
    if isfield(M,'tv_u'),  M.TV_u         = M.tv_u;  end
    if isfield(M,'peak_u'),M.Peak_u       = M.peak_u;end
    if isfield(M,'final_log10_ew')
        M.Final_log10_EWMA_e2 = M.final_log10_ew;
    end
end

function names = legend_names(S)
    names = strings(1, numel(S));
    for i=1:numel(S), names(i) = spec_name(S{i}.spec); end
    names = cellstr(names);
end

function t = extract_types(S)
    t = strings(1,numel(S));
    for i=1:numel(S), t(i) = string(lower(S{i}.spec.type)); end
end

function s = spec_name(spec)
    switch lower(spec.type)
        case 'ones',   s = 'Unitary';
        case 'linear', s = 'Linear';
        case 'poly',   s = sprintf('Polynomial-%d', spec.degree); %#ok<GFLD>
        case 'rbf',    s = sprintf('RBF', spec.sigma);
        otherwise,     s = 'unknown';
    end
end

function write_metrics_csv(S, path)
    fid = fopen(path,'w');
    fprintf(fid,'Method,RMSE_PhaseII,IAE_PhaseII,TV_u,Peak_u,Final_log10_EWMA_e2\n');
    for i=1:numel(S)
        M = S{i}.metrics;
        fprintf(fid,'%s,%.6g,%.6g,%.6g,%.6g,%.6g\n', ...
            spec_name(S{i}.spec), M.RMSE_PhaseII, M.IAE_PhaseII, ...
            M.TV_u, M.Peak_u, M.Final_log10_EWMA_e2);
    end
    fclose(fid);
end
