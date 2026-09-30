function summary = study4_summarize(output,cfg,destination)
%STUDY4_SUMMARIZE Appendix A windows; incomplete prefixes remain labelled.
% The optional destination separates regenerated reports from source records.
if nargin < 3, destination = output; end
assert_output_writable(destination);
for folder = {'tables','evaluation'}
    target = fullfile(destination,folder{1});
    if ~isfolder(target), mkdir(target); end
end
metrics = struct([]); diagnostics = struct([]); recoveries = struct([]);
grid = struct([]); events = struct([]); parameters = struct([]);
for scenario = string(cfg.scenarios)
    for id = string(cfg.modelIds)
        file = sprintf('%s_%s.mat',scenario,id);
        saved = load(fullfile(output,'runs',file),'result'); r = saved.result;
        saved = load(fullfile(output,'evaluation',file),'evaluation'); e = saved.evaluation;
        base = struct('scenario',string(r.scenarioName),'model',string(r.name), ...
            'scenarioId',scenario,'modelId',id,'coefficientCount',r.nEstimated,'completed',r.completed);
        for iw = 1:4
            row = base; row.window = string(cfg.windowNames{iw});
            row.windowStart = cfg.windows(iw,1); row.windowEnd = cfg.windows(iw,2);
            row.status = "complete"; if ~r.completed, row.status = "incompletePrefix"; end
            mask = r.time(1:end-1) >= row.windowStart & r.time(1:end-1) < row.windowEnd;
            row.expectedSamples = nnz(mask);
            indices = find(mask & (1:cfg.K) <= r.nSteps);
            row.scoredSamples = numel(indices);
            error = r.x(indices)-r.r(indices); duIndices = indices(indices > 1);
            du = r.u(duIndices)-r.u(duIndices-1);
            row.incrementSamples = numel(du);
            row.trackingRMS = required_rms(error); row.peakTrackingError = maximum(abs(error));
            row.inputRMS = required_rms(r.u(indices)); row.meanAbsoluteIncrement = required_mean(abs(du));
            row.totalInputVariation = sum(abs(du));
            row.predictionExpected = numel(indices);
            row.predictionFinite = nnz(isfinite(r.prediction(indices)-r.x(indices+1)));
            row.predictionTrueRMS = required_rms(r.prediction(indices)-r.x(indices+1));
            row.predictionMeasuredRMS = required_rms(r.prediction(indices)-r.y(indices+1));
            queries = e.time >= row.windowStart & e.time < row.windowEnd;
            row.gridSnapshotsExpected = nnz(queries);
            row.gridSnapshotsAttempted = nnz(queries & e.attempted);
            row.gridSnapshotsValid = nnz(queries & e.valid);
            row.gridPredictionRMS = required_rms(e.error(:,queries & e.attempted));
            if row.gridSnapshotsAttempted == 0, row.gridPredictionRMS = NaN; end
            row.parameterExactSamples = 0; row.parameterScaledRMSPercent = NaN;
            if r.nEstimated > 0
                exact = indices(e.exactTargetAvailable(indices));
                row.parameterExactSamples = numel(exact);
                % A mixed exact/inexact window has no whole-window target.
                if numel(exact) == numel(indices) && ~isempty(indices)
                    row.parameterScaledRMSPercent = required_rms(e.parameterScaledPercent(indices));
                end
                for p = 1:r.nEstimated
                    item = base; item.window = row.window; item.component = string(r.labels{p});
                    item.exactSamples = numel(exact); item.scoredSamples = numel(indices);
                    item.lastEstimate = NaN; item.lastTarget = NaN;
                    item.componentErrorRMS = NaN;
                    if ~isempty(indices)
                        item.lastEstimate = r.theta(p,indices(end));
                        item.lastTarget = e.exactTarget(p,indices(end));
                        if numel(exact) == numel(indices)
                            item.componentErrorRMS = required_rms(e.parameterError(p,indices));
                        end
                    end
                    parameters = [parameters;item]; %#ok<AGROW>
                end
            end
            metrics = [metrics;row]; %#ok<AGROW>
        end
        d = base; steps = 1:r.nSteps; states = r.x(1:r.nSteps+1);
        applied = r.u(steps); du = diff(applied);
        d.attemptedRuns = 1; d.completedRuns = double(r.completed);
        d.attemptedSteps = r.nSteps; d.expectedSteps = cfg.K;
        d.terminationReason = string(r.terminationReason);
        d.identificationAttempted = nnz(r.idAttempted);
        d.identificationRejected = nnz(r.idAttempted & ~r.idAccepted);
        d.controlRejected = nnz(~r.controlAccepted(steps)); d.fallbackActions = d.controlRejected;
        d.mappingActivations = nnz(r.mappingActivated);
        d.lambdaMin = minimum(r.lambda(steps)); d.lambdaMax = maximum(r.lambda(steps));
        d.lambdaBelowOne = nnz(r.lambda(steps) < 1);
        d.firstForgettingTime = NaN;
        first = find(r.lambda < 1,1); if ~isempty(first), d.firstForgettingTime = r.time(first); end
        d.covarianceEigenMin = minimum(r.covarianceEigenvalues(1,steps));
        d.covarianceEigenMax = maximum(r.covarianceEigenvalues(2,steps));
        d.covarianceConditionMax = maximum(r.covarianceCondition(steps));
        full = steps(r.gramCount(steps) == cfg.gramWindow);
        valid = full(r.gramValid(full));
        d.gramFullWindows = numel(full); d.gramInvalidFullWindows = numel(full)-numel(valid);
        d.gramRankMin = minimum(r.gramRank(valid)); d.gramRankMax = maximum(r.gramRank(valid));
        d.gramDeficientWindows = nnz(r.gramRank(valid) < r.nEstimated);
        d.gramDeficientFraction = NaN;
        if ~isempty(valid), d.gramDeficientFraction = d.gramDeficientWindows/numel(valid); end
        d.gramConditionMax = maximum(r.gramCondition(valid)); % Preserve Inf.
        d.rankRelativeThreshold = cfg.rankRelativeThreshold;
        d.gramEigenMin = minimum(r.gramEigenvalues(1,valid));
        d.gramEigenMax = maximum(r.gramEigenvalues(2,valid));
        d.qpConditionMax = maximum(r.qpCondition(steps));
        d.solverResidualMax = maximum(r.solverResiduals(:,steps));
        d.controlTimeMedianSeconds = median(r.controlTime(steps));
        d.controlTimeMaxSeconds = maximum(r.controlTime(steps));
        d.predictedSlackMax = maximum(r.slack(:,:,steps));
        d.predictedSlackActiveSteps = nnz(reshape(any(any(r.slack(:,:,steps) > 1e-6,1),2),1,[]));
        d.stateMin = minimum(states); d.stateMax = maximum(states);
        d.inputMin = minimum(applied); d.inputMax = maximum(applied);
        d.outputViolationPeak = maximum(max(abs(states)-cfg.control.hy(1),0));
        d.outputViolationCount = nnz(abs(states) > cfg.control.hy(1));
        d.inputViolationPeak = maximum(max(abs(applied)-cfg.control.hu(1),0));
        d.incrementViolationPeak = maximum(max(abs(du)-cfg.control.hdu(1),0));
        d.activityTolerance = 1e-6;
        d.inputActiveSamples = nnz(abs(applied) >= cfg.control.hu(1)-d.activityTolerance);
        d.incrementActiveSamples = nnz(abs(du) >= cfg.control.hdu(1)-d.activityTolerance);
        d.hardInputViolationSamples = nnz(abs(applied) > cfg.control.hu(1)+d.activityTolerance);
        d.hardIncrementViolationSamples = nnz(abs(du) > cfg.control.hdu(1)+d.activityTolerance);
        d.gridAttemptedSnapshots = nnz(e.attempted); d.gridInvalidSnapshots = nnz(e.attempted & ~e.valid);
        diagnostics = [diagnostics;d]; %#ok<AGROW>
        rec = base; recovery = study4_recovery(r);
        for field = string(fieldnames(recovery)).', rec.(field) = recovery.(field); end
        recoveries = [recoveries;rec]; %#ok<AGROW>
        for j = 1:numel(e.time)
            item = base; item.timeSeconds = e.time(j); item.sampleIndex = e.sampleIndices(j);
            item.attempted = e.attempted(j); item.valid = e.valid(j);
            item.queryCount = numel(e.x); item.predictionRMS = e.rms(j);
            grid = [grid;item]; %#ok<AGROW>
            if e.attempted(j) && ~e.valid(j)
                events = [events;event_row(base,e.sampleIndices(j),'gridEvaluation',e.message{j})]; %#ok<AGROW>
            end
        end
        for j = 1:numel(r.events)
            a = r.events(j);
            events = [events;event_row(base,a.index,a.stage,a.message)]; %#ok<AGROW>
        end
    end
end
summary.metrics = struct2table(metrics); summary.diagnostics = struct2table(diagnostics);
summary.recovery = struct2table(recoveries); summary.grid = struct2table(grid);
summary.parameters = struct2table(parameters);
if isempty(events)
    dummy = event_row(base,0,'',''); summary.events = struct2table(dummy); summary.events(1,:) = [];
else
    summary.events = struct2table(events);
end
[summary.initialization,initialization] = initial_scores(output,cfg);
save(fullfile(destination,'evaluation','initialization.mat'),'initialization');
summary.counts = table(12,sum(summary.diagnostics.completed), ...
    sum(~summary.diagnostics.completed),sum(summary.diagnostics.identificationRejected), ...
    sum(summary.diagnostics.fallbackActions),'VariableNames', ...
    {'attemptedRuns','completedRuns','incompleteRuns','rejectedUpdates','fallbackActions'});
names = {'metrics','diagnostics','recovery','grid','parameters','events','initialization','counts'};
for j = 1:numel(names)
    writetable(summary.(names{j}),fullfile(destination,'tables',[names{j},'.csv']));
end
end
function row = event_row(base,index,stage,message)
row = base; row.index = index; row.stage = string(stage); row.message = string(message);
end
function [scores,evidence] = initial_scores(output,cfg)
saved = load(fullfile(output,'records.mat'),'records'); r = saved.records.evaluation;
rows = struct([]); evidence = struct;
for id = string(cfg.modelIds)
    [model,theta,~,name] = study4_model(id);
    fit = []; n = 0;
    if id ~= "K"
        saved = load(fullfile(output,'fits',sprintf('fit_%s.mat',id)),'fit'); fit = saved.fit;
        n = fit.nEstimated;
    end
    errors = nan(600,numel(cfg.fitSteps));
    for checkpoint = 1:numel(cfg.fitSteps)
        if id ~= "K", theta = fit.checkpointTheta(:,checkpoint); end
        for j = 1:600
            errors(j,checkpoint) = forward_map(model,r.x(j),r.u(j),theta)-r.x(j+1);
        end
        row = struct('model',string(name),'modelId',id,'coefficientCount',n, ...
            'fittingTransitions',cfg.fitSteps(checkpoint),'predictionRMS',required_rms(errors(:,checkpoint)), ...
            'queryCount',600,'finiteQueries',nnz(isfinite(errors(:,checkpoint))), ...
            'attemptedUpdates',0,'rejectedUpdates',0,'finalCovarianceCondition',NaN);
        if id ~= "K"
            count = cfg.fitSteps(checkpoint);
            row.attemptedUpdates = nnz(fit.attempted(1:count));
            row.rejectedUpdates = nnz(~fit.accepted(1:count));
            row.finalCovarianceCondition = cond(fit.checkpointCovariance(:,:,checkpoint));
        end
        rows = [rows;row]; %#ok<AGROW>
    end
    evidence.(id) = errors;
end
scores = struct2table(rows);
end
function value = required_rms(values)
value = sqrt(required_mean(values.^2));
end
function value = required_mean(values)
value = NaN;
if ~isempty(values) && all(isfinite(values),'all'), value = mean(values,'all'); end
end
function value = minimum(values)
values = values(~isnan(values)); value = NaN;
if ~isempty(values), value = min(values(:)); end
end
function value = maximum(values)
values = values(~isnan(values)); value = NaN;
if ~isempty(values), value = max(values(:)); end
end
