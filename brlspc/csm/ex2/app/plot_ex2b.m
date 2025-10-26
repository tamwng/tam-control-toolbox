close all; clc; clear;

clear; clc; close all; %% ---- Config ---- 
cfg.linewidth = 3.0; 
cfg.zoomN = 80; % zoom-in prefix length 
cfg.figdir = 'brlspc/csm/ex2/app/figs'; 
cfg.resdir = 'brlspc/csm/ex2/app/results'; 
cfg.files = dir(fullfile(cfg.resdir, '*.mat'));
cfg.files = fullfile(cfg.resdir, {cfg.files.name});
if ~exist(cfg.figdir,'dir'), mkdir(cfg.figdir); end 

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

styles = {'-','-.'}; 

%% ---- Load ---- 
res = load_all(cfg.files); 
omega = res{1}{1}.cfg.omega_dstb;
names = legend_names(res);
f  = figure('Units','centimeters','Position',[3 4 15 12],'Color','w');
hold on

for k = 1:numel(res)
    out = zeros(numel(omega), 1);
    for i = 1:numel(omega)
        out(i) = log10(res{k}{i}.metrics.RMSE_PhaseII);
    end
    h = plot(omega, out,'LineStyle',styles{k}); %#ok<*UNRCH>
end
% leg{end+1} = get(h,'DisplayName'); %#ok<AGROW>
xticks([0, pi/4, pi/2, 3*pi/4, pi])
xticklabels({'$0$', '$\pi/4$','$\pi/2$','$3\pi/4$','$\pi$'})
xlim([0,pi])
ylabel('$\mathrm{RMSE}$')
xlabel('$\omega$')
legend(names, 'Location','southoutside','Interpreter','latex'); legend boxoff;

% Vector export, exact size
save_pdf_noscale(f,  fullfile(cfg.figdir,'ex2b_app_frequency.pdf'));

disp('Done.')

%% ==================== Helpers ====================

function S = load_all(files)
    S = cell(size(files));
    for i=1:numel(files)
        R = load(files{i}, 'S'); R = R.S;
        S{i} = R;
    end
end

function names = legend_names(S)
    names = strings(1, numel(S));
    for i=1:numel(S), names(i) = spec_name(S{i}{1}.spec); end
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