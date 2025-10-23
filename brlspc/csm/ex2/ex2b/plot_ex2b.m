close all; clc; clear;

clear; clc; close all; %% ---- Config ---- 
cfg.linewidth = 3.0; 
cfg.zoomN = 80; % zoom-in prefix length 
cfg.figdir = 'brlspc/csm/ex2/ex2b/figs'; 
cfg.tbldir = 'brlspc/csm/ex2/ex2b/tables'; 
cfg.resdir = 'brlspc/csm/ex2/ex2b/results'; 
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

set(groot,'defaultAxesFontSize',18)
set(groot,'defaultTextFontSize',18)
set(groot,'defaultLegendFontSize',20)
set(groot,'defaultAxesLineWidth',0.9)
set(groot,'DefaultStairLineWidth',cfg.linewidth)
set(groot,'DefaultLineLineWidth',cfg.linewidth)
set(groot,'defaultAxesTickDir','out')
set(groot,'defaultAxesBox','off')
set(groot,'defaultAxesColorOrder',colors)

styles = {'-','-',':',':'}; 

%% ---- Load ---- 
S = load_all(cfg.files); 
T = numel(S{1}.series.y); 
t = (1:T).'; 
tclip = S{1}.cfg.ell+1:T-1;
tZ = (1:min(cfg.zoomN,T)).'; 
names = legend_names(S);
cfg.Twarm = S{1,1}.cfg.Twarm;
ell = [2,3,4,5]; 
amp = [0.1, 0.5, 1];

%% Helper: line style per ell
ls_ell = @(e) switch_ls(e);
function s = switch_ls(e)
    switch e
        case 2, s = '-';
        case 3, s = '-';
        case 4, s = ':';
        case 5, s = '--';
        otherwise, s = '-.';
    end
end
lw_ell = @(e) switch_lw(e);
function w = switch_lw(e)
    switch e
        % thinner for ell=3 and ell = 5
        case 3, w = 1.0;
        case 5, w = 1.0;
        otherwise, w = 1.7;
    end
end

% find runs by type/ell/A
N = numel(S);
is_type  = @(i,typ) strcmp(S{i}.spec.type,typ);
matchrun = @(i,typ,e,a) is_type(i,typ) && S{i}.cfg.ell==e && S{i}.cfg.amp_dstb==a;
findrun  = @(typ,e,a) find(arrayfun(@(k) matchrun(k,typ,e,a), 1:N), 1, 'first');

% --- Figure A: unitary (ones). Rows = amplitudes. Each row overlays ell. ---
fA  = figure('Units','centimeters','Position',[2 2 16 17],'Color','w');
tlA = tiledlayout(numel(amp),1,'TileSpacing','compact','Padding','compact');
axA = gobjects(numel(amp),1);

for ai = 1:numel(amp)
    a = amp(ai);
    axA(ai) = nexttile(tlA); hold(axA(ai),'on'); grid(axA(ai),'on');

    leg = {};
    for ei = 1:numel(ell)
        e = ell(ei);
        idx = findrun('ones', e, a);
        if ~isempty(idx)
            h = stairs(axA(ai), t, S{idx}.series.y, ...
                       'LineStyle', ls_ell(e), ...
                       'LineWidth', lw_ell(e), ...
                       'DisplayName', sprintf('$\\ell=%d$',e), ...
                       'Tag', sprintf('ell=%d',e)); %#ok<*UNRCH>
            leg{end+1} = get(h,'DisplayName'); %#ok<AGROW>
        end
    end
    yline(axA(ai),0,'k:','HandleVisibility','off');
    xlim(axA(ai),[1 T]);

    if ai==numel(amp), xlabel(axA(ai),'$k$','Interpreter','latex'); end
    % amplitude in ylabel (no title)
    ylabel(axA(ai), sprintf('$y_k \\; (A=%.3g)$', a), 'Interpreter','latex');
    if ai == 1, legend(axA(ai), leg,'Location','northeastoutside','Interpreter','latex'); legend boxoff; end
end

% --- Insets: transient and steady zooms per row (clip ell=3 in y-limit calc) ---
drawnow;  % fix layout before overlay
ov = axes('Parent',fA,'Position',[0 0 1 1],'Units','normalized', ...
          'Color','none','XLim',[0 1],'YLim',[0 1], ...
          'HitTest','off','Visible','off');

% choose windows (edit as needed)
% Tw = S{findrun('ones',ell(1),amp(1))}.cfg.Twarm;   % use any matching run for Twarm

% place two insets per row
xwin_tr = [5, 250];                 % transient window
xwin_ss = [max(1, T-30),  T];                     % steady window
ax = axA(1);
% inset rectangles: [x y w h] in normalized units relative to tile
inset_tr = [0.57 0.05 0.45 0.45];
inset_ss = [0.27 0.75 0.55 0.35];

% compute y-limits from ell ≠ 3 only, but still plot all traces inside inset
opts.include_tags = {'ell=2','ell=4','ell=5'};
add_magnifier_overlay(ax, xwin_tr, inset_tr, 0, ov, opts);
add_magnifier_overlay(ax, xwin_ss, inset_ss, 0, ov, opts);

% place two insets per row
xwin_tr = [5, 250];                 % transient window
xwin_ss = [max(1, T-60),  T];                     % steady window
ax = axA(2);
% inset rectangles: [x y w h] in normalized units relative to tile
inset_tr = [0.57 0.15 0.45 0.45];
inset_ss = [0.47 0.85 0.45 0.25];

% compute y-limits from ell ≠ 3 only, but still plot all traces inside inset
opts.include_tags = {'ell=2','ell=4','ell=5'};
add_magnifier_overlay(ax, xwin_tr, inset_tr, 0, ov, opts);
add_magnifier_overlay(ax, xwin_ss, inset_ss, 0, ov, opts);

% place two insets per row
xwin_ss = [max(1, T-60),  T];                     % steady window
ax = axA(3);
% inset rectangles: [x y w h] in normalized units relative to tile
inset_ss = [0.47 0.03 0.45 0.38];

% compute y-limits from ell ≠ 3 only, but still plot all traces inside inset
opts.include_tags = {'ell=2','ell=4','ell=5'};
add_magnifier_overlay(ax, xwin_ss, inset_ss, 0, ov, opts);


%% Figure B: RBF. Same layout.
fB = figure('Units','centimeters','Position',[18 2 16 17],'Color','w');
tlB = tiledlayout(numel(amp),1,'TileSpacing','compact','Padding','compact');
axB = gobjects(numel(amp),1);

for ai = 1:numel(amp)
    a = amp(ai);
    axB(ai) = nexttile(tlB); hold(axB(ai),'on'); grid(axB(ai),'on');

    leg = {};
    for ei = 1:numel(ell)
        e = ell(ei);
        idx = findrun('rbf', e, a);
        if ~isempty(idx)
            h = stairs(axB(ai), t, S{idx}.series.y, ...
                       'LineStyle', ls_ell(e), ...
                       'LineWidth', lw_ell(e), ...
                       'DisplayName', sprintf('$\\ell=%d$',e), ...
                       'Tag', sprintf('ell=%d',e)); %#ok<*UNRCH>
            leg{end+1} = get(h,'DisplayName'); %#ok<AGROW>
        end
    end
    yline(axB(ai),0,'k:','HandleVisibility','off');
    xlim(axB(ai),[1 T]);

    if ai==numel(amp), xlabel(axB(ai),'$k$','Interpreter','latex'); end
    % amplitude in ylabel (no title)
    ylabel(axB(ai), sprintf('$y_k \\; (A=%.3g)$', a), 'Interpreter','latex');
    if ai == 1, legend(axB(ai), leg,'Location','northeastoutside','Interpreter','latex'); legend boxoff; end
end

% --- Insets: transient and steady zooms per row (clip ell=3 in y-limit calc) ---
drawnow;  % fix layout before overlay
ov = axes('Parent',fB,'Position',[0 0 1 1],'Units','normalized', ...
          'Color','none','XLim',[0 1],'YLim',[0 1], ...
          'HitTest','off','Visible','off');

% choose windows (edit as needed)
% Tw = S{findrun('ones',ell(1),amp(1))}.cfg.Twarm;   % use any matching run for Twarm

% place two insets per row
xwin_tr = [5, 250];                 % transient window
xwin_ss = [max(1, T-30),  T];                     % steady window
ax = axB(1);
% inset rectangles: [x y w h] in normalized units relative to tile
inset_ss = [0.27 0.65 0.55 0.45];

% compute y-limits from ell ≠ 3 only, but still plot all traces inside inset
opts.include_tags = {'ell=2','ell=4','ell=5'};
add_magnifier_overlay(ax, xwin_ss, inset_ss, 0, ov, opts);

% place two insets per row
xwin_tr = [5, 150];                 % transient window
xwin_ss = [max(1, T-120),  T];                     % steady window
ax = axB(2);
% inset rectangles: [x y w h] in normalized units relative to tile
inset_tr = [0.07 0.65 0.40 0.35];
inset_ss = [0.57 0.88 0.40 0.30];

% compute y-limits from ell ≠ 3 only, but still plot all traces inside inset
opts.include_tags = {'ell=2','ell=4','ell=5'};
add_magnifier_overlay(ax, xwin_tr, inset_tr, 0, ov, opts);
add_magnifier_overlay(ax, xwin_ss, inset_ss, 0, ov, opts);

% place two insets per row
xwin_ss = [max(1, T-120),  T];                     % steady window
ax = axB(3);
% inset rectangles: [x y w h] in normalized units relative to tile
inset_ss = [0.07 0.03 0.45 0.33];

% compute y-limits from ell ≠ 3 only, but still plot all traces inside inset
opts.include_tags = {'ell=2','ell=4','ell=5'};
add_magnifier_overlay(ax, xwin_ss, inset_ss, 0, ov, opts);


% --- Figure: log instantaneous error for Unitary (ones). Rows = amplitudes. ---
% Assumes helpers ls_ell, lw_ell, findrun, and variables S,t,T,ell,amp exist.
eps2 = 1e-16;  % small offset to avoid log(0)

fE1  = figure('Units','centimeters','Position',[2 2 16 17],'Color','w');
tlE1 = tiledlayout(numel(amp),1,'TileSpacing','compact','Padding','compact');
axE1 = gobjects(numel(amp),1);

for ai = 1:numel(amp)
    a = amp(ai);
    axE1(ai) = nexttile(tlE1); hold(axE1(ai),'on'); grid(axE1(ai),'on');

    leg = {};
    for ei = 1:numel(ell)
        e = ell(ei);
        idx = findrun('ones', e, a);
        if ~isempty(idx)
            z = log10(S{idx}.series.y.^2 + eps2);  % r=0 ⇒ e=y
            h = stairs(axE1(ai), t, z, ...
                'LineStyle', ls_ell(e), ...
                'LineWidth',  lw_ell(e), ...
                'DisplayName', sprintf('$\\ell=%d$',e));
            leg{end+1} = get(h,'DisplayName'); %#ok<AGROW>
        end
    end
    xlim(axE1(ai), [1 T]);
    if ai==numel(amp), xlabel(axE1(ai),'$k$','Interpreter','latex'); end
    ylabel(axE1(ai), sprintf('$\\log_{10}(y_k^2)\\; (A=%.3g)$', a), 'Interpreter','latex');
    % if ai==1, lg = legend(axE1(ai), leg,'Location','northeastoutside','Interpreter','latex'); legend(axE1(ai),'boxoff'); end
end

% enforce LaTeX interpreters prior to export (optional)
set(findall(fE1,'Type','Legend'), 'Interpreter','latex');
set(findall(fE1,'Type','Axes'), 'TickLabelInterpreter','latex');

% --- Figure: log instantaneous error for RBF. Same layout. ---
fE2  = figure('Units','centimeters','Position',[2 2 16 17],'Color','w');
tlE2 = tiledlayout(numel(amp),1,'TileSpacing','compact','Padding','compact');
axE2 = gobjects(numel(amp),1);

for ai = 1:numel(amp)
    a = amp(ai);
    axE2(ai) = nexttile(tlE2); hold(axE2(ai),'on'); grid(axE2(ai),'on');

    leg = {};
    for ei = 1:numel(ell)
        e = ell(ei);
        idx = findrun('rbf', e, a);
        if ~isempty(idx)
            z = log10(S{idx}.series.y.^2 + eps2);  % r=0 ⇒ e=y
            h = stairs(axE2(ai), t, z, ...
                'LineStyle', ls_ell(e), ...
                'LineWidth',  lw_ell(e), ...
                'DisplayName', sprintf('$\\ell=%d$',e));
            leg{end+1} = get(h,'DisplayName'); %#ok<AGROW>
        end
    end
    xlim(axE2(ai), [1 T]);
    if ai==numel(amp), xlabel(axE2(ai),'$k$','Interpreter','latex'); end
    ylabel(axE2(ai), sprintf('$\\log_{10}(y_k^2)\\; (A=%.3g)$', a), 'Interpreter','latex');
    % if ai==1, lg = legend(axE2(ai), leg,'Location','northeastoutside','Interpreter','latex'); legend(axE2(ai),'boxoff'); end
end

% enforce LaTeX interpreters prior to export (optional)
set(findall(fE2,'Type','Legend'), 'Interpreter','latex');
set(findall(fE2,'Type','Axes'), 'TickLabelInterpreter','latex');



% Vector export, exact size
save_pdf_noscale(fA,  fullfile(cfg.figdir,'ex2b_output_unitary.pdf'));
save_pdf_noscale(fB,  fullfile(cfg.figdir,'ex2b_output_rbf.pdf'));
save_pdf_noscale(fE1, fullfile(cfg.figdir,'ex2b_output_log_error_unitary.pdf'));
save_pdf_noscale(fE2, fullfile(cfg.figdir,'ex2b_output_log_error_rbf.pdf'));

%% ---- Metrics CSV (Phase II) ----
% recompute if missing; write tidy CSV
write_metrics_csv(S, fullfile(cfg.tbldir,'ex2b_phaseII_metrics.csv'))

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
end

function M = normalize_metric_names(M)
    % Map alternate field names to CSV schema if needed
    if isfield(M,'rmse2'), M.RMSE_PhaseII = M.rmse2; end
    if isfield(M,'iae2'),  M.IAE_PhaseII  = M.iae2;  end
    if isfield(M,'tv_u'),  M.TV_u         = M.tv_u;  end
    if isfield(M,'peak_u'),M.Peak_u       = M.peak_u;end
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
    fprintf(fid,'Kernel,A,ell,RMSE_PhaseII,IAE_PhaseII,TV_u,Peak_u\n');
    for i = 1:numel(S)
        M = S{i}.metrics;
        fprintf(fid,'%s,%.3g,%d,%.6g,%.6g,%.6g,%.6g\n', ...
            spec_name(S{i}.spec), ...
            S{i}.cfg.amp_dstb, ...
            S{i}.cfg.ell, ...
            M.RMSE_PhaseII, M.IAE_PhaseII, M.TV_u, M.Peak_u);
    end
    fclose(fid);
end


function add_magnifier_overlay(ax, xwin, inset_rel, true_val, ov, opts)
    if nargin < 6, opts = struct; end
    if ~isfield(opts,'include_tags'), opts.include_tags = {}; end

    fig = ancestor(ax,'figure');

    % collect series
    Hall = [flipud(findall(ax,'Type','Stair')); flipud(findall(ax,'Type','Line'))];
    if isempty(Hall), return; end

    % handles used to compute inset y-limits (optionally exclude ell=3)
    Hlim = Hall;
    if ~isempty(opts.include_tags)
        tags = get(Hall,'Tag'); if ~iscell(tags), tags = {tags}; end
        keep = ismember(tags, opts.include_tags);
        if any(keep), Hlim = Hall(keep); end  % fall back to all if none match
    end

    xmin = xwin(1); xmax = xwin(2);

    % window segments + y-lims (from Hlim)
    ylo = inf; yhi = -inf;
    XsegAll = cell(numel(Hall),1); YsegAll = cell(numel(Hall),1);
    XsegLim = cell(numel(Hlim),1); YsegLim = cell(numel(Hlim),1);

    % cache segments for all traces
    for i = 1:numel(Hall)
        x = get(Hall(i),'XData'); y = get(Hall(i),'YData');
        if isempty(x) || isempty(y), continue; end
        m = (x>=xmin) & (x<=xmax);
        if any(m)
            XsegAll{i} = x(m); YsegAll{i} = y(m);
        end
    end
    % segments for limit computation
    for i = 1:numel(Hlim)
        x = get(Hlim(i),'XData'); y = get(Hlim(i),'YData');
        if isempty(x) || isempty(y), continue; end
        m = (x>=xmin) & (x<=xmax);
        if any(m)
            XsegLim{i} = x(m); YsegLim{i} = y(m);
            ylo = min(ylo, min(YsegLim{i}));
            yhi = max(yhi, max(YsegLim{i}));
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

    % inset axes
    iax = axes('Parent',fig,'Units','normalized','Position',inset_pos); hold(iax,'on')
    set(iax,'Box','on','FontSize',max(get(ax,'FontSize')-1,6))

    % plot all traces into inset (limits computed from Hlim)
    for i = 1:numel(Hall)
        if isempty(XsegAll{i}), continue; end
        stairs(iax, XsegAll{i}, YsegAll{i}, ...
            'LineStyle', get(Hall(i),'LineStyle'), ...
            'Color',     get(Hall(i),'Color'), ...
            'LineWidth', max(get(Hall(i),'LineWidth')-0.1,0.6));
    end
    if ~isempty(true_val)
        ytrue = double((numel(true_val)==1)*true_val + (numel(true_val)~=1)*norm(true_val,'fro'));
        yline(iax, ytrue, 'k--', 'LineWidth',0.6);
    end
    xlim(iax,[xmin xmax]); ylim(iax,[y0 y1]); xticks(iax,[]); yticks(iax,[]);

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