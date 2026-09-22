function out = study5_forecasts(fit,record,queries,cfg)
%STUDY5_FORECASTS Nonlinear predictions only; no Study 6 decomposition.
model = study5_model(fit.id,cfg); physical = strcmp(model.kind,'physical');
fine = physical_model(cfg.Ts,cfg.refinedPredictorSubsteps);
out = struct('id',fit.id,'name',fit.name,'fitSteps',cfg.fitSteps, ...
    'horizons',cfg.horizons,'anchors',queries.anchors,'inputModes',{queries.inputModes}, ...
    'frozenTheta',fit.checkpointMappedTheta(:,end), ...
    'oneStepErrors',nan(numel(record.u),4),'oneStepPrediction',nan(numel(record.u),4), ...
    'oneStepRefinement',nan(numel(record.u),4), ...
    'states',nan(size(queries.truth)),'refinedStates',nan(size(queries.truth)), ...
    'modelError',nan(numel(cfg.anchors),numel(cfg.horizons),2), ...
    'valid',false(numel(cfg.anchors),numel(cfg.horizons),2), ...
    'failures',struct('fitStep',{},'anchor',{},'mode',{},'message',{}));
for s = 1:numel(cfg.fitSteps)
    theta = fit.checkpointMappedTheta(:,s);
    for j = 1:numel(record.u)
        try
            value = forward_map(model,record.x(j),record.u(j),theta);
            out.oneStepPrediction(j,s) = value;
            out.oneStepErrors(j,s) = value-record.x(j+1);
            if physical
                out.oneStepRefinement(j,s) = value-forward_map(fine,record.x(j),record.u(j),theta);
            end
        catch exception
            out.failures(end+1) = failure(cfg.fitSteps(s),j-1,'oneStep',exception.message);
        end
    end
end
for a = 1:numel(cfg.anchors)
    for mode = 1:2
        state = queries.initialStates(a); refined = state;
        out.states(a,1,mode) = state;
        if physical, out.refinedStates(a,1,mode) = refined; end
        try
            for h = 1:max(cfg.horizons)
                u = queries.inputs(a,h,mode);
                state = forward_map(model,state,u,out.frozenTheta);
                out.states(a,h+1,mode) = state;
                if physical
                    refined = forward_map(fine,refined,u,out.frozenTheta);
                    out.refinedStates(a,h+1,mode) = refined;
                end
                ih = find(cfg.horizons == h,1); if isempty(ih), continue; end
                out.modelError(a,ih,mode) = state-queries.truth(a,h+1,mode);
                out.valid(a,ih,mode) = isfinite(out.modelError(a,ih,mode));
            end
        catch exception
            out.failures(end+1) = failure(200,cfg.anchors(a),queries.inputModes{mode},exception.message);
        end
    end
end
out.forecastRefinement = out.states-out.refinedStates;
out.allQueriesValid = all(out.valid,'all') && all(isfinite(out.oneStepErrors),'all');
end
function value = failure(step,anchor,mode,message)
value = struct('fitStep',step,'anchor',anchor,'mode',mode,'message',message);
end
