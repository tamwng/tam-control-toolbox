function fit = study5_fit(id,record,cfg)
%STUDY5_FIT Core RLS from measured endpoints in the declared fixed coordinates.
[model,theta0,labels,name] = study5_model(id,cfg);
known = strcmp(id,'K'); n = model.ntheta; count = numel(record.u);
rowScale = 1; if strcmp(id,'I'), rowScale = 1/cfg.Ts; end
samples = zeros(1,n,41^2); index = 0;
for x = linspace(-1.2,1.2,41)
    second = linspace(-1,1,41);
    if strcmp(model.kind,'physical'), second = linspace(-.1,.1,41); end
    for s = second
        index = index+1;
        if strcmp(model.kind,'physical')
            [~,samples(:,:,index)] = model_regression(model,x,x+s,0);
        else
            [~,samples(:,:,index)] = model_regression(model,x,0,s);
        end
    end
end
D = regression_scaling(samples,rowScale);
fit = struct('id',char(id),'name',name,'labels',{labels},'nEstimated',n*double(~known), ...
    'theta0',theta0,'P0',(100/n)*eye(n),'D',D,'rowScale',rowScale, ...
    'theta',nan(n,count+1),'mappedTheta',nan(n,count+1),'beta',nan(n,count+1), ...
    'covariance',nan(n,n,count+1),'attempted',false(1,count),'accepted',false(1,count), ...
    'lambda',nan(1,count),'residual',nan(1,count),'mappingActivated',false(1,count+1), ...
    'message',{repmat({''},1,count)});
fit.residualUnits = 'rad/s';
if strcmp(id,'I'), fit.residualUnits = 'N m (row-scaled inverse relation)'; end
if known, fit.residualUnits = 'Not applicable'; end
if known
    fit.P0 = zeros(0); fit.covariance = zeros(0,0,count+1);
    fit.theta = repmat(theta0,1,count+1); fit.mappedTheta = fit.theta;
    fit.beta = D.*fit.theta;
else
    estimator = RlsEstimator(theta0,fit.P0,rowScale,D,cfg.forgetting,@(raw) study5_map(id,raw));
    fit.theta(:,1) = estimator.RawParameters; fit.mappedTheta(:,1) = estimator.Parameters;
    fit.beta(:,1) = estimator.Beta; fit.covariance(:,:,1) = estimator.Covariance;
    for j = 1:count
        fit.attempted(j) = true;
        [response,Phi] = model_regression(model,record.y(j),record.y(j+1),record.u(j));
        status = estimator.update(response,Phi);
        fit.accepted(j) = status.accepted; fit.lambda(j) = status.lambda;
        if ~isempty(status.residual), fit.residual(j) = status.residual; end
        fit.message{j} = status.message;
        fit.theta(:,j+1) = estimator.RawParameters; fit.mappedTheta(:,j+1) = estimator.Parameters;
        fit.beta(:,j+1) = estimator.Beta; fit.covariance(:,:,j+1) = estimator.Covariance;
    end
end
fit.mappingDelta = fit.mappedTheta-fit.theta;
fit.mappingActivated = any(fit.mappingDelta ~= 0,1);
fit.checkpointTheta = fit.theta(:,cfg.fitSteps+1);
fit.checkpointMappedTheta = fit.mappedTheta(:,cfg.fitSteps+1);
fit.checkpointCovariance = fit.covariance(:,:,cfg.fitSteps+1);
end
