function evaluation = study4_evaluate(result,cfg)
%STUDY4_EVALUATE Pure saved-snapshot evaluator; no controller or estimator.
% k is the snapshot time AFTER processing x(k-1)->x(k), BEFORE x(k+1).
model = study4_model(result.id);
[x,u] = ndgrid(cfg.gridX,cfg.gridU);
indices = 1:cfg.snapshotStride:cfg.K; count = numel(indices);
evaluation = struct('id',result.id,'scenario',result.scenario, ...
    'sampleIndices',indices-1,'time',(indices-1)*cfg.Ts, ...
    'x',x(:),'u',u(:),'prediction',nan(numel(x),count), ...
    'truth',nan(numel(x),count),'error',nan(numel(x),count), ...
    'attempted',false(1,count),'valid',false(1,count),'rms',nan(1,count), ...
    'message',{repmat({''},1,count)},'theta',result.theta(:,indices));
for j = 1:count
    index = indices(j);
    [h,rho] = study4_schedule(index-1,result.scenario,cfg);
    evaluation.truth(:,j) = study4_plant(x(:),u(:),h,rho);
    if index > result.nSteps, continue; end
    evaluation.attempted(j) = true;
    try
        for q = 1:numel(x)
            evaluation.prediction(q,j) = forward_map(model,x(q),u(q),result.theta(:,index));
        end
        evaluation.error(:,j) = evaluation.prediction(:,j)-evaluation.truth(:,j);
        evaluation.valid(j) = all(isfinite(evaluation.error(:,j)));
        evaluation.rms(j) = sqrt(mean(evaluation.error(:,j).^2));
    catch exception
        evaluation.message{j} = exception.message;
    end
end
% Exact targets are evaluator metadata only. NaN means no exact vector,
% including ALL post-change polynomial coefficients in the sine case.
n = result.nEstimated;
evaluation.exactTarget = nan(n,cfg.K); evaluation.exactTargetAvailable = false(1,cfg.K);
if n == 0, return; end
for j = 1:cfg.K
    h = result.trueH(j); rho = result.trueRho(j);
    if rho ~= 0 || (n == 3 && h ~= 0), continue; end
    target = [0;.65;.45;zeros(n-3,1)];
    if n >= 4, target(4) = h; end
    evaluation.exactTarget(:,j) = target;
    evaluation.exactTargetAvailable(j) = true;
end
evaluation.parameterError = result.theta-evaluation.exactTarget;
evaluation.parameterScaledPercent = 100*vecnorm(evaluation.parameterError)/sqrt(n);
end
