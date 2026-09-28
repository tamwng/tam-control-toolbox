function tests=test_p07_study2_gram_binding
tests=functiontests(localfunctions);
end
function setupOnce(t)
t.TestData.path=path;root=fileparts(fileparts(mfilename('fullpath')));
addpath(root,fullfile(root,'src'),fullfile(root,'studies/p07'),fullfile(root,'studies/study2'));
t.TestData.root=root;
end
function teardownOnce(t),path(t.TestData.path);end
function test_resolved_and_qualified_reductions_are_distinct(t)
[a,b,row,ref,pair]=fixture;v=ejc_study2_gram_reduction(a,b,row,ref,pair);
verifyEqual(t,v.status,"NUMERICAL_AGREEMENT");verifyTrue(t,v.ordinaryP6.passed);
a.gramCondition=[3e22 2e22 1e22];b.gramCondition=[2e22 4e22 1e22];
row.maxStoredCondition=max(a.gramCondition);ref.maxStoredCondition=max(b.gramCondition);
pair=parents(a,b,true);v=ejc_study2_gram_reduction(a,b,row,ref,pair);
verifyEqual(t,v.status,"QUALIFIED_UNRESOLVED_GRAM_REDUCTION");verifyFalse(t,v.rawExtremumReproduced);
verifyFalse(t,v.ordinaryP6.passed);verifyEqual(t,[v.firstCurrent v.firstReference],[1 2]);
verifyEqual(t,v.witnessIndices,[1 2]);verifyEqual(t,[v.witnessParents.index],[1 2]);
verifyEqual(t,[v.witnessParents.rawCurrent],a.gramCondition(1:2));
verifyEqual(t,[v.witnessParents.rawReference],b.gramCondition(1:2));
pair=parents(a,b,false);verifyError(t,@()ejc_study2_gram_reduction(a,b,row,ref,pair),'ejc:GramReportNumerical');
end
function test_own_source_bound_is_not_the_P6_bound(t)
[a,b,row,ref,pair]=fixture;
ref.maxStoredCondition=ref.maxStoredCondition+1e-8;
v=ejc_acceptance_numeric(row.maxStoredCondition,ref.maxStoredCondition,1e-8,1e-7,true);verifyTrue(t,v.passed);
verifyError(t,@()ejc_study2_gram_reduction(a,b,row,ref,pair),'ejc:GramReportOwnReduction');
[a,b,row,ref,pair]=fixture;row.maxStoredCondition=row.maxStoredCondition+eps(row.maxStoredCondition);
verifyError(t,@()ejc_study2_gram_reduction(a,b,row,ref,pair),'ejc:GramReportOwnReduction');
end
function test_wrong_history_missing_stale_failed_parents(t)
[a,b,row,ref,pair]=fixture;
bad=pair;bad.passed=false;verifyError(t,@()ejc_study2_gram_reduction(a,b,row,ref,bad),'ejc:GramReportParents');
bad=pair;bad.gramRows(2)=[];verifyError(t,@()ejc_study2_gram_reduction(a,b,row,ref,bad),'ejc:GramReportParents');
bad=pair;bad.gramRows(2).eligibleToAdvance=false;verifyError(t,@()ejc_study2_gram_reduction(a,b,row,ref,bad),'ejc:GramReportParents');
a.gramCondition(3)=a.gramCondition(3)+1e-9;
verifyError(t,@()ejc_study2_gram_reduction(a,b,row,ref,pair),'ejc:GramReportParents');
end
function test_exact_selection_identity_and_completion(t)
[a,b,row,ref,pair]=fixture;
for field=["nSteps","gramCount","amplitude","nEstimated","time"]
 q=a;q.(field)(1)=q.(field)(1)+1;verifyReject(t,@()ejc_study2_gram_reduction(q,b,row,ref,pair));
end
for field=["completed","kind","id"]
 q=a;if field=="completed",q.(field)=false;else,q.(field)='wrong';end
 verifyReject(t,@()ejc_study2_gram_reduction(q,b,row,ref,pair));
end
for field=["parameterCount","recordedFullWindowCount","validFullWindowCount","invalidFullWindowCount","relativeThreshold"]
 q=row;q.(field)=q.(field)+1;verifyReject(t,@()ejc_study2_gram_reduction(a,b,q,ref,pair));
end
q=row;q.runCompleted=false;verifyReject(t,@()ejc_study2_gram_reduction(a,b,q,ref,pair));
a.gramCount=a.gramCount.';verifyError(t,@()ejc_study2_gram_reduction(a,b,row,ref,pair),'ejc:GramReportSelection');
end
function test_nonfinite_is_not_generic_agreement(t)
for bad=[NaN -Inf Inf]
 [a,b,row,ref,pair]=fixture;a.gramCondition(1)=bad;row.maxStoredCondition=max(a.gramCondition);
 verifyReject(t,@()ejc_study2_gram_reduction(a,b,row,ref,pair));
end
[a,b,row,ref,~]=fixture;a.gramCondition(:)=Inf;b.gramCondition(:)=Inf;
row.maxStoredCondition=Inf;ref.maxStoredCondition=Inf;pair=parents(a,b,false);
verifyError(t,@()ejc_study2_gram_reduction(a,b,row,ref,pair),'ejc:GramReportNumerical');
pair.gramRows(1).status="EXACT_STRUCTURAL_ZERO_GRAM";
v=ejc_study2_gram_reduction(a,b,row,ref,pair);verifyEqual(t,v.status,"EXACT_STRUCTURAL_ZERO_GRAM_REDUCTION");
% This is a reducer unit fixture. Real source-specific permission is tested
% by the unchanged Gram-screen suite and the full saved-data parent binding.
end
function test_strict_defaults_and_callback_contract(t)
[folder,csv,a,b,ref]=report_fixture(t);baseline=study2_gram_report(folder,csv);
a.gramCondition=a.gramCondition+1e-8;save_run(folder,a);
verifyError(t,@()study2_gram_report(folder,csv),'study2:GramReferenceMismatch');
verifyError(t,@()study2_gram_report(folder,csv,true),'study2:GramComparisonHook');
verifyError(t,@()study2_gram_report(folder,csv,@(~)true),'study2:GramComparisonHook');
verifyError(t,@()study2_gram_report(folder,csv,@(~)struct('passed',true)),'study2:GramComparisonHook');
[actual,e]=study2_gram_report(folder,csv,@callback);verifyEqual(t,actual,baseline);verifyEqual(t,numel(e.rows),2);
bad=@(q) setfield(callback(q),'status',"UNLISTED"); %#ok<SFLD>
verifyError(t,@()study2_gram_report(folder,csv,bad),'study2:GramComparisonHook');
 function v=callback(q)
  if q.row.model=="A",x=a;y=b;else,x=run_fixture('E','Exact sine');y=x;end
  p=parents(x,y,false);v=ejc_study2_gram_reduction(x,y,q.row,q.referenceRow,p);
 end
end
function test_original_assertions_reached_after_old_stop_and_in_later_rows(t)
for field=["modelName","coefficients","fullWindows","rankMin","rankMax","rankDeficientWindows","relative_singular_value_threshold"]
 [folder,csv,a,~,ref]=report_fixture(t);a.gramCondition=a.gramCondition+1e-8;save_run(folder,a);
 if field=="modelName",ref.(field)(2)="wrong";else,ref.(field)(2)=ref.(field)(2)+1;end
 writetable(ref,csv);seen=0;
 verifyError(t,@()study2_gram_report(folder,csv,@callback),'study2:GramReferenceMismatch');verifyEqual(t,seen,1);
end
 function v=callback(q)
  seen=seen+1;x=run_fixture('A','Affine');y=x;x.gramCondition=x.gramCondition+1e-8;
  v=ejc_study2_gram_reduction(x,y,q.row,q.referenceRow,parents(x,y,false));
 end
end
function test_invalid_matrix_dimension_and_later_maximum_failure(t)
for defect=["invalid","dimension","rank","count","steps","maximum","incomplete"]
 [folder,csv,a,~,~]=report_fixture(t);a.gramCondition=a.gramCondition+1e-8;save_run(folder,a);
 e=run_fixture('E','Exact sine');
 switch defect
  case "invalid",e.gram(1,1,1)=NaN;
  case "dimension",e.gram=zeros(2,2,3);
  case "rank",e.gram(1,1,1)=0;
  case "count",e.gramCount(1)=49;
  case "steps",e.nSteps=2;
  case "maximum",e.gramCondition(1)=100;
  case "incomplete",e.completed=false;
 end
 save_run(folder,e);seen=0;verifyReject(t,@()study2_gram_report(folder,csv,@callback));verifyGreaterThanOrEqual(t,seen,1);
end
 function v=callback(q)
  seen=seen+1;y=run_fixture(char(q.row.model),char(q.row.modelName));
  if q.row.model=="A",x=a;else,x=e;end
  v=ejc_study2_gram_reduction(x,y,q.row,q.referenceRow,parents(x,y,false));
 end
end
function test_factory_rejects_unpinned_reference_and_stale_sources(t)
refs=ejc_reference_sources;csv=fullfile(t.TestData.root,'results/study2_journal/gram_numerical_rank_check.csv');
f=t.applyFixture(matlab.unittest.fixtures.TemporaryFolderFixture);
verifyError(t,@()ejc_study2_gram_binding(refs.study2,refs.study1,csv,fullfile(f.Folder,'wrong')),'ejc:GramReportScope');
copyfile(csv,fullfile(f.Folder,'replacement.csv'));
verifyError(t,@()ejc_study2_gram_binding(refs.study2,refs.study2,fullfile(f.Folder,'replacement.csv'),fullfile(f.Folder,'csv')),'ejc:GramReportScope');
copyfile(refs.study2,fullfile(f.Folder,'current'));current=fullfile(f.Folder,'current');
binding=ejc_study2_gram_binding(current,refs.study2,csv,fullfile(f.Folder,'binding'));
verifyError(t,@()binding.compare(struct('field',"qpConditionMax")),'ejc:GramReportScope');
verifyError(t,@()binding.finish(),'ejc:GramReportCoverage');
file=fullfile(current,'runs/amplitude_01_A.mat');z=load(file);z.result.gramCondition(51)=z.result.gramCondition(51)+1;
save(file,'-struct','z');verifyError(t,@()binding.finish(),'ejc:GramReportIntegrity');
end
function test_scopes_and_existing_claims_are_not_extended(t)
p=jsondecode(fileread(fullfile(t.TestData.root,'studies/p07/p07_acceptance_policy.json')));
verifyTrue(t,p.active);verifyEqual(t,string(p.status),"AUTHOR_APPROVED_FROZEN_REQUIREMENTS");
verifyEqual(t,string(p.study2_gram_report_binding.parent_coverage_id),"F0533");
for id=["F0698","F0713"],verifyTrue(t,any(string(p.study2_gram_report_binding.not_aliases)==id));end
v=ejc_claim_check(1,-1,"signedContrast");verifyFalse(t,v.passed);
v=ejc_acceptance_numeric(2,1,1e-8,1e-7,true);verifyFalse(t,v.passed);
end
function test_real_original_outcomes_covariance_and_scope_remain_mandatory(t)
refs=ejc_reference_sources;z=load(fullfile(refs.study2,'runs/amplitude_01_A.mat'),'result');b=z.result;
z=load(fullfile(refs.study2,'fits/A.mat'),'fit');fit=z.fit;z=load(fullfile(refs.study2,'settings.mat'),'cfg');cfg=z.cfg;
for name=["completed","nSteps","gramCount","nEstimated","controlAccepted","idAccepted"]
 a=b;if islogical(a.(name)),a.(name)(1)=~a.(name)(1);else,a.(name)(1)=a.(name)(1)+1;end
 r=ejc_pair_run_screen(a,b,"study2",cfg,fit,fit,"F0533");verifyFalse(t,r.passed,name);
end
a=b;a.gramRank=zeros(size(a.gramCount));r=ejc_pair_run_screen(a,b,"study2",cfg,fit,fit,"F0533");verifyFalse(t,r.passed);
a=b;a.gramValid=true(size(a.gramCount));r=ejc_pair_run_screen(a,b,"study2",cfg,fit,fit,"F0533");verifyFalse(t,r.passed);
a=b;a.covariance(:,:,2)=-eye(size(a.covariance,1));r=ejc_pair_run_screen(a,b,"study2",cfg,fit,fit,"F0533");verifyFalse(t,r.passed);
r=ejc_pair_run_screen(b,b,"study2",cfg,fit,fit,"F0698");verifyFalse(t,r.passed);
end
function test_original_plot_value_assertion_rejects_after_portable_report(t)
refs=ejc_reference_sources;f=t.applyFixture(matlab.unittest.fixtures.TemporaryFolderFixture);
csv=fullfile(t.TestData.root,'results/study2_journal/gram_numerical_rank_check.csv');
binding=ejc_study2_gram_binding(refs.study2,refs.study2,csv,fullfile(f.Folder,'binding'));
old=get(groot,'defaultLineCreateFcn');restore=onCleanup(@()set(groot,'defaultLineCreateFcn',old));
set(groot,'defaultLineCreateFcn',@(line,~)set(line,'XData',line.XData+1));
verifyError(t,@()plot_study2_journal(refs.study2,fullfile(f.Folder,'figure'),csv,binding.compare),'study2:PlotValues');
report=binding.finish();verifyEqual(t,report.adaptiveRows,15);
end
function test_original_figure_source_score_cannot_be_replaced(t)
refs=ejc_reference_sources;f=t.applyFixture(matlab.unittest.fixtures.TemporaryFolderFixture);
copyfile(refs.study2,fullfile(f.Folder,'current'));folder=fullfile(f.Folder,'current');
file=fullfile(folder,'tables/initialization_scores.csv');x=readtable(file,'TextType','string');
j=find(x.fittingTransitions==200,1);x.predictionRMS(j)=x.predictionRMS(j)+1;
writetable(x,file);verifyError(t,@()study2_figure_data(folder),'study2:FigureScore');
end
function [a,b,row,ref,pair]=fixture
a=run_fixture('A','Affine');b=a;row=table("A",.2,3,true,3,3,0,1e-10,3, ...
 'VariableNames',{'model','amplitude','parameterCount','runCompleted','recordedFullWindowCount','validFullWindowCount','invalidFullWindowCount','relativeThreshold','maxStoredCondition'});
ref=table("A",.2,3,3,1e-10,3,'VariableNames',{'model','amplitude','coefficients','fullWindows','relative_singular_value_threshold','maxStoredCondition'});
pair=parents(a,b,false);
end
function r=run_fixture(id,name)
r=struct('id',id,'name',name,'kind','amplitude','amplitude',.2,'nSteps',3,'nEstimated',3,'completed',true, ...
 'time',0:.1:.2,'gramCount',[50 50 50],'gramCondition',[3 2 1],'gram',repmat(diag([3 2 1]),1,1,3));
end
function pair=parents(a,b,qualified)
rows=struct([]);
for j=1:3
 rows=[rows,struct('index',j,'eligibleToAdvance',true,'qualifiedCount',double(qualified), ...
  'rawCurrent',a.gramCondition(j),'rawReference',b.gramCondition(j),'status',"NUMERICAL_AGREEMENT")]; %#ok<AGROW>
end
pair=struct('passed',true,'gramRows',rows);
end
function [folder,csv,a,b,ref]=report_fixture(t)
f=t.applyFixture(matlab.unittest.fixtures.TemporaryFolderFixture);folder=f.Folder;mkdir(fullfile(folder,'runs'));
a=run_fixture('A','Affine');b=a;save_run(folder,a);save_run(folder,run_fixture('E','Exact sine'));
ref=table(["A";"E"],["Affine";"Exact sine"],[.2;.2],[3;3],[3;3],[3;3],[3;3],[0;0],[3;3],[1e-10;1e-10], ...
 'VariableNames',{'model','modelName','amplitude','coefficients','fullWindows','rankMin','rankMax','rankDeficientWindows','maxStoredCondition','relative_singular_value_threshold'});
csv=fullfile(folder,'synthetic_reference.csv');writetable(ref,csv);
end
function save_run(folder,result),save(fullfile(folder,'runs',"amplitude_01_"+result.id+".mat"),'result');end
function verifyReject(t,operation)
rejected=false;try,operation();catch,rejected=true;end
verifyTrue(t,rejected,'The deliberately corrupted unit fixture must not pass.');
end
