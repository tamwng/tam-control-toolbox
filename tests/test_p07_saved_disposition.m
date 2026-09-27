function tests=test_p07_saved_disposition
tests=functiontests(localfunctions);
end
function setupOnce(t)
root=fileparts(fileparts(mfilename('fullpath')));t.TestData.path=path;t.TestData.root=root;
addpath(root,fullfile(root,'src'),fullfile(root,'studies','p07'));
end
function teardownOnce(t)
path(t.TestData.path);
end
function c=checks
names=["passiveUse","sourceMembership","coordinateDefinitions","matrixAgreement", ...
    "regressorAgreement","spectralAgreement","masksAndSigns","originalRanks", ...
    "originalCounts","originalFlags","outcomes","publicationChecks", ...
    "noRequiredUniqueSupplementalRankClaim"];
c=cell2struct(repmat({true},size(names)),cellstr(names),2);
end
function s=screen(G,R,k)
s=ejc_matrix_screen(G,"gram",Regressors=R,StoredCondition=k,RequireRank=true,ExpectedRegressorCount=size(R,1));
end
function test_exact_zero_and_parent_negatives(t)
s=screen(zeros(2),zeros(1,2),Inf);
verifyEqual(t,s.status,"STRUCTURAL_ZERO_GRAM");verifyEqual(t,[s.pointThresholdRank s.rankLower s.rankUpper],[0 0 0]);
v=ejc_p7_qualify(s,s,"F1614",checks);verifyTrue(t,v.eligibleToAdvance);
verifyEqual(t,v.status,"EXACT_STRUCTURAL_ZERO_GRAM");verifyEqual(t,v.qualifiedCount,0);
for R={ones(1,2),1e-200*ones(1,2),zeros(0,2),zeros(1,3),[NaN 0],[Inf 0],single(zeros(1,2))}
    q=screen(zeros(2),R{1},Inf);verifyFalse(t,q.structuralZero);
end
q=ejc_matrix_screen(zeros(2),"gram",Regressors=zeros(1,2),StoredCondition=Inf,ExpectedRegressorCount=2);
verifyFalse(t,q.valid);
for k=[NaN -Inf 0]
    q=screen(zeros(2),zeros(1,2),k);v=ejc_p7_qualify(s,q,"F1614",checks);verifyFalse(t,v.eligibleToAdvance);
end
q=screen(1e-200*eye(2),sqrt(2e-200)*eye(2),1);
v=ejc_p7_qualify(s,q,"F1614",checks);verifyFalse(t,v.eligibleToAdvance);
for kind=["covariance","hessian"]
    q=ejc_matrix_screen(zeros(2),kind);verifyFalse(t,q.valid || q.structuralZero);
end
end
function test_all_saved_blockers_reclassified_with_own_rows(t)
f=load(fullfile(t.TestData.root,'tests/fixtures/p07_saved_disposition.mat'),'fixtures');
verifyEqual(t,numel(f.fixtures),12);
for k=1:numel(f.fixtures)
    r=f.fixtures(k);s=screen(r.matrix,r.regressors,r.storedCondition);
    if all(r.matrix==0,'all'),expected="STRUCTURAL_ZERO_GRAM";
    else,expected="ELIGIBLE_P7_FULL_RANK_BOUNDARY";end
    verifyEqual(t,s.status,expected,r.case);verifyEqual(t,s.pointThresholdRank,r.pointThresholdRank);
    if ~s.structuralZero,verifyFalse(t,s.rankResolved);verifyTrue(t,isnan(s.thresholdRank));end
end
end
function test_boundary_pairs_and_all_guards(t)
G=diag([1 1e-10]);R=sqrt(2)*diag(sqrt(diag(G)));s=screen(G,R,cond(G));c=checks;
v=ejc_p7_qualify(s,s,"F0069",c);
verifyEqual(t,v.status,"QUALIFIED_PASSIVE_GRAM_BOUNDARY_POINT_RANK_MATCHED");verifyTrue(t,v.rawConditionUnresolved);
for name=string(fieldnames(c)).'
    bad=c;bad.(name)=false;v=ejc_p7_qualify(s,s,"F0069",bad);verifyFalse(t,v.eligibleToAdvance);
end
for scope=["F0070","unknown"]
    v=ejc_p7_qualify(s,s,scope,c);verifyFalse(t,v.eligibleToAdvance);
end
q=screen(G,R,1e15);verifyNotEqual(t,q.status,"ELIGIBLE_P7_FULL_RANK_BOUNDARY");
v=ejc_p7_qualify(q,q,"F0069",c);verifyFalse(t,v.eligibleToAdvance);
G=diag([1 1e-10 1e-10]);q=screen(G,sqrt(3)*diag(sqrt(diag(G))),cond(G));
verifyEqual(t,[q.rankLower q.rankUpper],[1 3]);
v=ejc_p7_qualify(q,q,"F0069",c);verifyFalse(t,v.eligibleToAdvance);
end
function test_point_rank_and_resolved_side(t)
G=diag([1 1e-10*(1-1e-5)]);a=screen(G,sqrt(2)*diag(sqrt(diag(G))),cond(G));
G=diag([1 1e-10*(1+1e-5)]);b=screen(G,sqrt(2)*diag(sqrt(diag(G))),cond(G));
verifyTrue(t,ejc_acceptance_numeric(a.matrix,b.matrix,1e-10,1e-7,true(2)).passed);
verifyNotEqual(t,a.pointThresholdRank,b.pointThresholdRank);
v=ejc_p7_qualify(a,b,"F0069",checks);verifyFalse(t,v.eligibleToAdvance);
a=screen(eye(2),sqrt(2)*eye(2),1);v=ejc_p7_qualify(a,a,"F0069",checks);
verifyEqual(t,v.status,"NUMERICAL_AGREEMENT");verifyEqual(t,v.qualifiedCount,0);
bad=a;bad.storedCondition=2;bad.conditionInsideEnvelope=false;
v=ejc_p7_qualify(bad,bad,"F0069",checks);verifyFalse(t,v.eligibleToAdvance);
end
function test_visible_propagation_and_failed_parent(t)
G=diag([1 1e-10]);s=screen(G,sqrt(2)*diag(sqrt(diag(G))),cond(G));
v=ejc_p7_qualify(s,s,"F0069",checks);
r=ejc_p7_reduce_verdict(1e10,1e10,1:2,1:2,v,true);
verifyTrue(t,r.eligibleToAdvance);verifyFalse(t,r.rawExtremumReproduced);
v=ejc_acceptance_verdict(0,0,r.qualifiedCount);verifyEqual(t,v.status,"PASSED_WITH_GRAM_QUALIFICATIONS");
v=ejc_acceptance_verdict(1,0,r.qualifiedCount);verifyFalse(t,v.eligibleToAdvance);
end
function test_reduction_qualification_preserves_nonfinite_contract(t)
v=struct('eligibleToAdvance',true,'qualifiedCount',1);
for pair={[NaN NaN],[Inf 1],[1 Inf],[-Inf Inf],[-Inf -Inf],[-1 -1]}
    p=pair{1};r=ejc_p7_reduce_verdict(p(1),p(2),1:2,1:2,v,true);
    verifyFalse(t,r.eligibleToAdvance);
end

for pair={[1 2],[Inf Inf]}
    p=pair{1};r=ejc_p7_reduce_verdict(p(1),p(2),1:2,1:2,v,true);
    verifyTrue(t,r.eligibleToAdvance);verifyFalse(t,r.rawExtremumReproduced);
end
r=ejc_p7_reduce_verdict(1,1,1:2,2:3,v,true);verifyFalse(t,r.eligibleToAdvance);
r=ejc_p7_reduce_verdict(1,1,1:2,1:2,v,false);verifyFalse(t,r.eligibleToAdvance);
v.eligibleToAdvance=false;r=ejc_p7_reduce_verdict(1,1,1:2,1:2,v,true);verifyFalse(t,r.eligibleToAdvance);
end
function test_structural_zero_reduction_requires_executed_parent(t)
p=struct('eligibleToAdvance',true,'qualifiedCount',0,'status',"EXACT_STRUCTURAL_ZERO_GRAM", ...
    'rawCurrent',Inf,'rawReference',Inf);
r=ejc_p7_reduce_verdict(Inf,Inf,1,1,p,true);verifyTrue(t,r.eligibleToAdvance);
verifyEqual(t,r.qualifiedCount,0);verifyEqual(t,r.status,"EXACT_STRUCTURAL_ZERO_GRAM_REDUCTION");
p.status="NUMERICAL_AGREEMENT";r=ejc_p7_reduce_verdict(Inf,Inf,1,1,p,true);verifyFalse(t,r.eligibleToAdvance);
p.status="EXACT_STRUCTURAL_ZERO_GRAM";p.rawReference=1;
r=ejc_p7_reduce_verdict(Inf,Inf,1,1,p,true);verifyFalse(t,r.eligibleToAdvance);
end
