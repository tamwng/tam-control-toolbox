function tests=test_p07_study34_binding
tests=functiontests(localfunctions);
end
function setupOnce(t)
root=fileparts(fileparts(mfilename('fullpath')));t.TestData.root=root;t.TestData.path=path;
addpath(root,fullfile(root,'src'),fullfile(root,'studies/p07'));
for k=1:4,addpath(fullfile(root,'studies',sprintf('study%d',k)));end
z=load(fullfile(root,'tests/fixtures/p07_study34_binding.mat'),'fixtures');t.TestData.fixtures=z.fixtures;
t.TestData.fixtureHash=ejc_file_sha256(fullfile(root,'tests/fixtures/p07_study34_binding.mat'));
assertEqual(t,t.TestData.fixtureHash,'d9c0472d582283a35806fcf056af867ee9832329c4048bbb403d9bbbad6264ad');
t.TestData.refs=ejc_reference_sources;
out=getenv('P07_W2_REPAIR_EVIDENCE');
if isempty(out),f=t.applyFixture(matlab.unittest.fixtures.TemporaryFolderFixture);out=fullfile(f.Folder,'evidence');end
assert(~isfolder(out),'test:ExistingEvidence');mkdir(out);t.TestData.output=out;
% Complete the real unchanged non-hook requirements and same-record binding.
% These measured outcomes replace the former unconditional global booleans.
for study=["study3","study4"]
 source=t.TestData.refs.(study);z=load(fullfile(source,'settings.mat'),'cfg');
 e=ejc_study34_extract(study,source,z.cfg,fullfile(out,study,'original'));
 assertTrue(t,e.originalRequirementsCompleted && e.status=="ORIGINAL_REQUIREMENTS_EXECUTED_PORTABLE_PENDING",e.exception);
 p=ejc_study34_bind(e,z.cfg,fullfile(out,study,'binding'));
 assertTrue(t,p.passed && p.failed==0,p.status);
 t.TestData.context.(study)=struct('extracted',e,'binding',p,'cfg',z.cfg);
end
t.TestData.sourceProof=ejc_claim_source_guard(root);
record(t,'positive_original_requirements',struct('study3',t.TestData.context.study3.binding,'study4',t.TestData.context.study4.binding));
end
function teardownOnce(t)
verifyEqual(t,ejc_file_sha256(fullfile(t.TestData.root,'tests/fixtures/p07_study34_binding.mat')),t.TestData.fixtureHash);
for study=["study3","study4"]
 e=t.TestData.context.(study).extracted;
 for row=e.inputManifest.'
  verifyEqual(t,ejc_file_sha256(row.path),char(row.sha256));
 end
end
path(t.TestData.path);
end
function [a,b,c,d,r,f,cfg,G,R,rankValue,condition,scope]=facts(t,k)
f=t.TestData.fixtures{k};source=fullfile(t.TestData.refs.(f.case.study),'runs',f.case.case);
z=load(source,'result');r=z.result;cfg=t.TestData.context.(f.case.study).cfg;
bind_fixture(t,f,r,cfg,source);
R=f.verifierRegressors;G=R.'*R/size(R,1);s=svd(G);
rankValue=nnz(s>1e-10*s(1));condition=Inf;
if rankValue==size(G,1),condition=s(1)/s(end);end
[a,b,c,d]=ejc_study34_gram_facts(r,G,R,f.case.index,rankValue,condition,f.case.study,cfg);
[c,scope]=global_checks(t,c,f.case.study,source,r);
end
function bind_fixture(t,f,r,cfg,source)
j=f.case.index;own=ejc_gram_parent(r,f.case.study,cfg,struct('D',r.D),j);
assertEqual(t,fullfile(t.TestData.refs.(f.case.study),'runs',f.case.case),source);
assertEqual(t,f.storedGram,r.gram(:,:,j));assertEqual(t,f.D,r.D);
assertEqual(t,string(f.storedConditionHex),string(num2hex(r.gramCondition(j))));
assertEqual(t,f.storedScreen.storedCondition,r.gramCondition(j));
assertEqual(t,string(f.recomputedConditionHex),string(num2hex(f.case.recomputedCondition)));
assertEqual(t,f.producerRegressors,own);assertEqual(t,f.verifierRegressors,own);
assertEqual(t,f.case.recomputedRank,r.gramRank(j));
e=t.TestData.context.(f.case.study).extracted;
row=e.inputManifest(string({e.inputManifest.path})==string(source));assertEqual(t,numel(row),1);
assertEqual(t,ejc_file_sha256(source),char(row.sha256));
end
function [c,scope]=global_checks(t,c,study,source,r)
scope="F0894";if study=="study4",scope="F1344";end
rule=ejc_rule_lookup(study,"runs/case.mat","value[].result[].gramCondition","double");
science=dir(fullfile(t.TestData.root,'src','**','*.m'));
passive=all(arrayfun(@(f)~contains(fileread(fullfile(f.folder,f.name)),'gramCondition'),science));
e=t.TestData.context.(study).extracted;p=t.TestData.context.(study).binding;
rows=e.inputManifest(string({e.inputManifest.path})==string(source));
sourceOK=isscalar(rows) && strcmp(ejc_file_sha256(source),rows.sha256);
if sourceOK,z=load(source,'result');sourceOK=isequaln(z.result,r);end
c.passiveUse=passive && rule.coverage_id==scope && rule.policy_family=="P7";
c.sourceMembership=sourceOK && startsWith(string(source),string(fullfile(t.TestData.refs.(study),'runs'))+filesep);
c.outcomes=e.originalRequirementsCompleted && p.passed && p.failed==0 && c.sourceMembership;
c.publicationChecks=c.outcomes && c.originalRanks && c.originalCounts && c.originalFlags;
c.noRequiredUniqueSupplementalRankClaim=c.passiveUse;
end
function v=positive(t,a,b,c,scope)
required=["passiveUse","sourceMembership","coordinateDefinitions","matrixAgreement","regressorAgreement", ...
 "spectralAgreement","masksAndSigns","originalRanks","originalCounts","originalFlags","outcomes","publicationChecks","noRequiredUniqueSupplementalRankClaim"];
for field=required,assertTrue(t,c.(field),"Positive guard: "+field);end
v=ejc_p7_qualify(a,b,scope,c);assertTrue(t,v.eligibleToAdvance,v.reason);
end
function test_three_saved_cases_and_p6_distinction(t)
rows=struct([]);
for k=1:numel(t.TestData.fixtures)
 [a,b,c,d,~,f,~,G,R,rankValue,condition,scope]=facts(t,k);v=positive(t,a,b,c,scope);
 assertTrue(t,c.coordinateDefinitions);assertEqual(t,G,R.'*R/size(R,1));
 s=svd(G);assertEqual(t,condition,s(1)/s(end));assertEqual(t,rankValue,nnz(s>1e-10*s(1)));
 % The imported numerical pair has its own immutable historical purpose.
 old=ejc_acceptance_numeric(f.case.recomputedCondition,f.storedScreen.storedCondition,1e-8,1e-7,true);
 verifyEqual(t,old.passed,f.case.index==54);verifyFalse(t,f.case.conditionPassed);
 strictTolerance=1e-12;if f.case.study=="study4",strictTolerance=1e-6;end
 oldStrictDifference=abs(f.case.recomputedCondition-f.storedScreen.storedCondition);
 oldStrictBound=strictTolerance*max(1,abs(f.case.recomputedCondition));
 verifyGreaterThan(t,oldStrictDifference,oldStrictBound);
 rows=[rows;struct('index',f.case.index,'scope',scope,'historicalP6Passed',old.passed,'historicalP6Ratio',old.maximumBoundRatio, ...
  'historicalStrictDifference',oldStrictDifference,'historicalStrictBound',oldStrictBound, ...
  'historicalStoredHex',f.storedConditionHex,'historicalReconstructedHex',f.recomputedConditionHex, ...
  'nativeP6Passed',d.ordinaryP6.passed,'nativeP6Ratio',d.ordinaryP6.maximumBoundRatio,'nativeStatus',v.status, ...
  'nativeQualifiedCount',v.qualifiedCount,'nativeConditionHex',num2hex(condition),'allGuards',c)]; %#ok<AGROW>
end
record(t,'historical_pairs_and_native_tuples',rows);
end
function test_resolved_agreement_and_unresolved_qualification(t)
[a,b,c,~,~,~,~,~,~,~,~,scope]=facts(t,1);v=positive(t,a,b,c,scope);
verifyTrue(t,a.resolved && b.resolved);verifyEqual(t,v.status,"NUMERICAL_AGREEMENT");verifyFalse(t,v.rawConditionUnresolved);
[a,b,c,~,~,~,~,~,~,~,~,scope]=facts(t,3);v=positive(t,a,b,c,scope);
verifyFalse(t,a.resolved || b.resolved);verifyTrue(t,a.rankResolved && b.rankResolved);
verifyEqual(t,v.status,"QUALIFIED_WITH_UNRESOLVED_GRAM_DIAGNOSTIC");verifyEqual(t,v.qualifiedCount,1);verifyTrue(t,v.rawConditionUnresolved);
record(t,'definition_bound_branches',struct('resolved',"NUMERICAL_AGREEMENT",'unresolved',v));
end
function test_resolved_p6_mismatch_is_not_qualified(t)
[a,b,c,~,r,f,cfg,~,R,~,~,scope]=facts(t,1);positive(t,a,b,c,scope);
% Perturb the least energetic native row direction. Existing parent limits
% must independently pass; only the resolved scalar bound may reject.
[~,~,V]=svd(R,0);scale=eye(size(R,2));scale(end,end)=1+1e-7;
R2=R*V*scale*V.';G2=R2.'*R2/size(R2,1);s=svd(G2);rank2=nnz(s>1e-10*s(1));condition2=s(1)/s(end);
[aa,bb,cc,d]=ejc_study34_gram_facts(r,G2,R2,f.case.index,rank2,condition2,f.case.study,cfg);
[cc,~]=global_checks(t,cc,f.case.study,fullfile(t.TestData.refs.(f.case.study),'runs',f.case.case),r);
for field=string(fieldnames(cc)).'
 if field~="permittedRankInfinity",assertTrue(t,cc.(field),"Independent mismatch parent: "+field);end
end
assertTrue(t,aa.resolved && bb.resolved && aa.conditionInsideEnvelope && bb.conditionInsideEnvelope);
assertFalse(t,d.ordinaryP6.passed);v=ejc_p7_qualify(aa,bb,scope,cc);
verifyFalse(t,v.eligibleToAdvance);verifyEqual(t,v.qualifiedCount,0);verifyEqual(t,v.reason,d.ordinaryP6.reason);
record(t,'resolved_mismatch',struct('positive',c,'negativeParents',cc,'numeric',d.ordinaryP6,'verdict',v));
end
function test_each_required_check_and_parent_failure(t)
[a,b,c,~,~,~,~,~,~,~,~,scope]=facts(t,3);events=struct([]);
for field=["passiveUse","sourceMembership","coordinateDefinitions","matrixAgreement","regressorAgreement","spectralAgreement", ...
 "masksAndSigns","originalRanks","originalCounts","originalFlags","outcomes","publicationChecks","noRequiredUniqueSupplementalRankClaim"]
 for mode=["missing","false"]
  positive(t,a,b,c,scope);bad=c;if mode=="missing",bad=rmfield(bad,field);else,bad.(field)=false;end
  v=ejc_p7_qualify(a,b,scope,bad);verifyFalse(t,v.eligibleToAdvance);
  verifyEqual(t,v.reason,"Mandatory prerequisite failed or missing: "+field);
  events=[events;struct('guard',field,'mutation',mode,'reason',v.reason)]; %#ok<AGROW>
 end
end
for field=["valid","formationPassed","decompositionPassed"]
 positive(t,a,b,c,scope);bad=a;bad.(field)=false;v=ejc_p7_qualify(bad,b,scope,c);
 verifyFalse(t,v.eligibleToAdvance);verifyEqual(t,v.reason,"Invalid or non-Gram parent");
end
record(t,'independent_required_guard_negatives',events);
end
function test_invalid_parent_values_scopes_and_dimensions(t)
[a,b,c,~,~,~,~,~,~,~,~,scope]=facts(t,3);
for value=[NaN Inf -Inf]
 positive(t,a,b,c,scope);badMatrix=a.matrix;badMatrix(1,1)=value;
 invalid=ejc_matrix_screen(badMatrix,"gram",Regressors=zeros(50,a.dimension),StoredCondition=a.storedCondition,RequireRank=true);
 verifyFalse(t,invalid.valid);verifyEqual(t,invalid.status,"FAILED_MATRIX_VALIDITY");
 v=ejc_p7_qualify(invalid,b,scope,c);verifyFalse(t,v.eligibleToAdvance);
end
for value=[NaN Inf -Inf]
 positive(t,a,b,c,scope);bad=a;bad.storedCondition=value;v=ejc_p7_qualify(bad,b,scope,c);
 verifyFalse(t,v.eligibleToAdvance);verifyEqual(t,v.reason,"Prohibited raw-condition values or masks");
end
for wrong=["F0070","covarianceCondition","qpCondition"]
 positive(t,a,b,c,scope);v=ejc_p7_qualify(a,b,wrong,c);verifyFalse(t,v.eligibleToAdvance);
 verifyEqual(t,v.reason,"Outside the unchanged 19 passive Gram-condition scopes");
end
for kind=["covariance","hessian"]
 positive(t,a,b,c,scope);bad=a;bad.kind=kind;v=ejc_p7_qualify(bad,b,scope,c);
 verifyFalse(t,v.eligibleToAdvance);verifyEqual(t,v.reason,"Invalid or non-Gram parent");
end
positive(t,a,b,c,scope);bad=a;bad.dimension=bad.dimension+1;
v=ejc_p7_qualify(bad,b,scope,c);verifyEqual(t,v.reason,"Invalid or non-Gram parent");verifyFalse(t,v.eligibleToAdvance);
positive(t,a,b,c,scope);bad=rmfield(a,'formationPassed');v=ejc_p7_qualify(bad,b,scope,c);verifyFalse(t,v.eligibleToAdvance);
positive(t,a,b,c,scope);bad=a;bad.pointThresholdRank=bad.pointThresholdRank-1;
v=ejc_p7_qualify(bad,b,scope,c);verifyFalse(t,v.eligibleToAdvance);verifyEqual(t,v.reason,"Point ranks differ or supplementary rank intervals do not overlap");
positive(t,a,b,c,scope);bad=a;bad.rankLower=b.rankUpper+1;
v=ejc_p7_qualify(bad,b,scope,c);verifyFalse(t,v.eligibleToAdvance);verifyEqual(t,v.reason,"Point ranks differ or supplementary rank intervals do not overlap");
end
function test_original_row_rank_validity_and_condition_facts(t)
[a,b,c,~,r,f,cfg,G,R,rankValue,condition,scope]=facts(t,1);j=f.case.index;
for field=["gramRank","gramValid"]
 positive(t,a,b,c,scope);bad=r;if field=="gramRank",bad.(field)(j)=2;else,bad.(field)(j)=false;end
 [aa,bb,cc]=ejc_study34_gram_facts(bad,G,R,j,rankValue,condition,f.case.study,cfg);
 % Only local guards are under test; complete global facts remain those
 % independently verified for the positive record before this mutation.
 cc=with_global(cc,c);v=ejc_p7_qualify(aa,bb,scope,cc);verifyFalse(t,v.eligibleToAdvance);
 if field=="gramRank",verifyFalse(t,cc.originalRanks);else,verifyFalse(t,cc.originalFlags);end
end
positive(t,a,b,c,scope);bad=r;bad.gramCount(j)=49;
verifyError(t,@()ejc_study34_gram_facts(bad,G,R,j,rankValue,condition,f.case.study,cfg),'ejc:GramRows');
[a,b,c,~,r,f,cfg,G,R,rankValue,condition,scope]=facts(t,3);positive(t,a,b,c,scope);
r.gramCondition(f.case.index)=2*r.gramCondition(f.case.index);
[aa,bb,cc]=ejc_study34_gram_facts(r,G,R,f.case.index,rankValue,condition,f.case.study,cfg);
verifyFalse(t,bb.resolved);verifyFalse(t,bb.conditionInsideEnvelope);cc=with_global(cc,c);
v=ejc_p7_qualify(aa,bb,scope,cc);verifyFalse(t,v.eligibleToAdvance);verifyFalse(t,cc.originalFlags);
end
function test_native_provenance_faults_from_positive_control(t)
[a,b,c,~,r,f,cfg,G,R,rankValue,condition,scope]=facts(t,1);j=f.case.index;
positive(t,a,b,c,scope);badR=R;badR(1,2)=badR(1,2)+1;
[aa,bb,cc]=ejc_study34_gram_facts(r,G,badR,j,rankValue,condition,f.case.study,cfg);
verifyFalse(t,cc.coordinateDefinitions);verifyFalse(t,cc.regressorAgreement);
v=ejc_p7_qualify(aa,bb,scope,with_global(cc,c));verifyFalse(t,v.eligibleToAdvance);
positive(t,a,b,c,scope);
[aa,bb,cc]=ejc_study34_gram_facts(r,G,R,j,rankValue,2*condition,f.case.study,cfg);
verifyFalse(t,cc.coordinateDefinitions);v=ejc_p7_qualify(aa,bb,scope,with_global(cc,c));verifyFalse(t,v.eligibleToAdvance);
positive(t,a,b,c,scope);badG=G;badG(1,1)=badG(1,1)+1;
[aa,bb,cc]=ejc_study34_gram_facts(r,badG,R,j,rankValue,condition,f.case.study,cfg);
verifyFalse(t,cc.coordinateDefinitions);verifyFalse(t,cc.matrixAgreement);
v=ejc_p7_qualify(aa,bb,scope,with_global(cc,c));verifyFalse(t,v.eligibleToAdvance);
end
function test_fixture_source_binding_negatives(t)
[a,b,c,~,r,f,cfg,~,~,~,~,scope]=facts(t,1);source=fullfile(t.TestData.refs.(f.case.study),'runs',f.case.case);
positive(t,a,b,c,scope);e=t.TestData.context.(f.case.study).extracted;
verifyTrue(t,any(string({e.inputManifest.path})==string(source)));
[bad,~]=global_checks(t,c,f.case.study,source+".not-a-member",r);
v=ejc_p7_qualify(a,b,scope,bad);verifyFalse(t,v.eligibleToAdvance);verifyFalse(t,bad.sourceMembership);
positive(t,a,b,c,scope);wrong=r;wrong.D(1)=2*wrong.D(1);
[bad,~]=global_checks(t,c,f.case.study,source,wrong);verifyFalse(t,bad.sourceMembership);
v=ejc_p7_qualify(a,b,scope,bad);verifyFalse(t,v.eligibleToAdvance);
% Fixture case/index/scaling/hex equality is asserted in every facts call.
verifyEqual(t,ejc_gram_parent(r,f.case.study,cfg,struct('D',r.D),f.case.index),f.producerRegressors);
end
function test_default_strict_path_and_post_hook_scientific_assertions(t)
% Preserve native real-data results, without requiring a historical Mac error.
rows=struct([]);
for study=["study3","study4"]
 source=t.TestData.refs.(study);cfg=t.TestData.context.(study).cfg;verifier=str2func(study+"_verify_results");
 first=native_outcome(@()verifier(source,cfg));second=native_outcome(@()verifier(source,cfg,[]));
 verifyEqual(t,first.passed,second.passed,'Omitted/empty hook must have identical native strict behavior.');
 verifyEqual(t,first.identifier,second.identifier);verifyEqual(t,first.message,second.message);
 if ~first.passed,assert_strict_site(t,first,study);assert_strict_site(t,second,study);end
 rows=[rows;struct('study',study,'omitted',first,'explicitEmpty',second)]; %#ok<AGROW>
end
record(t,'native_historical_strict_outcomes',rows);
end
function test_actual_strict_assertions_reject_scratch_faults(t)
events=struct([]);
for k=[1 2]
 [a,b,c,~,~,f,~,~,~,~,~,scope]=facts(t,k);positive(t,a,b,c,scope);
 study=f.case.study;cfg=t.TestData.context.(study).cfg;verifier=str2func(study+"_verify_results");
 folder=t.applyFixture(matlab.unittest.fixtures.TemporaryFolderFixture);
 virtual=fullfile(folder.Folder,'saved_inputs');mkdir(virtual);shim=fullfile(folder.Folder,'read_only_io');mkdir(shim);
 install_io(shim);beforePath=path;
 state=struct('virtualRoot',virtual,'source',t.TestData.refs.(study),'extracted',t.TestData.context.(study).extracted);
 p07_w2_saved_fixture('start',state);cleanup=onCleanup(@()stop_io(beforePath));
 addpath(shim,'-begin');rehash;
 for explicitEmpty=[false true]
  p07_w2_saved_fixture('mode','positive');
  if explicitEmpty,verifier(virtual,cfg,[]);else,verifier(virtual,cfg);end
  assertTrue(t,isempty(p07_w2_saved_fixture('events')));
  p07_w2_saved_fixture('mode','fault',struct('case',char(f.case.case),'index',f.case.index));
  if explicitEmpty,outcome=native_outcome(@()verifier(virtual,cfg,[]));else,outcome=native_outcome(@()verifier(virtual,cfg));end
  assertFalse(t,outcome.passed);assert_strict_site(t,outcome,study);
  injected=p07_w2_saved_fixture('events');assertEqual(t,numel(injected),1);
  events=[events;struct('study',study,'explicitEmpty',explicitEmpty,'positiveCompleted',true,'fault',injected,'outcome',outcome)]; %#ok<AGROW>
 end
 clear cleanup
end
record(t,'deterministic_strict_assertion_faults',events);
end
function test_post_hook_prediction_and_A_faults(t)
events=struct([]);
for k=[1 2]
 [a,b,c,~,~,f,~,~,~,~,~,scope]=facts(t,k);positive(t,a,b,c,scope);
 study=f.case.study;context=t.TestData.context.(study);source=t.TestData.refs.(study);
 % setupOnce actually completed the uncorrupted hook path and all portable
 % parent checks for these exact sources. It is the positive control.
 assertTrue(t,context.extracted.originalRequirementsCompleted && context.binding.passed);
 called=false;injected=false;verifier=str2func(study+"_verify_results");
 outcome=native_outcome(@()verifier(source,context.cfg,@corrupt_after_comparison));
 assertTrue(t,called && injected);assertFalse(t,outcome.passed);
 assertEqual(t,outcome.identifier,"MATLAB:assertion:failed");
 if study=="study3",needle='close(r.prediction(j),value);';else,needle='close([r.A(j),r.B(j),r.c(j)]';end
 assert_site(t,outcome,study,needle);
 events=[events;struct('study',study,'positiveComplete',context.binding.passed,'callbackReached',called,'injected',injected,'outcome',outcome)]; %#ok<AGROW>
end
record(t,'post_hook_scientific_faults',events);
 function corrupt_after_comparison(r,G,R,j,rankValue,condition,sourceFile)
  called=true;
  if string(sourceFile)==string(fullfile(source,'runs',f.case.case)) && j==f.case.index
   [aa,bb,cc]=ejc_study34_gram_facts(r,G,R,j,rankValue,condition,study,context.cfg);
   cc=with_global(cc,c);positive(t,aa,bb,cc,scope);
   if study=="study3",r.prediction(j)=r.prediction(j)+1;else,r.A(j)=r.A(j)+1;end
   injected=true;assignin('caller','r',r);
  end
 end
end
function test_original_evidence_is_mandatory(t)
context=t.TestData.context.study3;assertTrue(t,context.binding.passed);
assertTrue(t,context.extracted.originalRequirementsCompleted);
folder=t.applyFixture(matlab.unittest.fixtures.TemporaryFolderFixture);
e=context.extracted;e.originalRequirementsCompleted=false;e.status="FAILED_ORIGINAL_REQUIREMENT";
verifyError(t,@()ejc_study34_bind(e,context.cfg,fullfile(folder.Folder,'missing')),'ejc:MissingOriginalChecks');
assertTrue(t,context.binding.passed);e=context.extracted;e.verifierSHA256=repmat('0',1,64);
verifyError(t,@()ejc_study34_bind(e,context.cfg,fullfile(folder.Folder,'stale')),'ejc:StaleOriginalChecks');
end
function c=with_global(c,positiveChecks)
% Carry measured positive global premises into a one-variable unit negative.
% No guard is fabricated or changed from false to true.
for field=["passiveUse","sourceMembership","outcomes","publicationChecks","noRequiredUniqueSupplementalRankClaim"]
 c.(field)=positiveChecks.(field);
end
end
function outcome=native_outcome(f)
outcome=struct('passed',true,'identifier',"",'message',"",'stack',struct([]));
try,f();catch e
 outcome.passed=false;outcome.identifier=string(e.identifier);outcome.message=string(e.message);outcome.stack=e.stack;
end
end
function assert_strict_site(t,outcome,study)
assertEqual(t,outcome.identifier,"MATLAB:assertion:failed");
if study=="study3",needle='close(r.gramCondition(j),condition);';else,needle='elseif isempty(gramComparison), close(r.gramCondition(j),s(1)/s(end),1e-6); end';end
assert_site(t,outcome,study,needle);
end
function assert_site(t,outcome,study,needle)
file=which(study+"_verify_results");lines=splitlines(string(fileread(file)));
target=find(contains(lines,needle));assertEqual(t,numel(target),1);
matched=arrayfun(@(s)strcmp(s.file,file) && s.line==target,outcome.stack);
assertTrue(t,any(matched),"Unexpected failure site: "+outcome.message);
end
function install_io(folder)
% Scoped read-only indirection avoids copying an entire reference campaign.
% Both shims delegate non-overlay operations to handles captured beforehand.
for name=["load","dir"]
 text="function varargout="+name+"(varargin)"+newline+ ...
  "[varargout{1:nargout}]=p07_w2_saved_fixture('"+name+"',varargin{:});"+newline+"end"+newline;
 fid=fopen(fullfile(folder,name+".m"),'w');assert(fid>=0);fprintf(fid,'%s',text);fclose(fid);
end
end
function stop_io(previousPath)
path(previousPath);p07_w2_saved_fixture('stop');rehash;
end
function record(t,name,value)
folder=fullfile(t.TestData.output,'events');if ~isfolder(folder),mkdir(folder);end
file=fullfile(folder,name+".json");assert(~isfile(file),'test:ExistingEvidence');
fid=fopen(file,'w');assert(fid>=0);cleanup=onCleanup(@()fclose(fid));fprintf(fid,'%s\n',jsonencode(value,PrettyPrint=true));
end
