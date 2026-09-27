function claim=ejc_apply_claim_scope(strict,rule,a,b,rowA,rowB,c)
%EJC_APPLY_CLAIM_SCOPE Preserve strict raw verdict; change approved inference only.
claim=strict;
% A genuinely asserted scientific direction always retains the generic guard.
if isfield(c,'explicitDirectionalClaim') && c.explicitDirectionalClaim,return;end
scopeA=ejc_claim_scope(rule,rowA);scopeB=ejc_claim_scope(rule,rowB);
assert(isequal(scopeA,scopeB),'ejc:ClaimScope','Cross-machine applicability differs.');
if ~scopeB.applicable,return;end
assert(isfield(c,'parentCache') && isa(c.parentCache,'containers.Map') && ...
 isfield(c,'claimBindingsA') && isfield(c,'claimBindingsB'), ...
 'ejc:ClaimParents','Executed own-source evidence is required.');
% Cross-machine exact keys remain mandatory even when a leaf is checked alone.
keys=["campaign","contrast","metric","auditType","model","modelId","trial", ...
 "fittingTransitions","inputMode","horizon","attemptedPairs","completePairs","finitePairs", ...
 "bootstrapResamples","signConvention","unit","squaredUnit","attemptedCount","validCount", ...
 "invalidCount","allQueriesValid","queryCount","attemptedQueries","finiteQueries","failedQueries"];
keys=keys(ismember(keys,string(rowB.Properties.VariableNames)));
assert(all(ismember(keys,string(rowA.Properties.VariableNames))) && isequaln(rowA(:,keys),rowB(:,keys)), ...
 'ejc:ClaimKeys','Claim source keys, units, masks or memberships differ.');
if string(rule.policy_family)=="P11"
 assert(all(isfinite([rowA.medianDifference,rowA.lower95,rowA.upper95,rowB.medianDifference,rowB.lower95,rowB.upper95])) && ...
 rowA.lower95<=rowA.upper95 && rowB.lower95<=rowB.upper95, ...
 'ejc:ClaimInterval','Required finite, ordered endpoints failed.');
end
current=ejc_claim_parents(rowA,scopeA,c,"current");reference=ejc_claim_parents(rowB,scopeB,c,"reference");
assert(current.passed&&reference.passed,'ejc:ClaimParents','Own-parent validity failed.');
claim=struct('passed',true,'reason',"",'originalStrictVerdict',strict, ...
 'scope',scopeB,'currentParents',current,'referenceParents',reference, ...
 'rawCurrent',a,'rawReference',b,'rawCurrentSign',sign(a),'rawReferenceSign',sign(b), ...
 'postFailureAmendment',true,'policyID',"P07_PORTABLE_20260927_V5", ...
 'statisticalSignificanceAgreementClaimed',false,'fullStudyAndPaperGatesRequired',true);
if scopeB.kind=="STRUCTURAL_NULL_CONTRAST"
 claim.status="NUMERICAL_AGREEMENT_STRUCTURAL_NULL_CONTRAST";
 claim.directionalClaimApplicability="NOT_ASSERTED_FOR_STRUCTURAL_NULL";
else
 claim.status="NUMERICAL_AGREEMENT_SIGN_NOT_ASSERTED";
 claim.directionalClaimApplicability="NOT_ASSERTED";
end
if string(rule.policy_family)=="P11"
 claim.rawCurrentInterval=[rowA.lower95,rowA.upper95];claim.rawReferenceInterval=[rowB.lower95,rowB.upper95];
 claim.rawCurrentContainsZero=rowA.lower95<=0&&rowA.upper95>=0;
 claim.rawReferenceContainsZero=rowB.lower95<=0&&rowB.upper95>=0;
end
end
