function study5_figures(output,cfg,summary)
%STUDY5_FIGURES Compact diagnostic PNGs only, for deterministic pilot review.
colors = lines(5); styles = {'-','--','-.',':','-'};
names = strings(1,5); runs = cell(1,5); fits = cell(1,5);
for m = 1:5
    id = cfg.modelIds{m}; s = load(fullfile(output,'runs',[id,'.mat'])); runs{m} = s.result;
    s = load(fullfile(output,'fits',['fit_',id,'.mat'])); fits{m} = s.fit;
    names(m) = runs{m}.name;
end
fig = new_figure; layout = tiledlayout(fig,3,1,'TileSpacing','compact');
for panel = 1:3
    ax = nexttile(layout); hold(ax,'on');
    for m = 1:5
        r = runs{m}; n = r.nSteps; t = r.time(1:n);
        data = r.x(1:n); if panel == 2, data = data-r.r(1:n); end
        if panel == 3, data = r.u(1:n); end
        plot(ax,t,data,'Color',colors(m,:),'LineStyle',styles{m},'LineWidth',1.1,'DisplayName',names(m));
    end
    if panel == 1
        plot(ax,t,study5_reference(t),'k--','LineWidth',1,'DisplayName','Reference');
        ylabel(ax,'Angular velocity (rad/s)'); legend(ax,'Location','eastoutside');
    elseif panel == 2, ylabel(ax,'Tracking error (rad/s)');
    else, ylabel(ax,'Applied torque (N m)'); xlabel(ax,'Time (s)'); end
    xlim(ax,[0 80]); xline(ax,20,':','HandleVisibility','off'); grid(ax,'on');
end
title(layout,'Study 5 deterministic pilot: closed-loop behavior'); finish(fig,output,'closed_loop');

fig = new_figure; layout = tiledlayout(fig,2,2,'TileSpacing','compact');
fit = fits{1}; r = runs{1}; labels = {'J (kg m^2)','d_C (N m / (rad/s)^3)'};
for p = 1:2
    for phase = 1:2
        ax = nexttile(layout,(p-1)*2+phase); hold(ax,'on');
        t = 0:200; raw = fit.theta; mapped = fit.mappedTheta;
        if phase == 2, t = r.time(1:r.nSteps); raw = r.theta(:,1:r.nSteps); mapped = r.mappedTheta(:,1:r.nSteps); end
        plot(ax,t,raw(p,:),'-','LineWidth',1.3,'DisplayName','Raw RLS');
        plot(ax,t,mapped(p,:),'--','LineWidth',1,'DisplayName','Mapped predictor');
        yline(ax,cfg.trueParameters(p),'k:','LineWidth',1.2,'DisplayName','True value');
        ylabel(ax,labels{p}); grid(ax,'on');
        if phase == 1, xlabel(ax,'Initialization transitions'); else, xlabel(ax,'Control time (s)'); end
        if p == 1, legend(ax,'Location','best'); end
    end
end
title(layout,'Integrated physical model: raw and mapped parameters'); finish(fig,output,'physical_parameters');

fig = new_figure; layout = tiledlayout(fig,1,3,'TileSpacing','compact');
for panel = 1:3
    ax = nexttile(layout); hold(ax,'on');
    for m = 1:5
        if panel == 1
            rows = summary.initialization.modelId == string(cfg.modelIds{m});
            t = summary.initialization.fittingTransitions(rows); data = summary.initialization.predictionRMS(rows);
        else
            mode = "held"; if panel == 3, mode = "rateLimited"; end
            rows = summary.forecasts.modelId == string(cfg.modelIds{m}) & summary.forecasts.inputMode == mode;
            t = summary.forecasts.horizon(rows); data = summary.forecasts.predictionRMS(rows);
        end
        plot(ax,t,data,'o','Color',colors(m,:),'LineStyle',styles{m},'LineWidth',1,'MarkerSize',4,'DisplayName',names(m));
    end
    set(ax,'YScale','log'); grid(ax,'on'); ylabel(ax,'Prediction RMSE (rad/s)');
    if panel == 1, title(ax,'Held-out one-step'); xlabel(ax,'Initialization transitions');
    elseif panel == 2, title(ax,'Held-input forecast'); xlabel(ax,'Horizon (samples)');
    else, title(ax,'Rate-limited forecast'); xlabel(ax,'Horizon (samples)'); end
end
lg = legend(ax,names,'Orientation','horizontal'); lg.Layout.Tile = 'south';
title(layout,'Common-data predictions (known reference includes actual integration error)');
finish(fig,output,'forward_prediction');

fig = new_figure; layout = tiledlayout(fig,1,2,'TileSpacing','compact'); a = summary.quadrature;
ax = nexttile(layout); hold(ax,'on');
loglog(ax,a.Ts,a.trapezoidResidualRMS_Nm,'o-','DisplayName','Endpoint trapezoid');
loglog(ax,a.Ts,a.refinedResidualRMS_Nm,'s--','DisplayName','Refined integral');
set(ax,'XScale','log','YScale','log'); grid(ax,'on'); xlabel(ax,'Sampling interval (s)');
ylabel(ax,'Normalized equation residual RMS (N m)'); legend(ax,'Location','best');
ax = nexttile(layout); hold(ax,'on');
loglog(ax,a.Ts,a.plant20to40Max_radPerSecond,'o-','DisplayName','Plant: 20 versus 40');
loglog(ax,a.Ts,a.predictor5to10Max_radPerSecond,'s--','DisplayName','Predictor: 5 versus 10');
loglog(ax,a.Ts,a.zeroInput5Max_radPerSecond,'d-.','DisplayName','5 substeps versus zero-input solution');
set(ax,'XScale','log','YScale','log'); grid(ax,'on'); xlabel(ax,'Sampling interval (s)');
ylabel(ax,'Maximum state discrepancy (rad/s)'); legend(ax,'Location','best');
title(layout,'Offline numerical attribution (441 common state/input queries)'); finish(fig,output,'numerical_audit');

fig = new_figure; layout = tiledlayout(fig,2,1,'TileSpacing','compact');
for panel = 1:2
    ax = nexttile(layout); hold(ax,'on');
    for m = 1:4
        r = runs{m}; n = r.nSteps; data = r.gramRank(1:n)/r.nEstimated;
        if panel == 2, data = r.covarianceCondition(1:n); end
        plot(ax,r.time(1:n),data,'Color',colors(m,:),'LineStyle',styles{m},'LineWidth',1,'DisplayName',names(m));
    end
    grid(ax,'on'); xlabel(ax,'Time (s)'); xlim(ax,[0 80]);
    if panel == 1, ylabel(ax,'Recent rank / coefficient count'); ylim(ax,[0 1.05]); legend(ax,'Location','eastoutside');
    else, ylabel(ax,'Estimator covariance condition'); set(ax,'YScale','log'); end
end
title(layout,'Excitation and covariance are separate diagnostics (rank threshold 10^{-10})');
finish(fig,output,'conditioning');
end
function fig = new_figure
fig = figure('Visible','off','Color','w','Position',[100 100 1300 760]);
set(fig,'DefaultAxesFontSize',11,'DefaultTextInterpreter','tex');
end
function finish(fig,output,name)
exportgraphics(fig,fullfile(output,'figures',[name,'.png']),'Resolution',140);
close(fig);
end
