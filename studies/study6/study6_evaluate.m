function out = study6_evaluate(model,raw,mapped,q,meta,cache)
%STUDY6_EVALUATE Pathwise attribution, keeping every attempted query.
% raw/mapped: coefficient x query x snapshot. Truth remains evaluator-only.
if nargin < 6, cache = struct; end
n = numel(q.x); H = size(q.inputs,2); ns = size(mapped,3);
assert(isequal(size(raw),size(mapped)) && size(mapped,2) == n);
shape = [n,H+1,2,ns]; diagnosticShape = [n,2,ns];
out = struct('meta',meta,'rawTheta',raw,'mappedTheta',mapped,'horizons',q.horizons, ...
    'nonlinear',nan(shape),'affine',nan(shape),'A',nan(diagnosticShape), ...
    'B',nan(diagnosticShape),'c',nan(diagnosticShape),'contactResidual',nan(diagnosticShape), ...
    'freezeCount',zeros(diagnosticShape),'reusedNonlinear',false(diagnosticShape), ...
    'failures',struct('query',{},'snapshot',{},'mode',{},'step',{},'message',{}));
for s = 1:ns
    for mode = 1:2
        for a = 1:n
            saved = [];
            if isfield(cache,'snapshot') && s == cache.snapshot, saved = cache.states(a,:,mode); end
            p = study6_paths(model,mapped(:,a,s),q.y(a),q.inputs(a,:,mode),saved);
            out.nonlinear(a,:,mode,s) = p.nonlinear; out.affine(a,:,mode,s) = p.affine;
            for name = {'A','B','c','contactResidual','freezeCount','reusedNonlinear'}
                out.(name{1})(a,mode,s) = p.(name{1});
            end
            if ~isempty(p.message)
                out.failures(end+1) = struct('query',a,'snapshot',s,'mode',mode, ...
                    'step',p.failureStep,'message',p.message);
            end
        end
    end
end
out.modelError = out.nonlinear-q.truthY;
out.freezingError = out.affine-out.nonlinear;
out.totalError = out.affine-q.truthY;
out.initializationError = repmat(q.truthY-q.truthX,1,1,1,ns/size(q.truthX,4));
out.changeError = repmat(q.truthX-q.truthFuture,1,1,1,ns/size(q.truthX,4));
out.combinedError = out.affine-q.truthFuture;
out.crossTerm = 2*out.modelError.*out.freezingError;
out.identityResidual = out.totalError-out.modelError-out.freezingError;
out.squaredIdentityResidual = out.totalError.^2-out.modelError.^2-out.freezingError.^2-out.crossTerm;
out.combinedIdentityResidual = out.combinedError-out.modelError-out.freezingError-out.initializationError-out.changeError;
% All four contributions also retain every pairwise signed cross term.
out.combinedCrossTerm = out.crossTerm+2*(out.totalError.*out.initializationError + ...
    out.totalError.*out.changeError+out.initializationError.*out.changeError);
out.combinedSquaredIdentityResidual = out.combinedError.^2-out.modelError.^2-out.freezingError.^2- ...
    out.initializationError.^2-out.changeError.^2-out.combinedCrossTerm;
out.valid = isfinite(out.modelError) & isfinite(out.freezingError) & isfinite(out.totalError) & ...
    isfinite(out.combinedError) & isfinite(out.combinedSquaredIdentityResidual);
for s = 1:ns
    for mode = 1:2
        for a = 1:n
            bad = find(~out.valid(a,:,mode,s),1);
            reported = any(arrayfun(@(f) f.query == a && f.snapshot == s && f.mode == mode,out.failures));
            if ~isempty(bad) && ~reported
                out.failures(end+1) = struct('query',a,'snapshot',s,'mode',mode,'step',bad-1, ...
                    'message','Nonfinite error arithmetic; full attempted query retained.');
            end
        end
    end
end
out.archiveComparisonMax = NaN;
end
