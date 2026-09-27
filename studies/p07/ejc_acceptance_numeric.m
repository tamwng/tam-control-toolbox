function report=ejc_acceptance_numeric(a,b,absolute,relative,required)
%EJC_ACCEPTANCE_NUMERIC Every applicable finite scalar uses one additive bound.
% The caller supplies an independently established applicability mask.
arguments
    a
    b
    absolute double
    relative (1,1) double
    required logical
end
report=struct('passed',false,'strictEqual',isequaln(a,b),'reason',"", ...
    'elements',numel(a),'requiredCount',nnz(required),'notApplicableCount',nnz(~required), ...
    'unequalCount',0,'failedCount',0,'maximumAbsoluteDifference',NaN, ...
    'maximumLinearIndex',NaN,'maximumBoundRatio',NaN,'maximumRatioIndex',NaN);
if ~isa(a,'double') || ~isa(b,'double') || ~isreal(a) || ~isreal(b) || ...
        ~isequal(size(a),size(b),size(required))
    report.reason="Class, real-coordinate or shape mismatch";return
end
if ~(isscalar(absolute) || isequal(size(absolute),size(a))) || ...
        any(~isfinite(absolute),'all') || any(absolute<0,'all') || ...
        ~isfinite(relative) || relative<0
    report.reason="Invalid bound or component scaling";return
end
if ~isequal(isnan(a),isnan(b)) || ~isequal(isinf(a),isinf(b)) || ...
        ~isequal(a(isinf(a)),b(isinf(b)))
    report.reason="Nonfinite masks or infinity signs differ";return
end
if any(~isfinite(a(required))) || any(~isfinite(b(required)))
    report.reason="Required nonfinite value";return
end
% A numerical non-applicable slot must be the explicit saved NaN sentinel.
% Meaningful Inf conventions are exact/scoped checks outside this primitive.
if any(~isnan(a(~required))) || any(~isnan(b(~required)))
    report.reason="Invalid non-applicable sentinel";return
end
indices=find(required);delta=abs(a(required)-b(required));
if isscalar(absolute),floorValue=absolute;else,floorValue=absolute(required);end
budget=floorValue+relative*abs(b(required));
report.unequalCount=nnz(delta~=0);report.failedCount=nnz(delta>budget);
report.passed=report.failedCount==0;
if isempty(delta)
    report.maximumAbsoluteDifference=0;report.maximumBoundRatio=0;return
end
[report.maximumAbsoluteDifference,j]=max(delta(:));report.maximumLinearIndex=indices(j);
ratios=delta./budget;ratios(delta==0 & budget==0)=0;
[report.maximumBoundRatio,j]=max(ratios(:));report.maximumRatioIndex=indices(j);
if ~report.passed,report.reason="Approved additive agreement requirement failed";end
end
