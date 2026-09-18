function [estimator,fit] = study2_fit(id,record,cfg)
%STUDY2_FIT Fit the supplied completed measured transitions with core RLS.
% Histories include the prior; checkpoint j uses history column j+1.
% Calibration fixes coordinates and contributes no identification samples.

[model,theta0,labels,name] = study2_model(id);
count = numel(record.u);
assert(isrow(record.u) && isrow(record.y) && numel(record.y) == count+1, ...
    'study2:RecordShape','A record needs count inputs and count+1 measurements.');
assert(all(cfg.fitSteps >= 1 & cfg.fitSteps <= count) && ...
    all(cfg.fitSteps == floor(cfg.fitSteps)), ...
    'study2:FitCheckpoints','Fit checkpoints must be completed transition indices.');
n = model.ntheta;
states = linspace(-1.2,1.2,41);
inputs = linspace(-1.2,1.2,41);
samples = zeros(1,n,numel(states)*numel(inputs));
index = 0;
for x = states
    for u = inputs
        index = index+1;
        [~,samples(:,:,index)] = model_regression(model,x,0,u);
    end
end
D = regression_scaling(samples,1);
fit = struct('id',char(id),'name',name,'theta0',theta0,'D',D, ...
    'P0',(100/n)*eye(n),'labels',{labels},'nEstimated',n, ...
    'theta',nan(n,count+1),'beta',nan(n,count+1), ...
    'covariance',nan(n,n,count+1),'attempted',false(1,count), ...
    'accepted',false(1,count),'lambda',nan(1,count),'residual',nan(1,count), ...
    'message',{repmat({''},1,count)}, ...
    'checkpointTheta',[],'checkpointCovariance',[]);
if strcmp(id,'K')
    estimator = [];
    fit.nEstimated = 0;
    fit.P0 = zeros(0);
    fit.theta = repmat(theta0,1,count+1);
    fit.beta = D.*fit.theta;
    fit.covariance = zeros(0,0,count+1);
    fit.message(:) = {'Known-model reference: no identification update.'};
else
    estimator = RlsEstimator(theta0,fit.P0,1,D,struct('mode','none'));
    fit.theta(:,1) = estimator.RawParameters;
    fit.beta(:,1) = estimator.Beta;
    fit.covariance(:,:,1) = estimator.Covariance;
    for j = 1:count
        fit.attempted(j) = true;
        try
            [response,Phi] = model_regression(model,record.y(j),record.y(j+1),record.u(j));
            status = estimator.update(response,Phi);
            fit.accepted(j) = status.accepted;
            fit.lambda(j) = status.lambda;
            if ~isempty(status.residual)
                fit.residual(j) = status.residual;
            end
            fit.message{j} = status.message;
        catch exception
            fit.message{j} = exception.message;
        end
        fit.theta(:,j+1) = estimator.RawParameters;
        fit.beta(:,j+1) = estimator.Beta;
        fit.covariance(:,:,j+1) = estimator.Covariance;
    end
end
fit.checkpointTheta = fit.theta(:,cfg.fitSteps+1);
fit.checkpointCovariance = fit.covariance(:,:,cfg.fitSteps+1);
end
