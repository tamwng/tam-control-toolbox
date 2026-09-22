function checks = study6_check(out,q)
%STUDY6_CHECK Identities and query contact, independent of performance ranking.
tol = 1e-11;
assert(isequal(q.matlabColumns,q.indices+1));
finite = out.valid;
scale = max([1;abs(out.modelError(finite));abs(out.freezingError(finite)); ...
    abs(out.initializationError(finite));abs(out.changeError(finite));abs(out.combinedError(finite))]);
checks = struct('attemptedPaths',numel(out.freezeCount),'finitePaths', ...
    nnz(reshape(all(out.valid,2),[],1)),'failureRecords',numel(out.failures));
for name = ["identityResidual","combinedIdentityResidual"]
    checks.(name) = maximum(abs(out.(name)(finite)));
    assert(isnan(checks.(name)) || checks.(name) <= tol*scale,'study6:Identity','Forecast addition identity failed.');
end
for name = ["squaredIdentityResidual","combinedSquaredIdentityResidual"]
    checks.(name) = maximum(abs(out.(name)(finite)));
    assert(isnan(checks.(name)) || checks.(name) <= tol*scale^2,'study6:SquaredIdentity','Squared-error identity failed.');
end
checks.contactResidual = maximum(abs(out.contactResidual));
checks.firstStepFreezing = maximum(abs(out.freezingError(:,2,:,:)));
assert(isnan(checks.contactResidual) || checks.contactResidual <= tol);
assert(isnan(checks.firstStepFreezing) || checks.firstStepFreezing <= tol);
assert(all(out.freezeCount <= 1,'all'));
checks.affineFreezing = NaN;
if out.meta.modelId == "A"
    checks.affineFreezing = maximum(abs(out.freezingError));
    assert(isnan(checks.affineFreezing) || checks.affineFreezing <= tol, ...
        'study6:AffineMap','A complete affine learned map must agree at every horizon.');
end
summary = study6_summary(out,q);
assert(all(abs(summary.aggregateSquaredResidual(isfinite(summary.aggregateSquaredResidual))) <= tol*scale^2));
assert(all(abs(summary.aggregateCombinedSquaredResidual(isfinite(summary.aggregateCombinedSquaredResidual))) <= tol*scale^2));
end
function value = maximum(x)
x = x(isfinite(x)); value = NaN; if ~isempty(x), value = max(x,[],'all'); end
end
