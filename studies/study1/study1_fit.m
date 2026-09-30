function [estimator,fit] = study1_fit(id,record,cfg,priorScale)
% STUDY1_FIT Fit one model to supplied completed measured transitions.
%  RECORD has count inputs and count+1 endpoint measurements, stored as rows.
%  THETA and BETA histories have coefficient rows and count+1 columns;
%  covariance is n-by-n-by-(count+1). Column j+1 follows transition j.
%  Calibration sets fixed scaling only; it supplies no additional observations.
%  Optional positive priorScale multiplies only the normalized prior before
%  fitting. Rejections retain the last valid RLS state. For adaptive models,
%  ESTIMATOR carries the terminal coefficients AND covariance into control;
%  the controller resets only its residual window. The known model returns
%  an empty estimator and records no identification updates.
if nargin < 4, priorScale = 1; end
validateattributes(priorScale,{'double'},{'scalar','real','finite','positive'});

[model,theta0,labels] = study1_model(id);
count = numel(record.u);
assert(isrow(record.u) && isrow(record.y) && numel(record.y) == count+1, ...
    'study1:RecordShape','A record needs count inputs and count+1 measurements.');
assert(all(cfg.fitSteps >= 1 & cfg.fitSteps <= count) && ...
    all(cfg.fitSteps == floor(cfg.fitSteps)), ...
    'study1:FitCheckpoints','Fit checkpoints must be completed transition indices.');
n = model.ntheta;
states = linspace(-1.2,1.2,41);
inputs = linspace(-1,1,41);
samples = zeros(1,n,numel(states)*numel(inputs));
index = 0;
for x = states
    for u = inputs
        index = index+1;
        [~,samples(:,:,index)] = model_regression(model,x,0,u);
    end
end
D = regression_scaling(samples,1);
fit = struct('id',char(id),'theta0',theta0,'D',D,'P0',(100/n)*eye(n), ...
    'labels',{labels},'nEstimated',n,'theta',nan(n,count+1), ...
    'beta',nan(n,count+1),'covariance',nan(n,n,count+1), ...
    'attempted',false(1,count),'accepted',false(1,count), ...
    'lambda',nan(1,count),'residual',nan(1,count), ...
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
    if priorScale ~= 1, fit.P0 = priorScale*fit.P0; end
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
