function study3_figures(output,cfg,summary)
%STUDY3_FIGURES Five diagnostic PNGs from saved pilot data only.
% No curve is selected by outcome. The noisy trajectory uses fixed trial 1.
% Input-gain estimates are shown only for Shared models; an Affine input
% coefficient is not an exact physical gain parameter for this plant.
folder = fullfile(output,'figures');
if ~isfolder(folder), mkdir(folder); end
colors = [0 .45 .74;.85 .33 .10;.47 .67 .19;.49 .18 .56; ...
    .30 .75 .93;.64 .08 .18;.40 .40 .40;.65 .45 .15;0 0 0];
for scenario = string(cfg.scenarios)
    runs = read_runs(output,scenario,cfg.caseIds,0);
    if scenario == "abrupt", name = '01_clean_abrupt'; else, name = '02_clean_drift'; end
    trajectory_plot(runs,scenario,0,cfg,colors,folder,name);
end
runs = read_runs(output,'abrupt',cfg.noisyCases,cfg.representativeTrial);
trajectory_plot(runs,'abrupt',cfg.representativeTrial,cfg,colors,folder,'03_noisy_abrupt_trial_001');
noisy_plot(summary,cfg,colors,folder);
information_plot(summary,cfg,colors,folder);
fprintf('Study 3 diagnostic figures: 5 PNG files; noisy representative trial %d.\n',cfg.representativeTrial);
end

function runs = read_runs(output,scenario,ids,trial)
runs = cell(1,numel(ids));
for j = 1:numel(ids)
    saved = load(fullfile(output,'runs',sprintf('%s_%s_%03d.mat',scenario,ids{j},trial)),'result');
    runs{j} = saved.result;
end
end

function trajectory_plot(runs,scenario,trial,cfg,colors,folder,name)
fig = new_figure([1250 1000]);
layout = tiledlayout(fig,4,1,'TileSpacing','compact','Padding','compact');
for panel = 1:4
    ax = nexttile(layout); hold(ax,'on');
    for j = 1:numel(runs)
        r = runs{j}; n = r.nSteps;
        index = find(strcmp(cfg.caseIds,r.id));
        switch panel
            case 1
                time = r.time(1:n+1); value = r.x(1:n+1)-r.r(1:n+1);
            case 2
                if ~strcmp(r.modelId,'S'), continue; end
                time = r.time(1:n); value = r.theta(3,1:n);
            case 3
                time = r.time(1:n); value = r.u(1:n);
            case 4
                if ~strcmp(r.mode,'adaptive'), continue; end
                time = r.time(1:n); value = r.lambda(1:n);
        end
        plot(ax,time,value,'Color',colors(index,:),'LineStyle',line_style(index), ...
            'LineWidth',1.05,'DisplayName',r.name);
    end
    switch panel
        case 1
            ylabel(ax,'True tracking error'); yline(ax,0,':','HandleVisibility','off');
            if strcmp(scenario,'abrupt')
                plot(ax,[50 60],[.04 .04],'k:','HandleVisibility','off');
                plot(ax,[50 60],[-.04 -.04],'k:','HandleVisibility','off');
            end
            lg = legend(ax,'Orientation','horizontal','NumColumns',3);
            lg.Layout.Tile = 'north'; lg.Box = 'off';
        case 2
            reference = runs{1};
            plot(ax,reference.time(1:end-1),reference.trueGain,'k--', ...
                'LineWidth',1.5,'DisplayName','True input gain');
            ylabel(ax,'Shared input-gain estimate');
            title(ax,'Dashed black: current true gain; Affine coefficients are omitted');
        case 3
            ylabel(ax,'Applied input');
            yline(ax,1,':','HandleVisibility','off'); yline(ax,-1,':','HandleVisibility','off');
        case 4
            ylabel(ax,'Forgetting factor'); xlabel(ax,'Time (s)'); ylim(ax,[.82 1.01]);
    end
    xline(ax,50,':','HandleVisibility','off');
    if strcmp(scenario,'drift'), xline(ax,90,':','HandleVisibility','off'); end
    xlim(ax,[0 cfg.duration]); style_axes(ax);
end
label = 'Noise-free';
if trial > 0, label = sprintf('Paired noisy trial %d, selected before execution',trial); end
complete = sum(cellfun(@(r) r.completed,runs));
title(layout,{sprintf('%s gain change: %s',char(scenario),label), ...
    sprintf('%d/%d runs completed; terminated runs show their recorded prefixes',complete,numel(runs))});
save_plot(fig,folder,name);
end

function noisy_plot(summary,cfg,colors,folder)
fig = new_figure([1300 780]);
layout = tiledlayout(fig,2,3,'TileSpacing','compact','Padding','compact');
windows = ["pre","event","late"];
windowNames = {'Pre-event: 30 <= t < 40 s','Event: 50 <= t < 60 s','Late: 90 <= t < 100 s'};
scores = {'trackingRMS','meanAbsoluteIncrement'};
labels = {'Tracking RMSE','Mean absolute input increment'};
names = {'Shared: none','Shared: fixed','Shared: variable','Pretrained-frozen','Known model'};
for metric = 1:2
    for iw = 1:3
        ax = nexttile(layout); hold(ax,'on');
        for j = 1:numel(cfg.noisyCases)
            id = string(cfg.noisyCases{j}); index = find(strcmp(cfg.caseIds,id));
            row = summary.noisy(summary.noisy.caseId == id & ...
                summary.noisy.window == windows(iw) & summary.noisy.metric == scores{metric},:);
            assert(height(row) == 1,'study3:SummarySelection','Each noisy summary must be unique.');
            errorbar(ax,j,row.median,row.median-row.q1,row.q3-row.median,'o', ...
                'Color',colors(index,:),'MarkerFaceColor',colors(index,:), ...
                'LineWidth',1.3,'MarkerSize',5,'CapSize',7);
        end
        ax.XTick = 1:numel(cfg.noisyCases); ax.XTickLabel = names; ax.XTickLabelRotation = 20;
        xlim(ax,[.5 numel(cfg.noisyCases)+.5]); ylabel(ax,labels{metric});
        if metric == 1, title(ax,windowNames{iw}); end
        style_axes(ax);
    end
end
block = summary.diagnostics(summary.diagnostics.noise,:);
title(layout,{sprintf('Noisy abrupt-gain pilot: %d/%d runs completed',nnz(block.completed),height(block)), ...
    'Markers: medians; bars: interquartile ranges; complete-run scores only'});
save_plot(fig,folder,'04_noisy_scores');
end

function information_plot(summary,cfg,colors,folder)
fig = new_figure([1250 760]);
layout = tiledlayout(fig,2,2,'TileSpacing','compact','Padding','compact');
for is = 1:numel(cfg.scenarios)
    scenario = string(cfg.scenarios{is});
    windows = ["pre","event","late"];
    labels = {'30-40 s','50-60 s','90-100 s'};
    if scenario == "drift", windows(2) = "changing"; labels{2} = '50-90 s'; end
    for panel = 1:2
        ax = nexttile(layout); hold(ax,'on');
        for j = 1:numel(cfg.caseIds)
            id = string(cfg.caseIds{j});
            block = summary.metrics(summary.metrics.caseId == id & ...
                summary.metrics.scenario == scenario & ~summary.metrics.noise,:);
            if id == "K", continue; end
            if panel == 1 && block.mode(1) ~= "adaptive", continue; end
            values = nan(1,3);
            for k = 1:3
                row = block(block.window == windows(k),:);
                if panel == 1, values(k) = row.lambdaMedian;
                elseif row.gramInvalidFullWindows == 0
                    values(k) = row.gramDeficientFraction;
                end
            end
            plot(ax,1:3,values,'Color',colors(j,:),'LineStyle',line_style(j), ...
                'Marker','o','LineWidth',1.1,'DisplayName',char(block.caseName(1)));
        end
        ax.XTick = 1:3; ax.XTickLabel = labels; xlim(ax,[.8 3.2]);
        title(ax,char(scenario)); style_axes(ax);
        if panel == 1
            ylabel(ax,'Median realized forgetting factor'); ylim(ax,[.82 1.01]);
        else
            ylabel(ax,'Numerically deficient full windows (fraction)'); ylim(ax,[0 1]);
            ax.YTick = [0 .5 1];
            if is == 1
                lg = legend(ax,'Orientation','horizontal','NumColumns',3);
                lg.Layout.Tile = 'north'; lg.Box = 'off';
            end
        end
    end
end
title(layout,{'Noise-free forgetting and recent-data diagnostics', ...
    'Gram: 50-transition windows, relative SVD threshold 10^{-10}; raw histories and exclusions are in the tables'});
save_plot(fig,folder,'05_forgetting_and_recent_data');
end

function fig = new_figure(position)
fig = figure('Visible','off','Color','w','Position',[40 40 position],'Scrollable','off');
end
function style_axes(ax)
ax.FontName = 'Arial'; ax.FontSize = 10; ax.LineWidth = .8;
ax.Box = 'off'; ax.TickDir = 'out'; ax.XGrid = 'on'; ax.YGrid = 'on'; ax.GridAlpha = .12;
end
function style = line_style(index)
styles = {'-','--','-.','-','--','-.',':',':','--'}; style = styles{index};
end
function save_plot(fig,folder,name)
exportgraphics(fig,fullfile(folder,[name,'.png']),'Resolution',150);
close(fig);
end
