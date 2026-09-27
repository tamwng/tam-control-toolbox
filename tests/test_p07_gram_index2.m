function tests=test_p07_gram_index2
tests=functiontests(localfunctions);
end
function setupOnce(t)
root=fileparts(fileparts(mfilename('fullpath')));t.TestData.path=path;
addpath(fullfile(root,'studies/p07'));
z=load(fullfile(root,'tests/fixtures/p07_gram_index2.mat'),'fixture');t.TestData.fixture=z.fixture;
end
function teardownOnce(t)
path(t.TestData.path);
end
function [a,b,c]=pair(t)
f=t.TestData.fixture;s=f.sides;
a=ejc_matrix_screen(s{1}.gram,"gram",Regressors=s{1}.regressors, ...
 StoredCondition=s{1}.storedCondition,RequireRank=true,ExpectedRegressorCount=s{1}.gramCount);
b=ejc_matrix_screen(s{2}.gram,"gram",Regressors=s{2}.regressors, ...
 StoredCondition=s{2}.storedCondition,RequireRank=true,ExpectedRegressorCount=s{2}.gramCount);
c=f.checks;c.rawConditionOrigin="study1_trajectory:spectrum:cond";
end
function test_exact_saved_pair_uses_approved_passive_rule(t)
[a,b,c]=pair(t);f=t.TestData.fixture;
for k=1:2
 s=f.sides{k};verifyEqual(t,s.gram,diag([1 0 0]));verifyEqual(t,s.regressors,[1 0 0]);
 verifyEqual(t,s.storedCondition,Inf);verifyFalse(t,s.hasOriginalGramRank);
 verifyFalse(t,s.hasOriginalGramValid);verifyEqual(t,s.gramCount,1);
end
verifyEqual(t,a.defaultRank,1);verifyEqual(t,b.pointThresholdRank,1);
verifyEqual(t,[a.rankLower a.rankUpper b.rankLower b.rankUpper],[1 1 1 1]);
v=ejc_p7_qualify(a,b,"F3914",c);
verifyTrue(t,v.eligibleToAdvance,v.reason);
verifyEqual(t,v.status,"QUALIFIED_WITH_UNRESOLVED_GRAM_DIAGNOSTIC");
verifyTrue(t,v.rawConditionUnresolved);verifyEqual(t,v.qualifiedCount,1);
end
function test_mask_sign_nan_and_required_numeric_negatives(t)
[a,b,c]=pair(t);
for x=[NaN -Inf 1e16]
 bad=b;bad.storedCondition=x;
 v=ejc_p7_qualify(a,bad,"F3914",c);verifyFalse(t,v.eligibleToAdvance);
end
for x=[NaN -Inf]
 bad=a;bad.storedCondition=x;
 v=ejc_p7_qualify(bad,bad,"F3914",c);verifyFalse(t,v.eligibleToAdvance);
end
v=ejc_acceptance_numeric(Inf,Inf,1e-8,1e-7,true);verifyFalse(t,v.passed);
end
function test_injected_infinity_without_singular_source_blocks(t)
[~,~,c]=pair(t);M=diag([1 1e-20 1e-25]);R=sqrt(3)*diag(sqrt(diag(M)));
a=ejc_matrix_screen(M,"gram",Regressors=R,StoredCondition=Inf,RequireRank=true);
verifyTrue(t,a.valid && a.rankResolved && ~a.resolved);
v=ejc_p7_qualify(a,a,"F3914",c);verifyFalse(t,v.eligibleToAdvance);
end
function test_missing_provenance_or_failed_parent_blocks(t)
[a,b,c]=pair(t);
for name=["sourceMembership","matrixAgreement","regressorAgreement","spectralAgreement", ...
 "originalRanks","originalCounts","originalFlags","outcomes"]
 bad=c;bad.(name)=false;v=ejc_p7_qualify(a,b,"F3914",bad);verifyFalse(t,v.eligibleToAdvance);
end
bad=rmfield(c,'rawConditionOrigin');v=ejc_p7_qualify(a,b,"F3914",bad);verifyFalse(t,v.eligibleToAdvance);
bad=c;bad.rawConditionOrigin="unknown";v=ejc_p7_qualify(a,b,"F3914",bad);verifyFalse(t,v.eligibleToAdvance);
for name=["valid","formationPassed","decompositionPassed"]
 bad=b;bad.(name)=false;v=ejc_p7_qualify(a,bad,"F3914",c);verifyFalse(t,v.eligibleToAdvance);
end
end
function test_rank_scope_and_covariance_hessian_do_not_inherit_qualification(t)
[a,b,c]=pair(t);
bad=b;bad.pointThresholdRank=2;v=ejc_p7_qualify(a,bad,"F3914",c);verifyFalse(t,v.eligibleToAdvance);
for scope=["F0070","covarianceCondition","qpCondition"]
 v=ejc_p7_qualify(a,b,scope,c);verifyFalse(t,v.eligibleToAdvance);
end
for kind=["covariance","hessian"]
 bad=a;bad.kind=kind;v=ejc_p7_qualify(bad,bad,"F3914",c);verifyFalse(t,v.eligibleToAdvance);
end
end
