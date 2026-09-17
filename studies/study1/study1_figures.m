function study1_figures(output,cfg,summary)
%STUDY1_FIGURES Candidate Study 1 figures from the saved confirmation data.
%   Clean runs are primary; noisy trial 1 was selected before execution.
%   Error bars show Q1--Q3, or paired-bootstrap 95% intervals as labelled.
folder = fullfile(output,'figures');
if ~isfolder(folder), mkdir(folder); end
colors = lines(numel(cfg.modelIds));
clean = cell(1,numel(cfg.modelIds)); noisy = clean;
for j = 1:numel(cfg.modelIds)
    clean{j} = read_run(output,cfg.modelIds{j},0);
    noisy{j} = read_run(output,cfg.modelIds{j},cfg.representativeTrial);
end
trajectory_figure(clean,'Noise-free confirmation', ...
    '01_clean_trajectories',folder,cfg,colors);
trajectory_figure(noisy,sprintf('Noisy confirmation: preselected trial %d',cfg.representativeTrial), ...
    '02_representative_noisy_trajectories',folder,cfg,colors);
learning_figure(summary,folder,cfg,colors);
distribution_figure(summary,folder,cfg,colors);
contrast_figure(summary,folder);
forecast_figure(summary,folder,cfg,colors);
diagnostic_figure(clean,folder,cfg,colors);
measured_figure(summary,folder,cfg,colors);
fprintf('Study 1 candidate figures: 8 PNG and 8 SVG files.\n');
end

function result = read_run(output,id,trial)
saved = load(fullfile(output,'data',sprintf('confirmation_%s_%03d.mat',id,trial)),'result');
result = saved.result;
end

function trajectory_figure(runs,heading,name,folder,cfg,colors)
fig = new_figure([1100,850]);
layout = tiledlayout(fig,4,1,'TileSpacing','compact','Padding','compact');
labels = {'State and reference','Tracking error','Input','Input increment'};
for panel = 1:4
    ax = nexttile(layout); hold(ax,'on');
    for j = 1:numel(runs)
        run = runs{j}; t = run.time;
        switch panel
            case 1, value = run.x;
            case 2, value = run.x-run.r;
            case 3, value = run.u;
            case 4, value = [NaN,diff(run.u)];
        end
        plot(ax,t,value,'Color',colors(j,:),'LineWidth',1.05, ...
            'LineStyle',line_style(cfg.modelIds{j}),'DisplayName',cfg.modelIds{j});
    end
    switch panel
        case 1
            plot(ax,runs{1}.time,runs{1}.r,'k--','LineWidth',1.2,'DisplayName','reference');
            yline(ax,1.2,':','Color',[.4,.4,.4],'HandleVisibility','off');
            yline(ax,-1.2,':','Color',[.4,.4,.4],'HandleVisibility','off');
            lg = legend(ax,'Location','northoutside','Orientation','horizontal');
            lg.Box = 'off';
        case 2
            yline(ax,0,':','HandleVisibility','off');
        case 3
            yline(ax,1,':','Color',[.4,.4,.4],'HandleVisibility','off');
            yline(ax,-1,':','Color',[.4,.4,.4],'HandleVisibility','off');
        case 4
            yline(ax,.25,':','Color',[.4,.4,.4],'HandleVisibility','off');
            yline(ax,-.25,':','Color',[.4,.4,.4],'HandleVisibility','off');
    end
    ylabel(ax,labels{panel}); xlim(ax,[0,cfg.duration]); style_axes(ax);
    if panel == 4, xlabel(ax,'Time (s)'); end
end
title(layout,{heading,'Plant A; fixed dictionaries, no forgetting; dotted lines denote bounds'});
save_figure(fig,folder,name);
end

function learning_figure(summary,folder,cfg,colors)
fig = new_figure([1120,760]);
layout = tiledlayout(fig,2,2,'TileSpacing','compact','Padding','compact');
block = summary.initialization(summary.initialization.campaign == "confirmation",:);
for panel = 1:4
    ax = nexttile(layout); hold(ax,'on');
    noisy = mod(panel,2) == 0;
    parameter = panel > 2;
    for j = 1:numel(cfg.modelIds)
        id = cfg.modelIds{j};
        if parameter && ~ismember(id,{'S','R','P2'}), continue; end
        selected = block(block.model == id & block.noise == noisy,:);
        center = nan(1,4); low = center; high = center;
        for k = 1:4
            values = selected(selected.fittingTransitions == cfg.fitSteps(k),:);
            if parameter, values = values.parameterScaledPercent;
            else, values = values.predictionRMS; end
            center(k) = quantile_linear(values,.5);
            low(k) = quantile_linear(values,.25);
            high(k) = quantile_linear(values,.75);
        end
        center = display_floor(center); low = display_floor(low); high = display_floor(high);
        errorbar(ax,cfg.fitSteps,center,center-low,high-center, ...
            '-o','Color',colors(j,:),'MarkerSize',4,'LineWidth',1.2,'DisplayName',id);
    end
    set(ax,'YScale','log','XTick',cfg.fitSteps);
    xlabel(ax,'Fitting transitions');
    if parameter
        ylabel(ax,'Scaled parameter error (%)');
    else
        ylabel(ax,'Common-data prediction RMS');
    end
    if noisy, title(ax,'40 paired noisy fits: median and IQR');
    else, title(ax,'Noise-free fit'); end
    style_axes(ax); legend(ax,'Location','best','Box','off');
end
title(layout,{'Independent 600-transition evaluation record', ...
    'Exact parameter targets only for S, R and P2; logarithmic display floor 10^{-16}'});
save_figure(fig,folder,'03_initialization_learning');
end

function distribution_figure(summary,folder,cfg,colors)
fig = new_figure([1120,720]);
layout = tiledlayout(fig,2,2,'TileSpacing','compact','Padding','compact');
scores = {'trackingRMS','predictionTrueRMS','inputRMS','meanAbsoluteIncrement'};
labels = {'Tracking RMS','Prospective prediction RMS (true state)', ...
    'Input RMS','Mean absolute input increment'};
for panel = 1:4
    ax = nexttile(layout); hold(ax,'on');
    for j = 1:numel(cfg.modelIds)
        row = summary.noisy(summary.noisy.campaign == "confirmation" & ...
            summary.noisy.window == "stationary" & summary.noisy.model == cfg.modelIds{j} & ...
            summary.noisy.metric == scores{panel},:);
        errorbar(ax,j,row.median,row.median-row.q1,row.q3-row.median, ...
            'o','Color',colors(j,:),'MarkerFaceColor',colors(j,:), ...
            'MarkerSize',6,'LineWidth',1.5,'CapSize',10);
    end
    xlim(ax,[.5,numel(cfg.modelIds)+.5]);
    set(ax,'XTick',1:numel(cfg.modelIds),'XTickLabel',cfg.modelIds);
    ylabel(ax,labels{panel}); style_axes(ax);
end
counts = summary.counts(summary.counts.campaign == "confirmation" & summary.counts.noise,:);
countText = strjoin(compose('%s %d/%d',counts.model,counts.completed,counts.attempted),'; ');
title(layout,{'Noisy confirmation: median and interquartile range', ...
    sprintf('Last 10 s of every 20 s plateau; completed/attempted: %s',countText)});
save_figure(fig,folder,'04_noisy_stationary_scores');
end

function contrast_figure(summary,folder)
fig = new_figure([1120,720]);
layout = tiledlayout(fig,2,2,'TileSpacing','compact','Padding','compact');
scores = {'trackingRMS','predictionTrueRMS','inputRMS','meanAbsoluteIncrement'};
labels = {'Tracking RMS difference','Prediction RMS difference', ...
    'Input RMS difference','Mean input increment difference'};
contrasts = ["S-A","S-W","S-R","R-P2"];
for panel = 1:4
    ax = nexttile(layout); hold(ax,'on');
    counts = zeros(1,4);
    for j = 1:4
        row = summary.paired(summary.paired.campaign == "confirmation" & ...
            summary.paired.window == "stationary" & summary.paired.contrast == contrasts(j) & ...
            summary.paired.metric == scores{panel},:);
        errorbar(ax,j,row.medianDifference,row.medianDifference-row.lower95, ...
            row.upper95-row.medianDifference,'o','Color',[.16,.28,.43], ...
            'MarkerFaceColor',[.16,.28,.43],'LineWidth',1.5,'CapSize',10);
        counts(j) = row.completePairs;
    end
    yline(ax,0,'k:');
    xlim(ax,[.5,4.5]); set(ax,'XTick',1:4, ...
        'XTickLabel',compose('%s (n=%d)',contrasts(:),counts(:)));
    ylabel(ax,labels{panel}); style_axes(ax);
end
title(layout,{'Paired noisy contrasts: first model minus second model', ...
    'Median paired differences; 95% percentile intervals from 2,000 paired bootstrap resamples'});
save_figure(fig,folder,'05_paired_contrasts');
end

function forecast_figure(summary,folder,cfg,colors)
fig = new_figure([1120,950]);
layout = tiledlayout(fig,3,2,'TileSpacing','compact','Padding','compact');
scores = {'modelRMS','freezingRMS','totalRMS'};
labels = {'Model error RMS','Freezing error RMS','Total error RMS'};
inputModes = {'held','rateLimited'};
block = summary.forecasts(summary.forecasts.campaign == "confirmation" & ...
    summary.forecasts.trial == 0 & summary.forecasts.fittingTransitions == 200,:);
for errorType = 1:3
    for mode = 1:2
        ax = nexttile(layout); hold(ax,'on');
        for j = 1:numel(cfg.modelIds)
            selected = block(block.model == cfg.modelIds{j} & block.inputMode == inputModes{mode},:);
            plot(ax,selected.horizon,selected.(scores{errorType}),'-o', ...
                'Color',colors(j,:),'LineWidth',1.2,'MarkerSize',4, ...
                'DisplayName',cfg.modelIds{j},'LineStyle',line_style(cfg.modelIds{j}));
        end
        set(ax,'XTick',cfg.horizons); xlabel(ax,'Horizon (samples)');
        ylabel(ax,labels{errorType}); style_axes(ax);
        if errorType == 1
            if mode == 1, title(ax,'Held input'); else, title(ax,'Rate-limited input'); end
            legend(ax,'Location','best','Box','off');
        end
    end
end
title(layout,{'Common clean-state queries after 200 fitting transitions', ...
    '29 fixed anchors; identical inputs; mean cross terms and every checkpoint are retained in tables'});
save_figure(fig,folder,'06_common_query_forecasts');
end

function diagnostic_figure(runs,folder,cfg,colors)
fig = new_figure([1120,950]);
layout = tiledlayout(fig,3,2,'TileSpacing','compact','Padding','compact');
fields = {'covarianceCondition','gramCondition','qpCondition'};
labels = {'RLS covariance condition','50-transition Gram condition','QP Hessian condition'};
for panel = 1:3
    ax = nexttile(layout); hold(ax,'on');
    for j = 1:numel(runs)
        if ~isfield(runs{j},fields{panel}), continue; end
        values = runs{j}.(fields{panel});
        if panel == 2, values(runs{j}.gramCount < 50) = NaN; end
        plot(ax,(0:cfg.K-1)*cfg.Ts,values,'Color',colors(j,:), ...
            'LineStyle',line_style(cfg.modelIds{j}),'LineWidth',1.1,'DisplayName',cfg.modelIds{j});
    end
    set(ax,'YScale','log'); ylabel(ax,labels{panel});
    xlabel(ax,'Time (s)'); xlim(ax,[0,cfg.duration]); style_axes(ax);
    if panel == 1, legend(ax,'Location','best','Box','off'); end
end
ax = nexttile(layout); hold(ax,'on');
residual = zeros(4,cfg.K);
for j = 1:numel(runs)
    missing = ~isfinite(residual) | ~isfinite(runs{j}.solverResiduals);
    residual = max(residual,runs{j}.solverResiduals);
    residual(missing) = NaN;
end
names = {'primal','stationarity','dual','complementarity'};
for j = 1:4
    plot(ax,(0:cfg.K-1)*cfg.Ts,display_floor(residual(j,:)),'LineWidth',1,'DisplayName',names{j});
end
set(ax,'YScale','log'); ylabel(ax,'Maximum solver residual across models');
xlabel(ax,'Time (s)'); xlim(ax,[0,cfg.duration]); style_axes(ax);
legend(ax,'Location','best','Box','off');
ax = nexttile(layout); hold(ax,'on');
for j = 1:numel(runs)
    slack = squeeze(max(runs{j}.slack,[],[1,2]));
    plot(ax,(0:cfg.K-1)*cfg.Ts,slack,'Color',colors(j,:),'LineWidth',1.1);
end
ylabel(ax,'Largest predicted slack'); xlabel(ax,'Time (s)');
xlim(ax,[0,cfg.duration]); style_axes(ax);
ax = nexttile(layout); hold(ax,'on');
for j = 1:numel(runs)
    plot(ax,(0:cfg.K-1)*cfg.Ts,1e3*runs{j}.controlTime, ...
        'Color',colors(j,:),'LineWidth',.8);
end
ylabel(ax,'Control computation time (ms)'); xlabel(ax,'Time (s)');
xlim(ax,[0,cfg.duration]); style_axes(ax);
title(layout,{'Noise-free confirmation: numerical diagnostics', ...
    'Gram curves require 50 transitions; zero residual display floor 10^{-16}; actual violations are tabulated separately'});
save_figure(fig,folder,'07_numerical_diagnostics');
end

function measured_figure(summary,folder,cfg,colors)
fig = new_figure([1120,780]);
layout = tiledlayout(fig,2,2,'TileSpacing','compact','Padding','compact');
scores = {'totalRMS','initializationEffectRMS'};
labels = {'Total forecast error RMS','Initialization effect RMS'};
inputModes = {'held','recordedRateLimited'};
block = summary.measuredNoisy(summary.measuredNoisy.campaign == "confirmation",:);
for errorType = 1:2
    for mode = 1:2
        ax = nexttile(layout); hold(ax,'on');
        for j = 1:numel(cfg.modelIds)
            selected = block(block.model == cfg.modelIds{j} & ...
                block.inputMode == inputModes{mode} & block.metric == scores{errorType},:);
            selected = sortrows(selected,'horizon');
            errorbar(ax,selected.horizon,selected.median,selected.median-selected.q1, ...
                selected.q3-selected.median,'-o','Color',colors(j,:), ...
                'LineWidth',1.1,'MarkerSize',4,'CapSize',5, ...
                'DisplayName',cfg.modelIds{j},'LineStyle',line_style(cfg.modelIds{j}));
        end
        set(ax,'XTick',cfg.horizons); xlabel(ax,'Horizon (samples)');
        ylabel(ax,labels{errorType}); style_axes(ax);
        if errorType == 1
            if mode == 1, title(ax,'Held applied input');
            else, title(ax,'Recorded rate-limited applied inputs'); end
            legend(ax,'Location','best','Box','off');
        end
    end
end
title(layout,{'Measured-initial-state sensitivity: 40 noisy confirmation runs', ...
    'Median and IQR across within-run audits; controllers use different states and inputs'});
save_figure(fig,folder,'08_measured_initialization_sensitivity');
end

function fig = new_figure(size)
fig = figure('Visible','off','Color','white','Units','pixels', ...
    'Position',[50,50,size],'DefaultAxesFontName','Arial', ...
    'DefaultAxesFontSize',10,'DefaultTextInterpreter','tex');
if isprop(fig,'Scrollable'), fig.Scrollable = 'off'; end
end

function style_axes(ax)
grid(ax,'on'); ax.GridAlpha = .15; ax.Box = 'on';
end

function style = line_style(id)
if strcmp(id,'K'), style = '--'; else, style = '-'; end
end

function save_figure(fig,folder,name)
cleanup = onCleanup(@() close(fig));
exportgraphics(fig,fullfile(folder,[name,'.png']),'Resolution',180);
exportgraphics(fig,fullfile(folder,[name,'.svg']),'ContentType','vector');
end

function value = quantile_linear(values,p)
values = values(:);
if isempty(values) || any(~isfinite(values)), value = NaN; return; end
values = sort(values); position = 1+(numel(values)-1)*p;
lo = floor(position); hi = ceil(position);
value = values(lo)+(position-lo)*(values(hi)-values(lo));
end

function values = display_floor(values)
finite = isfinite(values);
values(finite) = max(values(finite),1e-16);
end
