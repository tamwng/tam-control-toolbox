function summary = study2_summarize(output,cfg)
%STUDY2_SUMMARIZE Deterministic pilot scores under Section 6.2.2/Appendix A.
% Reference amplitude belongs to control runs; evaluationRange belongs to
% independent common-data queries. No pairing of these variables is implied.
% Scores with missing/nonfinite entries remain undefined. A terminated run
% has explicitly labelled finite-prefix scores, never complete-run averages.
% Activity counts use 1e-6 proximity to a bound; strict exceedances and their
% magnitudes are retained separately, including floating-point exceedances.
folder = fullfile(output,'tables');
if ~isfolder(folder), mkdir(folder); end
metrics = struct([]); diagnostics = struct([]); initialization = struct([]);
parameters = struct([]); forecasts = struct([]); events = struct([]);
constraint = struct([]); fitDiagnostics = struct([]);
for im = 1:numel(cfg.modelIds)
    id = cfg.modelIds{im};
    saved = load(fullfile(output,'fits',[id,'.mat']),'fit'); fit = saved.fit;
    saved = load(fullfile(output,'evaluation',[id,'.mat']),'evaluations');
    evaluations = saved.evaluations;
    base = model_base(id,fit.name,fit.nEstimated);
    fitDiagnostics = [fitDiagnostics;fit_diagnostics(fit,base)]; %#ok<AGROW>
    for k = find(fit.attempted & ~fit.accepted)
        events = [events;event_row(base,'initialization',NaN,k,NaN, ...
            'identification',fit.message{k})]; %#ok<AGROW>
    end
    for ie = 1:numel(evaluations)
        f = evaluations(ie);
        for j = 1:numel(cfg.fitSteps)
            row = base; row.evaluationRange = f.evaluationRange;
            row.fittingTransitions = cfg.fitSteps(j);
            errors = f.oneStepErrors(:,j);
            row.evaluationQueries = numel(errors);
            row.finiteQueries = nnz(isfinite(errors));
            row.predictionRMS = rms_required(errors);
            row.parameterScaledPercent = NaN;
            if strcmp(id,'E')
                row.parameterScaledPercent = 100*norm( ...
                    fit.checkpointTheta(:,j)-[.03;.65;.40])/sqrt(3);
            end
            initialization = [initialization;row]; %#ok<AGROW>
            for mode = 1:numel(f.inputModes)
                for h = 1:numel(cfg.horizons)
                    item = base; item.evaluationRange = f.evaluationRange;
                    item.fittingTransitions = cfg.fitSteps(j);
                    item.inputMode = string(f.inputModes{mode});
                    item.horizon = cfg.horizons(h);
                    item.queryCount = numel(cfg.anchors);
                    item.validCount = nnz(f.valid(:,h,mode,j));
                    em = f.modelError(:,h,mode,j);
                    ef = f.freezingError(:,h,mode,j);
                    et = f.totalError(:,h,mode,j);
                    item.modelRMS = rms_required(em);
                    item.freezingRMS = rms_required(ef);
                    item.totalRMS = rms_required(et);
                    item.meanCrossTerm = mean_required(f.crossTerm(:,h,mode,j));
                    item.identityResidualMax = maximum(abs(et-em-ef));
                    item.squaredIdentityResidualMax = maximum(abs(et.^2-em.^2-ef.^2-2*em.*ef));
                    forecasts = [forecasts;item]; %#ok<AGROW>
                end
            end
        end
        for k = 1:numel(f.failures)
            failure = f.failures(k);
            message = sprintf('L=%.2f; fit=%d; mode=%s; %s', ...
                f.evaluationRange,failure.fitStep,failure.mode,failure.message);
            events = [events;event_row(base,'evaluation',NaN, ...
                failure.anchor,NaN,'forecast',message)]; %#ok<AGROW>
        end
    end
    if strcmp(id,'E')
        for j = 1:numel(cfg.fitSteps)
            parameters = [parameters;parameter_rows(base,'initialization',NaN, ...
                cfg.fitSteps(j),fit.checkpointTheta(:,j),fit.labels)]; %#ok<AGROW>
        end
    end
    for ia = 1:numel(cfg.amplitudes)
        path = fullfile(output,'runs',sprintf('amplitude_%02d_%s.mat',ia,id));
        saved = load(path,'result'); result = saved.result;
        metrics = [metrics;score_run(result,base)]; %#ok<AGROW>
        diagnostics = [diagnostics;diagnose_run(result,base)]; %#ok<AGROW>
        events = [events;run_events(result,base)]; %#ok<AGROW>
        if strcmp(id,'E') && result.nSteps > 0
            parameters = [parameters;parameter_rows(base,'controlFinal', ...
                result.amplitude,result.nSteps-1,result.theta(:,result.nSteps),fit.labels)]; %#ok<AGROW>
        end
    end
    if ismember(id,cfg.auditIds)
        saved = load(fullfile(output,'runs',['constraint_',id,'.mat']),'result');
        result = saved.result;
        metrics = [metrics;score_run(result,base)]; %#ok<AGROW>
        diagnostics = [diagnostics;diagnose_run(result,base)]; %#ok<AGROW>
        constraint = [constraint;constraint_row(result,base)]; %#ok<AGROW>
        events = [events;run_events(result,base)]; %#ok<AGROW>
    end
end
summary.metrics = struct2table(metrics);
summary.diagnostics = struct2table(diagnostics);
summary.initialization = struct2table(initialization);
summary.parameters = struct2table(parameters);
summary.forecasts = struct2table(forecasts);
summary.constraint = struct2table(constraint);
summary.fitDiagnostics = struct2table(fitDiagnostics);
if isempty(events)
    summary.events = table('Size',[0,8],'VariableTypes', ...
        {'string','string','string','double','double','double','string','string'}, ...
        'VariableNames',{'model','modelName','kind','amplitude','index','time','stage','message'});
else
    summary.events = struct2table(events);
end
saved = load(fullfile(output,'records.mat'),'initialization','evaluation');
summary.records = record_ranges(saved.initialization,saved.evaluation);
counts = struct([]);
for kind = ["amplitude","constraintAudit"]
    block = summary.diagnostics(summary.diagnostics.kind == kind,:);
    row = struct('kind',kind,'attempted',height(block),'completed',sum(block.completed), ...
        'incomplete',sum(~block.completed),'identificationRejected',sum(block.identificationRejected), ...
        'controlRejected',sum(block.controlRejected),'mappingActivations',sum(block.mappingActivations));
    counts = [counts;row]; %#ok<AGROW>
end
summary.counts = struct2table(counts);
fields = {'metrics','diagnostics','initialization','parameters','forecasts', ...
    'constraint','fitDiagnostics','events','records','counts'};
files = {'run_metrics','run_diagnostics','initialization_scores','parameter_components', ...
    'common_query_forecasts','constraint_audit','initialization_diagnostics', ...
    'events','record_ranges','run_counts'};
for j = 1:numel(fields)
    writetable(summary.(fields{j}),fullfile(folder,[files{j},'.csv']));
end
fprintf('Study 2 tables: %d/%d control runs completed; %d recorded events.\n', ...
    sum(summary.diagnostics.completed),height(summary.diagnostics),height(summary.events));
end

function base = model_base(id,name,count)
base = struct('model',string(id),'modelName',string(name),'estimatedCoefficients',count);
end

function rows = score_run(result,base)
n = result.nSteps; K = numel(result.time)-1;
time = result.time(1:K); names = {'whole'};
masks = {true(1,K)};
if strcmp(result.kind,'amplitude')
    names{2} = 'principal'; masks{2} = time >= 20 & time < 80;
end
rows = struct([]);
for iw = 1:numel(names)
    row = base; row.kind = string(result.kind); row.amplitude = result.amplitude;
    row.window = string(names{iw}); row.completed = result.completed;
    row.status = "complete";
    if ~result.completed, row.status = "incompletePrefix"; end
    mask = masks{iw}; row.expectedSamples = nnz(mask);
    selected = find(mask & (1:K) <= n & isfinite(result.x(1:K)) & ...
        isfinite(result.r(1:K)) & isfinite(result.u(1:K)));
    row.scoredSamples = numel(selected);
    error = result.x(selected)-result.r(selected);
    row.trackingRMS = rms_required(error);
    row.peakTrackingError = maximum(abs(error));
    row.inputRMS = rms_required(result.u(selected));
    increments = selected(selected > 1);
    du = result.u(increments)-result.u(increments-1);
    row.meanAbsoluteIncrement = mean_required(abs(du));
    row.totalInputVariation = sum_required(abs(du));
    row.incrementSamples = numel(increments);
    prediction = result.prediction(selected);
    row.predictionExpected = numel(selected);
    row.predictionFinite = nnz(isfinite(prediction) & isfinite(result.x(selected+1)));
    row.predictionTrueRMS = rms_required(prediction-result.x(selected+1));
    row.predictionMeasuredRMS = rms_required(prediction-result.y(selected+1));
    row.stateMin = minimum(result.x(selected)); row.stateMax = maximum(result.x(selected));
    row.inputMin = minimum(result.u(selected)); row.inputMax = maximum(result.u(selected));
    row.parameterScaledRMSPercent = NaN; row.parameterFinalScaledPercent = NaN;
    if strcmp(result.id,'E') && ~isempty(selected)
        e = 100*vecnorm(result.theta(:,selected)-[.03;.65;.40],2,1)/sqrt(3);
        row.parameterScaledRMSPercent = rms_required(e);
        row.parameterFinalScaledPercent = e(end);
    end
    rows = [rows;row]; %#ok<AGROW>
end
end

function row = diagnose_run(result,base)
row = base; row.kind = string(result.kind); row.amplitude = result.amplitude;
n = result.nSteps; steps = 1:n; c = result.controlSettings;
xmax = c.hy(1); umax = c.hu(1); dumax = c.hdu(1); tol = 1e-6;
row.completed = result.completed; row.attemptedSteps = n;
row.terminationReason = string(result.terminationReason);
row.identificationAttempted = nnz(result.idAttempted(steps));
row.identificationRejected = nnz(result.idAttempted(steps) & ~result.idAccepted(steps));
row.controlRejected = nnz(~result.controlAccepted(steps));
row.mappingActivations = nnz(result.mappingActivated(steps));
row.lambdaMin = minimum(result.lambda(steps)); row.lambdaMax = maximum(result.lambda(steps));
row.controlTimeMedianSeconds = median_required(result.controlTime(steps));
row.controlTimeMaximumSeconds = maximum(result.controlTime(steps));
row.qpConditionMedian = median_required(result.qpCondition(steps));
row.qpConditionMax = maximum(result.qpCondition(steps));
row.qpConditionNonfinite = nnz(~isfinite(result.qpCondition(steps)));
row.primalResidualMax = maximum(result.solverResiduals(1,steps));
row.stationarityResidualMax = maximum(result.solverResiduals(2,steps));
row.dualResidualMax = maximum(result.solverResiduals(3,steps));
row.complementarityResidualMax = maximum(result.solverResiduals(4,steps));
row.predictedSlackMax = maximum(result.slack(:,:,steps));
row.predictedFirstStepSlackMax = maximum(result.slack(:,1,steps));
row.predictedSlackActiveSteps = nnz(reshape(any(any(result.slack(:,:,steps) > tol,1),2),1,[]));
row.covarianceEigenMin = minimum(result.covarianceEigenvalues(1,steps));
row.covarianceEigenMax = maximum(result.covarianceEigenvalues(2,steps));
row.covarianceConditionMax = maximum(result.covarianceCondition(steps));
full = steps(result.gramCount(steps) == 50);
row.gramFullWindowCount = numel(full);
row.gramEigenMin = minimum(result.gramEigenvalues(1,full));
row.gramEigenMax = maximum(result.gramEigenvalues(2,full));
row.gramConditionMax = maximum(result.gramCondition(full));
row.gramConditionNonfinite = nnz(~isfinite(result.gramCondition(full)));
states = result.x(1:n+1); inputs = result.u(1:n); du = diff(inputs);
row.stateSamples = numel(states); row.finiteStateSamples = nnz(isfinite(states));
row.appliedInputSamples = numel(inputs); row.finiteAppliedInputSamples = nnz(isfinite(inputs));
row.stateMin = minimum(states); row.stateMax = maximum(states);
row.appliedInputMin = minimum(inputs); row.appliedInputMax = maximum(inputs);
row.referenceMin = minimum(result.r(1:n)); row.referenceMax = maximum(result.r(1:n));
row.outputBound = xmax; row.inputBound = umax; row.incrementBound = dumax;
row.activityTolerance = tol;
row.initialOutputViolation = max(abs(states(1))-xmax,0);
row.futureOutputViolationPeak = maximum(max(abs(states(2:end))-xmax,0));
row.futureOutputViolationCount = nnz(abs(states(2:end)) > xmax);
row.allOutputViolationPeak = maximum(max(abs(states)-xmax,0));
row.allOutputViolationCount = nnz(abs(states) > xmax);
row.allInputViolationPeak = maximum(max(abs(inputs)-umax,0));
row.allInputViolationCount = nnz(abs(inputs) > umax);
row.allIncrementViolationPeak = maximum(max(abs(du)-dumax,0));
row.allIncrementViolationCount = nnz(abs(du) > dumax);
row.inputViolationCountOverTolerance = nnz(abs(inputs) > umax+tol);
row.incrementViolationCountOverTolerance = nnz(abs(du) > dumax+tol);
row.outputBoundActiveSamples = nnz(abs(states) >= xmax-tol);
row.inputBoundActiveSamples = nnz(abs(inputs) >= umax-tol);
row.incrementBoundActiveSamples = nnz(abs(du) >= dumax-tol);
row.terminalState = states(end); row.terminalCommittedInput = result.u(n+1);
row.terminalCommittedInputViolation = max(abs(result.u(n+1))-umax,0);
row.terminalCommittedIncrementViolation = NaN;
if n > 0
    row.terminalCommittedIncrementViolation = max(abs(result.u(n+1)-result.u(n))-dumax,0);
end
end

function row = constraint_row(result,base)
row = base; row.completed = result.completed; row.attemptedSteps = result.nSteps;
bound = result.controlSettings.hy(1);
row.initialState = result.x(1); row.committedInput = result.u(1);
row.outputBound = bound; row.initialOutputViolation = max(abs(result.x(1))-bound,0);
row.firstPredictedState = NaN; row.firstPredictedUpperSlack = NaN;
row.firstPredictedLowerSlack = NaN; row.actualNextState = NaN;
row.actualNextOutputViolation = NaN; row.firstControlAccepted = false;
row.nextCommittedInput = NaN;
if result.nSteps > 0
    row.firstPredictedState = result.plannedOutput(1,1);
    row.firstPredictedUpperSlack = result.slack(1,1,1);
    row.firstPredictedLowerSlack = result.slack(2,1,1);
    row.actualNextState = result.x(2);
    row.actualNextOutputViolation = max(abs(result.x(2))-bound,0);
    row.firstControlAccepted = result.controlAccepted(1);
    row.nextCommittedInput = result.u(2);
end
row.knownModelAlgebraicUpperSlackMinimum = NaN;
if strcmp(result.id,'K'), row.knownModelAlgebraicUpperSlackMinimum = .09; end
end

function row = fit_diagnostics(fit,base)
row = base; row.attemptedUpdates = nnz(fit.attempted);
row.acceptedUpdates = nnz(fit.accepted); row.rejectedUpdates = nnz(fit.attempted & ~fit.accepted);
row.scalingMinimum = minimum(fit.D); row.scalingMaximum = maximum(fit.D);
row.lambdaMin = minimum(fit.lambda(fit.attempted));
row.lambdaMax = maximum(fit.lambda(fit.attempted));
row.finalCovarianceCondition = NaN;
if fit.nEstimated > 0, row.finalCovarianceCondition = cond(fit.covariance(:,:,end)); end
end

function rows = parameter_rows(base,phase,amplitude,index,theta,labels)
rows = struct([]); target = [.03;.65;.40];
for j = 1:3
    row = base; row.phase = string(phase); row.amplitude = amplitude; row.index = index;
    row.component = string(labels{j}); row.estimate = theta(j); row.target = target(j);
    row.error = theta(j)-target(j); rows = [rows;row]; %#ok<AGROW>
end
end

function rows = run_events(result,base)
rows = struct([]);
for j = 1:numel(result.events)
    event = result.events(j);
    rows = [rows;event_row(base,result.kind,result.amplitude,event.index, ...
        event.index*result.Ts,event.stage,event.message)]; %#ok<AGROW>
end
end

function row = event_row(base,kind,amplitude,index,time,stage,message)
row = struct('model',base.model,'modelName',base.modelName,'kind',string(kind), ...
    'amplitude',amplitude,'index',index,'time',time,'stage',string(stage),'message',string(message));
end

function result = record_ranges(initialization,evaluation)
records = [initialization,evaluation]; rows = struct([]);
for j = 1:numel(records)
    r = records(j); kind = "evaluation";
    if j == 1, kind = "initialization"; end
    row = struct('kind',kind,'inputTargetRange',r.L,'seed',r.seed, ...
        'transitions',numel(r.u),'stateMin',minimum(r.x),'stateMax',maximum(r.x), ...
        'inputMin',minimum(r.u),'inputMax',maximum(r.u), ...
        'inputIncrementPeak',maximum(abs(diff(r.u))));
    rows = [rows;row]; %#ok<AGROW>
end
result = struct2table(rows);
end

function value = rms_required(x)
value = NaN;
if ~isempty(x) && all(isfinite(x(:))), value = sqrt(mean(x(:).^2)); end
end
function value = mean_required(x)
value = NaN;
if ~isempty(x) && all(isfinite(x(:))), value = mean(x(:)); end
end
function value = median_required(x)
value = NaN;
if ~isempty(x) && all(isfinite(x(:))), value = median(x(:)); end
end
function value = sum_required(x)
value = NaN;
if ~isempty(x) && all(isfinite(x(:))), value = sum(x(:)); end
end
function value = maximum(x)
x = x(~isnan(x)); value = NaN;
if ~isempty(x), value = max(x(:)); end
end
function value = minimum(x)
x = x(~isnan(x)); value = NaN;
if ~isempty(x), value = min(x(:)); end
end
