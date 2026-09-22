function queries = study5_queries(record,cfg)
%STUDY5_QUERIES Evaluator-only common anchors/inputs and refined true flows.
% Anchors are zero-based. These arrays never enter an estimator/controller.
H = max(cfg.horizons); na = numel(cfg.anchors);
nominal = physical_model(cfg.Ts,cfg.plantSubsteps);
refined = physical_model(cfg.Ts,cfg.refinedPlantSubsteps);
known = physical_model(cfg.Ts,cfg.predictorSubsteps);
queries = struct('anchors',cfg.anchors,'horizons',cfg.horizons, ...
    'inputModes',{{'held','rateLimited'}},'initialStates',record.x(cfg.anchors+1), ...
    'inputs',nan(na,H,2),'truth',nan(na,H+1,2), ...
    'nominalTruth',nan(na,H+1,2),'knownPrediction',nan(na,H+1,2), ...
    'referenceSubsteps',cfg.refinedPlantSubsteps);
for a = 1:na
    index = cfg.anchors(a)+1;
    for mode = 1:2
        inputs = repmat(record.u(index),1,H);
        if mode == 2, inputs = record.u(index:index+H-1); end
        queries.inputs(a,:,mode) = inputs;
        truth = record.x(index); coarse = truth; predicted = truth;
        queries.truth(a,1,mode) = truth; queries.nominalTruth(a,1,mode) = truth;
        queries.knownPrediction(a,1,mode) = truth;
        for h = 1:H
            truth = forward_map(refined,truth,inputs(h),cfg.trueParameters);
            coarse = forward_map(nominal,coarse,inputs(h),cfg.trueParameters);
            predicted = forward_map(known,predicted,inputs(h),cfg.trueParameters);
            queries.truth(a,h+1,mode) = truth; queries.nominalTruth(a,h+1,mode) = coarse;
            queries.knownPrediction(a,h+1,mode) = predicted;
        end
    end
end
queries.referenceRefinementError = queries.nominalTruth-queries.truth;
queries.knownNumericalError = queries.knownPrediction-queries.truth;
end
