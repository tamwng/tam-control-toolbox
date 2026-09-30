function p = study6_paths(model,theta,initial,inputs,savedNonlinear)
% STUDY6_PATHS Fixed-model nonlinear and affine forecasts on common inputs.
%  INITIAL is a scalar state; INPUTS contains H prescribed input samples.
%  THETA is one selected model snapshot held fixed throughout this forecast.
%  The model receives neither true-plant dynamics nor a future gain schedule.
%  Both output paths are 1-by-(H+1), including INITIAL. Freeze the affine
%  coefficients once at INITIAL and INPUTS(1), the committed query input.
%  Optional SAVEDNONLINEAR must have H+1 values and the same initial/contact
%  values. A failed query retains NaNs, failureStep and message for inspection.
if nargin < 5, savedNonlinear = []; end
H = numel(inputs);
p = struct('nonlinear',nan(1,H+1),'affine',nan(1,H+1), ...
    'A',NaN,'B',NaN,'c',NaN,'contactResidual',NaN,'failureStep',NaN,'message','', ...
    'freezeCount',0,'reusedNonlinear',~isempty(savedNonlinear));
p.nonlinear(1) = initial; p.affine(1) = initial; h = 0;
try
    [p.A,p.B,p.c,value] = freeze_predictor(model,initial,inputs(1),theta);
    p.freezeCount = 1;
    p.contactResidual = p.c+p.A*initial+p.B*inputs(1)-value;
    if ~isempty(savedNonlinear)
        assert(numel(savedNonlinear) == H+1 && savedNonlinear(1) == initial && ...
            abs(savedNonlinear(2)-value) <= 1e-11, ...
            'study6:CachedContact','Cached nonlinear path must contact the declared snapshot at its query point.');
    end
    for h = 1:H
        if isempty(savedNonlinear)
            p.nonlinear(h+1) = forward_map(model,p.nonlinear(h),inputs(h),theta);
        else, p.nonlinear(h+1) = savedNonlinear(h+1); end
        p.affine(h+1) = p.c+p.A*p.affine(h)+p.B*inputs(h);
        assert(all(isfinite([p.nonlinear(h+1),p.affine(h+1)])), ...
            'study6:NonfiniteForecast','Nonfinite forecast retained as a failed query.');
    end
catch exception
    p.failureStep = h; p.message = exception.message;
end
end
