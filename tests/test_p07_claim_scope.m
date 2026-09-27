function tests=test_p07_claim_scope
tests=functiontests(localfunctions);
end
function setupOnce(t)
t.TestData.oldpath=path;root=fileparts(fileparts(mfilename('fullpath')));
addpath(root,fullfile(root,'src'),fullfile(root,'studies/p07'),fullfile(root,'studies/study1'),fullfile(root,'studies/study6'));
f=t.applyFixture(matlab.unittest.fixtures.TemporaryFolderFixture);t.TestData.folder=f.Folder;
refs=ejc_reference_sources;t.TestData.refs=refs;
bindings=ejc_csv_source_tables(struct('study1',refs.study1),fullfile(f.Folder,'bindings'));
t.TestData.bindings=bindings;
t.TestData.table=ejc_csv_read(fullfile(refs.study1,'tables/measured_initialization_paired_contrasts.csv'),"study1","tables/measured_initialization_paired_contrasts.csv");
z=load(fullfile(refs.study1,'settings.mat'),'cfg');t.TestData.cfg=z.cfg;
end
function teardownOnce(t),path(t.TestData.oldpath);end
function c=context(t,study,file)
c=struct('study',study,'file',file,'isCSV',false,'sources',t.TestData.refs,'references',t.TestData.refs, ...
 'parentCache',containers.Map('KeyType','char','ValueType','any'), ...
 'claimBindingsA',t.TestData.bindings,'claimBindingsB',t.TestData.bindings);
end
function v=leaf(c,a,b,field)
v=ejc_portable_leaf(a.(field),b.(field),"value."+field,a,b,c);
end
function test_definition_selector_all_480_rows(t)
T=t.TestData.table;classes=strings(height(T),1);
for j=1:height(T),classes(j)=ejc_freezing_identity(T(j,:));end
verifyEqual(t,nnz(classes~=""),40);verifyEqual(t,nnz(classes(T.campaign=="confirmation")~=""),20);
root=fileparts(fileparts(mfilename('fullpath')));
expected=readtable(fullfile(root,'evidence/p07_acceptance/freezing_identity/03_IDENTITY_SCOPE_ROWS.csv'));
verifyEqual(t,find(classes~=""),expected.tableRow);
for j=find(T.metric=="freezingRMS")'
 row=T(j,:);row.medianDifference=12345;row.lower95=-Inf;row.upper95=Inf;
 verifyEqual(t,ejc_freezing_identity(row),classes(j)); % classification never reads the values
end
end
function test_noneligible_definitions_not_magnitude(t)
row=t.TestData.table(2,:);row.medianDifference=0;row.lower95=0;row.upper95=0;
for h=[2 5 10 20]
 row.horizon=h;row.contrast="R-P2";row.inputMode="held";verifyEqual(t,ejc_freezing_identity(row),"");
 for pair=["S-A","S-W","S-R"]
  row.contrast=pair;row.inputMode="recordedRateLimited";verifyEqual(t,ejc_freezing_identity(row),"");
 end
end
row.contrast="S-UNKNOWN";verifyError(t,@()ejc_freezing_identity(row),'ejc:ClaimScope');
row.contrast="S-A";row.inputMode="changing";verifyError(t,@()ejc_freezing_identity(row),'ejc:ClaimScope');
end
function test_all_identity_rows_and_exact_paper_aliases(t)
T=t.TestData.table;c=context(t,"study1","tables/measured_initialization_paired_contrasts.csv");
checked=0;exports=0;
for j=1:height(T)
 if ejc_freezing_identity(T(j,:))=="",continue;end
 for field=["medianDifference","lower95","upper95"]
  v=leaf(c,T(j,:),T(j,:),field);verifyTrue(t,v.passed,v.reason);
  verifyEqual(t,v.status,"NUMERICAL_AGREEMENT_STRUCTURAL_NULL_CONTRAST");
  verifyFalse(t,v.claim.statisticalSignificanceAgreementClaimed);verifyTrue(t,v.claim.fullStudyAndPaperGatesRequired);
  verifyEqual(t,v.claim.rawCurrent,T.(field)(j));checked=checked+1;
  if T.campaign(j)=="confirmation"
   p=c;p.study="paper";p.file="paper_A17_study1_retrospective.csv";
   w=leaf(p,T(j,:),T(j,:),field);verifyTrue(t,w.passed,w.reason);
   verifyEqual(t,w.claim.currentParents,v.claim.currentParents);verifyEqual(t,w.claim.referenceParents,v.claim.referenceParents);
   verifyEqual(t,w.claim.rawCurrentInterval,v.claim.rawCurrentInterval);exports=exports+1;
  end
 end
end
verifyEqual(t,checked,120);verifyEqual(t,exports,60);
end
function test_broken_export_value_metadata_and_missing_parent(t)
row=t.TestData.table(242,:);c=context(t,"paper","paper_A17_study1_retrospective.csv");
a=row;a.medianDifference=a.medianDifference+1e-10;
v=leaf(c,a,row,"medianDifference");verifyTrue(t,v.numeric.passed);verifyFalse(t,v.passed);verifyTrue(t,contains(v.reason,'ClaimExportLink'));
a=row;a.trial=1;v=leaf(c,a,a,"medianDifference");verifyFalse(t,v.passed);
c.sources=struct;v=leaf(c,row,row,"medianDifference");verifyFalse(t,v.passed);
end
function test_noneligible_and_real_performance_guards_still_fail(t)
T=t.TestData.table;
for index=[241,284,386]
 a=T(index,:);b=a;
 if a.metric=="freezingRMS",verifyEqual(t,ejc_freezing_identity(a),"");end
 a.medianDifference=-1e-20;b.medianDifference=1e-20;
 for study=["study1","paper"]
  file="tables/measured_initialization_paired_contrasts.csv";if study=="paper",file="paper_A17_study1_retrospective.csv";end
  c=context(t,study,file);v=leaf(c,a,b,"medianDifference");verifyTrue(t,v.numeric.passed);verifyFalse(t,v.passed);
 end
end
end
function test_quantitative_nonfinite_and_interval_failures_not_rescued(t)
row=t.TestData.table(2,:);c=context(t,"study1","tables/measured_initialization_paired_contrasts.csv");
a=row;a.medianDifference=1;v=leaf(c,a,row,"medianDifference");verifyFalse(t,v.passed);verifyFalse(t,v.numeric.passed);
for x=[NaN,Inf,-Inf]
 a=row;a.medianDifference=x;v=leaf(c,a,a,"medianDifference");verifyFalse(t,v.passed);
end
a=row;a.lower95=1e-20;a.upper95=-1e-20;v=leaf(c,a,a,"lower95");verifyFalse(t,v.passed);verifyTrue(t,contains(v.reason,'ClaimInterval'));
end
function test_explicit_cross_term_sign_and_ci_remain_strict(t)
row=t.TestData.table(6,:);c=context(t,"study1","tables/measured_initialization_paired_contrasts.csv");c.explicitDirectionalClaim=true;
a=row;b=row;a.medianDifference=-1e-20;b.medianDifference=1e-20;
v=leaf(c,a,b,"medianDifference");verifyTrue(t,v.numeric.passed);verifyFalse(t,v.passed);
a.lower95=-1e-20;a.upper95=1e-20;b.lower95=1e-21;b.upper95=1e-20;
v=leaf(c,a,b,"lower95");verifyTrue(t,v.numeric.passed);verifyFalse(t,v.passed);
end
function test_cross_terms_require_source_and_keep_raw_values(t)
row=t.TestData.table(6,:);c=context(t,"study1","tables/measured_initialization_paired_contrasts.csv");
v=leaf(c,row,row,"medianDifference");verifyTrue(t,v.passed,v.reason);verifyEqual(t,v.status,"NUMERICAL_AGREEMENT_SIGN_NOT_ASSERTED");
verifyEqual(t,v.claim.rawCurrent,row.medianDifference);verifyEqual(t,v.claim.rawCurrentInterval,[row.lower95,row.upper95]);
c.claimBindingsA=[];v=leaf(c,row,row,"medianDifference");verifyFalse(t,v.passed);
end
function test_pilot_pair_and_raw_degenerate_interval_retained(t)
row=t.TestData.table(8,:);c=context(t,"study1","tables/measured_initialization_paired_contrasts.csv");
v=leaf(c,row,row,"lower95");verifyTrue(t,v.passed,v.reason);verifyEqual(t,v.claim.currentParents.trialIds,1);
verifyEqual(t,v.claim.rawCurrentInterval,[row.lower95,row.upper95]);verifyEqual(t,row.lower95,row.upper95);
end
function test_snapshot_membership_validity_and_decomposition_negatives(t)
base=t.TestData.refs.study1;z=load(fullfile(base,'audits/pilot_S_001.mat'),'audit');a=z.audit;
z=load(fullfile(base,'data/pilot_S_001.mat'),'result');r=z.result;cfg=t.TestData.cfg;
p=ejc_measured_parent_check(a,r,cfg);verifyTrue(t,p.passed);
b=a;b.measuredInitialState(1)=b.measuredInitialState(1)+1;
verifyError(t,@()ejc_measured_parent_check(b,r,cfg),'ejc:ClaimSnapshots');
b=a;b.snapshotTheta(1,1)=b.snapshotTheta(1,1)+1;
verifyError(t,@()ejc_measured_parent_check(b,r,cfg),'ejc:ClaimSnapshots');
b=a;b.snapshotIndices(1)=b.snapshotIndices(1)+1;
verifyError(t,@()ejc_measured_parent_check(b,r,cfg),'ejc:ClaimQueries');
b=a;b.inputModes{1}='recordedRateLimited';verifyError(t,@()ejc_measured_parent_check(b,r,cfg),'ejc:ClaimQueries');
b=a;b.valid(1)=false;verifyError(t,@()ejc_measured_parent_check(b,r,cfg),'ejc:ClaimValidity');
b=a;b.crossTerm(1)=1;verifyError(t,@()ejc_measured_parent_check(b,r,cfg),'ejc:ClaimDecomposition');
end
function test_all_listed_model_contact_and_held_affine_definitions(t)
base=t.TestData.refs.study1;cfg=t.TestData.cfg;
for id=["A","S","W","R","P2","K"]
 z=load(fullfile(base,'audits',"pilot_"+id+"_001.mat"),'audit');a=z.audit;
 z=load(fullfile(base,'data',"pilot_"+id+"_001.mat"),'result');p=ejc_measured_parent_check(a,z.result,cfg);
 verifyTrue(t,all(p.maxAbsFreezing(1,:)<=1e-11));
 if id~="P2",verifyTrue(t,all(p.maxAbsFreezing(:,1)<=1e-11));end
end
end
function test_modified_scientific_source_fails_hash_guard(t)
f=t.applyFixture(matlab.unittest.fixtures.TemporaryFolderFixture);file=fullfile(f.Folder,'definition.m');
fid=fopen(file,'w');fprintf(fid,'original');fclose(fid);
rows=struct('path','definition.m','sha256',ejc_file_sha256(file));p=ejc_claim_source_guard(f.Folder,rows);verifyTrue(t,p.passed);
fid=fopen(file,'w');fprintf(fid,'modified');fclose(fid);
verifyError(t,@()ejc_claim_source_guard(f.Folder,rows),'ejc:ClaimSourceChanged');
end
function test_equal_large_parent_errors_and_one_failed_parent_block(t)
% Use an isolated minimal package; no retained file is written.
for both=[false true]
 [c,base]=isolated(t);row=t.TestData.table(56,:);assert(row.contrast=="S-W"&&row.horizon==5);
 models="S";if both,models=["S","W"];end
 for id=models
  file=fullfile(base,'audits',"pilot_"+id+"_001.mat");z=load(file,'audit');audit=z.audit;
  % Keep all definitions internally consistent; only the selected identity fails.
  h=find(audit.horizons==5);audit.freezingError(:,h,1)=1e-6;
  audit.totalError(:,h,1)=audit.measuredModelError(:,h,1)+audit.freezingError(:,h,1);
  audit.crossTerm=2*audit.measuredModelError.*audit.freezingError;
  audit.identityResidual=abs(audit.totalError-audit.measuredModelError-audit.freezingError);
  audit.squaredIdentityResidual=abs(audit.totalError.^2-audit.measuredModelError.^2-audit.freezingError.^2-audit.crossTerm);
  save(file,'audit','-v7');
 end
 v=leaf(c,row,row,"medianDifference");verifyFalse(t,v.passed);verifyTrue(t,contains(v.reason,'ClaimIdentity'),v.reason);
end
end
function test_pair_count_seed_and_parent_membership_negatives(t)
row=t.TestData.table(8,:);
[c,base]=isolated(t);z=load(fullfile(base,'settings.mat'),'cfg');cfg=z.cfg;cfg.pilot.bootstrapSeed=99;save(fullfile(base,'settings.mat'),'cfg');
v=leaf(c,row,row,"medianDifference");verifyFalse(t,v.passed);verifyTrue(t,contains(v.reason,'ClaimBootstrap'),v.reason);
c=context(t,"study1","tables/measured_initialization_paired_contrasts.csv");bad=row;bad.finitePairs=0;
v=leaf(c,bad,row,"medianDifference");verifyFalse(t,v.passed);
[c,base]=isolated(t);file=fullfile(base,'tables/measured_initialization_audit.csv');T=ejc_csv_read(file,"study1","tables/measured_initialization_audit.csv");
T.trial(T.campaign=="pilot"&T.model=="W"&T.trial==1)=2;writetable(T,file);
v=leaf(c,row,row,"medianDifference");verifyFalse(t,v.passed);verifyTrue(t,contains(v.reason,'ClaimPairing'),v.reason);
end
function test_failed_reference_parent_is_not_hidden_by_current_pass(t)
[c,base]=isolated(t);c.claimBindingsB=c.claimBindingsA;c.claimBindingsA=t.TestData.bindings;
c.sources=t.TestData.refs;c.references.study1=base;
file=fullfile(base,'audits/pilot_W_001.mat');z=load(file,'audit');audit=z.audit;audit.valid(1)=false;save(file,'audit','-v7');
row=t.TestData.table(8,:);v=leaf(c,row,row,"medianDifference");verifyFalse(t,v.passed);verifyTrue(t,contains(v.reason,'ClaimValidity'),v.reason);
end
function test_altered_bootstrap_reduction_binding_fails(t)
c=context(t,"study1","tables/measured_initialization_paired_contrasts.csv");
ix=find(string({c.claimBindingsA.file})=="tables/measured_initialization_paired_contrasts.csv");
c.claimBindingsA(ix).values.lower95(8)=-1;
row=t.TestData.table(8,:);v=leaf(c,row,row,"lower95");verifyFalse(t,v.passed);verifyTrue(t,contains(v.reason,'ClaimReduction'),v.reason);
end
function test_study6_units_counts_and_both_cross_terms(t)
c=context(t,"study6","tables/measurement.csv");
T=ejc_csv_read(fullfile(t.TestData.refs.study6,'tables/measurement.csv'),"study6","tables/measurement.csv");row=T(1,:);
for field=["meanCrossTerm","meanCombinedCrossTerm"]
 v=leaf(c,row,row,field);verifyTrue(t,v.passed,v.reason);verifyEqual(t,v.status,"NUMERICAL_AGREEMENT_SIGN_NOT_ASSERTED");
end
bad=row;bad.unit="wrong unit";bad.squaredUnit="(wrong unit)^2";
v=leaf(c,bad,bad,"meanCrossTerm");verifyFalse(t,v.passed);verifyTrue(t,contains(v.reason,'ClaimUnits'),v.reason);
bad=row;bad.attemptedQueries=28;v=leaf(c,bad,bad,"meanCrossTerm");verifyFalse(t,v.passed);
end
function [c,base]=isolated(t)
f=t.applyFixture(matlab.unittest.fixtures.TemporaryFolderFixture);base=string(f.Folder);original=string(t.TestData.refs.study1);
mkdir(fullfile(base,'tables'));mkdir(fullfile(base,'data'));mkdir(fullfile(base,'audits'));
copyfile(fullfile(original,'settings.mat'),fullfile(base,'settings.mat'));
for file=["measured_initialization_paired_contrasts.csv","measured_initialization_audit.csv"]
 copyfile(fullfile(original,'tables',file),fullfile(base,'tables',file));
end
for id=["S","W"]
 for folder=["data","audits"]
  copyfile(fullfile(original,folder,"pilot_"+id+"_001.mat"),fullfile(base,folder,"pilot_"+id+"_001.mat"));
 end
end
c=context(t,"study1","tables/measured_initialization_paired_contrasts.csv");c.sources.study1=base;
for j=1:numel(c.claimBindingsA),c.claimBindingsA(j).parents=replace(string(c.claimBindingsA(j).parents),original,base);end
end

function test_table12_original_source_path_exclusion_keeps_exact_own_links(t)
z=load(fullfile(t.TestData.refs.study6,'summary.mat'),'summary');T=z.summary.measurement;
T=T(T.kind=="measurementInitialization"&T.sourceStudy==1&T.sourceCampaign=="confirmation" & ...
 T.trial==0&T.inputMode=="recordedRateLimited"&T.initialization=="measured",:);
T=sortrows(T,{'modelId','horizon'});T.sourceFile=[];
c=context(t,"paper","paper_table12.csv");count=0;
for j=1:height(T)
 for field=["meanCrossTerm","meanCombinedCrossTerm"]
  v=leaf(c,T(j,:),T(j,:),field);verifyTrue(t,v.passed,v.reason);
  verifyTrue(t,v.claim.currentParents.paperSelectionLink.passed);
  verifyEqual(t,v.claim.currentParents.paperSelectionLink.originalExcludedField,"sourceFile");count=count+1;
 end
end
verifyEqual(t,count,60);
end
function test_table12_changed_values_keys_and_general_missing_key_block(t)
z=load(fullfile(t.TestData.refs.study6,'summary.mat'),'summary');T=z.summary.measurement;
row=T(find(T.sourceCampaign=="confirmation"&T.trial==0&T.inputMode=="recordedRateLimited",1),:);row.sourceFile=[];
c=context(t,"paper","paper_table12.csv");bad=row;bad.meanCrossTerm=bad.meanCrossTerm+1e-12;
v=leaf(c,bad,bad,"meanCrossTerm");verifyTrue(t,v.numeric.passed);verifyFalse(t,v.passed);verifyTrue(t,contains(v.reason,'ClaimExportLink'),v.reason);
bad=row;bad.trial=1;v=leaf(c,bad,bad,"meanCrossTerm");verifyFalse(t,v.passed);
c.study="study6";c.file="tables/measurement.csv";
v=leaf(c,row,row,"meanCrossTerm");verifyFalse(t,v.passed);verifyTrue(t,contains(v.reason,'ClaimSourceLink'),v.reason);
end
function test_study6_csv_keys_use_the_existing_unrounded_source_binding(t)
[c,T,unrounded]=change_context(t);verifyNotEqual(t,T.snapshotTime(3),unrounded.snapshotTime(3));
count=0;
for j=1:height(T)
 c.rowIndex=j;
 for field=["meanCrossTerm","meanCombinedCrossTerm"]
  v=leaf(c,T(j,:),T(j,:),field);verifyTrue(t,v.passed,v.reason);
  p=v.claim.currentParents.csvSourceIdentity;
  verifyTrue(t,p.existingP13EncodingCheck.passed);verifyEqual(t,p.rawCSVKeys.snapshotTime,T.snapshotTime(j));
  verifyEqual(t,p.exactUnroundedKeys.snapshotTime,unrounded.snapshotTime(j));
  verifyEqual(t,v.claim.rawCurrent,T.(field)(j));count=count+1;
 end
end
verifyEqual(t,count,72);
end
function test_study6_csv_broken_row_and_unrounded_binding_still_block(t)
[c,T]=change_context(t);c.rowIndex=3;bad=T(3,:);bad.snapshotTime=49.5;
v=leaf(c,bad,bad,"meanCrossTerm");verifyFalse(t,v.passed);verifyTrue(t,contains(v.reason,'ClaimExportLink'),v.reason);
[c,T]=change_context(t);c.rowIndex=3;c.bindingA.values.snapshotTime(3)=49.5;
v=leaf(c,T(3,:),T(3,:),"meanCrossTerm");verifyFalse(t,v.passed);verifyTrue(t,contains(v.reason,'ClaimSourceLink'),v.reason);
[c,T]=change_context(t);c.rowIndex=4;
v=leaf(c,T(3,:),T(3,:),"meanCrossTerm");verifyFalse(t,v.passed);
end
function [c,T,S]=change_context(t)
base=t.TestData.refs.study6;file=string(fullfile(base,'tables/change.csv'));
T=ejc_csv_read(file,"study6","tables/change.csv");z=load(fullfile(base,'summary.mat'),'summary');S=z.summary.change;
b=struct('study',"study6",'file',"tables/change.csv",'values',S,'authority',"original saved summary", ...
 'sourceKind',"DIRECT_SAVED_UNROUNDED_TABLE",'parents',string(fullfile(base,'summary.mat')));
info=struct('study',"study6",'file',"tables/change.csv",'source',file,'reference',file);
c=ejc_portable_context(info,T,T,t.TestData.refs,t.TestData.refs,b,b,containers.Map('KeyType','char','ValueType','any'));
end
