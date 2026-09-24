function scores = p06_score(result,cfg)
%P06_SCORE Reuse the original definitions, including incomplete-prefix labels.
helper = study1_summarize('p06_helpers');
base = struct('campaign',"P06",'model',string(result.id), ...
    'trial',result.p06.trial,'noise',result.p06.noisy);
scores.metrics = helper.scoreRun(result,base,cfg);
scores.initialization = helper.scoreFit(result,base,cfg);
scores.diagnostics = helper.diagnoseRun(result,base,cfg);
% The retained Gram condition is Study 1's raw cond(G), not corrected rank.
scores.gramDefinition = 'Legacy Study 1 cond(G); not the thresholded rank diagnostic in Eq. A.7';
end
