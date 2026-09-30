function [result,scores] = sensitivity_case(row,plan,records,operations)
%SENSITIVITY_CASE Fit, control and score one selected sensitivity case.
% Optional operations are explicit synthetic-test doubles, never path shadows.
if nargin < 4
    operations = struct('fit',@study1_fit,'trajectory',@study1_trajectory, ...
        'evaluate',@study1_forecasts,'score',@sensitivity_score);
end
[training,noise,cfg] = sensitivity_trial(records,row.trial,row,plan.cfg);
prior = row.alphaP;
if ~row.identificationApplicable, prior = 1; end
[estimator,fit] = operations.fit(char(row.modelId),training,cfg,prior);
% Pass the returned state directly, preserving both beta and P exactly.
% No cache, covariance reset, data join, or prefix-dependent control stream.
result = operations.trajectory(char(row.modelId),fit,estimator,noise,cfg);
evaluationCfg = cfg;
evaluationCfg.anchors = []; % Only the existing 600-query one-step evaluator.
result.forecasts = operations.evaluate(fit,records.evaluation,evaluationCfg);
result.p06 = table2struct(row);
result.p06.fitCachePolicy = plan.cachePolicy;
result.p06.evaluationScope = '600 saved clean transitions; no multistep anchor forecasts';
scores = operations.score(result,cfg);
end
