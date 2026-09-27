function tests=test_p07_study34_binding
tests=functiontests(localfunctions);
end
function setupOnce(t)
root=fileparts(fileparts(mfilename('fullpath')));t.TestData.root=root;t.TestData.path=path;
addpath(root,fullfile(root,'src'),fullfile(root,'studies/p07'));
for k=1:4,addpath(fullfile(root,'studies',sprintf('study%d',k)));end
z=load(fullfile(root,'tests/fixtures/p07_study34_binding.mat'),'fixtures');t.TestData.fixtures=z.fixtures;
end
function teardownOnce(t)
path(t.TestData.path);
end
function [a,b,c,d,r,f,cfg]=facts(t,k)
f=t.TestData.fixtures{k};refs=ejc_reference_sources;
z=load(fullfile(refs.(f.case.study),'runs',f.case.case),'result');r=z.result;
z=load(fullfile(refs.(f.case.study),'settings.mat'),'cfg');cfg=z.cfg;
[a,b,c,d]=ejc_study34_gram_facts(r,f.verifierGram,f.verifierRegressors, ...
    f.case.index,f.case.recomputedRank,f.case.recomputedCondition,f.case.study,cfg);
end
function c=synthetic_global_guards(c)
% Unit-test witness only. Production obtains these facts only after the
% complete original verifier and policy/checker/source identity checks.
c.passiveUse=true;c.sourceMembership=true;c.outcomes=true;
c.publicationChecks=true;c.noRequiredUniqueSupplementalRankClaim=true;
end
function test_three_saved_cases_and_p6_distinction(t)
for k=1:numel(t.TestData.fixtures)
    [a,b,c,d,~,f]=facts(t,k);v=ejc_p7_qualify(a,b,"F0894",c);
    verifyFalse(t,v.eligibleToAdvance,'Local matrix facts cannot stand in for the complete original checks.');
    c=synthetic_global_guards(c);scope="F0894";if f.case.study=="study4",scope="F1344";end
    v=ejc_p7_qualify(a,b,scope,c);verifyTrue(t,v.eligibleToAdvance,v.reason);
    verifyFalse(t,f.case.conditionPassed);
    if f.case.index==54
        verifyTrue(t,d.ordinaryP6.passed);verifyEqual(t,v.status,"NUMERICAL_AGREEMENT");
    else
        verifyFalse(t,d.ordinaryP6.passed);verifyEqual(t,v.qualifiedCount,1);
        verifyTrue(t,v.rawConditionUnresolved);verifyNotEqual(t,v.status,"NUMERICAL_AGREEMENT");
    end
end
end
function test_resolved_p6_mismatch_is_not_qualified(t)
G=diag([1 1e-4]);R=sqrt(2)*diag(sqrt(diag(G)));
b=ejc_matrix_screen(G,"gram",Regressors=R,StoredCondition=cond(G),RequireRank=true);
G=diag([1 1e-4*(1+2e-7)]);R=sqrt(2)*diag(sqrt(diag(G)));
a=ejc_matrix_screen(G,"gram",Regressors=R,StoredCondition=cond(G),RequireRank=true);
[~,~,c]=facts(t,1);c=synthetic_global_guards(c);
verifyTrue(t,a.resolved && b.resolved && a.conditionInsideEnvelope && b.conditionInsideEnvelope);
verifyTrue(t,ejc_acceptance_numeric(a.matrix,b.matrix,1e-10,1e-7,true(2)).passed);
v=ejc_p7_qualify(a,b,"F0894",c);verifyFalse(t,v.eligibleToAdvance);
end
function test_each_required_check_and_parent_failure(t)
[a,b,c]=facts(t,3);c=synthetic_global_guards(c);
for field=["passiveUse","sourceMembership","coordinateDefinitions","matrixAgreement", ...
        "regressorAgreement","spectralAgreement","masksAndSigns","originalRanks", ...
        "originalCounts","originalFlags","outcomes","publicationChecks", ...
        "noRequiredUniqueSupplementalRankClaim"]
    missing=rmfield(c,field);v=ejc_p7_qualify(a,b,"F0894",missing);verifyFalse(t,v.eligibleToAdvance);
    bad=c;bad.(field)=false;v=ejc_p7_qualify(a,b,"F0894",bad);verifyFalse(t,v.eligibleToAdvance);
end
for field=["valid","formationPassed","decompositionPassed"]
    bad=a;bad.(field)=false;v=ejc_p7_qualify(bad,b,"F0894",c);verifyFalse(t,v.eligibleToAdvance);
end
for value=[NaN Inf -Inf]
    bad=a;bad.storedCondition=value;v=ejc_p7_qualify(bad,b,"F0894",c);verifyFalse(t,v.eligibleToAdvance);
end
for scope=["F0070","covarianceCondition","qpCondition"]
    v=ejc_p7_qualify(a,b,scope,c);verifyFalse(t,v.eligibleToAdvance);
end
for kind=["covariance","hessian"]
    bad=a;bad.kind=kind;v=ejc_p7_qualify(bad,b,"F0894",c);verifyFalse(t,v.eligibleToAdvance);
end
end
function test_original_row_rank_validity_and_condition_facts(t)
[~,~,~,~,r,f,cfg]=facts(t,1);j=f.case.index;
for field=["gramRank","gramValid"]
    bad=r;
    if field=="gramRank",bad.(field)(j)=2;else,bad.(field)(j)=false;end
    [a,b,c]=ejc_study34_gram_facts(bad,f.verifierGram,f.verifierRegressors,j, ...
        f.case.recomputedRank,f.case.recomputedCondition,f.case.study,cfg);
    v=ejc_p7_qualify(a,b,"F0894",synthetic_global_guards(c));verifyFalse(t,v.eligibleToAdvance);
end
bad=r;bad.gramCount(j)=49;
verifyError(t,@()ejc_study34_gram_facts(bad,f.verifierGram,f.verifierRegressors,j, ...
    f.case.recomputedRank,f.case.recomputedCondition,f.case.study,cfg),'ejc:GramRows');
R=f.verifierRegressors;R(1,2)=R(1,2)+1;
[a,b,c]=ejc_study34_gram_facts(r,f.verifierGram,R,j,f.case.recomputedRank, ...
    f.case.recomputedCondition,f.case.study,cfg);
v=ejc_p7_qualify(a,b,"F0894",synthetic_global_guards(c));verifyFalse(t,v.eligibleToAdvance);
[a,b,c]=ejc_study34_gram_facts(r,f.verifierGram,f.verifierRegressors,j,f.case.recomputedRank, ...
    f.case.recomputedCondition*2,f.case.study,cfg);
v=ejc_p7_qualify(a,b,"F0894",synthetic_global_guards(c));verifyFalse(t,v.eligibleToAdvance);
[~,~,~,~,r,f,cfg]=facts(t,3);j=f.case.index;r.gramCondition(j)=2*r.gramCondition(j);
[a,b,c]=ejc_study34_gram_facts(r,f.verifierGram,f.verifierRegressors,j,f.case.recomputedRank, ...
    f.case.recomputedCondition,f.case.study,cfg);
verifyFalse(t,b.resolved);verifyFalse(t,b.conditionInsideEnvelope);
v=ejc_p7_qualify(a,b,"F0894",synthetic_global_guards(c));verifyFalse(t,v.eligibleToAdvance);
end
function test_default_strict_path_and_post_hook_scientific_assertions(t)
refs=ejc_reference_sources;
for study=["study3","study4"]
    z=load(fullfile(refs.(study),'settings.mat'),'cfg');f=str2func(study+"_verify_results");
    verifyError(t,@()f(refs.(study),z.cfg),'MATLAB:assertion:failed');
    verifyError(t,@()f(refs.(study),z.cfg,[]),'MATLAB:assertion:failed');
    called=false;injected=false;failure=[];
    try,f(refs.(study),z.cfg,@corrupt_after_comparison);catch e,failure=e;end
    verifyTrue(t,called && injected);verifyNotEmpty(t,failure);
    verifyEqual(t,failure.identifier,'MATLAB:assertion:failed');
    % Injection changes only a caller's in-memory r. No archive write occurs.
end
    function corrupt_after_comparison(r,~,~,j,~,~,~)
        called=true;
        if study=="study3" && j==54
            r.prediction(j)=r.prediction(j)+1;injected=true;assignin('caller','r',r);
        elseif study=="study4" && j==61
            r.A(j)=r.A(j)+1;injected=true;assignin('caller','r',r);
        end
    end
end
function test_original_evidence_is_mandatory(t)
folder=t.applyFixture(matlab.unittest.fixtures.TemporaryFolderFixture);
e=struct('study',"study3",'originalRequirementsCompleted',false,'status',"FAILED_ORIGINAL_REQUIREMENT");
verifyError(t,@()ejc_study34_bind(e,struct,fullfile(folder.Folder,'missing')), ...
    'ejc:MissingOriginalChecks');
end
