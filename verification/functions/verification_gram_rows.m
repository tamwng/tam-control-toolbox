function R=verification_gram_rows(r,study,cfg,fit)
%VERIFICATION_GRAM_ROWS Reconstruct each original saved regressor once, in index order.
% Selecting max(1,j-50):j-1 reproduces verification_gram_parent exactly. No cache of a
% previous run or trajectory is used; every row is rebuilt from this record.
if isfield(r,'fit'),fit=r.fit;end
if isfield(r,'D'),D=r.D;else,D=fit.D;end
if study=="study3",model=study1_model(r.modelId);
elseif study=="study4",model=study4_model(r.id);
elseif study=="study5",model=study5_model(r.id,cfg);
elseif study=="study2",model=study2_model(r.id);
else,model=study1_model(r.id);end
scale=1;if isfield(r,'rowScale'),scale=r.rowScale;end
R=zeros(max(0,r.nSteps-1),numel(D));
for j=1:r.nSteps-1
    [~,phi]=model_regression(model,r.y(j),r.y(j+1),r.u(j));
    R(j,:)=(scale*phi)./D.';
end
end
