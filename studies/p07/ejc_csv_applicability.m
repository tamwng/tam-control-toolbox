function [required,reason]=ejc_csv_applicability(study,file,field,T,source)
%EJC_CSV_APPLICABILITY Producer-defined applicability, never inferred from NaN.
% Unknown numerical columns require finite values. Only the named source
% selectors below create non-applicable slots, still requiring exact NaN masks.
assert(istable(T),'ejc:Applicability','Explicit source rows are required.');
if nargin<5,source=[];end
required=true(height(T),1);reason="Required finite numerical quantity";
names=string(T.Properties.VariableNames);study=string(study);file=string(file);field=string(field);
if any(field==["median","q1","q3","iqr"]) && any(names=="finiteScores")
    required=T.finiteScores>0;reason="Original percentile source: positive finiteScores";
elseif any(field==["medianDifference","lower95","upper95"]) && any(names=="finitePairs")
    required=T.finitePairs>0;reason="Original paired source: positive finitePairs";
elseif any(field==["parameterScaledRMSPercent","parameterFinalScaledPercent","parameterScaledPercent"])
    assert(any(names=="model"),'ejc:Applicability','Parameter target needs the original model key.');
    switch study
        case "study1",required=ismember(string(T.model),["S","R","P2"]);
        case "study2",required=string(T.model)=="E";
        case "study3",required=string(T.model)=="S";
        case "study4"
            assert(all(ismember(["coefficientCount","parameterExactSamples","scoredSamples"],names)), ...
                'ejc:Applicability','Missing original exact-target counts.');
            required=T.coefficientCount>0 & T.scoredSamples>0 & T.parameterExactSamples==T.scoredSamples;
        otherwise,error('ejc:Applicability','Unsupported parameter-target source: %s/%s.',study,file);
    end
    if any(names=="scoredSamples"),required=required & T.scoredSamples>0;end
    reason="Exact original parameter-target dictionary and selected sample count";
elseif study=="study4" && field=="componentErrorRMS"
    required=T.scoredSamples>0 & T.exactSamples==T.scoredSamples;
    reason="Original whole-window exact-target count";
elseif study=="study4" && field=="lastTarget"
    assert(isstruct(source) && isfield(source,'lastExactTargetAvailable') && ...
        islogical(source.lastExactTargetAvailable) && isequal(size(source.lastExactTargetAvailable),[height(T),1]), ...
        'ejc:Applicability','The original last selected target mask is required.');
    required=T.scoredSamples>0 & source.lastExactTargetAvailable;
    reason="Original saved evaluator exactTargetAvailable at the last selected origin";
elseif study=="study5" && any(field==["predictorRefinementRMS","predictorRefinementMax", ...
        "predictorLocalRefinementMax","stateJacobianRefinementMax","inputJacobianRefinementMax","zeroInputAnalyticalErrorMax"])
    required=ismember(string(T.modelId),["I","K"]);
    reason="Original physical-model-only refinement diagnostic";
elseif study=="study6" && field=="archiveComparisonMax"
    assert(any(file=="tables/"+["primary","measurement","online","change","main","verification"]+".csv"), ...
        'ejc:Applicability','Unlisted Study 6 comparison scope.');
    if file=="tables/main.csv"
        assert(all(ismember(["kind","fittingTransitions"],names)) && ...
            all(T.kind=="commonData" & T.fittingTransitions==200), ...
            'ejc:Applicability','Main rows must be the original 200-transition primary selection.');
        required(:)=true;
    elseif file=="tables/verification.csv"
        assert(any(names=="filesChecked") && all(T.filesChecked==329), ...
            'ejc:Applicability','Original complete Study 6 verification coverage is required.');
        required(:)=true;
    else
        required(:)=any(file==["tables/primary.csv","tables/measurement.csv"]);
    end
    reason="Original primary/archive and measurement/archive comparison sites only";
elseif any(field==["lambdaMin","lambdaMedian","lambdaMax","residualRMS"])
    if any(names=="identificationAttempted")
        required=T.identificationAttempted>0;
    elseif file=="tables/initialization_diagnostics.csv" && any(study==["study2","study3"]) && ...
            any(field==["lambdaMin","lambdaMax"]) && any(names=="attemptedUpdates")
        % Both unchanged producers reduce fit.lambda(fit.attempted).
        % Bind the initialization mask to its exact saved attempt count.
        assert(all(isfinite(T.attemptedUpdates) & T.attemptedUpdates>=0 & ...
            T.attemptedUpdates==fix(T.attemptedUpdates)), ...
            'ejc:Applicability','Invalid original initialization attempt count.');
        required=T.attemptedUpdates>0;
    else,error('ejc:Applicability','Missing original identification applicability: %s/%s.',study,file);end
    reason="Original attempted identification transitions";
elseif field=="residualEnergyMax" && study=="study3"
    assert(any(names=="caseId") && any(names=="identificationAttempted"),'ejc:Applicability','Missing forgetting rule keys.');
    required=ismember(string(T.caseId),["A_vrf","S_vrf"]) & T.identificationAttempted>0;
    reason="Only original variable-forgetting cases evaluate residual energy";
elseif startsWith(field,"covariance") || field=="finalCovarianceCondition"
    if any(names=="coefficientCount"),required=T.coefficientCount>0;
    elseif any(names=="estimatedCoefficients"),required=T.estimatedCoefficients>0;
    elseif any(names=="model"),required=string(T.model)~="K";
    else,error('ejc:Applicability','Missing original covariance dimension/model.');end
    reason="Original positive estimated-coefficient dimension; known model is non-applicable";
elseif startsWith(field,"gramEigen") || any(field==["gramConditionMin","gramConditionMax"])
    if any(names=="gramValidFullWindows"),required=T.gramValidFullWindows>0;
    elseif any(names=="gramFullWindowCount"),required=T.gramFullWindowCount>0;
    elseif all(ismember(["gramFullWindows","gramInvalidFullWindows"],names))
        assert(all(T.gramInvalidFullWindows<=T.gramFullWindows),'ejc:Applicability','Invalid Gram counts.');
        required=T.gramFullWindows>T.gramInvalidFullWindows;
    else,error('ejc:Applicability','Missing exact Gram summary selection/count.');end
    reason="Original selected full-window Gram count";
elseif field=="knownModelAlgebraicUpperSlackMinimum" && study=="study2" && file=="tables/constraint_audit.csv"
    required=string(T.model)=="K";reason="Declared known-model algebraic slack statement only";
end
assert(islogical(required) && isequal(size(required),[height(T) 1]),'ejc:Applicability','Invalid applicability shape.');
end
