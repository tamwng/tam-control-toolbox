function out=verification_claim_check(current,reference,kind,options)
%VERIFICATION_CLAIM_CHECK Existing explicit reported claims only; no invented rankings.
arguments
    current double
    reference double
    kind (1,1) string
    options.ExplicitClaim (1,1) logical=false
    options.ReproductionBand double=[]
end
out=struct('passed',false,'status',"BLOCKED",'reason',"Required finite claim data missing");
if ~isequal(size(current),size(reference)) || ~isreal(current) || ~isreal(reference) || ...
        any(~isfinite(current),'all') || any(~isfinite(reference),'all'),return;end
switch kind
    case "signedContrast",out.passed=isequal(sign(current),sign(reference));
    case "intervalZeroContainment"
        if numel(current)~=2 || current(1)>current(2) || reference(1)>reference(2),return;end
        out.passed=isequal(current(1)<=0 && current(2)>=0,reference(1)<=0 && reference(2)>=0);
    case "strictOrdering"
        if ~options.ExplicitClaim
            out.status="NOT_AN_EXPLICIT_CLAIM";out.reason="No ordering assertion made";return
        end
        if numel(current)~=2 || ~isequal(size(options.ReproductionBand),size(current)) || ...
                any(~isfinite(options.ReproductionBand)) || any(options.ReproductionBand<0),return;end
        out.passed=all(diff(current)>0) && all(diff(reference)>0) && ...
            current(1)+options.ReproductionBand(1)<current(2)-options.ReproductionBand(2);
    otherwise,error('ejc:UnknownClaim','Unknown claim type.');
end
if out.passed,out.status="PASSED";out.reason="";else,out.reason="Reported claim changed or overlaps its conservative reproducibility margin";end
end
