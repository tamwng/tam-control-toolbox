function out=verification_gram_reduce(rawCurrent,rawReference,selectionCurrent,selectionReference,parentVerdicts,ownDefinitionPassed)
%VERIFICATION_GRAM_REDUCE Preserve raw passive extrema; never fabricate agreement.
out=struct('status',"BLOCKED",'eligibleToAdvance',false,'qualifiedCount',0, ...
    'rawCurrent',rawCurrent,'rawReference',rawReference,'rawExtremumReproduced',false, ...
    'reason',"Required reduction source/parent evidence is missing");
if ~isequaln(selectionCurrent,selectionReference),out.reason="Original reduction selections differ";return;end
if ~isequal(ownDefinitionPassed,true),out.reason="Reduction own-source definition is not established";return;end
if isempty(parentVerdicts) || ~all([parentVerdicts.eligibleToAdvance])
    out.reason="Missing or failed contributing Gram parent checks";return
end
% A qualified parent does not authorize an invalid reduction sentinel or
% a finite/Inf substitution in the reporting layer.
if ~isa(rawCurrent,'double') || ~isa(rawReference,'double') || ...
        ~isreal(rawCurrent) || ~isreal(rawReference) || ...
        ~isequal(size(rawCurrent),size(rawReference)) || ...
        any(isnan(rawCurrent),'all') || any(isnan(rawReference),'all') || ...
        ~isequal(isinf(rawCurrent),isinf(rawReference)) || ...
        ~isequal(rawCurrent(isinf(rawCurrent)),rawReference(isinf(rawReference))) || ...
        any(rawCurrent<0,'all') || any(rawReference<0,'all')
    out.reason="Invalid reduction class/shape, nonfinite mask/sign or negative condition";return
end
if any([parentVerdicts.qualifiedCount]>0)
    out.status="QUALIFIED_UNRESOLVED_GRAM_REDUCTION";
    out.qualifiedCount=1;out.eligibleToAdvance=true;
elseif isequal(rawCurrent,Inf) && isequal(rawReference,Inf) && ...
        all(isfield(parentVerdicts,{'status','rawCurrent','rawReference'})) && ...
        any(string({parentVerdicts.status})=="EXACT_STRUCTURAL_ZERO_GRAM" & ...
        [parentVerdicts.rawCurrent]==Inf & [parentVerdicts.rawReference]==Inf)
    % The maximum contains an executed exact structural-zero parent on both
    % sides. Preserve that fixed +Inf convention without Inf subtraction.
    out.status="EXACT_STRUCTURAL_ZERO_GRAM_REDUCTION";
    out.eligibleToAdvance=true;out.rawExtremumReproduced=true;
else
    r=verification_acceptance_numeric(rawCurrent,rawReference,1e-8,1e-7,true(size(rawCurrent)));
    out.eligibleToAdvance=r.passed;out.rawExtremumReproduced=r.passed;
    if r.passed,out.status="NUMERICAL_AGREEMENT";else,out.reason=r.reason;end
end
if out.eligibleToAdvance,out.reason="";end
end
