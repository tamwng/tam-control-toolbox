function out=ejc_p7_qualify(a,b,coverageId,checks)
%EJC_P7_QUALIFY Pair verdict; single-matrix eligibility never implies agreement.
% Callers must supply independently checked source/parent/scientific facts.
out=struct('status',"BLOCKED",'eligibleToAdvance',false,'qualifiedCount',0, ...
    'rawConditionUnresolved',true,'reason',"Missing mandatory prerequisites");
allowed=["F0069","F0374","F0533","F0713","F0894","F1133","F1134", ...
    "F1224","F1225","F1344","F1477","F1614","F1896","F2067", ...
    "F2190","F2462","F3589","F3736","F3914"];
if ~isscalar(string(coverageId)) || ~any(string(coverageId)==allowed)
    out.reason="Outside the unchanged 19 passive Gram-condition scopes";return
end
required=["passiveUse","sourceMembership","coordinateDefinitions","matrixAgreement", ...
    "regressorAgreement","spectralAgreement","masksAndSigns", ...
    "originalRanks","originalCounts","originalFlags","outcomes", ...
    "publicationChecks","noRequiredUniqueSupplementalRankClaim"];
for name=required
    if ~isfield(checks,name) || ~islogical(checks.(name)) || ~isscalar(checks.(name)) || ~checks.(name)
        out.reason="Mandatory prerequisite failed or missing: "+name;return
    end
end
fields=["kind","valid","decompositionPassed","formationPassed","zeroMatrix", ...
    "dimension","resolved","conditionInsideEnvelope","storedCondition", ...
    "rankResolved","rankLower","rankUpper","pointThresholdRank", ...
    "robustlyThresholdDeficient"];
if ~all(isfield(a,fields)) || ~all(isfield(b,fields)),return;end
if a.kind~="gram" || b.kind~="gram" || ~a.valid || ~b.valid || ...
        ~a.decompositionPassed || ~b.decompositionPassed || ...
        ~a.formationPassed || ~b.formationPassed || ...
        a.dimension~=b.dimension
    out.reason="Invalid or non-Gram parent";return
end
x=a.storedCondition;y=b.storedCondition;
if ~isa(x,'double') || ~isa(y,'double') || ~isreal(x) || ~isreal(y) || ...
        ~isscalar(x) || ~isscalar(y) || isnan(x) || isnan(y) || ...
        ~isequal(isinf(x),isinf(y)) || (isinf(x) && ~isequal(x,y))
    out.reason="Prohibited raw-condition values or masks";return
end
if a.zeroMatrix || b.zeroMatrix
    if a.zeroMatrix && b.zeroMatrix && isfield(a,'structuralZero') && ...
            isfield(b,'structuralZero') && a.structuralZero && b.structuralZero && ...
            a.zeroParentsExact && b.zeroParentsExact && isequal(x,Inf) && isequal(y,Inf)
        out.status="EXACT_STRUCTURAL_ZERO_GRAM";out.eligibleToAdvance=true;
        out.rawConditionUnresolved=false;
        out.reason="Exact structural rank zero and matching +Inf convention; no Inf subtraction";
    else,out.reason="Structural-zero parent or mask mismatch";end
    return
end
if isinf(x)
    rankConvention=isfield(checks,'permittedRankInfinity') && isequal(checks.permittedRankInfinity,true);
    % Study 1/2 (and P06's Study 1 producer) store cond(G), not the
    % separately thresholded rank diagnostic used by Studies 3--5. Missing
    % historical rank fields must not be invented or required by dispatch.
    rawSingularConvention=raw_singular_source(a,b,checks);
    if ~(rankConvention || rawSingularConvention) || ...
            x<0 || a.pointThresholdRank>=a.dimension || b.pointThresholdRank>=b.dimension
        out.reason="Infinity lacks a verified original rank or raw-singular condition source";return
    end
end
if a.pointThresholdRank~=b.pointThresholdRank || max(a.rankLower,b.rankLower)>min(a.rankUpper,b.rankUpper)
    out.reason="Point ranks differ or supplementary rank intervals do not overlap";return
end
if (a.resolved && ~a.conditionInsideEnvelope) || (b.resolved && ~b.conditionInsideEnvelope)
    out.reason="Resolved condition outside own envelope";return
end
if a.resolved && b.resolved
    numeric=ejc_acceptance_numeric(x,y,1e-8,1e-7,true);
    if numeric.passed
        out.status="NUMERICAL_AGREEMENT";out.eligibleToAdvance=true;
        out.rawConditionUnresolved=false;out.reason="";
    else,out.reason=numeric.reason;end
    return
end
if ~eligible_side(a) || ~eligible_side(b)
    out.reason="Unapproved or failed single-matrix condition/rank screen";return
end
if a.status=="ELIGIBLE_P7_FULL_RANK_BOUNDARY" || b.status=="ELIGIBLE_P7_FULL_RANK_BOUNDARY"
    out.status="QUALIFIED_PASSIVE_GRAM_BOUNDARY_POINT_RANK_MATCHED";
elseif a.rankResolved && b.rankResolved
    if a.thresholdRank~=b.thresholdRank,out.reason="Resolved threshold ranks differ";return;end
    out.status="QUALIFIED_WITH_UNRESOLVED_GRAM_DIAGNOSTIC";
elseif a.robustlyThresholdDeficient && b.robustlyThresholdDeficient
    out.status="QUALIFIED_WITH_UNRESOLVED_GRAM_RANK_DETAIL";
else
    out.reason="Unresolved full-rank/deficient boundary";return
end
out.eligibleToAdvance=true;out.qualifiedCount=1;
out.reason="Raw condition remains unresolved; qualification is not numeric equality";
end
function yes=raw_singular_source(a,b,checks)
yes=false;
if ~isfield(checks,'rawConditionOrigin') || ~isscalar(string(checks.rawConditionOrigin)) || ...
        ~any(string(checks.rawConditionOrigin)==["study1_trajectory:spectrum:cond","study2_trajectory:spectrum:cond"])
    return
end
for side={a,b}
    s=side{1};
    if ~all(isfield(s,{'recomputedCondition','singularValues','regressorCount'})) || ...
            ~isequal(s.recomputedCondition,Inf) || s.regressorCount<1 || ...
            numel(s.singularValues)~=s.dimension || any(~isfinite(s.singularValues)) || ...
            s.singularValues(1)<=0 || s.singularValues(end)~=0
        return
    end
end
yes=true;
end
function yes=eligible_side(s)
yes=(s.resolved && s.conditionInsideEnvelope) || ...
    (~s.resolved && s.rankResolved && s.status=="UNRESOLVED_CONDITION") || ...
    (~s.resolved && s.robustlyThresholdDeficient && s.status=="ELIGIBLE_P7_UNRESOLVED_INTERMEDIATE_RANK") || ...
    (~s.resolved && s.status=="ELIGIBLE_P7_FULL_RANK_BOUNDARY" && ...
     s.rankLower==s.dimension-1 && s.rankUpper==s.dimension && ...
     s.singularValues(end)>s.eta && all(isfinite(s.envelope)) && s.conditionInsideEnvelope);
end
