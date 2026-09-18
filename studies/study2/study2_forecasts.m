function out = study2_forecasts(fit,record,cfg)
%STUDY2_FORECASTS Held-out one-step and common-query diagnostics, Eqs.64-66.
% Evaluation range is independent of the closed-loop reference amplitude.
% Core forward_map/freeze_predictor supply all learned-map calculations.
model = study2_model(fit.id);
shape = [numel(cfg.anchors),numel(cfg.horizons),2,numel(cfg.fitSteps)];
out = struct('evaluationRange',record.L,'fitSteps',cfg.fitSteps, ...
    'horizons',cfg.horizons,'anchors',cfg.anchors,'inputModes',{{'held','rateLimited'}}, ...
    'oneStepErrors',nan(numel(record.u),numel(cfg.fitSteps)), ...
    'modelError',nan(shape),'freezingError',nan(shape),'totalError',nan(shape), ...
    'crossTerm',nan(shape),'valid',false(shape), ...
    'failures',struct('fitStep',{},'anchor',{},'mode',{},'message',{}));
for s = 1:numel(cfg.fitSteps)
    theta = fit.checkpointTheta(:,s);
    for j = 1:numel(record.u)
        try
            value = forward_map(model,record.x(j),record.u(j),theta)-record.x(j+1);
            assert(isfinite(value),'study2:InvalidForecast','Nonfinite one-step error.');
            out.oneStepErrors(j,s) = value;
        catch exception
            out.failures(end+1) = failure(cfg.fitSteps(s),j-1,'oneStep',exception.message);
        end
    end
    for a = 1:numel(cfg.anchors)
        j = cfg.anchors(a)+1;
        for mode = 1:2
            truth = record.x(j); learned = truth; affine = truth;
            try
                [A,B,c] = freeze_predictor(model,truth,record.u(j),theta);
                for h = 1:max(cfg.horizons)
                    u = record.u(j);
                    if mode == 2, u = record.u(j+h-1); end
                    truth = study2_plant(truth,u);
                    learned = forward_map(model,learned,u,theta);
                    affine = c+A*affine+B*u;
                    assert(all(isfinite([truth,learned,affine])), ...
                        'study2:InvalidForecast','Nonfinite multi-step forecast.');
                    ih = find(cfg.horizons == h,1);
                    if isempty(ih), continue; end
                    em = learned-truth; ef = affine-learned; et = affine-truth;
                    assert(all(isfinite([em,ef,et,em^2,ef^2,et^2,2*em*ef])), ...
                        'study2:InvalidForecast','Nonfinite forecast error arithmetic.');
                    out.modelError(a,ih,mode,s) = em;
                    out.freezingError(a,ih,mode,s) = ef;
                    out.totalError(a,ih,mode,s) = et;
                    out.crossTerm(a,ih,mode,s) = 2*em*ef;
                    out.valid(a,ih,mode,s) = true;
                end
            catch exception
                out.failures(end+1) = failure(cfg.fitSteps(s),cfg.anchors(a), ...
                    out.inputModes{mode},exception.message);
            end
        end
    end
end
em = out.modelError(out.valid); ef = out.freezingError(out.valid); et = out.totalError(out.valid);
out.maxIdentityResidual = max(abs(et-em-ef),[],'omitnan');
out.maxSquaredIdentityResidual = max(abs(et.^2-em.^2-ef.^2-out.crossTerm(out.valid)),[],'omitnan');
first = abs(out.freezingError(:,1,:,:));
out.maxFirstStepFreezingError = max(first(:),[],'omitnan');
out.maxAffineFreezingError = NaN;
if strcmp(fit.id,'A'), out.maxAffineFreezingError = max(abs(ef),[],'omitnan'); end
out.allQueriesValid = all(out.valid(:)) && all(isfinite(out.oneStepErrors(:)));
% Required finite-query consistency is verified independently from saved data.
end

function item = failure(step,anchor,mode,message)
item = struct('fitStep',step,'anchor',anchor,'mode',mode,'message',message);
end
