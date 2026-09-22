function study6_figures(output,s)
%STUDY6_FIGURES Selected pilot diagnostics; full combinations remain in tables.
% Log axes show positive recorded RMSEs only. Exact zeros remain in MAT/CSV;
% no numerical floor, smoothing, or replacement values are introduced.
for plant = ["A","B","C"]
    t = s.main(s.main.plant == plant,:);
    detail = 'Plant C, Study 5';
    if plant == "A", t = t(t.sourceCampaign == "confirmation",:); detail = 'Plant A, Study 1 saved confirmation-labelled clean record';
    elseif plant == "B", t = t(t.evaluationRange == 1.10,:); detail = 'Plant B, Study 2 evaluation range 1.10'; end
    fig = new_figure; layout = tiledlayout(fig,3,2,'TileSpacing','compact');
    names = unique(t.model,'stable'); colors = lines(numel(names));
    markers = {'s','o','d','^','v','x'}; styles = {'-','--',':','-.','-','--'};
    for row = 1:3
        fields = {'modelRMSE','freezingRMSE','totalRMSE'}; labels = {'Nonlinear-model','Freezing','Total affine'};
        for mode = 1:2
            modes = ["held","rateLimited"]; ax = nexttile(layout); hold(ax,'on');
            for m = 1:numel(names)
                block = sortrows(t(t.model == names(m) & t.inputMode == modes(mode),:),'horizon');
                plot(ax,block.horizonSeconds,block.(fields{row}),'Color',colors(m,:), ...
                    'Marker',markers{m},'LineStyle',styles{m},'MarkerSize',3,'LineWidth',1,'DisplayName',names(m));
            end
            set(ax,'YScale','log'); grid(ax,'on'); ax.YMinorGrid = 'off';
            ylabel(ax,[labels{row},' RMSE']); xlabel(ax,'Forecast horizon (s)');
            if row == 1
                title(ax,strrep(modes(mode),'rateLimited','Rate-limited inputs'));
                if mode == 2, legend(ax,'Location','eastoutside'); end
            end
        end
    end
    title(layout,{[detail,'; fixed 200-transition estimates'], ...
        ['Derived pilot; ',char(t.unit(1)),'. Log axes display positive values.']});
    finish(fig,output,'forecast_'+plant);
end
t = s.measurement;
t = t(t.sourceCampaign == "confirmation" & t.trial == 1 & t.modelId == "S",:);
fig = new_figure; layout = tiledlayout(fig,1,2,'TileSpacing','compact');
fields = {'modelRMSE','freezingRMSE','initializationRMSE','combinedRMSE'};
names = {'Nonlinear-model','Freezing','Initialization','Combined'};
for mode = 1:2
    modes = ["held","recordedRateLimited"]; block = sortrows(t(t.inputMode == modes(mode),:),'horizon');
    ax = nexttile(layout); hold(ax,'on');
    for j = 1:4, plot(ax,block.horizonSeconds,block.(fields{j}),'o-','DisplayName',names{j}); end
    set(ax,'YScale','log'); grid(ax,'on'); ax.YMinorGrid = 'off';
    title(ax,strrep(modes(mode),'recordedRateLimited','Recorded rate-limited inputs'));
    xlabel(ax,'Forecast horizon (s)'); ylabel(ax,'RMSE (dimensionless state)'); legend(ax,'Location','best');
end
title(layout,{'Initialization attribution: Shared, Study 1 preselected noisy trial 1', ...
    'Original confirmation-labelled record; derived pilot, within-run queries'});
finish(fig,output,'initialization');

fig = new_figure; layout = tiledlayout(fig,1,2,'TileSpacing','compact');
for time = [49.5 49.9]
    t = s.change(abs(s.change.snapshotTime-time) < 1e-12 & s.change.inputMode == "recordedRateLimited",:);
    ax = nexttile(layout); barh(ax,[t.modelMeanError,t.freezingMeanError,t.changeMeanError,t.combinedMeanError]);
    ax.YTick = 1:height(t); ax.YTickLabel = t.model; ax.YDir = 'reverse';
    xlabel(ax,'Signed terminal error (dimensionless state)'); grid(ax,'on');
    title(ax,sprintf('Origin %.1f s, H = 20',time));
    if time == 49.5
        key = legend(ax,{'Nonlinear-model','Freezing','Future change','Combined'},'Orientation','horizontal');
        key.Layout.Tile = 'south';
    end
end
title(layout,{'Unforeseen-change attribution: nine noise-free Study 3 cases', ...
    'Recorded applied inputs; one query per controller; cross terms retained in MAT/CSV'});
finish(fig,output,'future_change');

fig = new_figure; layout = tiledlayout(fig,2,1,'TileSpacing','compact');
t = s.constraintHistory; names = unique(t.model,'stable');
for side = 1:2
    ax = nexttile(layout); hold(ax,'on');
    field = 'predictedUpperSlack'; actual = 'actualUpperViolation'; label = 'Upper';
    if side == 2, field = 'predictedLowerSlack'; actual = 'actualLowerViolation'; label = 'Lower'; end
    for m = 1:numel(names)
        block = t(t.model == names(m),:);
        plot(ax,block.nextSampleTime,block.(field),'-','DisplayName',names(m),'LineWidth',1);
        plot(ax,block.nextSampleTime,block.(actual),'k:','HandleVisibility','off');
    end
    plot(ax,NaN,NaN,'k:','DisplayName','Actual next-sample violation');
    grid(ax,'on'); xlabel(ax,'Next-sample time (s)'); ylabel(ax,[label,' slack / violation']);
    if side == 1, legend(ax,'Location','eastoutside'); end
end
title(layout,{'Reused Study 2 constraint audit (dimensionless state)', ...
    'Initial violation 0.55 is separate; first future violation 0.09 at 0.1 s'});
finish(fig,output,'constraint_alignment');
end
function fig = new_figure
fig = figure('Visible','off','Color','w','Position',[100 100 1350 850]);
set(fig,'DefaultAxesFontSize',10,'DefaultTextInterpreter','none');
end
function finish(fig,output,name)
exportgraphics(fig,fullfile(output,'figures',char(name)+".png"),'Resolution',140); close(fig);
end
