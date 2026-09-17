function result = study1_trajectory(id,fit,estimator,controlNoise,cfg)
%STUDY1_TRAJECTORY Stationary Plant A; true states stay in the evaluator.
% Controller timing is delegated to the verified core. Diagnostics outside
% the controller timer never change the applied input or estimator state.
[model,~,~] = study1_model(id);
known = strcmp(id,'K');
K = cfg.K;
n = numel(fit.theta0);
result.id = id;
result.fit = fit;
result.time = (0:K)*cfg.Ts;
result.r = study1_reference(result.time);
result.x = nan(1,K+1); result.x(1) = 0;
result.y = nan(1,K+1);
result.u = nan(1,K+1); result.u(1) = 0;
result.theta = nan(n,K);
result.beta = nan(n,K);
result.prediction = nan(1,K);
result.covariance = nan(fit.nEstimated,fit.nEstimated,K);
result.gram = nan(fit.nEstimated,fit.nEstimated,K);
result.gramCount = zeros(1,K);
result.covarianceEigenvalues = nan(2,K);
result.gramEigenvalues = nan(2,K);
result.covarianceCondition = nan(1,K);
result.gramCondition = nan(1,K);
result.qpCondition = nan(1,K);
result.controlTime = nan(1,K);
result.idAttempted = false(1,K); result.idAccepted = false(1,K);
result.controlAccepted = false(1,K); result.mappingActivated = false(1,K);
result.lambda = nan(1,K);
result.solverResiduals = nan(4,K);
result.exitflag = nan(1,K);
result.slack = nan(2,cfg.N,K);
result.plannedInput = nan(cfg.N-1,K);
result.plannedOutput = nan(cfg.N,K);
result.A = nan(1,K); result.B = nan(1,K); result.c = nan(1,K);
result.events = struct('index',{},'stage',{},'message',{});
result.completed = false;
result.terminationReason = '';
result.nSteps = 0;
regressors = zeros(0,n);
if ~known
    controller = AdaptiveController(model,estimator,cfg.control,0,0);
end
for j = 1:K
    k = j-1;
    if ~isfinite(result.x(j)) || abs(result.x(j)) > 5
        result.terminationReason = 'True state is nonfinite or exceeds five state units.';
        result.events(end+1) = event(k,'termination',result.terminationReason);
        break
    end
    measurement = result.x(j)+controlNoise(j);
    result.y(j) = measurement;
    reference = study1_reference((k+(1:cfg.N))*cfg.Ts);
    committed = result.u(j);
    timer = tic;
    if known
        % Only this declared diagnostic reference receives true parameters.
        theta = fit.theta0;
        prediction = [];
        nextInput = committed;
        try
            [A,B,c,value] = freeze_predictor(model,measurement,committed,theta);
            prediction = struct('A',A,'B',B,'c',c,'value',value);
            qp = assemble_qp(A,B,c,1,measurement,committed,reference,cfg.control);
            control = solve_mpc(qp);
            nextInput = control.uNext;
        catch exception
            control = struct('accepted',false,'message',exception.message);
        end
    else
        [nextInput,info] = controller.step(measurement,reference);
        theta = info.parameters;
        prediction = info.prediction;
        control = info.control;
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
        assert(isequal(nextInput,committed),'study1:Fallback','Rejected control must hold its input.');
        result.events(end+1) = event(k,'control',control.message);
    end
    if isfield(control,'exitflag'), result.exitflag(j) = control.exitflag; end
    if isfield(control,'residuals')
        r = control.residuals;
        result.solverResiduals(:,j) = [r.primal;r.stationarity;r.dual;r.complementarity];
    end
    if control.accepted
        result.slack(:,:,j) = control.slack;
        result.plannedInput(:,j) = control.U(:);
        result.plannedOutput(:,j) = control.Y(:);
    end
    if ~isempty(prediction)
        result.A(j) = prediction.A; result.B(j) = prediction.B; result.c(j) = prediction.c;
        result.prediction(j) = prediction.value;
        % Reconstruct only for the Hessian diagnostic; never solve twice.
        try
            qp = assemble_qp(prediction.A,prediction.B,prediction.c,1, ...
                measurement,committed,reference,cfg.control);
            result.qpCondition(j) = cond(qp.H);
        catch exception
            result.events(end+1) = event(k,'diagnostic',exception.message);
        end
    end
    if ~isempty(theta), result.theta(:,j) = theta; end
    if ~known
        result.beta(:,j) = estimator.Beta;
        result.covariance(:,:,j) = estimator.Covariance;
        [result.covarianceEigenvalues(:,j),result.covarianceCondition(j)] = ...
            spectrum(estimator.Covariance);
        if j > 1
            [~,Phi] = model_regression(model,result.y(j-1),measurement,result.u(j-1));
            regressors = [regressors;Phi./fit.D.']; %#ok<AGROW>
            regressors = regressors(max(1,size(regressors,1)-49):end,:);
            % Control-record-only window, normalized by the available count.
            result.gramCount(j) = size(regressors,1);
            G = (regressors.'*regressors)/size(regressors,1);
            result.gram(:,:,j) = G;
            [result.gramEigenvalues(:,j),result.gramCondition(j)] = spectrum(G);
        end
    end
    % u(k), not the newly computed u(k+1), generates this transition.
    result.u(j+1) = nextInput;
    result.x(j+1) = study1_plant(result.x(j),committed);
    result.y(j+1) = result.x(j+1)+controlNoise(j+1);
    result.nSteps = j;
end
if result.nSteps == K && isfinite(result.x(K+1)) && abs(result.x(K+1)) <= 5
    result.completed = true;
elseif isempty(result.terminationReason)
    result.terminationReason = 'True state is nonfinite or exceeds five state units.';
    result.events(end+1) = event(result.nSteps,'termination',result.terminationReason);
end
end

function entry = event(index,stage,message)
entry = struct('index',index,'stage',stage,'message',message);
end

function [extreme,condition] = spectrum(matrix)
% Symmetrization is for eigenvalue diagnostics only, never estimator state.
eigenvalues = eig((matrix+matrix.')/2);
extreme = [min(eigenvalues);max(eigenvalues)];
condition = cond(matrix);
end
