function p = study6_paths(model,theta,initial,inputs,savedNonlinear)
%STUDY6_PATHS Pure fixed-model forecast. No true plant/schedule is an argument.
% Freeze once at the actual initial state and first committed query input.
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
