function forecasts = study1_forecasts(fit,record,cfg)
%STUDY1_FORECASTS Independent, clean-state common queries, Eqs. (64)-(66).
%   Anchors are zero-based transition indices. Parameters and the affine
%   coefficients remain fixed over each forecast. Invalid queries remain
%   explicit and are never silently removed from aggregate scores.
model = study1_model(fit.id);
nFit = numel(cfg.fitSteps);
nAnchor = numel(cfg.anchors);
nH = numel(cfg.horizons);
nEval = numel(record.u);
shape = [nAnchor,nH,2,nFit];
forecasts = struct('fitSteps',cfg.fitSteps,'horizons',cfg.horizons, ...
    'anchors',cfg.anchors,'inputModes',{{'held','rateLimited'}}, ...
    'oneStepErrors',nan(nEval,nFit),'modelError',nan(shape), ...
    'freezingError',nan(shape),'totalError',nan(shape), ...
    'crossTerm',nan(shape),'valid',false(shape), ...
    'identityResidual',nan(shape),'squaredIdentityResidual',nan(shape), ...
    'failures',struct('fitStep',{},'anchor',{},'mode',{},'message',{}));
for j = 1:nFit
    theta = fit.checkpointTheta(:,j);
    for k = 1:nEval
        try
            forecasts.oneStepErrors(k,j) = ...
                forward_map(model,record.x(k),record.u(k),theta)-record.x(k+1);
        catch err
            forecasts.failures(end+1) = failure(cfg.fitSteps(j),k-1, ...
                'oneStep',err.message);
        end
    end
    for a = 1:nAnchor
        k = cfg.anchors(a)+1;
        for mode = 1:2
            zTrue = record.x(k);
            zNonlinear = zTrue;
            zAffine = zTrue;
            try
                [A,B,c] = freeze_predictor(model,zTrue,record.u(k),theta);
                for h = 1:max(cfg.horizons)
                    if mode == 1
                        input = record.u(k);
                    else
                        input = record.u(k+h-1);
                    end
                    zTrue = study1_plant(zTrue,input);
                    zNonlinear = forward_map(model,zNonlinear,input,theta);
                    zAffine = c+A*zAffine+B*input;
                    if any(~isfinite([zTrue,zNonlinear,zAffine]))
                        error('study1:InvalidForecast','Nonfinite common-query forecast.');
                    end
                    ih = find(cfg.horizons == h,1);
                    if isempty(ih), continue; end
                    em = zNonlinear-zTrue;
                    ef = zAffine-zNonlinear;
                    et = zAffine-zTrue;
                    forecasts.modelError(a,ih,mode,j) = em;
                    forecasts.freezingError(a,ih,mode,j) = ef;
                    forecasts.totalError(a,ih,mode,j) = et;
                    forecasts.crossTerm(a,ih,mode,j) = 2*em*ef;
                    forecasts.identityResidual(a,ih,mode,j) = abs(et-em-ef);
                    forecasts.squaredIdentityResidual(a,ih,mode,j) = ...
                        abs(et^2-em^2-ef^2-2*em*ef);
                    forecasts.valid(a,ih,mode,j) = true;
                end
            catch err
                forecasts.failures(end+1) = failure(cfg.fitSteps(j), ...
                    cfg.anchors(a),forecasts.inputModes{mode},err.message);
            end
        end
    end
end
finiteErrors = [forecasts.modelError(:);forecasts.freezingError(:);forecasts.totalError(:)];
finiteErrors = finiteErrors(isfinite(finiteErrors));
scale = max([1;abs(finiteErrors)]);
forecasts.maxIdentityResidual = finite_max(forecasts.identityResidual);
forecasts.maxSquaredIdentityResidual = finite_max(forecasts.squaredIdentityResidual);
forecasts.maxFirstStepFreezingError = finite_max(abs(forecasts.freezingError(:,1,:,:)));
forecasts.maxAffineFreezingError = NaN;
if strcmp(fit.id,'A')
    forecasts.maxAffineFreezingError = finite_max(abs(forecasts.freezingError));
end
forecasts.allQueriesValid = all(forecasts.valid(:)) && all(isfinite(forecasts.oneStepErrors(:)));
% Only evaluated finite queries can establish the algebraic identities.
% Missing queries remain failures, not manufactured passes or scores.
forecasts.identityChecksEvaluated = isfinite(forecasts.maxIdentityResidual);
forecasts.firstStepCheckEvaluated = isfinite(forecasts.maxFirstStepFreezingError);
if forecasts.identityChecksEvaluated
    assert(forecasts.maxIdentityResidual <= 1e-11*scale, ...
        'study1:ForecastIdentity','Forecast error addition identity failed.');
    assert(forecasts.maxSquaredIdentityResidual <= 1e-11*scale^2, ...
        'study1:ForecastSquaredIdentity','Forecast squared-error identity failed.');
end
if forecasts.firstStepCheckEvaluated
    assert(forecasts.maxFirstStepFreezingError <= 1e-11, ...
        'study1:FirstStepFreezing','First-step freezing contact failed.');
end
if strcmp(fit.id,'A') && isfinite(forecasts.maxAffineFreezingError)
    assert(forecasts.maxAffineFreezingError <= 1e-11, ...
        'study1:AffineFreezing','Complete affine model accumulated freezing error.');
end
end

function item = failure(fitStep,anchor,mode,message)
item = struct('fitStep',fitStep,'anchor',anchor,'mode',mode,'message',message);
end

function value = finite_max(values)
values = values(isfinite(values));
if isempty(values), value = NaN; else, value = max(values); end
end
