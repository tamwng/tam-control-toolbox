function fit = study4_fit(id,record,cfg)
%STUDY4_FIT All retained coefficients fitted with core RLS, no forgetting.
[model,theta0,labels,name] = study4_model(id);
assert(~strcmp(id,'K'),'study4:KnownFit','The known reference is not fitted.');
n = model.ntheta; count = numel(record.u);
samples = zeros(1,n,41^2); index = 0;
for x = linspace(-1.2,1.2,41)
    for u = linspace(-1,1,41)
        index = index+1;
        [~,samples(:,:,index)] = model_regression(model,x,0,u);
    end
end
D = regression_scaling(samples,1);
fit = struct('id',char(id),'name',name,'labels',{labels},'nEstimated',n, ...
    'theta0',theta0,'P0',(100/n)*eye(n),'D',D,'rowScale',1, ...
    'theta',nan(n,count+1),'beta',nan(n,count+1),'covariance',nan(n,n,count+1), ...
    'attempted',true(1,count),'accepted',false(1,count),'lambda',nan(1,count), ...
    'residual',nan(1,count),'message',{repmat({''},1,count)});
estimator = RlsEstimator(theta0,fit.P0,1,D,struct('mode','none'));
fit.theta(:,1) = estimator.RawParameters;
fit.beta(:,1) = estimator.Beta; fit.covariance(:,:,1) = estimator.Covariance;
for j = 1:count
    [response,Phi] = model_regression(model,record.y(j),record.y(j+1),record.u(j));
    status = estimator.update(response,Phi);
    fit.accepted(j) = status.accepted; fit.lambda(j) = status.lambda;
    if ~isempty(status.residual), fit.residual(j) = status.residual; end
    fit.message{j} = status.message;
    fit.theta(:,j+1) = estimator.RawParameters;
    fit.beta(:,j+1) = estimator.Beta; fit.covariance(:,:,j+1) = estimator.Covariance;
end
fit.checkpointTheta = fit.theta(:,cfg.fitSteps+1);
fit.checkpointCovariance = fit.covariance(:,:,cfg.fitSteps+1);
end
