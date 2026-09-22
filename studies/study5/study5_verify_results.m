function study5_verify_results(output,cfg)
%STUDY5_VERIFY_RESULTS Audit the saved pilot without rerunning controllers.
saved = load(fullfile(output,'records.mat'),'records'); records = saved.records;
saved = load(fullfile(output,'evaluation','common_queries.mat'),'queries'); q = saved.queries;
assert(isequal(q.anchors,20:20:580) && isequal(q.horizons,[1 2 5 10 20]));
assert(isequal(q.initialStates,records.evaluation.x(q.anchors+1)));
for a = 1:numel(q.anchors)
    index = q.anchors(a)+1;
    assert(isequal(q.inputs(a,:,1),repmat(records.evaluation.u(index),1,20)));
    assert(isequal(q.inputs(a,:,2),records.evaluation.u(index:index+19)));
end
for id = string(cfg.modelIds)
    saved = load(fullfile(output,'fits',sprintf('fit_%s.mat',id)),'fit'); fit = saved.fit;
    saved = load(fullfile(output,'runs',sprintf('%s.mat',id)),'result'); r = saved.result;
    saved = load(fullfile(output,'evaluation',sprintf('%s.mat',id)),'forecasts'); f = saved.forecasts;
    model = study5_model(id,cfg); n = r.nSteps;
    assert(isequal(r.initialTheta,fit.theta(:,end)) && isequal(r.initialCovariance,fit.covariance(:,:,end)));
    assert(r.x(1) == 0 && r.u(1) == 0 && ~r.idAttempted(1) && r.residualWindowCount(1) == 0);
    near(r.theta(:,1),fit.theta(:,end));
    near(r.mappedTheta(:,1:n),study5_map(id,r.theta(:,1:n)));
    assert(isequal(r.mappingActivated(1:n),any(r.mappingDelta(:,1:n) ~= 0,1)));
    assert(isequal(f.frozenTheta,fit.checkpointMappedTheta(:,end)));
    near(f.oneStepErrors,f.oneStepPrediction-records.evaluation.x(2:end).');
    for h = 1:numel(cfg.horizons)
        near(f.modelError(:,h,:),f.states(:,cfg.horizons(h)+1,:)-q.truth(:,cfg.horizons(h)+1,:));
    end
    if id == "K"
        assert(~any(r.idAttempted) && fit.nEstimated == 0);
        near(f.states,q.knownPrediction);
    else
        assert(all(fit.lambda(fit.attempted) == 1) && all(r.lambda(r.idAttempted) == 1));
        near(r.covariance(:,:,1),fit.covariance(:,:,end));
        X = zeros(200,model.ntheta); b = zeros(200,1);
        for j = 1:200
            [b(j),X(j,:)] = endpoint_row(id,records.initialization.y(j), ...
                records.initialization.y(j+1),records.initialization.u(j),cfg.Ts);
        end
        X = fit.rowScale*X./fit.D.'; b = fit.rowScale*b;
        for j = cfg.fitSteps
            accepted = find(fit.accepted(1:j));
            batch_check(X(accepted,:),b(accepted),fit.D.*fit.theta0,fit.P0, ...
                fit.beta(:,j+1),fit.covariance(:,:,j+1));
        end
        X = zeros(n-1,model.ntheta); b = zeros(n-1,1);
        for j = 2:n
            [b(j-1),X(j-1,:)] = endpoint_row(id,r.y(j-1),r.y(j),r.u(j-1),cfg.Ts);
            near(r.idResponse(j),b(j-1)); near(r.idRegressor(:,:,j),X(j-1,:));
        end
        X = r.rowScale*X./r.D.'; b = r.rowScale*b;
        for j = unique([2,min(201,n),n])
            accepted = find(r.idAccepted(2:j));
            batch_check(X(accepted,:),b(accepted),r.initialBeta,r.initialCovariance, ...
                r.beta(:,j),r.covariance(:,:,j));
        end
        for j = 2:n
            window = X(max(1,j-cfg.gramWindow):j-1,:);
            G = window.'*window/size(window,1); near(r.gram(:,:,j),G);
            [rank,condition,valid] = study2_gram_diagnostic(G);
            assert(r.gramRank(j) == rank && r.gramValid(j) == valid);
            if rank < model.ntheta, assert(isinf(r.gramCondition(j)));
            else, near(r.gramCondition(j),condition); end
        end
    end
    for j = 1:n
        if isfinite(r.prediction(j))
            [value,A,B] = forward_map(model,r.y(j),r.u(j),r.mappedTheta(:,j));
            near([r.prediction(j),r.A(j),r.B(j),r.c(j)], ...
                [value,A,B,value-A*r.y(j)-B*r.u(j)]);
        end
        if r.controlAccepted(j)
            near(r.u(j+1),r.plannedInput(1,j));
            near(r.plannedOutput(1,j),r.prediction(j));
        else, assert(r.u(j+1) == r.u(j)); end
    end
    scores = study5_metrics(r,cfg);
    for w = 1:2
        indices = find(r.time(1:n) >= cfg.windows(w,1) & r.time(1:n) < cfg.windows(w,2));
        near(scores.trackingRMS(w),sqrt(mean((r.x(indices)-r.r(indices)).^2)));
        assert(scores.scoredSamples(w) == numel(indices));
    end
end
saved = load(fullfile(output,'evaluation','numerical_audit.mat'),'audit'); a = saved.audit;
assert(a.stateChecksPassed && all(isfinite(a.refinedIntegral),'all'));
near(a.trapezoidResidual, ...
    (a.u.*a.sampling-cfg.trueParameters(1)*(squeeze(a.endpoints(:,4,:))-a.x) ...
    -cfg.trueParameters(2)*a.trapezoid)./a.sampling);
fprintf('Study 5 saved-data checks passed: endpoint timing, independent batch fits, mapping, forecasts, rank and metrics.\n');
end
function [b,Phi] = endpoint_row(id,x,y,u,Ts)
% Explicit definitions independent of the core regression dispatcher.
switch char(id)
    case 'I', b = Ts*u; Phi = [y-x,Ts*(x^3+y^3)/2];
    case 'D', b = y-x; Phi = [u,x^3];
    case 'A', b = y; Phi = [1,x,u];
    case 'P3', b = y; Phi = [1,x,u,x^2,x*u,u^2,x^3,x^2*u,x*u^2,u^3];
end
end
function batch_check(X,y,beta0,P0,beta,P)
W = chol(P0,'lower')\eye(numel(beta0));
design = [W;X]; response = [W*beta0;y];
[~,R] = qr(design,0);
near(beta,design\response); near(P,R\(R.'\eye(numel(beta0))));
end
function near(actual,expected)
assert(isequal(size(actual),size(expected)) && isequal(isnan(actual),isnan(expected)));
valid = isfinite(actual) & isfinite(expected);
assert(isequal(isinf(actual),isinf(expected)));
assert(all(abs(actual(valid)-expected(valid)) <= 1e-7*max(1,max(abs(expected(valid)),[],'all')),'all'), ...
    'study5:SavedDataMismatch','Saved numerical evidence does not match its defining calculation.');
end
