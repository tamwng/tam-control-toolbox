function R=ejc_gram_parent(r,study,cfg,fit,index)
%EJC_GRAM_PARENT Own saved completed rows in the unchanged scientific coordinates.
assert(index>=2 && index<=r.nSteps && index==fix(index),'ejc:GramRows','Invalid completed-row selection.');
if isfield(r,'fit'),fit=r.fit;end
if isfield(r,'D'),D=r.D;else,D=fit.D;end
if study=="study3",model=study1_model(r.modelId);
elseif study=="study4",model=study4_model(r.id);
elseif study=="study5",model=study5_model(r.id,cfg);
elseif study=="study2",model=study2_model(r.id);
else,model=study1_model(r.id);end
scale=1;if isfield(r,'rowScale'),scale=r.rowScale;end
rows=max(1,index-50):index-1;R=zeros(numel(rows),numel(D));
assert(r.gramCount(index)==numel(rows),'ejc:GramRows','Stored count differs from the completed-row selection.');
for k=1:numel(rows)
    j=rows(k);[~,phi]=model_regression(model,r.y(j),r.y(j+1),r.u(j));
    R(k,:)=(scale*phi)./D.';
end
end
