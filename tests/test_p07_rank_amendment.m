function tests=test_p07_rank_amendment
tests=functiontests(localfunctions);
end
function setupOnce(t)
root=fileparts(fileparts(mfilename('fullpath')));t.TestData.path=path;
t.TestData.root=root;addpath(fullfile(root,'studies','p07'));
end
function teardownOnce(t)
path(t.TestData.path);
end
function [r,c]=boundary_fixture(x)
M=diag([1 x 1e-20]);R=sqrt(3)*diag(sqrt(diag(M)));
r=ejc_matrix_screen(M,"gram",Regressors=R,StoredCondition=cond(M),RequireRank=true);
names=["passiveUse","sourceMembership","coordinateDefinitions","matrixAgreement", ...
    "regressorAgreement","spectralAgreement","masksAndSigns","originalRanks", ...
    "originalCounts","originalFlags","outcomes","publicationChecks", ...
    "noRequiredUniqueSupplementalRankClaim"];
c=cell2struct(repmat({true},size(names)),cellstr(names),2);
end
function test_original_765_and_1067(t)
f=load(fullfile(t.TestData.root,'tests','fixtures','p07_gram_screens.mat'));
s=ejc_matrix_screen(f.G765,"gram",Regressors=f.R765,StoredCondition=f.condition765,RequireRank=true);
verifyTrue(t,s.valid && s.decompositionPassed && s.formationPassed);
verifyEqual(t,s.pointThresholdRank,1);verifyEqual(t,[s.rankLower s.rankUpper],[1 2]);
verifyTrue(t,s.robustlyThresholdDeficient);verifyFalse(t,s.rankResolved);
verifyTrue(t,isnan(s.thresholdRank));verifyFalse(t,s.resolved);
verifyEqual(t,s.status,"ELIGIBLE_P7_UNRESOLVED_INTERMEDIATE_RANK");
for k=1:2
    s=ejc_matrix_screen(f.G1067{k},"gram",Regressors=f.R1067{k},StoredCondition=f.condition1067(k),RequireRank=true);
    verifyTrue(t,s.valid && s.rankResolved);verifyEqual(t,s.thresholdRank,1);
    verifyFalse(t,s.resolved);verifyEqual(t,s.status,"UNRESOLVED_CONDITION");
end
end
function test_interior_boundary_pair(t)
[s,c]=boundary_fixture(1e-10);v=ejc_p7_qualify(s,s,"F0069",c);
verifyEqual(t,s.status,"ELIGIBLE_P7_UNRESOLVED_INTERMEDIATE_RANK");
verifyEqual(t,v.status,"QUALIFIED_WITH_UNRESOLVED_GRAM_RANK_DETAIL");
verifyTrue(t,v.eligibleToAdvance && v.rawConditionUnresolved);verifyEqual(t,v.qualifiedCount,1);
end
function test_full_rank_boundary_disposition(t)
[~,c]=boundary_fixture(1e-10);M=diag([1 1e-10]);R=sqrt(2)*diag(sqrt(diag(M)));
s=ejc_matrix_screen(M,"gram",Regressors=R,StoredCondition=cond(M),RequireRank=true);
verifyEqual(t,s.rankUpper,2);verifyFalse(t,s.robustlyThresholdDeficient);
v=ejc_p7_qualify(s,s,"F0069",c);verifyTrue(t,v.eligibleToAdvance);
verifyEqual(t,v.status,"QUALIFIED_PASSIVE_GRAM_BOUNDARY_POINT_RANK_MATCHED");
end
function test_different_nominal_ranks_block(t)
[a,c]=boundary_fixture(1e-10*(1-1e-5));[b,~]=boundary_fixture(1e-10*(1+1e-5));
verifyTrue(t,a.robustlyThresholdDeficient && b.robustlyThresholdDeficient);
verifyNotEqual(t,a.pointThresholdRank,b.pointThresholdRank);
verifyTrue(t,ejc_acceptance_numeric(a.matrix,b.matrix,1e-10,1e-7,true(3)).passed);
v=ejc_p7_qualify(a,b,"F0069",c);verifyFalse(t,v.eligibleToAdvance);
end
function test_every_mandatory_prerequisite(t)
[s,c]=boundary_fixture(1e-10);
for name=string(fieldnames(c)).'
    bad=c;bad.(name)=false;v=ejc_p7_qualify(s,s,"F0069",bad);verifyFalse(t,v.eligibleToAdvance);
    bad=rmfield(c,name);v=ejc_p7_qualify(s,s,"F0069",bad);verifyFalse(t,v.eligibleToAdvance);
end
end
function test_scope_and_matrix_negatives(t)
[s,c]=boundary_fixture(1e-10);
for scope=["F0070","covarianceCondition","qpCondition",""]
    v=ejc_p7_qualify(s,s,scope,c);verifyFalse(t,v.eligibleToAdvance);
end
for name=["valid","decompositionPassed","formationPassed"]
    bad=s;bad.(name)=false;v=ejc_p7_qualify(s,bad,"F0069",c);verifyFalse(t,v.eligibleToAdvance);
end
for kind=["covariance","hessian"]
    bad=s;bad.kind=kind;v=ejc_p7_qualify(bad,bad,"F0069",c);verifyFalse(t,v.eligibleToAdvance);
end
for value=[NaN Inf -Inf]
    bad=s;bad.storedCondition=value;v=ejc_p7_qualify(bad,bad,"F0069",c);verifyFalse(t,v.eligibleToAdvance);
end
bad=s;bad.zeroMatrix=true;v=ejc_p7_qualify(bad,bad,"F0069",c);verifyFalse(t,v.eligibleToAdvance);
bad=s;bad.resolved=true;bad.conditionInsideEnvelope=false;
v=ejc_p7_qualify(bad,bad,"F0069",c);verifyFalse(t,v.eligibleToAdvance);
bad=rmfield(s,'rankUpper');v=ejc_p7_qualify(s,bad,"F0069",c);verifyFalse(t,v.eligibleToAdvance);
bad=s;bad.dimension=2;v=ejc_p7_qualify(s,bad,"F0069",c);verifyFalse(t,v.eligibleToAdvance);
end
function test_parent_campaign_and_reducer(t)
[s,c]=boundary_fixture(1e-10);v=ejc_p7_qualify(s,s,"F0069",c);
for counts={[1 0 1],[0 1 1]}
    x=counts{1};p=ejc_acceptance_verdict(x(1),x(2),x(3));verifyFalse(t,p.eligibleToAdvance);
end
p=ejc_acceptance_verdict(0,0,v.qualifiedCount);
verifyEqual(t,p.status,"PASSED_WITH_GRAM_QUALIFICATIONS");verifyTrue(t,p.eligibleToAdvance);
z=ejc_p7_reduce_verdict(1e20,2e20,1:3,1:3,v,true);
verifyTrue(t,z.eligibleToAdvance);verifyFalse(t,z.rawExtremumReproduced);
verifyEqual(t,z.rawCurrent,1e20);verifyEqual(t,z.rawReference,2e20);
z=ejc_p7_reduce_verdict(1e20,2e20,1:3,2:4,v,true);verifyFalse(t,z.eligibleToAdvance);
z=ejc_p7_reduce_verdict(1e20,2e20,1:3,1:3,v,false);verifyFalse(t,z.eligibleToAdvance);
end
