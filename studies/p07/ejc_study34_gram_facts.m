function [a,b,checks,detail]=ejc_study34_gram_facts(r,G,R,index,pointRank,condition,study,cfg)
%EJC_STUDY34_GRAM_FACTS Actual local facts for the two named reconstruction sites.
% a is the independently reconstructed value; b is the historical/stored
% reference. This function cannot accept a run: source and completed original
% requirement evidence must still be supplied by the lifecycle adapter.
assert(any(study==["study3","study4"]),'ejc:BindingScope','Unlisted reconstruction context.');
assert(index>=2 && index<=r.nSteps && index==fix(index),'ejc:BindingIndex','Invalid index.');
own=ejc_gram_parent(r,study,cfg,struct('D',r.D),index);
a=ejc_matrix_screen(G,"gram",Regressors=R,StoredCondition=condition, ...
    RequireRank=true,ExpectedRegressorCount=r.gramCount(index));
b=ejc_matrix_screen(r.gram(:,:,index),"gram",Regressors=own, ...
    StoredCondition=r.gramCondition(index),RequireRank=true,ExpectedRegressorCount=r.gramCount(index));
checks=struct;
checks.coordinateDefinitions=isequal(size(G),[r.nEstimated r.nEstimated]) && ...
    isequal(size(own),size(R)) && all(isfinite(r.D)) && all(r.D>0);
checks.matrixAgreement=ejc_acceptance_numeric(G,r.gram(:,:,index),1e-10,1e-7,true(size(G))).passed;
checks.regressorAgreement=ejc_acceptance_numeric(R,own,1e-8,1e-7,true(size(R))).passed;
checks.masksAndSigns=isequal(isnan(condition),isnan(r.gramCondition(index))) && ...
    isequal(isinf(condition),isinf(r.gramCondition(index))) && ...
    (~isinf(condition) || isequal(condition,r.gramCondition(index)));
checks.originalRanks=a.valid && b.valid && isequal(r.gramRank(index),pointRank) && ...
    isequal(pointRank,a.pointThresholdRank) && isequal(pointRank,b.pointThresholdRank);
checks.originalCounts=isequal(size(R,1),min(50,index-1)) && ...
    isequal(r.gramCount(index),size(R,1)) && isequal(size(own,1),size(R,1));
checks.originalFlags=isequal(r.gramValid(index),true);
checks.permittedRankInfinity=checks.originalRanks && pointRank<r.nEstimated && ...
    isequal(condition,Inf) && isequal(r.gramCondition(index),Inf);
if pointRank<r.nEstimated
    checks.originalFlags=checks.originalFlags && checks.permittedRankInfinity;
else
    checks.originalFlags=checks.originalFlags && isfinite(condition) && isfinite(r.gramCondition(index)) && ...
        a.conditionInsideEnvelope && b.conditionInsideEnvelope;
end
checks.spectralAgreement=false;
ownSpectral=false;
if a.valid && b.valid
    checks.spectralAgreement=ejc_acceptance_numeric(sort(a.eigenvalues),sort(b.eigenvalues), ...
        1e-10*max(1,b.norm2),1e-7,true(size(b.eigenvalues))).passed;
    values=sort(b.eigenvalues);
    ownSpectral=ejc_acceptance_numeric(r.gramEigenvalues(:,index),values([1 end]), ...
        1e-10*max(1,b.norm2),1e-7,true(2,1)).passed;
    checks.spectralAgreement=checks.spectralAgreement && ownSpectral;
end
expected=Inf;
if a.valid && pointRank==r.nEstimated
    expected=a.singularValues(1)/a.singularValues(end);
end
checks.coordinateDefinitions=checks.coordinateDefinitions && isequaln(condition,expected) && ...
    isequaln(G,R.'*R/size(R,1));
numeric=ejc_acceptance_numeric(condition,r.gramCondition(index),1e-8,1e-7,true);
detail=struct('index',index,'stored',r.gramCondition(index),'reconstructed',condition, ...
    'ordinaryP6',numeric,'ownSpectralPassed',ownSpectral,'storedRank',r.gramRank(index), ...
    'reconstructedRank',pointRank,'storedCount',r.gramCount(index),'verifierCount',size(R,1), ...
    'storedInterval',[b.rankLower b.rankUpper],'reconstructedInterval',[a.rankLower a.rankUpper], ...
    'storedScreen',b.status,'reconstructedScreen',a.status);
end
