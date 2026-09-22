function result = study4_trajectory(id,fit,scenario,cfg)
%STUDY4_TRAJECTORY Committed-input loop using the fixed verified core.
% Only measurement and reference preview enter AdaptiveController.step.
% No event branch, reset, regressor insertion, or evaluator query enters it.
[model,theta0,labels,name] = study4_model(id);
known = strcmp(id,'K'); K = cfg.K; n = model.ntheta;
result = struct('id',char(id),'name',name,'scenario',char(scenario), ...
    'scenarioName',cfg.scenarioNames{strcmp(cfg.scenarios,scenario)}, ...
    'labels',{labels},'Ts',cfg.Ts,'controlSettings',cfg.control, ...
    'forgetting',cfg.forgetting,'time',(0:K)*cfg.Ts,'nSteps',0, ...
    'completed',false,'terminationReason','','nEstimated',n*double(~known));
result.r = study1_reference(result.time);
result.x = nan(1,K+1); result.x(1) = 0;
result.y = nan(1,K+1); result.y(1) = 0;
result.u = nan(1,K+1); result.u(1) = 0;
[result.trueH,result.trueRho] = study4_schedule(0:K-1,scenario,cfg);
result.D = ones(n,1); result.initialTheta = theta0; result.initialCovariance = zeros(0);
if ~known
    result.D = fit.D; result.initialTheta = fit.theta(:,end);
    result.initialCovariance = fit.covariance(:,:,end);
end
result.initialBeta = result.D.*result.initialTheta;
result.theta = nan(n,K); result.beta = nan(n,K);
result.covariance = nan(result.nEstimated,result.nEstimated,K);
result.gram = nan(result.nEstimated,result.nEstimated,K);
result.gramCount = zeros(1,K); result.gramRank = nan(1,K);
result.gramCondition = nan(1,K); result.gramValid = false(1,K);
result.covarianceEigenvalues = nan(2,K); result.gramEigenvalues = nan(2,K);
result.covarianceCondition = nan(1,K); result.qpCondition = nan(1,K);
result.controlTime = nan(1,K);
result.idAttempted = false(1,K); result.idAccepted = false(1,K);
result.controlAccepted = false(1,K); result.mappingActivated = false(1,K);
result.lambda = nan(1,K); result.residual = nan(1,K); result.energy = nan(1,K);
result.residualWindowCount = zeros(1,K); result.prediction = nan(1,K);
result.solverResiduals = nan(4,K); result.exitflag = nan(1,K);
result.slack = nan(2,cfg.N,K); result.plannedInput = nan(cfg.N-1,K);
result.plannedOutput = nan(cfg.N,K);
result.A = nan(1,K); result.B = nan(1,K); result.c = nan(1,K);
result.events = struct('index',{},'stage',{},'message',{});
rows = zeros(0,n);
if ~known
    estimator = RlsEstimator(result.initialTheta,result.initialCovariance,1,result.D,cfg.forgetting);
    controller = AdaptiveController(model,estimator,cfg.control,0,0);
end
for j = 1:K
    k = j-1;
    if ~isfinite(result.x(j)) || abs(result.x(j)) > 5, break; end
    measurement = result.y(j); committed = result.u(j);
    preview = study1_reference((k+(1:cfg.N))*cfg.Ts);
    timer = tic;
    if known
        % Current parameters only; the shared fixed-step function cannot see
        % the schedule or time index, and freezes this map over the horizon.
        theta = [0;.65;.45;result.trueH(j);result.trueRho(j)];
        [nextInput,prediction,control] = study3_fixed_step( ...
            model,theta,measurement,committed,preview,cfg.control);
    else
        [nextInput,info] = controller.step(measurement,preview);
        theta = info.rawParameters; prediction = info.prediction; control = info.control;
        result.idAttempted(j) = info.identification.attempted;
        result.idAccepted(j) = info.identification.accepted;
        result.mappingActivated(j) = info.mappingActivated;
        if isfield(info.identification,'lambda'), result.lambda(j) = info.identification.lambda; end
        if isfield(info.identification,'residual') && ~isempty(info.identification.residual)
            result.residual(j) = info.identification.residual;
        end
        if isfield(info.identification,'energy'), result.energy(j) = info.identification.energy; end
        result.residualWindowCount(j) = numel(estimator.ResidualSquares);
        if info.identification.attempted && ~info.identification.accepted
            result.events(end+1) = event(k,'identification',info.identification.message);
        end
    end
    result.controlTime(j) = toc(timer);
    result.controlAccepted(j) = control.accepted;
    if ~control.accepted
        assert(isequal(nextInput,committed),'study4:Fallback','Rejected control must hold its input.');
        result.events(end+1) = event(k,'control',control.message);
    end
    if isfield(control,'exitflag'), result.exitflag(j) = control.exitflag; end
    if isfield(control,'residuals')
        res = control.residuals;
        result.solverResiduals(:,j) = [res.primal;res.stationarity;res.dual;res.complementarity];
    end
    if control.accepted
        result.slack(:,:,j) = control.slack;
        result.plannedInput(:,j) = control.U(:); result.plannedOutput(:,j) = control.Y(:);
    end
    result.theta(:,j) = theta;
    if ~isempty(prediction)
        result.A(j) = prediction.A; result.B(j) = prediction.B; result.c(j) = prediction.c;
        result.prediction(j) = prediction.value;
        try
            qp = assemble_qp(prediction.A,prediction.B,prediction.c,1, ...
                measurement,committed,preview,cfg.control);
            result.qpCondition(j) = cond(qp.H);
        catch exception
            result.events(end+1) = event(k,'diagnostic',exception.message);
        end
    end
    if ~known
        P = estimator.Covariance;
        result.beta(:,j) = estimator.Beta; result.covariance(:,:,j) = P;
        result.covarianceEigenvalues(:,j) = extremes(P); result.covarianceCondition(j) = cond(P);
        if j > 1
            [~,Phi] = model_regression(model,result.y(j-1),measurement,result.u(j-1));
            rows = [rows;Phi./result.D.']; %#ok<AGROW>
            rows = rows(max(1,size(rows,1)-cfg.gramWindow+1):end,:);
            result.gramCount(j) = size(rows,1);
            G = rows.'*rows/size(rows,1); result.gram(:,:,j) = G;
            result.gramEigenvalues(:,j) = extremes(G);
            [result.gramRank(j),result.gramCondition(j),result.gramValid(j)] = study2_gram_diagnostic(G);
        end
    else
        result.beta(:,j) = theta;
    end
    result.u(j+1) = nextInput;
    result.x(j+1) = study4_plant(result.x(j),committed,result.trueH(j),result.trueRho(j));
    result.y(j+1) = result.x(j+1);
    result.nSteps = j;
end
result.completed = result.nSteps == K && isfinite(result.x(K+1)) && abs(result.x(K+1)) <= 5;
if ~result.completed
    result.terminationReason = 'True state is nonfinite or exceeds five state units.';
    result.events(end+1) = event(result.nSteps,'termination',result.terminationReason);
end
end
function item = event(index,stage,message)
item = struct('index',index,'stage',stage,'message',message);
end
function value = extremes(matrix)
% Diagnostic symmetrization never replaces the estimator covariance.
values = eig((matrix+matrix.')/2); value = [min(values);max(values)];
end
