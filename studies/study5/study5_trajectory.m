function result = study5_trajectory(id,fit,cfg)
%STUDY5_TRAJECTORY Established logging/timing around the verified controller.
% The controller consumes endpoints and preview only. True parameters belong
% to the plant driver (and K); no intersample integral reaches identification.
[model,~,labels,name] = study5_model(id,cfg);
plant = physical_model(cfg.Ts,cfg.plantSubsteps);
known = strcmp(id,'K'); K = cfg.K; n = model.ntheta;
result = struct('id',char(id),'name',name,'labels',{labels},'Ts',cfg.Ts, ...
    'controlSettings',cfg.control,'forgetting',cfg.forgetting,'time',(0:K)*cfg.Ts, ...
    'nSteps',0,'completed',false,'terminationReason','','nEstimated',fit.nEstimated, ...
    'D',fit.D,'rowScale',fit.rowScale,'units',cfg.units);
result.residualUnits = fit.residualUnits;
result.r = study5_reference(result.time);
result.x = nan(1,K+1); result.x(1) = 0;
result.y = nan(1,K+1); result.y(1) = 0;
result.u = nan(1,K+1); result.u(1) = 0;
result.initialTheta = fit.theta(:,end); result.initialCovariance = fit.covariance(:,:,end);
result.initialBeta = fit.beta(:,end);
result.theta = nan(n,K); result.mappedTheta = nan(n,K); result.beta = nan(n,K);
result.covariance = nan(fit.nEstimated,fit.nEstimated,K);
result.gram = nan(fit.nEstimated,fit.nEstimated,K);
result.gramCount = zeros(1,K); result.gramRank = nan(1,K);
result.gramCondition = nan(1,K); result.gramValid = false(1,K);
result.covarianceEigenvalues = nan(2,K); result.gramEigenvalues = nan(2,K);
result.covarianceCondition = nan(1,K); result.qpCondition = nan(1,K);
result.controlTime = nan(1,K);
result.idAttempted = false(1,K); result.idAccepted = false(1,K);
result.idResponse = nan(1,K); result.idRegressor = nan(1,n,K);
result.controlAccepted = false(1,K); result.mappingActivated = false(1,K);
result.lambda = nan(1,K); result.residual = nan(1,K); result.prediction = nan(1,K);
result.residualWindowCount = zeros(1,K);
result.solverResiduals = nan(4,K); result.exitflag = nan(1,K);
result.slack = nan(2,cfg.N,K); result.plannedInput = nan(cfg.N-1,K);
result.plannedOutput = nan(cfg.N,K);
result.A = nan(1,K); result.B = nan(1,K); result.c = nan(1,K);
result.events = struct('index',{},'stage',{},'message',{});
rows = zeros(0,n);
if ~known
    estimator = RlsEstimator(result.initialTheta,result.initialCovariance, ...
        fit.rowScale,fit.D,cfg.forgetting,@(raw) study5_map(id,raw));
    controller = AdaptiveController(model,estimator,cfg.control,0,0);
end
for j = 1:K
    k = j-1;
    if ~isfinite(result.x(j)) || abs(result.x(j)) > 5, break; end
    measurement = result.y(j); committed = result.u(j);
    preview = study5_reference((k+(1:cfg.N))*cfg.Ts);
    timer = tic;
    if known
        theta = fit.theta0; mapped = theta;
        [nextInput,prediction,control] = study3_fixed_step(model,mapped,measurement,committed,preview,cfg.control);
    else
        [nextInput,info] = controller.step(measurement,preview);
        theta = info.rawParameters; mapped = info.parameters;
        prediction = info.prediction; control = info.control;
        result.idAttempted(j) = info.identification.attempted;
        result.idAccepted(j) = info.identification.accepted;
        result.mappingActivated(j) = info.mappingActivated;
        if isfield(info.identification,'lambda'), result.lambda(j) = info.identification.lambda; end
        if isfield(info.identification,'residual') && ~isempty(info.identification.residual)
            result.residual(j) = info.identification.residual;
        end
        result.residualWindowCount(j) = numel(estimator.ResidualSquares);
        if info.identification.attempted && ~info.identification.accepted
            result.events(end+1) = event(k,'identification',info.identification.message);
        end
    end
    result.controlTime(j) = toc(timer);
    result.controlAccepted(j) = control.accepted;
    if ~control.accepted
        assert(isequal(nextInput,committed),'study5:Fallback','Rejected control must hold its input.');
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
    if ~isempty(mapped), result.mappedTheta(:,j) = mapped; end
    if ~isempty(prediction)
        result.A(j) = prediction.A; result.B(j) = prediction.B; result.c(j) = prediction.c;
        result.prediction(j) = prediction.value;
        try
            qp = assemble_qp(prediction.A,prediction.B,prediction.c,1,measurement,committed,preview,cfg.control);
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
            [response,Phi] = model_regression(model,result.y(j-1),measurement,result.u(j-1));
            result.idResponse(j) = response; result.idRegressor(:,:,j) = Phi;
            rows = [rows;(fit.rowScale*Phi)./fit.D.']; %#ok<AGROW>
            rows = rows(max(1,size(rows,1)-cfg.gramWindow+1):end,:);
            result.gramCount(j) = size(rows,1);
            G = rows.'*rows/size(rows,1); result.gram(:,:,j) = G;
            result.gramEigenvalues(:,j) = extremes(G);
            [result.gramRank(j),result.gramCondition(j),result.gramValid(j)] = study2_gram_diagnostic(G);
        end
    else
        result.beta(:,j) = fit.D.*theta;
    end
    result.u(j+1) = nextInput;
    result.x(j+1) = forward_map(plant,result.x(j),committed,cfg.trueParameters);
    result.y(j+1) = result.x(j+1);
    result.nSteps = j;
end
result.mappingDelta = result.mappedTheta-result.theta;
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
values = eig((matrix+matrix.')/2); value = [min(values);max(values)];
end
