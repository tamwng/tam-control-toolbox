function summary = study1_summarize(output,cfg)
%STUDY1_SUMMARIZE Study 1 scores and diagnostics under Appendix A.
%   Complete-run summaries exclude incomplete runs and retain their counts.
%   Finite-prefix scores are explicitly labelled. Quantiles interpolate
%   linearly at order-statistic position 1+(n-1)*p; no Statistics Toolbox.
% Single-argument P06 access exposes the unchanged per-run scoring helpers.
if nargin == 1 && isequal(output,'p06_helpers')
    summary = struct('scoreRun',@score_run,'scoreFit',@score_fit, ...
        'diagnoseRun',@diagnose_run,'percentile',@percentile);
    return
end
tableDir = fullfile(output,'tables');
if ~isfolder(tableDir), mkdir(tableDir); end
metrics = struct([]); diagnostics = struct([]); initialization = struct([]);
parameters = struct([]); forecasts = struct([]); events = struct([]);
campaigns = {'pilot','confirmation'};
for ic = 1:numel(campaigns)
    campaign = campaigns{ic};
    for im = 1:numel(cfg.modelIds)
        id = cfg.modelIds{im};
        for trial = 0:cfg.(campaign).noiseTrials
            name = sprintf('%s_%s_%03d.mat',campaign,id,trial);
            path = fullfile(output,'data',name);
            if ~isfile(path)
                error('study1:MissingRun','Required attempted-run file is missing: %s',name);
            end
            saved = load(path,'result');
            result = saved.result;
            base = struct('campaign',string(campaign),'model',string(id), ...
                'trial',trial,'noise',trial > 0);
            metrics = [metrics;score_run(result,base,cfg)]; %#ok<AGROW>
            auditSaved = load(fullfile(output,'audits',name),'audit');
            audit = auditSaved.audit;
            diagnosticRow = diagnose_run(result,base,cfg);
            diagnosticRow.measuredAuditInvalid = nnz(~audit.valid);
            diagnostics = [diagnostics;diagnosticRow]; %#ok<AGROW>
            initialization = [initialization;score_fit(result,base,cfg)]; %#ok<AGROW>
            parameters = [parameters;parameter_rows(result,base,cfg)]; %#ok<AGROW>
            forecasts = [forecasts;score_forecasts(result,base,cfg)]; %#ok<AGROW>
            for ie = 1:numel(result.events)
                row = base;
                row.index = result.events(ie).index;
                row.time = result.events(ie).index*cfg.Ts;
                row.stage = string(result.events(ie).stage);
                row.message = string(result.events(ie).message);
                events = [events;row]; %#ok<AGROW>
            end
            rejected = find(result.fit.attempted & ~result.fit.accepted);
            for ie = rejected
                row = base; row.index = ie;
                row.time = ie*cfg.Ts; row.stage = "initialization";
                row.message = string(result.fit.message{ie});
                events = [events;row]; %#ok<AGROW>
            end
            for ie = 1:numel(result.forecasts.failures)
                event = result.forecasts.failures(ie);
                row = base; row.index = event.anchor; row.time = NaN;
                row.stage = "forecast";
                row.message = string(sprintf('fit=%d; mode=%s; %s', ...
                    event.fitStep,event.mode,event.message));
                events = [events;row]; %#ok<AGROW>
            end
            for ie = 1:numel(audit.failures)
                event = audit.failures(ie);
                row = base; row.index = event.snapshotIndex;
                row.time = event.snapshotIndex*cfg.Ts;
                row.stage = "measuredInitialization";
                row.message = string(sprintf('mode=%s; horizon=%d; %s', ...
                    event.mode,event.horizon,event.message));
                events = [events;row]; %#ok<AGROW>
            end
        end
    end
end
summary.metrics = struct2table(metrics);
summary.diagnostics = struct2table(diagnostics);
summary.initialization = struct2table(initialization);
summary.parameters = struct2table(parameters);
summary.forecasts = struct2table(forecasts);
if isempty(events)
    summary.events = table('Size',[0,8],'VariableTypes', ...
        {'string','string','double','logical','double','double','string','string'}, ...
        'VariableNames',{'campaign','model','trial','noise','index','time','stage','message'});
else
    summary.events = struct2table(events);
end
summary.counts = trial_counts(summary.diagnostics,cfg);
summary.noisy = noisy_summaries(summary.metrics,cfg);
summary.paired = paired_contrasts(summary.metrics,cfg);
[summary.initializationNoisy,summary.initializationPaired] = ...
    query_summaries(summary.initialization,{'fittingTransitions'}, ...
    {'predictionRMS','parameterScaledPercent'},cfg);
[summary.forecastsNoisy,summary.forecastsPaired] = ...
    query_summaries(summary.forecasts,{'fittingTransitions','inputMode','horizon'}, ...
    {'modelRMS','freezingRMS','totalRMS','meanCrossTerm'},cfg);
% These recorded-trajectory audits use each controller's own states and
% inputs. Their paired summaries describe sensitivity, not common queries.
summary.measured = readtable(fullfile(tableDir,'measured_initialization_audit.csv'), ...
    'TextType','string');
summary.measured.noise = summary.measured.trial > 0;
[summary.measuredNoisy,summary.measuredPaired] = ...
    query_summaries(summary.measured,{'auditType','inputMode','horizon'}, ...
    {'measuredModelRMS','freezingRMS','totalRMS','cleanModelRMS', ...
    'initializationEffectRMS','meanCrossTerm'},cfg);
names = {'metrics','diagnostics','initialization','parameters','forecasts', ...
    'events','counts','noisy','paired','initializationNoisy','initializationPaired', ...
    'forecastsNoisy','forecastsPaired','measuredNoisy','measuredPaired'};
files = {'run_metrics','run_diagnostics','initialization_scores', ...
    'parameter_components','common_query_forecasts','events', ...
    'trial_counts','noisy_summaries','paired_contrasts', ...
    'initialization_noisy_summaries','initialization_paired_contrasts', ...
    'forecast_noisy_summaries','forecast_paired_contrasts', ...
    'measured_initialization_noisy_summaries','measured_initialization_paired_contrasts'};
for j = 1:numel(names)
    writetable(summary.(names{j}),fullfile(tableDir,[files{j},'.csv']));
end
fprintf('Study 1 tables: %d attempted runs, %d completed, %d recorded events.\n', ...
    height(summary.diagnostics),sum(summary.diagnostics.completed),height(summary.events));
end

function rows = score_run(result,base,cfg)
rows = struct([]);
time = (0:cfg.K-1)*cfg.Ts;
windows = {true(1,cfg.K),mod(time,20) >= 10-1e-10};
names = {'whole','stationary'};
for iw = 1:2
    row = base; row.window = string(names{iw});
    row.completed = result.completed;
    row.status = "complete";
    if ~result.completed, row.status = "incompletePrefix"; end
    mask = windows{iw};
    row.expectedSamples = nnz(mask);
    available = (1:cfg.K) <= result.nSteps & ...
        isfinite(result.x(1:cfg.K)) & isfinite(result.r(1:cfg.K)) & ...
        isfinite(result.u(1:cfg.K));
    selected = find(mask & available);
    row.scoredSamples = numel(selected);
    row.trackingRMS = root_mean_square(result.x(selected)-result.r(selected));
    row.inputRMS = root_mean_square(result.u(selected));
    row.peakTrackingError = maximum(abs(result.x(selected)-result.r(selected)));
    increments = selected(selected > 1);
    du = result.u(increments)-result.u(increments-1);
    row.meanAbsoluteIncrement = mean_finite_required(abs(du));
    row.totalInputVariation = sum_required(abs(du));
    p = result.prediction(selected);
    row.predictionExpected = numel(selected);
    row.predictionFinite = nnz(isfinite(p) & isfinite(result.x(selected+1)));
    row.predictionTrueRMS = root_mean_square(p-result.x(selected+1));
    row.predictionMeasuredRMS = root_mean_square(p-result.y(selected+1));
    row.parameterScaledRMSPercent = NaN;
    row.parameterFinalScaledPercent = NaN;
    target = parameter_target(result.id);
    if ~isempty(target) && ~isempty(selected)
        error = 100*vecnorm(result.theta(:,selected)-target,2,1)/sqrt(numel(target));
        row.parameterScaledRMSPercent = root_mean_square(error);
        row.parameterFinalScaledPercent = error(end);
    end
    row.stateMin = minimum(result.x(selected));
    row.stateMax = maximum(result.x(selected));
    row.inputMin = minimum(result.u(selected));
    row.inputMax = maximum(result.u(selected));
    row.outputViolationPeak = maximum(max(abs(result.x(selected))-1.2,0));
    row.outputViolationCount = nnz(abs(result.x(selected)) > 1.2);
    row.inputViolationPeak = maximum(max(abs(result.u(selected))-1,0));
    row.incrementViolationPeak = maximum(max(abs(du)-.25,0));
    rows = [rows;row]; %#ok<AGROW>
end
end

function row = diagnose_run(result,base,cfg)
row = base;
row.completed = result.completed;
row.attemptedSteps = result.nSteps;
row.terminationReason = string(result.terminationReason);
n = result.nSteps;
steps = 1:n;
row.identificationAttempted = nnz(result.idAttempted(steps));
row.identificationRejected = nnz(result.idAttempted(steps) & ~result.idAccepted(steps));
row.initializationAttempted = nnz(result.fit.attempted);
row.initializationRejected = nnz(result.fit.attempted & ~result.fit.accepted);
row.totalIdentificationRejected = row.initializationRejected+row.identificationRejected;
row.controlRejected = nnz(~result.controlAccepted(steps));
row.mappingActivations = nnz(result.mappingActivated(steps));
row.forecastInvalid = nnz(~result.forecasts.valid);
row.oneStepForecastInvalid = nnz(~isfinite(result.forecasts.oneStepErrors));
row.controlTimeMedianSeconds = percentile(result.controlTime(steps),.5);
row.controlTimeMaximumSeconds = maximum(result.controlTime(steps));
row.lambdaMin = minimum(result.lambda(steps));
row.lambdaMax = maximum(result.lambda(steps));
row.qpConditionMedian = percentile(result.qpCondition(steps),.5);
row.qpConditionMax = maximum(result.qpCondition(steps));
row.primalResidualMax = maximum(result.solverResiduals(1,steps));
row.stationarityResidualMax = maximum(result.solverResiduals(2,steps));
row.dualResidualMax = maximum(result.solverResiduals(3,steps));
row.complementarityResidualMax = maximum(result.solverResiduals(4,steps));
row.predictedSlackMax = maximum(result.slack(:,:,steps));
row.predictedFirstStepSlackMax = maximum(result.slack(:,1,steps));
row.covarianceEigenMin = NaN; row.covarianceEigenMax = NaN;
row.covarianceConditionMax = NaN;
if ~isempty(result.covariance)
    extrema = nan(3,n);
    for k = steps
        matrix = result.covariance(:,:,k);
        if all(isfinite(matrix(:)))
            eigenvalues = eig((matrix+matrix')/2);
            extrema(:,k) = [min(eigenvalues);max(eigenvalues);cond(matrix)];
        end
    end
    row.covarianceEigenMin = minimum(extrema(1,:));
    row.covarianceEigenMax = maximum(extrema(2,:));
    row.covarianceConditionMax = maximum(extrema(3,:));
end
row.gramEigenMin = NaN; row.gramEigenMax = NaN; row.gramConditionMax = NaN;
row.gramFullWindowCount = 0;
if isfield(result,'gram') && ~isempty(result.gram)
    extrema = [];
    for k = steps
        if isfield(result,'gramCount') && result.gramCount(k) < 50, continue; end
        if ~isfield(result,'gramCount') && k <= 50, continue; end
        matrix = result.gram(:,:,k);
        if all(isfinite(matrix(:)))
            eigenvalues = eig((matrix+matrix')/2);
            extrema(:,end+1) = [min(eigenvalues);max(eigenvalues);cond(matrix)]; %#ok<AGROW>
        end
    end
    if ~isempty(extrema)
        row.gramEigenMin = minimum(extrema(1,:));
        row.gramEigenMax = maximum(extrema(2,:));
        row.gramConditionMax = maximum(extrema(3,:));
        row.gramFullWindowCount = size(extrema,2);
    end
end
states = result.x(1:min(n+1,cfg.K+1));
inputs = result.u(1:min(n,cfg.K));
du = diff(inputs);
row.initialOutputViolation = max(abs(states(1))-1.2,0);
row.terminalOutputViolation = max(abs(states(end))-1.2,0);
row.allOutputViolationPeak = maximum(max(abs(states)-1.2,0));
row.allOutputViolationCount = nnz(abs(states) > 1.2);
row.allInputViolationPeak = maximum(max(abs(inputs)-1,0));
row.allInputViolationCount = nnz(abs(inputs) > 1);
row.allIncrementViolationPeak = maximum(max(abs(du)-.25,0));
row.allIncrementViolationCount = nnz(abs(du) > .25);
row.inputViolationCountOver1e8Tolerance = nnz(abs(inputs) > 1+1e-8);
row.incrementViolationCountOver1e8Tolerance = nnz(abs(du) > .25+1e-8);
row.terminalCommittedInput = result.u(min(n+1,cfg.K+1));
row.terminalCommittedInputViolation = max(abs(row.terminalCommittedInput)-1,0);
row.terminalCommittedIncrementViolation = NaN;
if n > 0
    row.terminalCommittedIncrementViolation = max(abs(result.u(n+1)-result.u(n))-.25,0);
end
end

function rows = score_fit(result,base,cfg)
rows = struct([]);
target = parameter_target(result.id);
for j = 1:numel(cfg.fitSteps)
    row = base; row.fittingTransitions = cfg.fitSteps(j);
    errors = result.forecasts.oneStepErrors(:,j);
    row.evaluationQueries = numel(errors);
    row.finiteQueries = nnz(isfinite(errors));
    row.predictionRMS = root_mean_square(errors);
    row.parameterScaledPercent = NaN;
    if ~isempty(target)
        row.parameterScaledPercent = 100*norm(result.fit.checkpointTheta(:,j)-target)/sqrt(numel(target));
    end
    rows = [rows;row]; %#ok<AGROW>
end
end

function rows = parameter_rows(result,base,cfg)
rows = struct([]);
target = parameter_target(result.id);
if isempty(target), return; end
for j = 1:numel(cfg.fitSteps)+1
    if j <= numel(cfg.fitSteps)
        theta = result.fit.checkpointTheta(:,j);
        phase = "initialization"; index = cfg.fitSteps(j);
    else
        if result.nSteps == 0, continue; end
        index = result.nSteps-1; phase = "controlFinal";
        theta = result.theta(:,result.nSteps);
    end
    for i = 1:numel(target)
        row = base; row.phase = phase; row.index = index;
        row.component = i; row.estimate = theta(i); row.target = target(i);
        row.error = theta(i)-target(i);
        rows = [rows;row]; %#ok<AGROW>
    end
end
end

function rows = score_forecasts(result,base,cfg)
rows = struct([]); f = result.forecasts;
for j = 1:numel(cfg.fitSteps)
    for mode = 1:2
        for h = 1:numel(cfg.horizons)
            row = base; row.fittingTransitions = cfg.fitSteps(j);
            row.inputMode = string(f.inputModes{mode});
            row.horizon = cfg.horizons(h); row.queryCount = numel(cfg.anchors);
            row.validCount = nnz(f.valid(:,h,mode,j));
            row.modelRMS = root_mean_square(f.modelError(:,h,mode,j));
            row.freezingRMS = root_mean_square(f.freezingError(:,h,mode,j));
            row.totalRMS = root_mean_square(f.totalError(:,h,mode,j));
            row.meanCrossTerm = mean_finite_required(f.crossTerm(:,h,mode,j));
            row.identityResidualMax = maximum(f.identityResidual(:,h,mode,j));
            row.squaredIdentityResidualMax = maximum(f.squaredIdentityResidual(:,h,mode,j));
            rows = [rows;row]; %#ok<AGROW>
        end
    end
end
end

function counts = trial_counts(diagnostics,cfg)
rows = struct([]);
for campaign = ["pilot","confirmation"]
    for model = string(cfg.modelIds)
        for noise = [false,true]
            block = diagnostics(diagnostics.campaign == campaign & diagnostics.model == model & diagnostics.noise == noise,:);
            row = struct('campaign',campaign,'model',model,'noise',noise, ...
                'attempted',height(block),'completed',sum(block.completed), ...
                'incomplete',sum(~block.completed), ...
                'runsWithIdentificationRejections',nnz(block.identificationRejected > 0), ...
                'onlineIdentificationRejections',sum(block.identificationRejected), ...
                'runsWithInitializationRejections',nnz(block.initializationRejected > 0), ...
                'initializationRejections',sum(block.initializationRejected), ...
                'totalIdentificationRejections',sum(block.totalIdentificationRejected), ...
                'runsWithControlRejections',nnz(block.controlRejected > 0), ...
                'controlRejections',sum(block.controlRejected), ...
                'invalidForecasts',sum(block.forecastInvalid+block.oneStepForecastInvalid), ...
                'invalidMeasuredAuditQueries',sum(block.measuredAuditInvalid));
            rows = [rows;row]; %#ok<AGROW>
        end
    end
end
counts = struct2table(rows);
end

function scores = score_names()
scores = {'trackingRMS','inputRMS','meanAbsoluteIncrement','peakTrackingError', ...
    'totalInputVariation','predictionTrueRMS','predictionMeasuredRMS', ...
    'parameterScaledRMSPercent','parameterFinalScaledPercent'};
end

function summary = noisy_summaries(metrics,cfg)
rows = struct([]); scores = score_names();
for campaign = ["pilot","confirmation"]
    for model = string(cfg.modelIds)
        for window = ["whole","stationary"]
            block = metrics(metrics.campaign == campaign & metrics.model == model & ...
                metrics.noise & metrics.window == window,:);
            for s = 1:numel(scores)
                values = block.(scores{s})(block.completed);
                row = struct('campaign',campaign,'model',model,'window',window, ...
                    'metric',string(scores{s}),'attempted',height(block), ...
                    'completed',sum(block.completed),'finiteScores',nnz(isfinite(values)), ...
                    'median',percentile(values,.5),'q1',percentile(values,.25), ...
                    'q3',percentile(values,.75),'iqr',percentile(values,.75)-percentile(values,.25));
                rows = [rows;row]; %#ok<AGROW>
            end
        end
    end
end
summary = struct2table(rows);
end

function contrasts = paired_contrasts(metrics,cfg)
rows = struct([]); scores = score_names();
pairs = {'S','A';'S','W';'S','R';'R','P2'};
for campaign = ["pilot","confirmation"]
    stream = RandStream('mt19937ar','Seed',cfg.(char(campaign)).bootstrapSeed);
    for window = ["whole","stationary"]
        for p = 1:size(pairs,1)
            left = metrics(metrics.campaign == campaign & metrics.model == pairs{p,1} & ...
                metrics.noise & metrics.window == window,:);
            right = metrics(metrics.campaign == campaign & metrics.model == pairs{p,2} & ...
                metrics.noise & metrics.window == window,:);
            [~,il,ir] = intersect(left.trial,right.trial);
            complete = left.completed(il) & right.completed(ir);
            for s = 1:numel(scores)
                values = left.(scores{s})(il(complete))-right.(scores{s})(ir(complete));
                finite = isfinite(values);
                lower = NaN; upper = NaN; center = NaN;
                % Undefined parameter targets stay undefined; no trial is
                % discarded to manufacture a valid complete-pair score.
                if ~isempty(values) && all(finite)
                    center = percentile(values,.5);
                    samples = randi(stream,numel(values),numel(values),cfg.bootstrapCount);
                    bootstrap = median(values(samples),1);
                    lower = percentile(bootstrap,.025); upper = percentile(bootstrap,.975);
                end
                row = struct('campaign',campaign,'window',window, ...
                    'contrast',string([pairs{p,1},'-',pairs{p,2}]), ...
                    'metric',string(scores{s}),'attemptedPairs',numel(il), ...
                    'completePairs',nnz(complete),'finitePairs',nnz(finite), ...
                    'medianDifference',center,'lower95',lower,'upper95',upper, ...
                    'bootstrapResamples',cfg.bootstrapCount);
                rows = [rows;row]; %#ok<AGROW>
            end
        end
    end
end
contrasts = struct2table(rows);
end

function [summaries,contrasts] = query_summaries(data,keys,scores,cfg)
% Common-data queries do not depend on completion of a later control run.
% A complete pair here requires every prescribed query score to be finite.
data = data(data.noise,:);
groups = unique(data(:,keys),'rows','stable');
summaryRows = struct([]); contrastRows = struct([]);
pairs = {'S','A';'S','W';'S','R';'R','P2'};
for campaign = ["pilot","confirmation"]
    stream = RandStream('mt19937ar','Seed',cfg.(char(campaign)).bootstrapSeed);
    for ig = 1:height(groups)
        selected = data.campaign == campaign;
        context = struct;
        for ik = 1:numel(keys)
            key = keys{ik};
            selected = selected & data.(key) == groups.(key)(ig);
            context.(key) = groups.(key)(ig);
        end
        group = data(selected,:);
        for model = string(cfg.modelIds)
            block = group(group.model == model,:);
            for is = 1:numel(scores)
                values = block.(scores{is});
                row = context; row.campaign = campaign; row.model = model;
                row.metric = string(scores{is}); row.attempted = height(block);
                row.finiteScores = nnz(isfinite(values));
                row.median = percentile(values,.5); row.q1 = percentile(values,.25);
                row.q3 = percentile(values,.75); row.iqr = row.q3-row.q1;
                summaryRows = [summaryRows;row]; %#ok<AGROW>
            end
        end
        for ip = 1:size(pairs,1)
            left = group(group.model == pairs{ip,1},:);
            right = group(group.model == pairs{ip,2},:);
            [~,il,ir] = intersect(left.trial,right.trial);
            for is = 1:numel(scores)
                values = left.(scores{is})(il)-right.(scores{is})(ir);
                finite = isfinite(values);
                center = NaN; lower = NaN; upper = NaN;
                if ~isempty(values) && all(finite)
                    center = percentile(values,.5);
                    samples = randi(stream,numel(values),numel(values),cfg.bootstrapCount);
                    bootstrap = median(values(samples),1);
                    lower = percentile(bootstrap,.025); upper = percentile(bootstrap,.975);
                end
                row = context; row.campaign = campaign;
                row.contrast = string([pairs{ip,1},'-',pairs{ip,2}]);
                row.metric = string(scores{is}); row.attemptedPairs = numel(il);
                row.completePairs = nnz(finite); row.finitePairs = nnz(finite);
                row.medianDifference = center; row.lower95 = lower; row.upper95 = upper;
                row.bootstrapResamples = cfg.bootstrapCount;
                contrastRows = [contrastRows;row]; %#ok<AGROW>
            end
        end
    end
end
summaries = struct2table(summaryRows);
contrasts = struct2table(contrastRows);
end

function target = parameter_target(id)
switch char(id)
    case 'S', target = [.03;.65;.45];
    case 'R', target = [.03;.65;.45;.45*.35];
    case 'P2', target = [.03;.65;.45;0;.45*.35;0];
    otherwise, target = [];
end
end

function value = percentile(values,p)
values = values(:);
if isempty(values) || any(~isfinite(values)), value = NaN; return; end
values = sort(values);
position = 1+(numel(values)-1)*p;
lower = floor(position); upper = ceil(position);
value = values(lower)+(position-lower)*(values(upper)-values(lower));
end

function value = root_mean_square(values)
value = sqrt(mean_finite_required(values.^2));
end

function value = mean_finite_required(values)
if isempty(values) || any(~isfinite(values(:))), value = NaN;
else, value = mean(values(:)); end
end

function value = sum_required(values)
if isempty(values) || any(~isfinite(values(:))), value = NaN;
else, value = sum(values(:)); end
end

function value = maximum(values)
values = values(~isnan(values));
if isempty(values), value = NaN; else, value = max(values(:)); end
end

function value = minimum(values)
values = values(~isnan(values));
if isempty(values), value = NaN; else, value = min(values(:)); end
end
