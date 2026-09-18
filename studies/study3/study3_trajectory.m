function result = study3_trajectory(caseId,fit,scenario,trial,noise,cfg)
%STUDY3_TRAJECTORY Plant A parameter variation using the verified v2 core.
% The controller receives a measurement and the reference preview only.
% Plant gain and disturbances belong to the evaluator. At k=500 the abrupt
% gain first changes x(501); its transition is first identified at k=501.
spec = study3_case(caseId);
model = study1_model(spec.modelId);
adaptive = strcmp(spec.mode,'adaptive');
known = strcmp(spec.mode,'known');
K = cfg.K; n = model.ntheta;
assert(isequal(size(noise.measurement),[1 K+1]) && ...
    isequal(size(noise.process),[1 K]),'study3:NoiseShape','Noise must cover the declared record.');
result = struct('id',char(caseId),'name',spec.name,'modelId',spec.modelId, ...
    'mode',spec.mode,'forgetting',spec.forgetting,'scenario',scenario, ...
    'trial',trial,'Ts',cfg.Ts,'controlSettings',cfg.control,'D',fit.D, ...
    'time',(0:K)*cfg.Ts,'nSteps',0,'completed',false,'terminationReason','');
result.nEstimated = n*double(~known);
result.trueGain = study3_gain(0:K-1,scenario,cfg.Ts);
result.measurementNoise = noise.measurement; result.processNoise = noise.process;
result.r = study1_reference(result.time);
result.x = nan(1,K+1); result.x(1) = 0;
result.y = nan(1,K+1); result.y(1) = noise.measurement(1);
result.u = nan(1,K+1); result.u(1) = 0;
result.initialTheta = fit.theta(:,end);
result.initialCovariance = fit.covariance(:,:,end);
if strcmp(spec.mode,'prior')
    result.initialTheta = fit.theta0;
    result.initialCovariance = fit.P0;
elseif known
    result.initialTheta = [.03;.65;.45];
    result.initialCovariance = zeros(0);
end
result.initialBeta = fit.D.*result.initialTheta;
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
if adaptive
    estimator = RlsEstimator(result.initialTheta,result.initialCovariance,1,fit.D,spec.forgetting);
    controller = AdaptiveController(model,estimator,cfg.control,0,0);
end
for j = 1:K
    k = j-1;
    if ~isfinite(result.x(j)) || abs(result.x(j)) > 5, break; end
    measurement = result.y(j);
    preview = study1_reference((k+(1:cfg.N))*cfg.Ts);
    committed = result.u(j);
    timer = tic;
    if adaptive
        [nextInput,info] = controller.step(measurement,preview);
        theta = info.parameters; prediction = info.prediction; control = info.control;
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
    else
        theta = result.initialTheta;
        if known, theta = [.03;.65;result.trueGain(j)]; end
        [nextInput,prediction,control] = study3_fixed_step( ...
            model,theta,measurement,committed,preview,cfg.control);
    end
    result.controlTime(j) = toc(timer);
    result.controlAccepted(j) = control.accepted;
    if ~control.accepted
        assert(isequal(nextInput,committed),'study3:Fallback','Rejected control must hold its input.');
        result.events(end+1) = event(k,'control',control.message);
    end
    if isfield(control,'exitflag'), result.exitflag(j) = control.exitflag; end
    if isfield(control,'residuals')
        res = control.residuals;
        result.solverResiduals(:,j) = [res.primal;res.stationarity;res.dual;res.complementarity];
    end
    if control.accepted
        result.slack(:,:,j) = control.slack;
        result.plannedInput(:,j) = control.U(:);
        result.plannedOutput(:,j) = control.Y(:);
    end
    if ~isempty(theta), result.theta(:,j) = theta; end
    if ~isempty(prediction)
        result.A(j) = prediction.A; result.B(j) = prediction.B; result.c(j) = prediction.c;
        result.prediction(j) = prediction.value;
        % Diagnostic assembly is outside the control timer and never solves.
        try
            qp = assemble_qp(prediction.A,prediction.B,prediction.c,1, ...
                measurement,committed,preview,cfg.control);
            result.qpCondition(j) = cond(qp.H);
        catch exception
            result.events(end+1) = event(k,'diagnostic',exception.message);
        end
    end
    if ~known
        P = result.initialCovariance; beta = result.initialBeta;
        if adaptive, P = estimator.Covariance; beta = estimator.Beta; end
        result.beta(:,j) = beta; result.covariance(:,:,j) = P;
        result.covarianceEigenvalues(:,j) = extreme_eigenvalues(P);
        result.covarianceCondition(j) = cond(P);
        if j > 1
            [~,Phi] = model_regression(model,result.y(j-1),measurement,result.u(j-1));
            rows = [rows;Phi./fit.D.']; %#ok<AGROW>
            rows = rows(max(1,size(rows,1)-49):end,:);
            result.gramCount(j) = size(rows,1);
            G = rows.'*rows/size(rows,1);
            result.gram(:,:,j) = G;
            result.gramEigenvalues(:,j) = extreme_eigenvalues(G);
            [result.gramRank(j),result.gramCondition(j),result.gramValid(j)] = study2_gram_diagnostic(G);
        end
    else
        result.beta(:,j) = result.D.*theta;
    end
    result.u(j+1) = nextInput;
    result.x(j+1) = study3_plant(result.x(j),committed,result.trueGain(j),noise.process(j));
    result.y(j+1) = result.x(j+1)+noise.measurement(j+1);
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

function extreme = extreme_eigenvalues(matrix)
% Symmetrization is diagnostic only and never changes the stored covariance.
if any(~isfinite(matrix),'all'), extreme = [NaN;NaN]; return; end
values = eig((matrix+matrix.')/2);
extreme = [min(values);max(values)];
end
