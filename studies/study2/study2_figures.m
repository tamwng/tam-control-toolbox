function study2_figures(output,cfg,summary)
%STUDY2_FIGURES Simple inspection plots for the deterministic pilot.
% Only saved results are used. Held-out range and reference amplitude remain
% different horizontal variables; no publication styling or selection occurs.
folder = fullfile(output,'figures');
if ~isfolder(folder), mkdir(folder); end
colors = [0 .447 .741;.85 .325 .098;.466 .674 .188; ...
    .494 .184 .556;.301 .745 .933;.15 .15 .15];
markers = {'o','s','^','d','v','x'};
names = {'Affine (3)','Exact sine (3)','Odd cubic (4)', ...
    'Odd quintic (5)','Complete cubic (10)','Known model'};
learning_plot(folder,cfg,summary,colors,markers,names);
performance_plot(folder,cfg,summary,colors,markers,names);
trajectory_plot(output,folder,cfg,colors,names);
diagnostic_plot(folder,cfg,summary,colors,markers,names);
constraint_plot(output,folder,cfg,summary,colors,names);
fprintf('Study 2 diagnostic figures: 5 PNG files.\n');
end

function learning_plot(folder,cfg,summary,colors,markers,names)
fig = new_figure([1250 470]);
layout = tiledlayout(fig,1,3,'TileSpacing','compact','Padding','compact');
values = summary.initialization.predictionRMS(summary.initialization.model ~= "K");
values = values(isfinite(values) & values > 0);
limits = [];
if ~isempty(values), limits = [min(values)*.7,max(values)*1.4]; end
for ir = 1:numel(cfg.evaluationRanges)
    ax = nexttile(layout); hold(ax,'on');
    for im = 1:numel(cfg.modelIds)-1
        rows = summary.initialization(summary.initialization.model == cfg.modelIds{im} & ...
            summary.initialization.evaluationRange == cfg.evaluationRanges(ir),:);
        plot(ax,rows.fittingTransitions,rows.predictionRMS, ...
            'Color',colors(im,:),'Marker',markers{im},'LineWidth',1.2, ...
            'MarkerSize',5,'LineStyle',line_style(im),'DisplayName',names{im});
    end
    ax.YScale = 'log'; ax.XTick = cfg.fitSteps;
    if ~isempty(limits), ylim(ax,limits); end
    title(ax,sprintf('Evaluation input range L = %.2f',cfg.evaluationRanges(ir)));
    xlabel(ax,'Identification transitions'); ylabel(ax,'Held-out one-step RMSE');
    style_axes(ax);
    if ir == 1, horizontal_legend(ax,5); end
end
title(layout,{'Plant B: common-data prediction; noise-free pilot', ...
    'Known-model numerical floor is retained in the tables and omitted here'});
save_plot(fig,folder,'01_held_out_prediction');
end

function performance_plot(folder,cfg,summary,colors,markers,names)
fig = new_figure([1250 470]);
layout = tiledlayout(fig,1,3,'TileSpacing','compact','Padding','compact');
columns = {'trackingRMS','inputRMS','meanAbsoluteIncrement'};
labels = {'Tracking RMSE','Input RMS','Mean absolute input increment'};
for panel = 1:3
    ax = nexttile(layout); hold(ax,'on');
    for im = 1:numel(cfg.modelIds)
        rows = summary.metrics(summary.metrics.model == cfg.modelIds{im} & ...
            summary.metrics.kind == "amplitude" & summary.metrics.window == "principal",:);
        values = rows.(columns{panel});
        values(~rows.completed) = NaN;
        plot(ax,rows.amplitude,values,'Color',colors(im,:), ...
            'Marker',markers{im},'LineStyle',line_style(im),'LineWidth',1.2, ...
            'MarkerSize',5,'DisplayName',names{im});
    end
    xlabel(ax,'Reference amplitude A_r'); ylabel(ax,labels{panel});
    ax.XTick = cfg.amplitudes; xlim(ax,[.15 1.05]); style_axes(ax);
    if panel == 1
        ax.YScale = 'log';
        horizontal_legend(ax,6);
    end
end
count = summary.counts(summary.counts.kind == "amplitude",:);
title(layout,{sprintf('Closed-loop pilot: %d/%d amplitude runs completed',count.completed,count.attempted), ...
    'Principal window: 20 <= t < 80 s; incomplete runs are omitted from these curves'});
save_plot(fig,folder,'02_tracking_and_input_activity');
end

function trajectory_plot(output,folder,cfg,colors,names)
fig = new_figure([1250 900]);
layout = tiledlayout(fig,3,2,'TileSpacing','compact','Padding','compact');
for ia = 1:numel(cfg.amplitudes)
    stateAx = nexttile(layout); hold(stateAx,'on');
    inputAx = nexttile(layout); hold(inputAx,'on');
    for im = 1:numel(cfg.modelIds)
        saved = load(fullfile(output,'runs',sprintf('amplitude_%02d_%s.mat',ia,cfg.modelIds{im})),'result');
        r = saved.result; n = r.nSteps;
        plot(stateAx,r.time(1:n+1),r.x(1:n+1),'Color',colors(im,:), ...
            'LineStyle',line_style(im),'LineWidth',1,'DisplayName',names{im});
        stairs(inputAx,r.time(1:n),r.u(1:n),'Color',colors(im,:), ...
            'LineStyle',line_style(im),'LineWidth',1,'DisplayName',names{im});
        if im == 1
            plot(stateAx,r.time,r.r,'k:','LineWidth',1.3,'DisplayName','Reference');
        end
    end
    for ax = [stateAx,inputAx]
        xlim(ax,[0 cfg.duration]); style_axes(ax);
        yline(ax,1.2,':','Color',[.5 .5 .5],'HandleVisibility','off');
        yline(ax,-1.2,':','Color',[.5 .5 .5],'HandleVisibility','off');
        if ia == 3, xlabel(ax,'Time (s)'); end
    end
    ylabel(stateAx,'State'); ylabel(inputAx,'Applied input');
    title(stateAx,sprintf('Reference amplitude A_r = %.1f',cfg.amplitudes(ia)));
    title(inputAx,sprintf('Reference amplitude A_r = %.1f',cfg.amplitudes(ia)));
    if ia == 1
        horizontal_legend(stateAx,4);
    end
end
title(layout,{'Plant B: separate closed-loop trajectories', ...
    'Dotted horizontal lines are bounds; the final unapplied input is excluded'});
save_plot(fig,folder,'03_closed_loop_trajectories');
end

function diagnostic_plot(folder,cfg,summary,colors,markers,names)
fig = new_figure([1250 800]);
layout = tiledlayout(fig,2,3,'TileSpacing','compact','Padding','compact');
% Read the archived matrices; enormous finite conditions are superseded by
% numerical-rank reporting at relative threshold 1e-10. No archive is changed.
rankReport = study2_gram_report(fileparts(folder));
columns = {'covarianceConditionMax','gramConditionMax','qpConditionMax', ...
    'predictedSlackMax','primalResidualMax','controlTimeMedianSeconds'};
labels = {'Maximum covariance condition number','Numerically deficient window fraction', ...
    'Maximum QP Hessian condition number','Maximum predicted slack', ...
    'Maximum QP primal residual','Median control computation time (s)'};
for panel = 1:6
    ax = nexttile(layout); hold(ax,'on');
    for im = 1:numel(cfg.modelIds)
        if panel <= 2 && strcmp(cfg.modelIds{im},'K'), continue; end
        rows = summary.diagnostics(summary.diagnostics.model == cfg.modelIds{im} & ...
            summary.diagnostics.kind == "amplitude",:);
        if panel == 2
            ranks = sortrows(rankReport(rankReport.model == cfg.modelIds{im},:),'amplitude');
            assert(all(ranks.invalidFullWindowCount == 0), ...
                'study2:InvalidGramWindows','Cannot plot a fraction while excluding invalid windows.');
            values = ranks.fractionDeficient;
        else
            values = rows.(columns{panel});
        end
        plot(ax,rows.amplitude,values,'Color',colors(im,:),'Marker',markers{im}, ...
            'LineStyle',line_style(im),'LineWidth',1.1,'MarkerSize',5,'DisplayName',names{im});
    end
    if panel == 1 || panel == 3, ax.YScale = 'log'; end
    if panel == 2, ylim(ax,[-.05 1.05]); ax.YTick = [0 .5 1]; end
    if panel == 4
        limits = ylim(ax); ylim(ax,[0 limits(2)]);
    end
    ylabel(ax,labels{panel}); xlabel(ax,'Reference amplitude A_r');
    ax.XTick = cfg.amplitudes; xlim(ax,[.15 1.05]); style_axes(ax);
    if panel == 3, horizontal_legend(ax,6); end
end
title(layout,{'Numerical pilot diagnostics; 50-transition Gram rank uses relative threshold 10^{-10}', ...
    'Full histories, eigenvalues, residuals, activity counts and failures are saved separately'});
save_plot(fig,folder,'04_numerical_diagnostics');
end

function constraint_plot(output,folder,cfg,summary,colors,names)
fig = new_figure([1100 760]);
layout = tiledlayout(fig,2,2,'TileSpacing','compact','Padding','compact');
stateAx = nexttile(layout); hold(stateAx,'on');
inputAx = nexttile(layout); hold(inputAx,'on');
for j = 1:numel(cfg.auditIds)
    id = cfg.auditIds{j}; im = find(strcmp(cfg.modelIds,id));
    saved = load(fullfile(output,'runs',['constraint_',id,'.mat']),'result'); r = saved.result;
    n = r.nSteps;
    plot(stateAx,r.time(1:n+1),r.x(1:n+1),'Color',colors(im,:), ...
        'LineStyle',line_style(im),'LineWidth',1.2,'DisplayName',names{im});
    stairs(inputAx,r.time(1:n),r.u(1:n),'Color',colors(im,:), ...
        'LineStyle',line_style(im),'LineWidth',1.2,'DisplayName',names{im});
end
yline(stateAx,.6,'k:','DisplayName','Reference');
yline(stateAx,.85,'--','Color',[.5 .5 .5],'DisplayName','Output bound');
yline(stateAx,-.85,'--','Color',[.5 .5 .5],'HandleVisibility','off');
yline(inputAx,1.2,':','HandleVisibility','off');
yline(inputAx,-1.2,':','HandleVisibility','off');
for ax = [stateAx,inputAx], xlabel(ax,'Time (s)'); xlim(ax,[0 10]); style_axes(ax); end
ylabel(stateAx,'State'); ylabel(inputAx,'Applied input');
horizontal_legend(stateAx,6);
ax = nexttile(layout); hold(ax,'on');
block = summary.constraint;
values = [block.firstPredictedUpperSlack,block.actualNextOutputViolation];
bar(ax,values,'grouped'); ax.XTick = 1:height(block); ax.XTickLabel = block.modelName;
ylabel(ax,'First-step slack / actual violation');
lg = legend(ax,{'Predicted upper slack','Actual next-sample violation'},'Location','northoutside'); lg.Box = 'off';
yline(ax,.09,'k:','HandleVisibility','off'); style_axes(ax);
ax = nexttile(layout); hold(ax,'on');
rows = summary.diagnostics(summary.diagnostics.kind == "constraintAudit",:);
bar(ax,[rows.initialOutputViolation,rows.futureOutputViolationPeak],'grouped');
ax.XTick = 1:height(rows); ax.XTickLabel = rows.modelName;
ylabel(ax,'Actual output-bound exceedance');
lg = legend(ax,{'Initial sample','Future-sample peak'},'Location','northoutside'); lg.Box = 'off';
style_axes(ax);
title(layout,{'Separate constraint audit: x_0 = 1.4, u_0 = 0, output bound = 0.85', ...
    'Known model: x_1 = 0.94 requires at least 0.09 first-step upper slack'});
save_plot(fig,folder,'05_constraint_audit');
end

function fig = new_figure(sizePixels)
fig = figure('Visible','off','Color','w','Position',[40 40 sizePixels], ...
    'Scrollable','off');
end
function style_axes(ax)
ax.FontName = 'Arial'; ax.FontSize = 10; ax.LineWidth = .8;
ax.Box = 'off'; ax.TickDir = 'out'; ax.XGrid = 'on'; ax.YGrid = 'on';
ax.GridAlpha = .12;
end
function horizontal_legend(ax,columns)
lg = legend(ax,'Orientation','horizontal','NumColumns',columns);
lg.Layout.Tile = 'north'; lg.Box = 'off';
end
function style = line_style(index)
styles = {'-','-','--','-.',':','--'}; style = styles{index};
end
function save_plot(fig,folder,name)
exportgraphics(fig,fullfile(folder,[name,'.png']),'Resolution',150);
close(fig);
end
