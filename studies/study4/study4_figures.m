function study4_figures(output,cfg)
%STUDY4_FIGURES Simple diagnostic PNGs of every saved deterministic run.
colors = [0 .45 .74;.85 .33 .1;.47 .67 .19;0 0 0];
styles = {'-','--','-.',':'};
for scenario = string(cfg.scenarios)
    fig = figure('Visible','off','Color','w','Position',[50 50 1250 1250]);
    layout = tiledlayout(fig,5,1,'TileSpacing','compact','Padding','compact');
    axesList = gobjects(1,5);
    for panel = 1:5, axesList(panel) = nexttile(layout); hold(axesList(panel),'on'); end
    for m = 1:4
        id = cfg.modelIds{m}; file = sprintf('%s_%s.mat',scenario,id);
        saved = load(fullfile(output,'runs',file),'result'); r = saved.result;
        saved = load(fullfile(output,'evaluation',file),'evaluation'); e = saved.evaluation;
        n = r.nSteps; t = r.time(1:n);
        plot(axesList(1),r.time(1:n+1),r.x(1:n+1),'Color',colors(m,:), ...
            'LineStyle',styles{m},'DisplayName',r.name,'LineWidth',1.1);
        stairs(axesList(2),t,r.u(1:n),'Color',colors(m,:),'LineStyle',styles{m});
        if ismember(id,{'Aplus','P2'})
            plot(axesList(3),t,r.theta(4,1:n),'Color',colors(m,:),'LineStyle',styles{m}, ...
                'DisplayName',r.name,'LineWidth',1.1);
        end
        plot(axesList(4),e.time,e.rms,'Color',colors(m,:),'LineStyle',styles{m},'LineWidth',1.1);
        if m < 4, plot(axesList(5),t,r.lambda(1:n),'Color',colors(m,:),'LineStyle',styles{m}); end
    end
    plot(axesList(1),r.time,r.r,'k--','DisplayName','Reference','LineWidth',1);
    if scenario ~= "unrepresented"
        plot(axesList(3),t,r.trueH(1:n),'k:','DisplayName','True coefficient','LineWidth',1.5);
    else
        title(axesList(3),'Sine change: no exact post-change polynomial coefficient target');
    end
    legend(axesList(1),'Location','northoutside','Orientation','horizontal','NumColumns',3);
    legend(axesList(3),'Location','best','Orientation','horizontal');
    labels = {'State and reference','Applied input','Estimated \xi^2 coefficient', ...
        'Common-grid prediction RMSE','Forgetting factor'};
    for panel = 1:5
        ax = axesList(panel); ylabel(ax,labels{panel}); grid(ax,'on'); xlim(ax,[0 cfg.duration]);
        ax.FontSize = 10; ax.Box = 'off';
        if scenario ~= "no_change", xline(ax,50,':','HandleVisibility','off'); end
    end
    xlabel(axesList(5),'Time (s)');
    title(layout,{r.scenarioName,'Deterministic pilot; common-grid errors use independent evaluator queries'});
    exportgraphics(fig,fullfile(output,'figures',[char(scenario),'.png']),'Resolution',120); close(fig);
end
fig = figure('Visible','off','Color','w','Position',[50 50 1400 750]);
layout = tiledlayout(fig,2,3,'TileSpacing','compact','Padding','compact');
for s = 1:3
    for panel = 1:2
        ax = nexttile(layout,(panel-1)*3+s); hold(ax,'on');
        for m = 1:3
            saved = load(fullfile(output,'runs',sprintf('%s_%s.mat',cfg.scenarios{s},cfg.modelIds{m})),'result'); r = saved.result;
            if panel == 1
                indices = find(r.gramCount == 50); value = r.gramRank(indices);
            else
                indices = 1:r.nSteps; value = r.covarianceCondition(indices);
            end
            plot(ax,r.time(indices),value,'Color',colors(m,:),'LineStyle',styles{m},'DisplayName',r.name);
        end
        if panel == 1, ylabel(ax,'Numerical rank (50 transitions)'); title(ax,cfg.scenarioNames{s});
        else, ylabel(ax,'Covariance condition'); ax.YScale = 'log'; xlabel(ax,'Time (s)'); end
        grid(ax,'on'); xlim(ax,[0 cfg.duration]);
        if s > 1, xline(ax,50,':','HandleVisibility','off'); end
        if s == 1 && panel == 1
            lg = legend(ax,'Orientation','horizontal'); lg.Layout.Tile = 'north';
        end
    end
end
title(layout,'Recent-data rank at relative threshold 10^{-10}; covariance remains unmodified');
exportgraphics(fig,fullfile(output,'figures','rank_and_covariance.png'),'Resolution',120); close(fig);
end
