function [required,reason]=ejc_mat_applicability(study,file,field,value,parent,record)
%EJC_MAT_APPLICABILITY Explicit saved-producer masks in the original units.
% No numeric value determines its own required/not-applicable status.
study=string(study);file=string(file);field=string(field);
leaf=string(regexp(char(field),'[^.]+$','match','once'));
required=true(size(value));reason="Required finite scientific quantity";
if isempty(value),reason="Exact empty shape; zero applicable elements";return;end
if study=="study6" && file=="constraint_audit.mat" && contains(field,".runs{}")
    study="study2"; % The four original exact own-source Study 2 copies.
end
if isfield(parent,'nSteps') && isfield(parent,'controlAccepted')
    r=parent;n=r.nSteps;K=numel(r.controlAccepted);
    estimated=0;if isfield(r,'nEstimated'),estimated=r.nEstimated;
    elseif isfield(r,'fit'),estimated=r.fit.nEstimated;end
    mask=(1:K)<=n;
    switch leaf
        case {"x","y","u"},mask=(1:K+1)<=n+1;
        case {"plannedInput","plannedOutput","slack","solverResiduals"}
            mask=mask & r.controlAccepted;
        case {"lambda","residual","idResponse","idRegressor"}
            mask=mask & r.idAttempted;
        case "energy"
            mask=mask & r.idAttempted & string(r.forgetting.mode)=="variable";
        case {"covarianceCondition","covarianceEigenvalues"}
            mask=mask & estimated>0;
        case {"gram","gramCondition","gramEigenvalues"}
            mask=mask & (1:K)>1 & estimated>0;
        case "beta"
            if any(study==["study1","study2","p06"]),mask=mask & estimated>0;end
        case {"A","B","c","theta","mappedTheta","mappingDelta","covariance","qpCondition","prediction"}
            % All completed origins require these producer quantities.
        otherwise
            return % Initial values, D and scalar definitions are finite.
    end
    required=broadcast_last(mask,size(value));reason="Original completed origin, accepted plan, identification and estimator-dimension masks";
elseif isfield(parent,'attempted') && isfield(parent,'accepted') && any(leaf==["lambda","residual"])
    required=broadcast_last(parent.attempted,size(value));reason="Original fit attempted-transition mask";
elseif any(leaf==["maxIdentityResidual","maxSquaredIdentityResidual","maxFirstStepFreezingError","maxAffineFreezingError"])
    if isfield(parent,'anchors')
        required(:)=~isempty(parent.anchors);
        reason="Original declared multistep anchor inventory (P06 deliberately has none)";
    end
    if leaf=="maxAffineFreezingError"
        required=required & model_id(study,file,parent,record)=="A";
        reason="Original affine-model-only maximum, and nonempty declared anchor set";
    end
elseif study=="study4" && any(leaf==["parameterError","parameterScaledPercent"])
    assert(isfield(parent,'exactTargetAvailable'),'ejc:Applicability','Missing exact target mask.');
    required=broadcast_last(parent.exactTargetAvailable,size(value));reason="Original exactTargetAvailable mask";
elseif study=="study5" && any(leaf==["oneStepRefinement","refinedStates","forecastRefinement", ...
        "predictorLocalDifference","predictorJacobianDifference","zeroInputDifference"])
    required(:)=ismember(model_id(study,file,parent,record),["I","K"]);
    reason="Original physical-model-only refinement diagnostic";
elseif study=="study6" && leaf=="affineFreezing"
    assert(isfield(record,'out') && isfield(record.out,'meta'),'ejc:Applicability','Missing Study 6 model source.');
    required(:)=string(record.out.meta.modelId)=="A";reason="Original Study 6 affine-model-only check";
elseif study=="study6" && leaf=="archiveComparisonMax"
    required(:)=startsWith(file,["primary/","measurement/"]);
    reason="Original primary/archive and measurement/archive comparison sites only";
elseif study=="p06" && startsWith(field,"value[].scores[].")
    T=struct2table(parent,'AsArray',true);
    tableFile="tables/run_metrics.csv";
    if contains(field,".diagnostics[]."),tableFile="tables/run_diagnostics.csv";
    elseif contains(field,".initialization[]."),tableFile="tables/initialization_scores.csv";end
    [mask,reason]=ejc_csv_applicability("study1",tableFile,leaf,T);
    required(:)=mask;
end
end
function required=broadcast_last(mask,shape)
assert(numel(mask)==shape(end),'ejc:Applicability','Producer mask length does not match the original history axis.');
mask=reshape(logical(mask),[ones(1,numel(shape)-1),numel(mask)]);
required=repmat(mask,[shape(1:end-1),1]);
end
function id=model_id(study,file,parent,record)
id="";
if isfield(parent,'id'),id=string(parent.id);
elseif isfield(record,'result'),id=string(record.result.id);
elseif isfield(record,'fit'),id=string(record.fit.id);
elseif isfield(record,'out'),id=string(record.out.meta.modelId);
else
    [~,name]=fileparts(file);
    if study=="study2" && startsWith(file,"evaluation/"),id=string(name);
    elseif study=="study3" && startsWith(file,"evaluation/")
        token=regexp(char(name),'^evaluation_([AS])_[0-9]{3}$','tokens','once');
        if ~isempty(token),id=string(token{1});end
    elseif study=="study5" && startsWith(file,"evaluation/run_audit_")
        id=extractAfter(string(name),"run_audit_");
    end
end
assert(strlength(id)>0,'ejc:Applicability','The original producer model cannot be identified.');
end
