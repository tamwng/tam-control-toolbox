close all; clc; clear;

clear; clc; close all; %% ---- Config ---- 
cfg.linewidth = 3.0; 
cfg.zoomN = 80; % zoom-in prefix length 
cfg.figdir = 'brlspc/csm/ex7/figs'; 
cfg.resdir = 'brlspc/csm/ex7/results'; 
cfg.tbldir = 'brlspc/csm/ex7/tables'; 
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

styles = {'-.','-',':','--'}; 

%% ---- Load ---- 
res = load_all(cfg.files); 
names = legend_names(res);
T = size(res{1}.series.y,1); 
t = (1:T).'; 
Ts = res{1}.plant.Ts;

%% ---- Output Reponse ----
f_output  = figure('Units','centimeters','Position',[3 4 15 17],'Color','w');
tl = tiledlayout(4,1,'TileSpacing','compact','Padding','compact');
q = zeros(T,4);
qd = q;
s = cell(4,1);

for i = 1:numel(res)
    for j = 1:T
        q(j,:) = res{i}.state{j}.q.';
    end
    for k = 1:4
        ax = nexttile(tl,k); hold on
        s{i} = plot(0:res{1}.plant.Ts:res{1}.plant.Ts*(T-1),q(:,k), 'LineStyle',styles{i});
        if i == numel(res)
            stairs(0:res{1}.plant.Ts:res{1}.plant.Ts*(T-1),res{i}.ref(1:T,k), '--k');
        end
        switch k
            case 1
                ylabel('$\eta$');
            otherwise
                ylabel(sprintf('$\\varepsilon_%d$', k-1));
        end
    end

    if k == 4
        xlabel('$t$ (s)')
    end
end

drawnow;                                   % finalize tiledlayout positions
axes_in_order = flipud(findall(tl,'Type','axes'));  % robust axes list

for i = 1:numel(axes_in_order)
    ax = axes_in_order(i);
    hold(ax,'on');

    % freeze limits so the patch cannot move them
    set(ax,'XLimMode','manual','YLimMode','manual');
    yl = ylim(ax);

    % draw background patch that is ignored by autoscaling (when supported)
    hPatch = patch('XData',[0 (res{1}.cfg.Twarm-1)*Ts (res{1}.cfg.Twarm-1)*Ts 0], ...
                   'YData',[yl(1) yl(1) yl(2) yl(2)], ...
                   'Parent',ax, ...
                   'FaceColor',[0.85 0.93 1.0], ...
                   'FaceAlpha',0.6, ...
                   'EdgeColor','none', ...
                   'HandleVisibility','off');   % keep it out of legend
    try
        set(hPatch,'XLimInclude','off','YLimInclude','off');
    catch
        % older releases: the manual X/YLim modes already prevent expansion
    end

    % send patch to back
    uistack(hPatch,'bottom');
end

legend([hPatch, [s{:}]], [{'PRBS'}, names], 'NumColumns', 2, 'Location', 'southoutside');
legend boxoff


% Vector export, exact size
save_pdf_noscale(f_output,  fullfile(cfg.figdir,'ex7_output.pdf'));
write_effort_table(res, fullfile(cfg.tbldir,'ex7_phaseII_metrics.csv'))

disp('Done.')

%% ==================== Helpers ====================

function f_lpv = plot_endrun_heatmaps_results(Results_list, names)
% Results_list: 1xK cell array, each cell is a Results struct for a kernel
% names: 1xK cell array of kernel names in display order
% Uses the last identified LPV coefficients:
%   Results.series.lpv_coeff(end).Ak  % size p×p×ell
%   Results.series.lpv_coeff(end).Bk  % size p×m×(ell+1)
%   Results.series.lpv_coeff(end).C   % size p×p  (optional)
% Truth taken from the first entry:
%   Results.coeff_true.A, .B, .C      % sizes as above

K = numel(Results_list);
R1 = Results_list{1};
hasC = isfield(R1.series.lpv_coeff(end-1), 'Ck') && ~isempty(R1.series.lpv_coeff(end-1).Ck);
p = size(R1.series.lpv_coeff(end).Ak,1);
kLab = '299';

% Collect estimated final matrices for each kernel
X = cell(K+1,1);  % last row = truth
for i = 1:K
    Ri = Results_list{i};
    A_last = Ri.series.lpv_coeff(end-1).Ak;   % p×p×ell
    B_last = Ri.series.lpv_coeff(end-1).Bk;   % p×m×(ell+1)
    C_last = hasC * Ri.series.lpv_coeff(end-1).Ck;  %#ok<NASGU>
    X{i} = struct( ...
        'A1', A_last{1}, ...
        'A2', A_last{2}, ...
        'B0', B_last{1}, ...
        'B1', B_last{2}, ...
        'B2', B_last{3} ...
    );
    if hasC
        X{i}.C = Ri.series.lpv_coeff(end-1).Ck;
    end
end

% Truth
Atrue = R1.coeff_true.A;   % p×p×ell
Btrue = R1.coeff_true.B;   % p×m×(ell+1)
X{K+1} = struct( ...
    'A1', Atrue{1}, ...
    'A2', Atrue{2}, ...
    'B0', Btrue{1}, ...
    'B1', Btrue{2}, ...
    'B2', Btrue{3} ...
);
if isfield(R1.coeff_true,'C') && ~isempty(R1.coeff_true.C)
    X{K+1}.C = R1.coeff_true.C;
    hasC = true;
end

% Columns (include C if present)
cols = {'A1','A2','B0','B1','B2'};
if hasC, cols{end+1} = 'C'; end
nCols = numel(cols);

% Precompute symmetric color limits per column across all rows
cl = cell(1,nCols);
for j = 1:nCols
    mx = 0;
    for i = 1:(K+1)
        if isfield(X{i}, cols{j}) && ~isempty(X{i}.(cols{j}))
            mx = max(mx, max(abs(X{i}.(cols{j})(:))));
        end
    end
    cl{j} = [-max(mx, 1e-12), max(mx, 1e-12)];
end

% Plot grid: rows = kernels + truth; cols = blocks
f_lpv  = figure('Name','End-of-run heatmaps','Units','centimeters','Position',[2 4 40 20],'Color','w');
tiledlayout(K+1, nCols, 'TileSpacing','compact', 'Padding','compact');

for i = 1:(K+1)
    for j = 1:nCols
        ax = nexttile; 
        if isfield(X{i}, cols{j}) && ~isempty(X{i}.(cols{j}))
            imagesc(X{i}.(cols{j}));
            axis image off; clim(cl{j}); colorbar('eastoutside');
        else
            axis off;
        end
        if i == 1
            if (j < nCols)
                title(sprintf('$%s_%s$%', cols{j}(1),cols{j}(2)));
            else
                title(sprintf('$%s$%', cols{j}));
            end
        end
        if j==1
            if i <= K
                % lbl = sprintf('%s', Results_list{i}.spec.type);
                lbl = sprintf('%s', names{i});
            else
                lbl = 'True';
            end
            % ax.Clipping = 'off';  % allow text outside axes
            text(ax, -0.15, 0.5, lbl, 'Units','normalized', ...
                'HorizontalAlignment','center', 'VerticalAlignment','middle', ...
                'Rotation',90, 'FontWeight','normal');
        end
    end
end

% Optional: annotate first column with A_{k,·} style
% (kept minimal to avoid clutter; uncomment if desired)
% for i=1:K
%     nexttile(i*nCols - (nCols-1)); % first column tile in row i
%     text(0.5, -0.15, sprintf('A_{%s,\\cdot}', kLab), 'Units','normalized', ...
%          'HorizontalAlignment','center', 'VerticalAlignment','top');
% end

end

function S = load_all(files)
    S = cell(size(files));
    for i=1:numel(files)
        R = load(files{i}, 'Results'); R = R.Results;
        S{i} = R;
    end
end

function names = legend_names(S)
    names = strings(1, numel(S));
    for i=1:numel(S), names(i) = spec_name(S{i}.spec); end
    names = cellstr(names);
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

function write_effort_table(S, path)
    % Write Phase-II input-effort metrics (TV_u and Peak_u) for each kernel
    fid = fopen(path,'w');
    fprintf(fid,'Kernel,TV_u,Peak_u\n');
    for i = 1:numel(S)
        M = S{i}.metrics;
        fprintf(fid,'%s,%.6g,%.6g\n', ...
            spec_name(S{i}.spec), ...
            M.tv_u_all, M.peak_u_all);
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
    h = findobj(fig, 'Type', 'image');                % returns array of handles
    for k = 1:numel(h)
        set(h(k), 'Interpolation', 'nearest');
    end
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
    print(fig, filename, '-dpdf', '-painters', '-r600');
    % restore
    set(fig,'Units',oldU);
end