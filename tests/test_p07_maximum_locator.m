function tests=test_p07_maximum_locator
tests=functiontests(localfunctions);
end
function setupOnce(t)
t.TestData.path=path;root=fileparts(fileparts(mfilename('fullpath')));
addpath(root,fullfile(root,'src'),fullfile(root,'studies/p07'));
t.TestData.root=root;
end
function teardownOnce(t),path(t.TestData.path);end
function [a,b,p]=synthetic
b=[2 2 1];a=[2-1e-8 2 1];[ma,ia]=max(a);[mb,ib]=max(b);
p=struct('coverageId',"F0698",'maximumLocationClaim',"NOT_ASSERTED",'activeIndex',false,'exactAlias',false, ...
 'selectionCurrent',1:3,'selectionReference',1:3,'countCurrent',3,'countReference',3, ...
 'keysCurrent',"same",'keysReference',"same",'timeCurrent',1:3,'timeReference',1:3, ...
 'settingsCurrent',1,'settingsReference',1,'units',"dimensionless QP condition", ...
 'parentPassed',true,'hessianCount',3,'ownSourcePassed',true, ...
 'ownMaximumCurrent',ma,'ownMaximumReference',mb,'ownIndexCurrent',ia,'ownIndexReference',ib);
p.witnessIndices=unique([ia ib]);p.hessians=cell(2,2);
for k=1:2,j=p.witnessIndices(k);p.hessians{k,1}=diag([1 a(j)]);p.hessians{k,2}=diag([1 b(j)]);end
end
function test_same_and_different_indices(t)
[a,b,p]=synthetic;v=ejc_maximum_locator(a,b,p);verifyTrue(t,v.passed,v.reason);
verifyEqual(t,v.status,"NUMERICAL_AGREEMENT_MAX_LOCATOR_DIFFERENT");verifyFalse(t,v.originalStrictPassed);
verifyEqual(t,v.exactMaximizersReference,[1 2]);
a=b;p.ownIndexCurrent=1;p.witnessIndices=1;p.hessians={diag([1 2]),diag([1 2])};
v=ejc_maximum_locator(a,b,p);verifyTrue(t,v.passed,v.reason);verifyTrue(t,v.originalStrictPassed);
end
function test_wrong_own_index_and_maximum(t)
[a,b,p]=synthetic;
for field=["ownIndexCurrent","ownIndexReference","ownMaximumCurrent","ownMaximumReference"]
 q=p;q.(field)=q.(field)+1;v=ejc_maximum_locator(a,b,q);verifyFalse(t,v.passed);
end
end
function test_equal_aggregate_does_not_hide_history_failure(t)
[a,b,p]=synthetic;a(3)=1.01;v=ejc_maximum_locator(a,b,p);verifyFalse(t,v.passed);
verifyTrue(t,v.maximum.passed);verifyFalse(t,v.history.passed);
end
function test_selection_count_keys_timing_weights_and_units(t)
[a,b,p]=synthetic;
fields=["selectionCurrent","countCurrent","keysCurrent","timeCurrent","settingsCurrent","units","hessianCount"];
for field=fields
 q=p;if isstring(q.(field)),q.(field)="changed";else,q.(field)=q.(field)+1;end
 v=ejc_maximum_locator(a,b,q);verifyFalse(t,v.passed,field);
end
end
function test_invalid_masks_and_classes(t)
[a,b,p]=synthetic;
for value=[NaN Inf -Inf],x=a;x(3)=value;v=ejc_maximum_locator(x,b,p);verifyFalse(t,v.passed);end
v=ejc_maximum_locator(single(a),b,p);verifyFalse(t,v.passed);
v=ejc_maximum_locator(a.',b,p);verifyFalse(t,v.passed);
end
function test_required_parents_and_same_index_witness(t)
[a,b,p]=synthetic;
for field=["parentPassed","ownSourcePassed"]
 q=p;q.(field)=false;v=ejc_maximum_locator(a,b,q);verifyFalse(t,v.passed);
end
for M={diag([1 -1]),diag([1 1e-30]),[NaN 0;0 1]}
 q=p;q.hessians{1,1}=M{1};v=ejc_maximum_locator(a,b,q);verifyFalse(t,v.passed);
end
q=p;q.witnessIndices=[2 1];v=ejc_maximum_locator(a,b,q);verifyFalse(t,v.passed);
end
function test_claims_and_unsupported_aliases_fail_closed(t)
[a,b,p]=synthetic;
for field=["activeIndex","exactAlias"]
 q=p;q.(field)=true;v=ejc_maximum_locator(a,b,q);verifyFalse(t,v.passed);
end
q=p;q.maximumLocationClaim="EVENT_TIME";v=ejc_maximum_locator(a,b,q);verifyFalse(t,v.passed);
q=p;q.coverageId="F1138";v=ejc_maximum_locator(a,b,q);verifyFalse(t,v.passed);
end
function test_actual_original_failure_fixtures(t)
z=load(fullfile(t.TestData.root,'evidence/p07_acceptance/maximum_locator/qp_argmax_fixture.mat'));
for k=1:2
 f=z.fixtures{k};a=f.qpConditionCurrent;b=f.qpConditionReference;[~,~,p]=synthetic;
 p.selectionCurrent=1:800;p.selectionReference=1:800;p.countCurrent=800;p.countReference=800;p.hessianCount=800;
 p.timeCurrent=f.timeCurrent;p.timeReference=f.timeReference;p.settingsCurrent=f.settingsCurrent;p.settingsReference=f.settingsReference;
 [p.ownMaximumCurrent,p.ownIndexCurrent]=max(a);[p.ownMaximumReference,p.ownIndexReference]=max(b);
 p.witnessIndices=f.selectedIndices;p.hessians=f.Hessians;
 v=ejc_maximum_locator(a,b,p);verifyTrue(t,v.passed,v.reason);verifyFalse(t,v.originalStrictPassed);
 verifyEqual(t,v.status,"NUMERICAL_AGREEMENT_MAX_LOCATOR_DIFFERENT");
 verifyFalse(t,f.originalVerdict.passed); % Never rewrite the original verdict.
end
end
function test_inventory_has_no_exact_alias(t)
s=jsondecode(fileread(fullfile(t.TestData.root,'evidence/p07_acceptance/maximum_locator/CLAIM_SCOPE.json')));
verifyEmpty(t,s.exactAliases);verifyEqual(t,string(s.coverageId),"F0698");
rows=readtable(fullfile(t.TestData.root,'evidence/p07_acceptance/full_field_coverage.csv'),'TextType','string');
rows=rows(rows.study=="study2" & endsWith(rows.fieldPath,".qpConditionMax"),:);
verifyEqual(t,rows.coverage_id,"F0698");
verifyFalse(t,contains(fileread(fullfile(t.TestData.root,'studies/p07/ejc_paper_export_checks.m')),'run_diagnostics.csv'));
end
function test_diagnostic_collects_after_failure_and_production_stops(t)
f=t.applyFixture(matlab.unittest.fixtures.TemporaryFolderFixture);a=fullfile(f.Folder,'a');b=fullfile(f.Folder,'b');
mkdir(fullfile(a,'audits'));mkdir(fullfile(b,'audits'));
for k=1:2
 audit=struct('trial',k);save(fullfile(b,'audits',sprintf('confirmation_S_%03d.mat',k)),'audit');
 audit.trial=k+1;save(fullfile(a,'audits',sprintf('confirmation_S_%03d.mat',k)),'audit');
end
adapter=struct('contextForFile',@ctx);
r=ejc_compare_results(struct('study1',a),struct('study1',b),fullfile(f.Folder,'production'),adapter);
verifyFalse(t,r.passed);verifyEqual(t,height(r.files),1);
adapter.diagnosticCollect=true;
r=ejc_compare_results(struct('study1',a),struct('study1',b),fullfile(f.Folder,'diagnostic'),adapter);
verifyFalse(t,r.passed);verifyEqual(t,height(r.files),2);verifyEqual(t,height(r.failures),2);
end
function c=ctx(info,a,b)
c=info;c.rootA=a;c.rootB=b;c.isCSV=false;c.rowIndex=NaN;
end
function test_diagnostic_dependency_failures_are_not_passes(t)
verifyError(t,@()ejc_preflight_branch(false,true,true,true),'ejc:PreflightIntegrity');
verifyEqual(t,ejc_preflight_branch(true,false,true,true),"FAILED_SCIENTIFIC_VALIDITY");
verifyEqual(t,ejc_preflight_branch(true,true,false,true),"FAILED_COMPARISON_VALID_SCIENTIFIC_INPUTS");
verifyEqual(t,ejc_preflight_branch(true,true,true,false),"BLOCKED_DEPENDENCY");
verifyEqual(t,ejc_preflight_branch(true,true,true,true),"DIAGNOSTIC_CHECKS_PASSED_NOT_CERTIFICATION");
end
function test_study6_missing_science_or_identity_blocks_before_computation(t)
f=t.applyFixture(matlab.unittest.fixtures.TemporaryFolderFixture);
p=struct('diagnosticOnly',true,'originalValidityPassed',[true true false true true]);
verifyError(t,@()ejc_preflight_study6(fullfile(f.Folder,'missing'),struct,p),'ejc:PreflightDependency');
verifyFalse(t,isfolder(fullfile(f.Folder,'missing')));
end
function test_real_constraint_source_and_false_alias_links(t)
refs=ejc_reference_sources;z=load(fullfile(refs.study2,'runs/constraint_K.mat'),'result');a=z.result;b=a;
T=ejc_csv_read(fullfile(refs.study2,'tables/run_diagnostics.csv'),"study2","tables/run_diagnostics.csv");
row=T(T.model=="K" & T.kind=="constraintAudit",:);verifyEqual(t,height(row),1);
x=load(fullfile(refs.study2,'settings.mat'),'cfg');f=load(fullfile(refs.study2,'fits/K.mat'),'fit');
pair=ejc_pair_run_screen(a,b,"study2",x.cfg,f.fit,f.fit,"F0533");verifyTrue(t,pair.passed,pair.reason);
c=struct('study',"study2",'file',"tables/run_diagnostics.csv",'sources',refs,'references',refs, ...
 'sourceSHA256',string(ejc_file_sha256(fullfile(refs.study2,'runs/constraint_K.mat'))));c.referenceSHA256=c.sourceSHA256;
[m,i]=max(a.qpCondition(1:a.nSteps));r=struct('selectedCurrent',1:a.nSteps,'selectedReference',1:b.nSteps, ...
 'sourceCurrent',m,'sourceReference',m,'argmaxCurrent',i,'argmaxReference',i);
v=ejc_qp_max_locator(a,b,row,row,c,pair,r);verifyTrue(t,v.passed,v.reason);
q=row;q.qpConditionMax=q.qpConditionMax+1e-4;verifyError(t,@()ejc_qp_max_locator(a,b,q,row,c,pair,r),'ejc:LocatorOwnCSV');
q=row;q.amplitude=0.2;verifyError(t,@()ejc_qp_max_locator(a,b,q,row,c,pair,r),'ejc:LocatorIdentity');
q=c;q.file="paper_A14_conditioning.csv";verifyError(t,@()ejc_qp_max_locator(a,b,row,row,q,pair,r),'ejc:LocatorScope');
q=pair;q.passed=false;v=ejc_qp_max_locator(a,b,row,row,c,q,r);verifyFalse(t,v.passed);
end
function test_study6_validity_guard_cannot_be_bypassed_by_a_status_label(t)
f=t.applyFixture(matlab.unittest.fixtures.TemporaryFolderFixture);
p=struct('diagnosticOnly',true,'originalValidityPassed',true(1,5),'inputSnapshot',struct);
verifyError(t,@()ejc_preflight_study6(fullfile(f.Folder,'invalid'),struct,p),'ejc:MissingSource');
verifyFalse(t,isfolder(fullfile(f.Folder,'invalid')));
end
function test_integrity_exceptions_stop_collector(t)
for id=["ejc:PreflightIntegrity","ejc:InputChanged","ejc:SourceChanged","ejc:PolicyChanged","ejc:RecordMismatch"]
 verifyError(t,@()caught_integrity(id),char(id));
end
ejc_preflight_integrity_exception(MException('ejc:ReproductionMismatch','Comparison failure remains evidence.'));
end
function test_preflight_never_overwrites_and_requires_authorization(t)
f=t.applyFixture(matlab.unittest.fixtures.TemporaryFolderFixture);
verifyError(t,@()ejc_diagnostic_preflight(f.Folder,'unused',''),'ejc:DiagnosticAuthorization');
verifyError(t,@()ejc_diagnostic_preflight(f.Folder,'unused','P07_DIAGNOSTIC_ONLY_AUTHORIZED'),'ejc:ExistingEvidence');
end
function test_preflight_rejects_changed_base_before_any_stage(t)
f=t.applyFixture(matlab.unittest.fixtures.TemporaryFolderFixture);file=fullfile(f.Folder,'snapshot.json');
fid=fopen(file,'w');fprintf(fid,'%s',jsonencode(struct('baseCandidate','wrong')));fclose(fid);
verifyError(t,@()ejc_diagnostic_preflight(fullfile(f.Folder,'output'),file,'P07_DIAGNOSTIC_ONLY_AUTHORIZED'),'ejc:PreflightIntegrity');
verifyFalse(t,isfolder(fullfile(f.Folder,'output')));
end

function caught_integrity(id)
try,error(char(id),'Synthetic already-caught integrity failure.');
catch e,ejc_preflight_integrity_exception(e);end
end
