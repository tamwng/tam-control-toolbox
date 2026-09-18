function summary = study3_summarize(output,cfg)
%STUDY3_SUMMARIZE Gain-change pilot scores, failures, and paired comparisons.
% Windows follow Appendix A; input scores exclude the terminal unapplied u.
% Censored recovery stays separate from ordinary continuous-score summaries.
% Every pair among the five prescribed noisy cases is declared before data
% inspection. Bootstrap resamples retain complete trial pairs (2,000 draws).
folder = fullfile(output,'tables');
if ~isfolder(folder), mkdir(folder); end
metrics = struct([]); diagnostics = struct([]); parameters = struct([]);
recoveries = struct([]); events = struct([]);
for scenario = string(cfg.scenarios)
    for id = string(cfg.caseIds)
        trials = 0;
        if scenario == "abrupt" && ismember(id,string(cfg.noisyCases))
            trials = 0:cfg.noiseTrials;
        end
        for trial = trials
            file = sprintf('%s_%s_%03d.mat',scenario,id,trial);
            saved = load(fullfile(output,'runs',file),'result'); r = saved.result;
            assert(string(r.id) == id && string(r.scenario) == scenario && r.trial == trial, ...
                'study3:RunIdentity','Run metadata must match its prescribed filename.');
            base = run_base(r);
            [scored,components] = score_run(r,base);
            metrics = [metrics;scored]; %#ok<AGROW>
            parameters = [parameters;components]; %#ok<AGROW>
            diagnostics = [diagnostics;diagnose_run(r,base,cfg)]; %#ok<AGROW>
            recovery = study3_recovery(r);
            row = base;
            fields = fieldnames(recovery);
            for j = 1:numel(fields), row.(fields{j}) = recovery.(fields{j}); end
            recoveries = [recoveries;row]; %#ok<AGROW>
            for j = 1:numel(r.events)
                row = base; row.index = r.events(j).index;
                row.time = row.index*r.Ts;
                row.stage = string(r.events(j).stage);
                row.message = string(r.events(j).message);
                events = [events;row]; %#ok<AGROW>
            end
        end
    end
end
[initialization,fitDiagnostics,fitEvents] = initialization_scores(output,cfg);
events = [events;fitEvents];
summary.metrics = struct2table(metrics);
summary.diagnostics = struct2table(diagnostics);
summary.parameters = struct2table(parameters);
summary.recovery = struct2table(recoveries);
summary.initialization = initialization;
summary.fitDiagnostics = fitDiagnostics;
summary.initializationNoisy = initialization_noisy(initialization);
if isempty(events)
    summary.events = table('Size',[0,12],'VariableTypes', ...
        {'string','string','string','string','string','double','logical','double', ...
        'double','double','string','string'},'VariableNames', ...
        {'scenario','caseId','caseName','model','mode','trial','noise','coefficientCount', ...
        'index','time','stage','message'});
else
    summary.events = struct2table(events);
end
summary.counts = run_counts(summary.diagnostics);
summary.recoveryCounts = recovery_counts(summary.recovery);
[summary.noisy,summary.paired] = repeated_scores(summary.metrics,cfg);
names = {'metrics','diagnostics','parameters','recovery','events','counts', ...
    'recoveryCounts','noisy','paired','initialization','fitDiagnostics','initializationNoisy'};
files = {'run_metrics','run_diagnostics','parameter_components','recovery', ...
    'events','run_counts','recovery_counts','noisy_summaries','paired_contrasts', ...
    'initialization_scores','initialization_diagnostics','initialization_noisy_summaries'};
for j = 1:numel(names)
    writetable(summary.(names{j}),fullfile(folder,[files{j},'.csv']));
end
fprintf('Study 3 reporting: %d/%d runs completed, %d recorded events.\n', ...
    sum(summary.diagnostics.completed),height(summary.diagnostics),height(summary.events));
end

function [scores,diagnostics,events] = initialization_scores(output,cfg)
rows = struct([]); info = struct([]); events = struct([]);
for model = ["A","S"]
    trials = 0;
    if model == "S", trials = 0:cfg.noiseTrials; end
    for trial = trials
        saved = load(fullfile(output,'fits',sprintf('fit_%s_%03d.mat',model,trial)),'fit');
        fit = saved.fit;
        saved = load(fullfile(output,'evaluation',sprintf('evaluation_%s_%03d.mat',model,trial)),'forecasts');
        forecasts = saved.forecasts;
        diagnostic = struct('model',model,'trial',trial,'noise',trial > 0, ...
            'attemptedUpdates',nnz(fit.attempted),'acceptedUpdates',nnz(fit.accepted), ...
            'rejectedUpdates',nnz(fit.attempted & ~fit.accepted), ...
            'lambdaMin',minimum(fit.lambda(fit.attempted)), ...
            'lambdaMax',maximum(fit.lambda(fit.attempted)), ...
            'finalCovarianceCondition',cond(fit.covariance(:,:,end)), ...
            'invalidOneStepQueries',nnz(~isfinite(forecasts.oneStepErrors)), ...
            'invalidCommonForecastQueries',nnz(~forecasts.valid));
        info = [info;diagnostic]; %#ok<AGROW>
        for j = 1:numel(cfg.fitSteps)
            errors = forecasts.oneStepErrors(:,j);
            row = struct('model',model,'trial',trial,'noise',trial > 0, ...
                'fittingTransitions',cfg.fitSteps(j),'evaluationQueries',numel(errors), ...
                'finiteQueries',nnz(isfinite(errors)),'predictionRMS',rms_required(errors), ...
                'parameterScaledPercent',NaN);
            if model == "S"
                row.parameterScaledPercent = 100*norm(fit.checkpointTheta(:,j)-[.03;.65;.45])/sqrt(3);
            end
            rows = [rows;row]; %#ok<AGROW>
        end
        base = struct('scenario',"initialization",'caseId',"fit_"+model, ...
            'caseName',"Common "+model+" initialization fit",'model',model,'mode',"fit", ...
            'trial',trial,'noise',trial > 0,'coefficientCount',3);
        for k = find(fit.attempted & ~fit.accepted)
            row = base; row.index = k; row.time = k*cfg.Ts;
            row.stage = "initializationIdentification"; row.message = string(fit.message{k});
            events = [events;row]; %#ok<AGROW>
        end
        for k = 1:numel(forecasts.failures)
            f = forecasts.failures(k); row = base;
            row.index = f.anchor; row.time = NaN; row.stage = "initializationEvaluation";
            row.message = string(sprintf('fit=%d; mode=%s; %s',f.fitStep,f.mode,f.message));
            events = [events;row]; %#ok<AGROW>
        end
    end
end
scores = struct2table(rows); diagnostics = struct2table(info);
end

function tableOut = initialization_noisy(data)
rows = struct([]); data = data(data.noise,:);
groups = unique(data(:,{'model','fittingTransitions'}),'rows','stable');
for j = 1:height(groups)
    key = groups(j,:);
    block = data(data.model == key.model & data.fittingTransitions == key.fittingTransitions,:);
    for score = ["predictionRMS","parameterScaledPercent"]
        values = block.(score); row = table2struct(key); row.metric = score;
        row.attempted = height(block); row.finiteScores = nnz(isfinite(values));
        row.median = percentile(values,.5); row.q1 = percentile(values,.25); row.q3 = percentile(values,.75);
        row.iqr = row.q3-row.q1; rows = [rows;row]; %#ok<AGROW>
    end
end
tableOut = struct2table(rows);
end

function base = run_base(r)
count = 3;
if strcmp(r.modelId,'K'), count = 0; end
base = struct('scenario',string(r.scenario),'caseId',string(r.id), ...
    'caseName',string(r.name),'model',string(r.modelId),'mode',string(r.mode), ...
    'trial',r.trial,'noise',r.trial > 0,'coefficientCount',count);
end

function [rows,parameters] = score_run(r,base)
K = numel(r.time)-1; time = r.time(1:K);
windows = [0,K*r.Ts;30,40;50,60;90,100];
names = ["whole","pre","event","late"];
if strcmp(r.scenario,'drift'), windows(3,:) = [50,90]; names(3) = "changing"; end
rows = struct([]); parameters = struct([]);
for iw = 1:size(windows,1)
    row = base; row.window = names(iw);
    row.windowStart = windows(iw,1); row.windowEnd = windows(iw,2);
    row.completed = r.completed; row.status = "complete";
    if ~r.completed, row.status = "incompletePrefix"; end
    mask = time >= row.windowStart & time < row.windowEnd;
    row.expectedSamples = nnz(mask);
    selected = find(mask & (1:K) <= r.nSteps & isfinite(r.x(1:K)) & ...
        isfinite(r.r(1:K)) & isfinite(r.u(1:K)));
    row.scoredSamples = numel(selected);
    error = r.x(selected)-r.r(selected);
    row.trackingRMS = rms_required(error);
    row.peakTrackingError = maximum(abs(error));
    row.inputRMS = rms_required(r.u(selected));
    increments = selected(selected > 1);
    du = r.u(increments)-r.u(increments-1);
    row.meanAbsoluteIncrement = mean_required(abs(du));
    row.totalInputVariation = sum_required(abs(du));
    row.incrementSamples = numel(increments);
    p = r.prediction(selected);
    row.predictionExpected = numel(selected);
    row.predictionFinite = nnz(isfinite(p) & isfinite(r.x(selected+1)));
    row.predictionTrueRMS = rms_required(p-r.x(selected+1));
    row.predictionMeasuredRMS = rms_required(p-r.y(selected+1));
    row.stateMin = minimum(r.x(selected)); row.stateMax = maximum(r.x(selected));
    row.inputMin = minimum(r.u(selected)); row.inputMax = maximum(r.u(selected));
    row.outputViolationPeak = maximum(max(abs(r.x(selected))-r.controlSettings.hy(1),0));
    row.outputViolationCount = nnz(abs(r.x(selected)) > r.controlSettings.hy(1));
    row.inputViolationPeak = maximum(max(abs(r.u(selected))-r.controlSettings.hu(1),0));
    row.incrementViolationPeak = maximum(max(abs(du)-r.controlSettings.hdu(1),0));
    identified = selected(r.idAttempted(selected));
    row.identificationAttempted = numel(identified);
    row.identificationRejected = nnz(~r.idAccepted(identified));
    row.lambdaFinite = nnz(isfinite(r.lambda(identified)));
    row.lambdaMin = minimum(r.lambda(identified));
    row.lambdaMedian = percentile(r.lambda(identified),.5);
    row.lambdaMax = maximum(r.lambda(identified));
    row.lambdaBelowOne = nnz(r.lambda(identified) < 1);
    full = selected(r.gramCount(selected) == 50);
    valid = full(r.gramValid(full));
    row.gramFullWindows = numel(full); row.gramValidFullWindows = numel(valid);
    row.gramInvalidFullWindows = numel(full)-numel(valid);
    row.gramRankMin = minimum(r.gramRank(valid)); row.gramRankMax = maximum(r.gramRank(valid));
    row.gramDeficientWindows = nnz(r.gramRank(valid) < base.coefficientCount);
    row.gramDeficientFraction = NaN;
    if ~isempty(valid), row.gramDeficientFraction = row.gramDeficientWindows/numel(valid); end
    row.gramConditionMin = minimum(r.gramCondition(valid));
    row.gramConditionMax = maximum(r.gramCondition(valid));
    row.covarianceConditionMax = maximum(r.covarianceCondition(selected));
    row.controlRejected = nnz(~r.controlAccepted(selected));
    row.parameterScaledRMSPercent = NaN; row.parameterFinalScaledPercent = NaN;
    if strcmp(r.modelId,'S') && ~isempty(selected)
        target = [.03*ones(1,numel(selected));.65*ones(1,numel(selected));r.trueGain(selected)];
        delta = r.theta(:,selected)-target;
        scaled = 100*vecnorm(delta,2,1)/sqrt(3);
        row.parameterScaledRMSPercent = rms_required(scaled);
        row.parameterFinalScaledPercent = scaled(end);
        labels = ["offset","stateCoefficient","inputGain"];
        for j = 1:3
            item = base; item.window = names(iw); item.component = labels(j);
            item.completed = r.completed; item.scoredSamples = numel(selected);
            item.errorRMS = rms_required(delta(j,:)); item.meanError = mean_required(delta(j,:));
            item.lastSampleIndex = selected(end)-1;
            item.lastEstimate = r.theta(j,selected(end)); item.lastTarget = target(j,end);
            item.lastError = delta(j,end);
            parameters = [parameters;item]; %#ok<AGROW>
        end
    end
    rows = [rows;row]; %#ok<AGROW>
end
end

function row = diagnose_run(r,base,cfg)
row = base; n = r.nSteps; steps = 1:n;
c = cfg.control; xmax = c.hy(1); umax = c.hu(1); dumax = c.hdu(1);
row.completed = r.completed; row.attemptedSteps = n;
row.terminationReason = string(r.terminationReason);
row.identificationAttempted = nnz(r.idAttempted(steps));
row.identificationRejected = nnz(r.idAttempted(steps) & ~r.idAccepted(steps));
row.controlRejected = nnz(~r.controlAccepted(steps));
row.mappingActivations = nnz(r.mappingActivated(steps));
row.lambdaMin = minimum(r.lambda(steps)); row.lambdaMax = maximum(r.lambda(steps));
row.lambdaBelowOne = nnz(r.lambda(steps) < 1);
row.residualRMS = rms_required(r.residual(steps(r.idAttempted(steps))));
row.residualEnergyMax = maximum(r.energy(steps));
row.residualWindowCountMax = maximum(r.residualWindowCount(steps));
row.covarianceEigenMin = minimum(r.covarianceEigenvalues(1,steps));
row.covarianceEigenMax = maximum(r.covarianceEigenvalues(2,steps));
row.covarianceConditionMax = maximum(r.covarianceCondition(steps));
full = steps(r.gramCount(steps) == 50);
valid = full(r.gramValid(full));
row.gramFullWindows = numel(full); row.gramValidFullWindows = numel(valid);
row.gramInvalidFullWindows = numel(full)-numel(valid);
row.gramRankMin = minimum(r.gramRank(valid)); row.gramRankMax = maximum(r.gramRank(valid));
row.gramDeficientWindows = nnz(r.gramRank(valid) < base.coefficientCount);
row.gramDeficientFraction = NaN;
if ~isempty(valid), row.gramDeficientFraction = row.gramDeficientWindows/numel(valid); end
row.gramConditionMin = minimum(r.gramCondition(valid));
row.gramConditionMax = maximum(r.gramCondition(valid)); % Retain Inf.
row.gramEigenMin = minimum(r.gramEigenvalues(1,valid));
row.gramEigenMax = maximum(r.gramEigenvalues(2,valid));
row.qpConditionMedian = percentile(r.qpCondition(steps),.5);
row.qpConditionMax = maximum(r.qpCondition(steps));
row.qpConditionNonfinite = nnz(~isfinite(r.qpCondition(steps)));
row.primalResidualMax = maximum(r.solverResiduals(1,steps));
row.stationarityResidualMax = maximum(r.solverResiduals(2,steps));
row.dualResidualMax = maximum(r.solverResiduals(3,steps));
row.complementarityResidualMax = maximum(r.solverResiduals(4,steps));
row.controlTimeMedianSeconds = percentile(r.controlTime(steps),.5);
row.controlTimeMaxSeconds = maximum(r.controlTime(steps));
row.predictedSlackMax = maximum(r.slack(:,:,steps));
row.predictedFirstStepSlackMax = maximum(r.slack(:,1,steps));
row.activityTolerance = 1e-6;
row.predictedSlackActiveSteps = nnz(reshape(any(any(r.slack(:,:,steps) > 1e-6,1),2),1,[]));
states = r.x(1:n+1); inputs = r.u(1:n); du = diff(inputs);
row.stateSamples = numel(states); row.finiteStateSamples = nnz(isfinite(states));
row.appliedInputSamples = numel(inputs); row.finiteAppliedInputSamples = nnz(isfinite(inputs));
row.stateMin = minimum(states); row.stateMax = maximum(states);
row.appliedInputMin = minimum(inputs); row.appliedInputMax = maximum(inputs);
row.initialOutputViolation = max(abs(states(1))-xmax,0);
row.futureOutputViolationPeak = maximum(max(abs(states(2:end))-xmax,0));
row.futureOutputViolationCount = nnz(abs(states(2:end)) > xmax);
row.allOutputViolationPeak = maximum(max(abs(states)-xmax,0));
row.allOutputViolationCount = nnz(abs(states) > xmax);
row.allInputViolationPeak = maximum(max(abs(inputs)-umax,0));
row.allInputViolationCount = nnz(abs(inputs) > umax);
row.allIncrementViolationPeak = maximum(max(abs(du)-dumax,0));
row.allIncrementViolationCount = nnz(abs(du) > dumax);
row.inputViolationCountOverTolerance = nnz(abs(inputs) > umax+1e-6);
row.incrementViolationCountOverTolerance = nnz(abs(du) > dumax+1e-6);
row.outputBoundActiveSamples = nnz(abs(states) >= xmax-1e-6);
row.inputBoundActiveSamples = nnz(abs(inputs) >= umax-1e-6);
row.incrementBoundActiveSamples = nnz(abs(du) >= dumax-1e-6);
row.terminalState = states(end); row.terminalCommittedInput = r.u(n+1);
row.terminalCommittedInputViolation = max(abs(r.u(n+1))-umax,0);
row.terminalCommittedIncrementViolation = NaN;
if n > 0, row.terminalCommittedIncrementViolation = max(abs(r.u(n+1)-r.u(n))-dumax,0); end
end

function tableOut = run_counts(data)
rows = struct([]); groups = unique(data(:,{'scenario','caseId','caseName','noise'}),'rows','stable');
for j = 1:height(groups)
    key = groups(j,:);
    block = data(data.scenario == key.scenario & data.caseId == key.caseId & data.noise == key.noise,:);
    row = table2struct(key); row.attempted = height(block); row.completed = nnz(block.completed);
    row.incomplete = nnz(~block.completed);
    row.identificationRejected = sum(block.identificationRejected);
    row.controlRejected = sum(block.controlRejected);
    row.runsWithIdentificationRejections = nnz(block.identificationRejected > 0);
    row.runsWithControlRejections = nnz(block.controlRejected > 0);
    row.mappingActivations = sum(block.mappingActivations);
    rows = [rows;row]; %#ok<AGROW>
end
tableOut = struct2table(rows);
end

function tableOut = recovery_counts(data)
rows = struct([]);
groups = unique(data(:,{'scenario','caseId','caseName','noise'}),'rows','stable');
for j = 1:height(groups)
    key = groups(j,:);
    block = data(data.scenario == key.scenario & data.caseId == key.caseId & data.noise == key.noise,:);
    row = table2struct(key); row.attempted = height(block); row.applicable = nnz(block.applicable);
    row.recovered = nnz(block.recovered); row.rightCensored = nnz(block.rightCensored);
    row.terminatedBeforeCensor = nnz(block.status == "terminatedBeforeCensor");
    row.anyTerminationBeforeCensor = nnz(block.terminationBeforeCensor);
    row.notApplicable = nnz(~block.applicable);
    rows = [rows;row]; %#ok<AGROW>
end
tableOut = struct2table(rows);
end

function [summaries,contrasts] = repeated_scores(data,cfg)
data = data(data.noise & data.scenario == "abrupt",:);
scores = {'trackingRMS','inputRMS','meanAbsoluteIncrement','peakTrackingError', ...
    'totalInputVariation','predictionTrueRMS','predictionMeasuredRMS', ...
    'parameterScaledRMSPercent','parameterFinalScaledPercent'};
ids = string(cfg.noisyCases); pairs = nchoosek(1:numel(ids),2);
stream = RandStream('mt19937ar','Seed',cfg.bootstrapSeed);
rows = struct([]); paired = struct([]);
for window = ["whole","pre","event","late"]
    for id = ids
        block = data(data.caseId == id & data.window == window,:);
        for is = 1:numel(scores)
            score = scores{is}; values = block.(score)(block.completed);
            row = struct('scenario',"abrupt",'caseId',id,'window',window,'metric',string(score), ...
                'attempted',height(block),'completed',nnz(block.completed), ...
                'finiteScores',nnz(isfinite(values)), ...
                'median',percentile(values,.5),'q1',percentile(values,.25),'q3',percentile(values,.75));
            row.iqr = row.q3-row.q1; rows = [rows;row]; %#ok<AGROW>
        end
    end
    for ip = 1:size(pairs,1)
        first = ids(pairs(ip,1)); second = ids(pairs(ip,2));
        left = data(data.caseId == first & data.window == window,:);
        right = data(data.caseId == second & data.window == window,:);
        [~,il,ir] = intersect(left.trial,right.trial);
        complete = left.completed(il) & right.completed(ir);
        for is = 1:numel(scores)
            score = scores{is};
            values = left.(score)(il(complete))-right.(score)(ir(complete));
            valid = isfinite(values); center = NaN; low = NaN; high = NaN;
            if ~isempty(values) && all(valid)
                center = percentile(values,.5);
                draws = randi(stream,numel(values),numel(values),cfg.bootstrapCount);
                boot = median(values(draws),1);
                low = percentile(boot,.025); high = percentile(boot,.975);
            end
            row = struct('scenario',"abrupt",'window',window,'firstCase',first, ...
                'secondCase',second,'contrast',first+" - "+second,'metric',string(score), ...
                'attemptedPairs',numel(il),'completePairs',nnz(complete), ...
                'finitePairs',nnz(valid),'medianDifference',center,'lower95',low,'upper95',high, ...
                'bootstrapResamples',cfg.bootstrapCount);
            paired = [paired;row]; %#ok<AGROW>
        end
    end
end
summaries = struct2table(rows); contrasts = struct2table(paired);
end

function value = percentile(values,p)
values = values(:); value = NaN;
if isempty(values) || any(~isfinite(values)), return; end
values = sort(values); position = 1+(numel(values)-1)*p;
lower = floor(position); upper = ceil(position);
value = values(lower)+(position-lower)*(values(upper)-values(lower));
end
function value = rms_required(values)
value = sqrt(mean_required(values.^2));
end
function value = mean_required(values)
value = NaN;
if ~isempty(values) && all(isfinite(values(:))), value = mean(values(:)); end
end
function value = sum_required(values)
value = NaN;
if ~isempty(values) && all(isfinite(values(:))), value = sum(values(:)); end
end
function value = maximum(values)
values = values(~isnan(values)); value = NaN;
if ~isempty(values), value = max(values(:)); end
end
function value = minimum(values)
values = values(~isnan(values)); value = NaN;
if ~isempty(values), value = min(values(:)); end
end
