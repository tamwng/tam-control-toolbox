function result = study2_trajectory(id,fit,amplitude,cfg)
%STUDY2_TRAJECTORY One deterministic Plant B run using the verified core.
% Identification receives only measured completed transitions. The evaluator
% applies committed u(k) to the plant, while the controller computes u(k+1).
% The fitted state is restarted identically for each reference amplitude.
[model,~,~,name] = study2_model(id);
known = strcmp(id,'K');
K = cfg.K; n = model.ntheta;
result = struct('id',char(id),'name',name,'nEstimated',fit.nEstimated, ...
    'kind',cfg.kind,'amplitude',amplitude,'Ts',cfg.Ts, ...
    'controlSettings',cfg.control,'time',(0:K)*cfg.Ts, ...
    'nSteps',0,'completed',false,'terminationReason','');
result.r = reference(result.time,amplitude,cfg);
result.x = nan(1,K+1); result.x(1) = cfg.initialState;
result.y = nan(1,K+1); result.u = nan(1,K+1); result.u(1) = cfg.initialInput;
result.initialTheta = fit.theta(:,end);
result.initialBeta = fit.beta(:,end);
result.initialCovariance = fit.covariance(:,:,end);
result.theta = nan(n,K); result.beta = nan(n,K);
result.covariance = nan(fit.nEstimated,fit.nEstimated,K);
result.gram = nan(fit.nEstimated,fit.nEstimated,K);
result.gramCount = zeros(1,K);
result.covarianceEigenvalues = nan(2,K); result.gramEigenvalues = nan(2,K);
result.covarianceCondition = nan(1,K); result.gramCondition = nan(1,K);
result.qpCondition = nan(1,K); result.controlTime = nan(1,K);
result.idAttempted = false(1,K); result.idAccepted = false(1,K);
result.controlAccepted = false(1,K); result.mappingActivated = false(1,K);
result.lambda = nan(1,K); result.prediction = nan(1,K);
result.solverResiduals = nan(4,K); result.exitflag = nan(1,K);
result.slack = nan(2,cfg.N,K); result.plannedInput = nan(cfg.N-1,K);
result.plannedOutput = nan(cfg.N,K);
result.A = nan(1,K); result.B = nan(1,K); result.c = nan(1,K);
result.events = struct('index',{},'stage',{},'message',{});
rows = zeros(0,n);
if ~known
    estimator = RlsEstimator(result.initialTheta,result.initialCovariance, ...
        1,fit.D,struct('mode','none'));
    controller = AdaptiveController(model,estimator,cfg.control, ...
        cfg.initialState,cfg.initialInput);
end
for j = 1:K
    k = j-1;
    if ~isfinite(result.x(j)) || abs(result.x(j)) > 5
        break
    end
    measurement = result.x(j); result.y(j) = measurement;
    preview = reference((k+(1:cfg.N))*cfg.Ts,amplitude,cfg);
    committed = result.u(j);
    timer = tic;
    if known
        theta = fit.theta0;
        prediction = []; nextInput = committed;
        try
            [A,B,c,value] = freeze_predictor(model,measurement,committed,theta);
            prediction = struct('A',A,'B',B,'c',c,'value',value);
            qp = assemble_qp(A,B,c,1,measurement,committed,preview,cfg.control);
            control = solve_mpc(qp);
            nextInput = control.uNext;
        catch exception
            control = struct('accepted',false,'message',exception.message);
        end
    else
        [nextInput,info] = controller.step(measurement,preview);
        theta = info.parameters; prediction = info.prediction; control = info.control;
        result.idAttempted(j) = info.identification.attempted;
        result.idAccepted(j) = info.identification.accepted;
        result.mappingActivated(j) = info.mappingActivated;
        if isfield(info.identification,'lambda')
            result.lambda(j) = info.identification.lambda;
        end
        if info.identification.attempted && ~info.identification.accepted
            result.events(end+1) = event(k,'identification',info.identification.message);
        end
    end
    result.controlTime(j) = toc(timer);
    result.controlAccepted(j) = control.accepted;
    if ~control.accepted
        assert(isequal(nextInput,committed),'study2:Fallback','Rejected control must hold its input.');
        result.events(end+1) = event(k,'control',control.message);
    end
    if isfield(control,'exitflag'), result.exitflag(j) = control.exitflag; end
    if isfield(control,'residuals')
        residual = control.residuals;
        result.solverResiduals(:,j) = [residual.primal;residual.stationarity; ...
            residual.dual;residual.complementarity];
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
        % This second assembly records conditioning, outside the control timer.
        % It neither solves the QP again nor changes the committed input.
        try
            qp = assemble_qp(prediction.A,prediction.B,prediction.c,1, ...
                measurement,committed,preview,cfg.control);
            result.qpCondition(j) = cond(qp.H);
        catch exception
            result.events(end+1) = event(k,'diagnostic',exception.message);
        end
    end
    if ~known
        result.beta(:,j) = estimator.Beta;
        result.covariance(:,:,j) = estimator.Covariance;
        [result.covarianceEigenvalues(:,j),result.covarianceCondition(j)] = ...
            spectrum(estimator.Covariance);
        if j > 1
            [~,Phi] = model_regression(model,result.y(j-1),measurement,result.u(j-1));
            rows = [rows;Phi./fit.D.']; %#ok<AGROW>
            rows = rows(max(1,size(rows,1)-49):end,:);
            result.gramCount(j) = size(rows,1);
            G = rows.'*rows/size(rows,1);
            result.gram(:,:,j) = G;
            [result.gramEigenvalues(:,j),result.gramCondition(j)] = spectrum(G);
        end
    end
    result.u(j+1) = nextInput;
    result.x(j+1) = study2_plant(result.x(j),committed);
    result.y(j+1) = result.x(j+1);
    result.nSteps = j;
end
result.completed = result.nSteps == K && isfinite(result.x(K+1)) && abs(result.x(K+1)) <= 5;
if ~result.completed
    result.terminationReason = 'True state is nonfinite or exceeds five state units.';
    result.events(end+1) = event(result.nSteps,'termination',result.terminationReason);
end
end

function values = reference(time,amplitude,cfg)
if isfinite(cfg.constantReference)
    values = cfg.constantReference*ones(size(time));
else
    values = study2_reference(time,amplitude);
end
end

function item = event(index,stage,message)
item = struct('index',index,'stage',stage,'message',message);
end

function [extreme,condition] = spectrum(matrix)
% Diagnostic symmetrization does not alter the estimator covariance.
values = eig((matrix+matrix.')/2);
extreme = [min(values);max(values)];
condition = cond(matrix);
end
