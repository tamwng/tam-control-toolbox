function summary = study5_summarize(output,cfg,destination)
%STUDY5_SUMMARIZE All pilot outcomes in physical forward-output units.
% Inverse and direct regression residuals are not pooled or compared.
% The optional destination separates regenerated reports from source records.
if nargin < 3, destination = output; end
assert_output_writable(destination);
tableDir = fullfile(destination,'tables');
if ~isfolder(tableDir), mkdir(tableDir); end
summary.metrics = table; initialization = struct([]); forecasts = struct([]);
diagnostics = struct([]); events = struct([]); parameters = table;
numericalRuns = struct([]);
saved = load(fullfile(output,'evaluation','common_queries.mat'),'queries'); q = saved.queries;
for id = string(cfg.modelIds)
    saved = load(fullfile(output,'fits',sprintf('fit_%s.mat',id)),'fit'); fit = saved.fit;
    saved = load(fullfile(output,'runs',sprintf('%s.mat',id)),'result'); r = saved.result;
    saved = load(fullfile(output,'evaluation',sprintf('%s.mat',id)),'forecasts'); f = saved.forecasts;
    base = struct('model',string(r.name),'modelId',id,'coefficientCount',r.nEstimated);
    summary.metrics = [summary.metrics;study5_metrics(r,cfg)]; %#ok<AGROW>
    for s = 1:numel(cfg.fitSteps)
        row = base; row.fittingTransitions = cfg.fitSteps(s);
        row.queryCount = size(f.oneStepErrors,1); row.finiteQueries = nnz(isfinite(f.oneStepErrors(:,s)));
        row.predictionRMS = rms_required(f.oneStepErrors(:,s));
        row.predictionMax = maximum(abs(f.oneStepErrors(:,s)));
        row.predictorRefinementRMS = rms_required(f.oneStepRefinement(:,s));
        row.predictorRefinementMax = maximum(abs(f.oneStepRefinement(:,s)));
        row.attemptedUpdates = nnz(fit.attempted(1:cfg.fitSteps(s)));
        row.rejectedUpdates = nnz(fit.attempted(1:cfg.fitSteps(s)) & ~fit.accepted(1:cfg.fitSteps(s)));
        initialization = [initialization;row]; %#ok<AGROW>
    end
    for mode = 1:2
        for h = 1:numel(cfg.horizons)
            row = base; row.inputMode = string(q.inputModes{mode}); row.horizon = cfg.horizons(h);
            row.fittingTransitions = 200; row.queryCount = numel(q.anchors);
            row.validQueries = nnz(f.valid(:,h,mode)); row.predictionRMS = rms_required(f.modelError(:,h,mode));
            row.predictionMax = maximum(abs(f.modelError(:,h,mode)));
            row.knownNumericalFloorRMS = rms_required(q.knownNumericalError(:,row.horizon+1,mode));
            row.plantRefinementRMS = rms_required(q.referenceRefinementError(:,row.horizon+1,mode));
            row.predictorRefinementRMS = rms_required(f.forecastRefinement(:,row.horizon+1,mode));
            forecasts = [forecasts;row]; %#ok<AGROW>
        end
    end
    row = base; n = r.nSteps; steps = 1:n;
    row.attemptedRuns = 1; row.completedRuns = double(r.completed); row.completed = r.completed;
    row.expectedSteps = cfg.K; row.attemptedSteps = n; row.terminationReason = string(r.terminationReason);
    row.fitUpdatesAttempted = nnz(fit.attempted); row.fitUpdatesRejected = nnz(fit.attempted & ~fit.accepted);
    row.identificationAttempted = nnz(r.idAttempted); row.identificationRejected = nnz(r.idAttempted & ~r.idAccepted);
    row.fallbackActions = nnz(~r.controlAccepted(steps)); row.controlAccepted = nnz(r.controlAccepted(steps));
    row.fitMappingActivations = nnz(fit.mappingActivated); row.controlMappingActivations = nnz(r.mappingActivated);
    row.fitMappingFraction = mean(fit.mappingActivated); row.controlMappingFraction = mean(r.mappingActivated(steps));
    row.mappingMagnitudeMax = maximum(abs(r.mappingDelta(:,steps)));
    row.lambdaMin = minimum(r.lambda(steps)); row.lambdaMax = maximum(r.lambda(steps));
    row.regressionResidualUnits = string(r.residualUnits);
    row.covarianceEigenMin = minimum(r.covarianceEigenvalues(1,steps));
    row.covarianceEigenMax = maximum(r.covarianceEigenvalues(2,steps));
    row.covarianceConditionMax = maximum(r.covarianceCondition(steps));
    full = steps(r.gramCount(steps) == 50); valid = full(r.gramValid(full));
    row.gramFullWindows = numel(full); row.gramInvalidFullWindows = numel(full)-numel(valid);
    row.gramRankMin = minimum(r.gramRank(valid)); row.gramRankMax = maximum(r.gramRank(valid));
    row.gramDeficientWindows = nnz(r.gramRank(valid) < r.nEstimated);
    row.gramDeficientFraction = NaN;
    if ~isempty(valid), row.gramDeficientFraction = row.gramDeficientWindows/numel(valid); end
    row.gramConditionMax = maximum(r.gramCondition(valid)); % Inf is retained.
    row.rankRelativeThreshold = 1e-10;
    row.gramEigenMin = minimum(r.gramEigenvalues(1,valid)); row.gramEigenMax = maximum(r.gramEigenvalues(2,valid));
    row.qpConditionMax = maximum(r.qpCondition(steps));
    row.primalResidualMax = maximum(r.solverResiduals(1,steps));
    row.stationarityResidualMax = maximum(r.solverResiduals(2,steps));
    row.dualResidualMax = maximum(r.solverResiduals(3,steps));
    row.complementarityResidualMax = maximum(r.solverResiduals(4,steps));
    row.controlTimeMedianSeconds = median(r.controlTime(steps)); row.controlTimeMaxSeconds = maximum(r.controlTime(steps));
    row.predictedSlackMax = maximum(r.slack(:,:,steps));
    row.predictedSlackActiveSteps = nnz(reshape(any(any(r.slack(:,:,steps) > 1e-6,1),2),1,[]));
    states = r.x(1:n+1); inputs = r.u(steps); du = diff(inputs);
    row.stateMin = minimum(states); row.stateMax = maximum(states);
    row.inputMin = minimum(inputs); row.inputMax = maximum(inputs);
    row.outputViolationPeak = maximum(max(abs(states)-cfg.control.hy(1),0));
    row.outputViolationCount = nnz(abs(states) > cfg.control.hy(1));
    row.inputViolationPeak = maximum(max(abs(inputs)-cfg.control.hu(1),0));
    row.incrementViolationPeak = maximum(max(abs(du)-cfg.control.hdu(1),0));
    row.activityTolerance = 1e-6;
    row.inputActiveSamples = nnz(abs(inputs) >= cfg.control.hu(1)-1e-6);
    row.incrementActiveSamples = nnz(abs(du) >= cfg.control.hdu(1)-1e-6);
    row.hardInputViolationSamples = nnz(abs(inputs) > cfg.control.hu(1)+1e-6);
    row.hardIncrementViolationSamples = nnz(abs(du) > cfg.control.hdu(1)+1e-6);
    row.invalidOneStepQueries = nnz(~isfinite(f.oneStepErrors)); row.invalidForecastQueries = nnz(~f.valid);
    diagnostics = [diagnostics;row]; %#ok<AGROW>
    if id == "I"
        parameters = [parameters;parameter_rows(fit.theta,fit.mappedTheta,0:200,"initialization",cfg); ...
            parameter_rows(r.theta(:,steps),r.mappedTheta(:,steps),steps-1,"control",cfg)]; %#ok<AGROW>
    end
    for j = find(fit.attempted & ~fit.accepted)
        events = [events;event_row(base,"initialization",j,"identification",fit.message{j})]; %#ok<AGROW>
    end
    for j = 1:numel(r.events)
        a = r.events(j); events = [events;event_row(base,"control",a.index,a.stage,a.message)]; %#ok<AGROW>
    end
    for j = 1:numel(f.failures)
        a = f.failures(j); events = [events;event_row(base,"evaluation",a.anchor,a.mode,a.message)]; %#ok<AGROW>
    end
    saved = load(fullfile(output,'evaluation',sprintf('run_audit_%s.mat',id)),'runAudit'); a = saved.runAudit;
    row = base; row.plantLocalRefinementMax = maximum(abs(a.plantLocalDifference));
    row.plantReplayRefinementMax = maximum(abs(a.plantReplayDifference));
    row.predictorLocalRefinementMax = maximum(abs(a.predictorLocalDifference));
    row.stateJacobianRefinementMax = maximum(abs(a.predictorJacobianDifference(1,:)));
    row.inputJacobianRefinementMax = maximum(abs(a.predictorJacobianDifference(2,:)));
    row.zeroInputAnalyticalErrorMax = maximum(abs(a.zeroInputDifference));
    numericalRuns = [numericalRuns;row]; %#ok<AGROW>
end
summary.initialization = struct2table(initialization); summary.forecasts = struct2table(forecasts);
summary.diagnostics = struct2table(diagnostics); summary.physicalParameters = parameters;
summary.runNumerics = struct2table(numericalRuns);
if isempty(events)
    dummy = event_row(base,"",0,"",""); summary.events = struct2table(dummy); summary.events(1,:) = [];
else, summary.events = struct2table(events); end
saved = load(fullfile(output,'evaluation','numerical_audit.mat'),'audit'); a = saved.audit; rows = struct([]);
for s = 1:3
    row = struct('Ts',a.sampling(s),'queries',numel(a.x), ...
        'trapezoidResidualRMS_Nm',rms_required(a.trapezoidResidual(:,s)), ...
        'trapezoidResidualMax_Nm',maximum(abs(a.trapezoidResidual(:,s))), ...
        'refinedResidualRMS_Nm',rms_required(a.refinedResidual(:,s)), ...
        'refinedResidualMax_Nm',maximum(abs(a.refinedResidual(:,s))), ...
        'plant20to40Max_radPerSecond',maximum(abs(a.plantRefinement(:,s))), ...
        'predictor5to10Max_radPerSecond',maximum(abs(a.predictorRefinement(:,s))), ...
        'endpoint40IndependentMax_radPerSecond',maximum(abs(a.independentStateError(:,4,s))));
    for j = 1:4
        row.(sprintf('zeroInput%dMax_radPerSecond',a.substeps(j))) = maximum(abs(a.zeroInputError(:,j,s)));
    end
    rows = [rows;row]; %#ok<AGROW>
end
summary.quadrature = struct2table(rows);
summary.counts = table(numel(cfg.modelIds),sum(summary.diagnostics.completed), ...
    sum(~summary.diagnostics.completed),sum(summary.diagnostics.identificationRejected), ...
    sum(summary.diagnostics.fitUpdatesRejected),sum(summary.diagnostics.fallbackActions), ...
    'VariableNames',{'attemptedRuns','completedRuns','incompleteRuns','rejectedOnlineUpdates','rejectedFitUpdates','fallbackActions'});
names = fieldnames(summary);
for j = 1:numel(names), writetable(summary.(names{j}),fullfile(tableDir,[names{j},'.csv'])); end
end
function values = parameter_rows(raw,mapped,index,phase,cfg)
rows = struct([]); units = [string(cfg.units.J),string(cfg.units.d_C)];
labels = ["J","d_C"];
for j = 1:numel(index)
    for p = 1:2
        row = struct('model',"Integrated physical",'phase',phase,'index',index(j), ...
            'timeSeconds',index(j)*cfg.Ts,'parameter',labels(p),'unit',units(p), ...
            'raw',raw(p,j),'mapped',mapped(p,j),'trueValue',cfg.trueParameters(p), ...
            'rawError',raw(p,j)-cfg.trueParameters(p),'mappedError',mapped(p,j)-cfg.trueParameters(p), ...
            'mappingDelta',mapped(p,j)-raw(p,j),'mappingActivated',mapped(p,j) ~= raw(p,j), ...
            'rawScaledPercent',100*norm(raw(:,j)-cfg.trueParameters)/sqrt(2), ...
            'mappedScaledPercent',100*norm(mapped(:,j)-cfg.trueParameters)/sqrt(2));
        rows = [rows;row]; %#ok<AGROW>
    end
end
values = struct2table(rows);
end
function row = event_row(base,phase,index,stage,message)
row = base; row.phase = string(phase); row.index = index; row.stage = string(stage); row.message = string(message);
end
function value = rms_required(x)
value = NaN; if ~isempty(x) && all(isfinite(x),'all'), value = sqrt(mean(x.^2,'all')); end
end
function value = maximum(x)
x = x(~isnan(x)); value = NaN; if ~isempty(x), value = max(x(:)); end
end
function value = minimum(x)
x = x(~isnan(x)); value = NaN; if ~isempty(x), value = min(x(:)); end
end
