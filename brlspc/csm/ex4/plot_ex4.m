close all; clc; clear;

clear; clc; close all; %% ---- Config ---- 
cfg.linewidth = 3.0; 
cfg.zoomN = 80; % zoom-in prefix length 
cfg.figdir = 'brlspc/csm/ex4/figs'; 
cfg.tbldir = 'brlspc/csm/ex4/tables'; 
cfg.resdir = 'brlspc/csm/ex4/results'; 
cfg.files = dir(fullfile(cfg.resdir, '*.mat'));
cfg.files = fullfile(cfg.resdir, {cfg.files.name});
if ~exist(cfg.figdir,'dir'), mkdir(cfg.figdir); end 
if ~exist(cfg.tbldir,'dir'), mkdir(cfg.tbldir); end 

% --- Global aesthetics (put before plotting) ---
set(groot,'defaultTextInterpreter','latex')
set(groot,'defaultAxesTickLabelInterpreter','latex')
set(groot,'defaultLegendInterpreter','latex')

set(0,'DefaultFigureColor','w') 
set(0,'DefaultAxesColor','w') 
set(0,'DefaultLegendColor','w') 
set(0,'DefaultAxesXColor','k') 
set(0,'DefaultAxesYColor','k') 
set(0,'DefaultAxesZColor','k') 
set(0,'DefaultTextColor','k') 
set(0,'DefaultLegendTextColor','k')

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
set(groot,'DefaultStairLineWidth',cfg.linewidth)
set(groot,'DefaultLineLineWidth',cfg.linewidth)
set(groot,'defaultAxesTickDir','out')
set(groot,'defaultAxesBox','off')
set(groot,'defaultAxesColorOrder',colors)

styles = {'-','-.',':',':'}; 

%% ---- Load ---- 
S = load_all(cfg.files); 
T = numel(S{1}.series.y); 
t = (1:T).'; 
tclip = S{1}.cfg.ell+1:T-1;
tZ = (1:min(cfg.zoomN,T)).'; 
names = legend_names(S);
cfg.Twarm = S{1,1}.cfg.Twarm;

%% --- Output trace figure ---
f_output = figure('Units','centimeters','Position',[2 2 20 10],'Color','w');
tl = tiledlayout(1,1,'Padding','compact','TileSpacing','compact');
nexttile(tl); hold on
for i=1:numel(S),stairs(t, S{i}.series.y,'LineStyle',styles{i}); end
stairs(t, S{1}.series.r,'k--')
xlabel('$k$'); ylabel('$y_k$')
xlim([1 T]);
legend('off')
% blue patch
yL = ylim;
x_patch = [1 cfg.Twarm cfg.Twarm 1];
y_patch = [yL(1) yL(1) yL(2) yL(2)];
fill(x_patch, y_patch, [0.85 0.93 1.0], ...
     'EdgeColor','none','FaceAlpha',0.6);
uistack(findobj(gca,'Type','Stair'),'top'); % keep lines above

drawnow;  % finalize tiledlayout positions

ov = axes('Parent',f_output,'Position',[0 0 1 1],'Units','normalized', ...
          'Color','none','XLim',[0 1],'YLim',[0 1], ...
          'HitTest','off','Visible','off');  % overlay for connectors

% tiles are reversed in tl.Children
axes_in_order = flipud(tl.Children);
ax = axes_in_order(1);
add_magnifier_overlay(ax, [cfg.Twarm+1, cfg.Twarm+20], [0.35 0.75 0.4 0.28], [], ov);
add_magnifier_overlay(ax, [251, 275], [0.7 0.08 0.3 0.28], [], ov);

%% --- Output error log figure ---
f_err_log = figure('Name','Log Error','Color','w');
set(f_err_log,'Units','centimeters','Position',[2 2 20 10])
hold on

lw = 0.9;                             % thinner linewidth
for i = 1:numel(S)
    r = S{i}.series.r(:);
    y = S{i}.series.y(:);
    e = abs(r - y);
    stairs(t, max(e, eps), 'LineStyle', styles{i});
end

set(gca, 'YScale', 'log', 'TickDir', 'out', 'Box', 'off', 'YMinorTick','on', 'YLim',[1e-12 2e0], ...
        'YTick',10.^(-12:3:0));
xlabel('$k$'); ylabel('$|r_k - y_k|$');
xlim([1 T]);
legend boxoff;
grid on;
% blue patch
yL = ylim;
x_patch = [1 cfg.Twarm cfg.Twarm 1];
y_patch = [yL(1) yL(1) yL(2) yL(2)];
fill(x_patch, y_patch, [0.85 0.93 1.0], ...
     'EdgeColor','none','FaceAlpha',0.6);
uistack(findobj(gca,'Type','Stair'),'top'); % keep lines above
legend([{'PRBS'}, names], 'NumColumns', 2, 'Location', 'southoutside');

%% ---- Prediction error ----
fPred = figure('Units','centimeters','Position',[2 2 20 11],'Color','w');

nexttile; hold on
for i=1:numel(S)
    e = S{i}.series.e(:);
    ae = max(abs(e), 1e-14);
    stairs(tclip, ae, 'LineStyle', styles{i});
end
set(gca,'YScale','log','TickDir','out','Box','off')
xlabel('$k$'); ylabel('$|\hat{y}_k-y_k|$')
% xlim([1 T])
% legend(legend_names(S),'NumColumns',2,'Location','southoutside'); legend boxoff
yL = ylim;
x_patch = [1 cfg.Twarm cfg.Twarm 1];
y_patch = [yL(1) yL(1) yL(2) yL(2)];
fill(x_patch, y_patch, [0.85 0.93 1.0], ...
     'EdgeColor','none','FaceAlpha',0.6);
uistack(findobj(gca,'Type','Stair'),'top'); % keep lines above
legend boxoff
legend([{'PRBS'}, names], 'NumColumns', 2, 'Location', 'southoutside');

K = numel(S);
T = numel(S{1}.series.lpv_coeff);
tt = S{1}.cfg.ell+1:T-1;

% ===== LPV-ARX A (with magnifier insets) =====
% Assumes: S, K, ellA, tt, T, cfg, coeff_true, styles, names, val_or_fro

ellA = 2;
fA = figure('Name','LPV-ARX A','Color','w');
set(fA,'Units','centimeters','Position',[2 2 13 13])
tl = tiledlayout(ellA,1,'Padding','compact','TileSpacing','compact');

for j = 1:ellA
    ax = nexttile(tl); hold(ax,'on')
    % ax.PositionConstraint = 'innerposition';

    % series
    for i = 1:K
        v = zeros(numel(tt),1); l = 1;
        for k = tt
            v(l) = S{i}.series.lpv_coeff(k).Ak{j};
            l = l + 1;
        end
        stairs(ax, tt, v, 'LineStyle', styles{i}, 'DisplayName', names{i});
    end

    % PRBS shading BEHIND data
    yL = ylim(ax);
    fill([1 cfg.Twarm cfg.Twarm 1],[yL(1) yL(1) yL(2) yL(2)], ...
        [0.85 0.93 1.0],'EdgeColor','none','FaceAlpha',0.6,'Parent',ax);

    % axes cosmetics
    grid(ax,'on'); xlim(ax,[1 T]); xlabel(ax,'$k$'); ylabel(ax,sprintf('$A_{k,%d}$', j));

    % bring data above shading
    uistack(findall(ax,'Type','Stair','-or','Type','Line'),'top');
    hold(ax,'off')
end

% -------- B-blocks --------
ellB = 3;
fB = figure('Name','LPV-ARX B','Color','w');
set(fB,'Units','centimeters','Position',[2 2 13 13])

tl = tiledlayout(ellB,1,'Padding','compact','TileSpacing','compact');

for j = 1:ellB
    nexttile(tl); hold on
    for i = 1:K
        v = zeros(length(tt),1);
        l = 1;
        for k = tt   % avoid shadowing
            v(l) = S{i}.series.lpv_coeff(k).Bk{j};
            l = l + 1;
        end
        stairs(tt, v, 'LineStyle', styles{i}, 'DisplayName', names{i});
    end
    grid on
    xlabel('$k$'); ylabel(sprintf('$B_{k,%d}$', j-1));
    xlim([1 T]);
    yL = ylim;
    x_patch = [1 cfg.Twarm cfg.Twarm 1];
    y_patch = [yL(1) yL(1) yL(2) yL(2)];
    fill(x_patch, y_patch, [0.85 0.93 1.0], ...
        'EdgeColor','none','FaceAlpha',0.6);
    uistack(findobj(gca,'Type','Stair'),'top'); % keep lines above
    hold off
end

% -------- C-block --------
fC = figure('Name','LPV-ARX C','Color','w'); hold on
set(fC,'Units','centimeters','Position',[2 2 17 6])
tl = tiledlayout(1,1,'Padding','compact','TileSpacing','compact');
nexttile(tl);
hold on
for i = 1:K
    v = zeros(length(tt),1);
    l = 1;
    for t = tt
        v(l) = S{i}.series.lpv_coeff(t).Ck;
        l = l + 1;
    end
    stairs(tt, v, 'LineStyle', styles{i}, 'DisplayName', names{i});
end
grid on; xlabel('$k$'); ylabel('$C_k$');
xlim([1,T])

yL = ylim;
x_patch = [1 cfg.Twarm cfg.Twarm 1];
y_patch = [yL(1) yL(1) yL(2) yL(2)];
fill(x_patch, y_patch, [0.85 0.93 1.0], ...
    'EdgeColor','none','FaceAlpha',0.6);
uistack(findobj(gca,'Type','Stair'),'top'); % keep lines above
legend boxoff
legend([{'PRBS'}, names], 'NumColumns', 2, 'Location', 'westoutside');
hold off

%% ---- Theta plot ----
f_theta = figure('Units','centimeters','Position',[10 2 20 18],'Color','w');
tl = tiledlayout(5,2,'Padding','compact','TileSpacing','compact');
theta_idx = S{1}.theta.idx;
names_th = {};
s = cell(2);
ii = 1;

for k = 1:numel(S)
    if (strcmp(S{k}.spec.type, 'linear') || strcmp(S{k}.spec.type, 'poly'))
        names_th{end+1} = names{k};
        for i=1:numel(S{1}.theta.true)
            nexttile(tl,i); hold on

            theta_plot = nan(1, T);  % preallocate with NaN for missing data

            for j = 1:T
                if numel(S{k}.theta_id(j).theta) >= i
                    theta_plot(j) = S{k}.theta_id(j).theta(theta_idx(i));
                end
            end

            s{ii} = stairs(1:T, theta_plot, 'LineStyle', styles{k}, 'Color', colors(ii,:));
            s2 = stairs(1:T, ones(length(1:T),1) * S{1}.theta.true(i), ...
                'LineStyle', ':', 'Color', 'black', 'LineWidth', 2.0);
            xlim([1,T])
            grid on; xlabel('$k$');
            ylabel(sprintf('$\\beta_{%d}$',i));

            yL = ylim;
            x_patch = [1 cfg.Twarm cfg.Twarm 1];
            y_patch = [yL(1) yL(1) yL(2) yL(2)];
            p1 = fill(x_patch, y_patch, [0.85 0.93 1.0], ...
                'EdgeColor','none','FaceAlpha',0.6);
            uistack(findobj(gca,'Type','Stair'),'top'); % keep lines above
        end
        ii = ii + 1;
    end
end

legend boxoff
L = legend(s2, 'True coefficient', 'NumColumns', 2);
L.Layout.Tile = 'south';
hold off

%% ---- Theta residual ----

f_res = figure('Units','centimeters','Position',[10 2 16 4],'Color','w');
tl = tiledlayout(1,1,'Padding','compact','TileSpacing','compact');
theta_residual_idx = setdiff(1:numel(S{1}.theta.true), theta_idx);
nexttile(tl); hold on
ii = 1;

for k = 1:numel(S)
    if (strcmp(S{k}.spec.type, 'linear') || strcmp(S{k}.spec.type, 'poly'))

        theta_res_plot = nan(1, T);  % preallocate with NaN for missing data

        for j = 1:T
            if numel(S{k}.theta_id(j).theta) >= 1
                theta_res_plot(j) = 0;
                for i = 1:numel(theta_residual_idx)
                    theta_res_plot(j) = theta_res_plot(j) + S{k}.theta_id(j).theta(theta_residual_idx(i))^2;
                end
                theta_res_plot(j) = sqrt(theta_res_plot(j));
            end
        end

        s{ii} = stairs(1:T, log10(theta_res_plot), 'LineStyle', styles{k});
        xlim([1,T])
        grid on; xlabel('$k$');
        ylabel('$\log_{10}||\beta_{\mathrm{res}}||$');

        yL = ylim;
        x_patch = [1 cfg.Twarm cfg.Twarm 1];
        y_patch = [yL(1) yL(1) yL(2) yL(2)];
        p1 = fill(x_patch, y_patch, [0.85 0.93 1.0], ...
            'EdgeColor','none','FaceAlpha',0.6);
        uistack(findobj(gca,'Type','Stair'),'top'); % keep lines above

        ii = ii + 1;
    end
end
L = legend([p1, s{1}, s{2}], [{'PRBS'}, names_th], 'NumColumns', 2);
L.Layout.Tile = 'east';
legend boxoff
hold off
drawnow;

save_pdf_noscale(f_output,  fullfile(cfg.figdir,'ex4_output.pdf'));
save_pdf_noscale(f_err_log, fullfile(cfg.figdir,'ex4_output_log_error.pdf'));
save_pdf_noscale(fPred,     fullfile(cfg.figdir,'ex4_err_prediction.pdf'));
save_pdf_noscale(fA,        fullfile(cfg.figdir,'ex4_err_Ak.pdf'));
save_pdf_noscale(fB,        fullfile(cfg.figdir,'ex4_err_Bk.pdf'));
save_pdf_noscale(fC,        fullfile(cfg.figdir,'ex4_err_Ck.pdf'));
save_pdf_noscale(f_theta,   fullfile(cfg.figdir,'ex4_theta.pdf'));
save_pdf_noscale(f_res,     fullfile(cfg.figdir,'ex4_theta_res.pdf'));

%% ---- Metrics CSV (Phase II) ----
% recompute if missing; write tidy CSV
write_metrics_csv(S, fullfile(cfg.tbldir,'ex4_phaseII_metrics.csv'))

disp('Done.')

%% ==================== Helpers ====================

function S = load_all(files)
    S = cell(size(files));
    for i=1:numel(files)
        R = load(files{i}, 'Results'); R = R.Results;
        % stash true theta for plotting convenience
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
    fprintf(fid,'Method,RMSE_PhaseII,IAE_PhaseII,TV_u,Peak_u\n');
    for i=1:numel(S)
        M = S{i}.metrics;
        fprintf(fid,'%s,%.6g,%.6g,%.6g,%.6g\n', ...
            spec_name(S{i}.spec), M.RMSE_PhaseII, M.IAE_PhaseII, ...
            M.TV_u, M.Peak_u);
    end
    fclose(fid);
end

function add_magnifier_overlay(ax, xwin, inset_rel, true_val, ov)
    fig = ancestor(ax,'figure');

    % collect series (stairs + lines)
    H = [flipud(findall(ax,'Type','Stair')); flipud(findall(ax,'Type','Line'))];
    if isempty(H), return; end

    xmin = xwin(1); xmax = xwin(2);

    % window segments + y-lims
    ylo = inf; yhi = -inf;
    Xseg = cell(numel(H),1); Yseg = cell(numel(H),1);
    for i = 1:numel(H)
        x = get(H(i),'XData'); y = get(H(i),'YData');
        if isempty(x) || isempty(y), continue; end
        m = (x>=xmin) & (x<=xmax);
        if any(m)
            Xseg{i} = x(m); Yseg{i} = y(m);
            ylo = min(ylo, min(Yseg{i}));
            yhi = max(yhi, max(Yseg{i}));
        end
    end
    if ~isfinite(ylo), return; end
    pad = 0.05*(yhi - ylo + eps);
    y0 = ylo - pad; y1 = yhi + pad;

    % rectangle in data units on main axes
    rectangle(ax,'Position',[xmin y0 (xmax-xmin) (y1-y0)], ...
        'EdgeColor',[0.15 0.15 0.15],'LineWidth',0.6,'LineStyle','-','HitTest','off');

    % inset position relative to tile
    axpos = get(ax,'Position'); r = inset_rel;
    inset_pos = [axpos(1)+r(1)*axpos(3), axpos(2)+r(2)*axpos(4), r(3)*axpos(3), r(4)*axpos(4)];

    % inset axes (figure child)
    iax = axes('Parent',fig,'Units','normalized','Position',inset_pos); hold(iax,'on')
    set(iax,'Box','on','FontSize',max(get(ax,'FontSize')-1,6))
    for i = 1:numel(H)
        if isempty(Xseg{i}), continue; end
        stairs(iax, Xseg{i}, Yseg{i}, ...
            'LineStyle', get(H(i),'LineStyle'), ...
            'Color',     get(H(i),'Color'), ...
            'LineWidth', max(get(H(i),'LineWidth')-0.2,0.6));
    end
    if ~isempty(true_val)
        ytrue = double((numel(true_val)==1)*true_val + (numel(true_val)~=1)*norm(true_val,'fro'));
        yline(iax, ytrue, 'k--', 'LineWidth',0.6);
    end
    xlim(iax,[xmin xmax]); ylim(iax,[y0 y1]); xticks(iax,[]); yticks(iax,[]);
    hold(iax,'off')

    % connectors on overlay axes (normalized coords)
    [x2n,y2n] = data2fignorm_plotbox(ax, xmax, y1);
    [x3n,y3n] = data2fignorm_plotbox(ax, xmax, y0);
    ix = inset_pos(1); iy = inset_pos(2); iw = inset_pos(3); ih = inset_pos(4);
    line(ov,[x2n ix],[y2n iy+ih],'Color',[0.2 0.2 0.2],'LineWidth',0.6);
    line(ov,[x3n ix],[y3n iy   ],'Color',[0.2 0.2 0.2],'LineWidth',0.6);
end

function [xn,yn] = data2fignorm_plotbox(ax, xd, yd)
    pb = plotboxpos(ax); xl = xlim(ax); yl = ylim(ax);
    if strcmpi(ax.XScale,'log'), xd = log10(xd); xl = log10(xl); end
    if strcmpi(ax.YScale,'log'), yd = log10(yd); yl = log10(yl); end
    fx = (xd - xl(1)) / max(xl(2)-xl(1), eps);
    fy = (yd - yl(1)) / max(yl(2)-yl(1), eps);
    xn = pb(1) + fx*pb(3);
    yn = pb(2) + fy*pb(4);
end

function pb = plotboxpos(ax)
    old = ax.Units; ax.Units = 'normalized';
    op  = ax.OuterPosition; ti = ax.TightInset;
    pb  = [op(1)+ti(1), op(2)+ti(2), op(3)-ti(1)-ti(3), op(4)-ti(2)-ti(4)];
    ax.Units = old;
end

function save_pdf_noscale(fig, filename)
    % Lock figure size
    set(fig,'Renderer','painters');                  % vector
    set(fig,'InvertHardcopy','off');                 % keep background
    % Use centimeters for 1:1 mapping
    oldU = get(fig,'Units'); set(fig,'Units','centimeters');
    pos  = get(fig,'Position');                     % [x y w h] in cm
    % Paper = exactly the on-screen size
    set(fig,'PaperUnits','centimeters');
    set(fig,'PaperPositionMode','manual');
    set(fig,'PaperPosition',[0 0 pos(3) pos(4)]);
    set(fig,'PaperSize',[pos(3) pos(4)]);
    % Important: no '-bestfit' or '-fillpage'
    print(fig, filename, '-dpdf', '-painters', '-r300');
    % restore
    set(fig,'Units',oldU);
end