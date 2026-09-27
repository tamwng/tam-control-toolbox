function out=ejc_diagnostic_parent(study,file,field,row,r)
%EJC_DIAGNOSTIC_PARENT Explicit original saved-array diagnostic selection.
% Supplies the source value and corresponding eigenvalue-parent scale. This
% is not an acceptance verdict; matrix, paired, source and P7 gates are separate.
study=string(study);file=string(file);field=string(field);
assert(isscalar(study) && isscalar(file) && isscalar(field),'ejc:DiagnosticScope','Scalar scope identifiers required.');
assert(any(study==["study1","study2","study3","study4","study5","p06"]) && ...
    (file=="tables/run_diagnostics.csv" || ...
    (any(study==["study4","study5"]) && file=="tables/diagnostics.csv") || ...
    (study=="study3" && file=="tables/run_metrics.csv")), ...
    'ejc:DiagnosticScope','Unlisted diagnostic reduction.');
assert(istable(row) && height(row)==1,'ejc:DiagnosticScope','One exact source row required.');
if study=="p06"
    assert(row.campaign=="P06" && string(r.id)==row.model && r.p06.trial==row.trial, ...
        'ejc:DiagnosticSource','P06 score identity differs.');estimated=r.fit.nEstimated;
elseif study=="study1"
    assert(string(r.campaign)==row.campaign && string(r.id)==row.model && r.trial==row.trial, ...
        'ejc:DiagnosticSource','Run identity differs.');
    estimated=r.fit.nEstimated;
elseif study=="study2"
    assert(string(r.id)==row.model && string(r.kind)==row.kind && isequaln(r.amplitude,row.amplitude), ...
        'ejc:DiagnosticSource','Run identity differs.');estimated=r.nEstimated;
elseif study=="study3"
    assert(string(r.id)==row.caseId && string(r.scenario)==row.scenario && r.trial==row.trial, ...
        'ejc:DiagnosticSource','Run identity differs.');estimated=r.nEstimated;
elseif study=="study4"
    assert(string(r.id)==row.modelId && string(r.scenario)==row.scenarioId, ...
        'ejc:DiagnosticSource','Run identity differs.');estimated=r.nEstimated;
else
    assert(string(r.id)==row.modelId,'ejc:DiagnosticSource','Run identity differs.');estimated=r.nEstimated;
end
isGram=startsWith(field,"gram");isEigen=contains(field,"Eigen");
assert(any(field==["gramEigenMin","gramEigenMax","gramConditionMin","gramConditionMax", ...
    "covarianceEigenMin","covarianceEigenMax"]),'ejc:DiagnosticScope','Unlisted field.');
selected=1:r.nSteps;
if file=="tables/run_metrics.csv"
    time=r.time(1:end-1);K=numel(time);
    selected=find(time>=row.windowStart & time<row.windowEnd & (1:K)<=r.nSteps & ...
        isfinite(r.x(1:K)) & isfinite(r.r(1:K)) & isfinite(r.u(1:K)));
    assert(numel(selected)==row.scoredSamples,'ejc:DiagnosticSource','Selected sample count differs.');
end
if isGram
    selected=selected(r.gramCount(selected)==50);
    if any(study==["study3","study4","study5"]),selected=selected(r.gramValid(selected));end
end
if estimated==0,selected=[];end
out=struct('required',~isempty(selected),'selection',selected,'sourceValue',NaN, ...
    'selectedExtremum',NaN,'parentNorm',NaN,'recipe',"",'values',zeros(1,0));
if isempty(selected),return;end
if isGram,kind="gram";else,kind="covariance";end
if any(study==["study1","p06"])
    values=zeros(1,numel(selected));
    for k=1:numel(selected)
        M=r.(kind)(:,:,selected(k));
        if isEigen
            ev=eig((M+M')/2);
            if endsWith(field,"Min"),values(k)=min(ev);else,values(k)=max(ev);end
        else,values(k)=cond(M);end
    end
    out.recipe="study1_summarize:diagnose_run independently recomputed from each selected saved matrix";
elseif isEigen
    component=1;if endsWith(field,"Max"),component=2;end
    values=r.(kind+"Eigenvalues")(component,selected);
    out.recipe=study+"_summarize: stored eigenvalue history, original selected origins";
else
    values=r.gramCondition(selected);
    out.recipe=study+"_summarize: stored Gram condition history, original valid full windows";
end
assert(~any(isnan(values)),'ejc:DiagnosticSource','A required diagnostic parent is NaN.');
if endsWith(field,"Min"),[value,index]=min(values);else,[value,index]=max(values);end
out.sourceValue=value;out.selectedExtremum=selected(index);out.values=values;
if isEigen,out.parentNorm=norm(r.(kind)(:,:,selected(index)),2);end
end
