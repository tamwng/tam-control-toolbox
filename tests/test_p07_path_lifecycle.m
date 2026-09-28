function tests=test_p07_path_lifecycle
tests=functiontests(localfunctions);
end
function setupOnce(t)
t.TestData.root=fileparts(fileparts(mfilename('fullpath')));t.TestData.path=path;
addpath(t.TestData.root,fullfile(t.TestData.root,'src'),fullfile(t.TestData.root,'studies/p07'));
end
function teardownOnce(t),path(t.TestData.path);end
function test_original_callback_fails_after_real_study3_reset(t)
f=fixture(t,true);oldPath=path;oldPwd=pwd;
verifyError(t,@()p07_path_fixture_ejc('study3',OutputDirectory=fullfile(f.root,'output')),'MATLAB:UndefinedFunction');
verifyEqual(t,path,oldPath);verifyEqual(t,pwd,oldPwd);
z=jsondecode(fileread(fullfile(f.root,'output/run_manifest.json')));
verifyEqual(t,z.identifier,'MATLAB:UndefinedFunction');
trace=readTrace(f);verifyTrue(t,any(string({trace.event})=="cold_study3"));
verifyFalse(t,any(string({trace.event})=="original_entry"));preserve(t,f);
end
function test_production_callback_both_real_reset_sequences(t)
f=fixture(t,false);beforePath=path;beforePwd=pwd;
for study=["study3","study4"]
 out=fullfile(f.root,"output_"+study);
 p07_path_fixture_ejc(char(study),OutputDirectory=out);
 verifyEqual(t,path,beforePath);verifyEqual(t,pwd,beforePwd);
 z=jsondecode(fileread(fullfile(out,'run_manifest.json')));verifyEqual(t,z.status,'PASSED');
end
trace=readTrace(f);entries=trace(string({trace.event})=="original_entry");
verifyEqual(t,numel(entries),2);verifyEqual(t,string({entries.study}),["study3","study4"]);
for j=1:2
 s="study"+(j+2);verifyEqual(t,string(entries(j).source),string(fullfile(f.root,"output_"+s,s)));
 verifyEqual(t,entries(j).cfg.fixtureStage,j+2);
 verifyEqual(t,string(entries(j).output),string(fullfile(f.root,"output_"+s,"validity_"+s,'original_requirements')));
 verifyEqual(t,string(entries(j).resolved),string(fullfile(f.root,'studies/p07/ejc_study34_verify.m')));
 verifyTrue(t,any(string({trace.event})=="cold_"+s));
end
verifyEqual(t,nnz(string({trace.event})=="portable_entry"),2);preserve(t,f);
end
function test_failure_after_entry_restores_and_stops_later_stages(t)
f=fixture(t,false);writeJSON(fullfile(f.root,'control.json'),struct('failStage','study3'));
a=path;b=pwd;
verifyError(t,@()p07_path_fixture_ejc('full',OutputDirectory=fullfile(f.root,'output')),'p07fixture:VerifierFailure');
verifyEqual(t,path,a);verifyEqual(t,pwd,b);
z=jsondecode(fileread(fullfile(f.root,'output/run_manifest.json')));
verifyEqual(t,z.status,'FAILED_OR_BLOCKED');verifyEqual(t,z.identifier,'p07fixture:VerifierFailure');
trace=readTrace(f);verifyTrue(t,any(string({trace.event})=="original_entry"));
verifyFalse(t,any(string({trace.event})=="cold_study4"));
verifyFalse(t,isfolder(fullfile(f.root,'output/study4')));preserve(t,f);
end
function test_all_stage_and_final_dispatch_boundaries(t)
f=fixture(t,false);a=path;b=pwd;
p07_path_fixture_ejc('full',OutputDirectory=fullfile(f.root,'output'));
verifyEqual(t,path,a);verifyEqual(t,pwd,b);trace=readTrace(f);events=string({trace.event});
for j=1:6,verifyEqual(t,nnz(events=="cold_study"+j),1);end
for j=[1 2 5 6],verifyEqual(t,nnz(events=="validity_dispatch_study"+j),1);end
for key=["p06_prerequisites","p06_dispatch","paper_dispatch","figure_dispatch"]
 verifyEqual(t,nnz(events==key),1);
end
verifyEqual(t,nnz(events=="comparison_dispatch"),7);preserve(t,f);
end
function test_missing_verifier_fails_closed(t)
f=fixture(t,false);movefile(fullfile(f.root,'studies/p07/ejc_study34_verify.m'),fullfile(f.root,'preserved_verifier.txt'));
verifyError(t,@()ejc_study34_callback(f.root,"study3",fullfile(f.root,'evidence_new')),'ejc:CallbackMissingSource');
end
function test_missing_helper_fails_closed(t)
f=fixture(t,false);movefile(fullfile(f.root,'studies/p07/ejc_study34_bind.m'),fullfile(f.root,'preserved_bind.txt'));
verifyError(t,@()ejc_study34_callback(f.root,"study3",fullfile(f.root,'evidence_new')),'ejc:CallbackMissingSource');
end
function test_wrong_checkout_and_shadow_fail_closed(t)
f=fixture(t,false);
verifyError(t,@()ejc_study34_callback(t.TestData.root,"study3",fullfile(f.root,'evidence_new')),'ejc:CallbackCheckout');
[callback,source,cfg]=direct(f);mkdir(fullfile(f.root,'shadow'));copyfile(fullfile(f.root,'studies/p07/ejc_study34_verify.m'),fullfile(f.root,'shadow/ejc_study34_verify.m'));
rmpath(fullfile(f.root,'studies/p07'));addpath(fullfile(f.root,'shadow'));a=path;b=pwd;
verifyError(t,@()callback(source,cfg),'ejc:CallbackResolution');verifyEqual(t,path,a);verifyEqual(t,pwd,b);
end
function test_current_directory_helper_shadow_fails_closed(t)
f=fixture(t,false);[callback,source,cfg]=direct(f);
copyfile(fullfile(f.root,'studies/p07/ejc_study34_bind.m'),fullfile(f.root,'ejc_study34_bind.m'));
verifyError(t,@()callback(source,cfg),'ejc:CallbackResolution');
end
function test_stale_source_pin_and_after_capture_change_fail_closed(t)
f=fixture(t,false);file=fullfile(f.root,'studies/p07/ejc_study34_bind.m');
write(file,[fileread(file) newline '% changed']);
verifyError(t,@()ejc_study34_callback(f.root,"study3",fullfile(f.root,'evidence_new')),'ejc:CallbackSource');
end
function test_source_changes_after_capture_fail_closed(t)
f=fixture(t,false);[callback,source,cfg]=direct(f);file=fullfile(f.root,'studies/p07/ejc_study34_bind.m');
write(file,[fileread(file) newline '% changed']);
verifyError(t,@()callback(source,cfg),'ejc:CallbackSource');
end
function test_wrong_policy_fails_closed(t)
f=fixture(t,false);file=fullfile(f.root,'studies/p07/p07_acceptance_policy.json');write(file,'{"changed":true}');
verifyError(t,@()ejc_study34_callback(f.root,"study3",fullfile(f.root,'evidence_new')),'ejc:CallbackPolicy');
end
function test_mismatched_source_configuration_fails_closed(t)
f=fixture(t,false);[callback,source,cfg]=direct(f);cfg.fixtureStage=4;
verifyError(t,@()callback(source,cfg),'ejc:CallbackSourceIdentity');
end
function test_callback_success_and_error_restore_cold_caller(t)
f=fixture(t,false);[callback,source,cfg]=direct(f);restoredefaultpath;addpath(f.root,fullfile(f.root,'src'),fullfile(f.root,'studies/study3'));a=path;b=pwd;
r=callback(source,cfg);verifyTrue(t,r.passed);verifyEqual(t,path,a);verifyEqual(t,pwd,b);
% A second independently captured invocation targets a separate output. The
% injected error changes cwd/path after real wrapper entry; cleanup must run.
addpath(fullfile(f.root,'studies/p07'));callback=ejc_study34_callback(f.root,"study3",fullfile(f.root,'direct_error'));
writeJSON(fullfile(f.root,'control.json'),struct('failStage','study3'));rmpath(fullfile(f.root,'studies/p07'));a=path;
verifyError(t,@()callback(source,cfg),'p07fixture:VerifierFailure');verifyEqual(t,path,a);verifyEqual(t,pwd,b);
end
function [callback,source,cfg]=direct(f)
source=fullfile(f.root,'saved');mkdir(source);cfg=struct('fixtureStage',3);save(fullfile(source,'settings.mat'),'cfg');
callback=ejc_study34_callback(f.root,"study3",fullfile(f.root,'direct'));
end
function f=fixture(t,old)
% Isolated orchestration fixture, NEVER production data/certification. Exact
% runner setup, nested RUN_TESTS lifecycle, callback construction, dispatch,
% wrapper and cleanup are retained. Costly calculations/data/gates are mocks.
folder=t.applyFixture(matlab.unittest.fixtures.TemporaryFolderFixture);f.root=folder.Folder;
original=t.TestData.root;oldPath=path;oldPwd=pwd;
t.addTeardown(@()restore(oldPath,oldPwd));
for name=["src","tests","studies/p06","studies/p07","evidence/p07_acceptance"]
 mkdir(fullfile(f.root,name));
end
for j=1:6,mkdir(fullfile(f.root,'studies',"study"+j));end
for name=["run_tests.m","run_verification.m"],copyfile(fullfile(original,name),fullfile(f.root,name));end
text=fileread(fullfile(original,'run_ejc.m'));text=strrep(text,'function [output,sources] = run_ejc(','function [output,sources] = p07_path_fixture_ejc(');
if old
 text=strrep(text,'adapter=ejc_study34_callback(root,string(study),fullfile(output,[''validity_'' study]));', ...
 'adapter=@(source,cfg)ejc_study34_verify(string(study),source,cfg,fullfile(output,[''validity_'' study]));');
end
write(fullfile(f.root,'p07_path_fixture_ejc.m'),text);
for name=["ejc_study34_callback.m","ejc_study34_verify.m"]
 copyfile(fullfile(original,'studies/p07',name),fullfile(f.root,'studies/p07',name));
end
copyfile(fullfile(original,'studies/p07/p07_acceptance_policy.json'),fullfile(f.root,'studies/p07/p07_acceptance_policy.json'));
for j=1:6
 study="study"+j;text=fileread(fullfile(original,"run_"+study+".m"));
 start=strfind(text,"cfg = "+study+"_settings;");assert(isscalar(start));
 prefix=text(1:start-1);
 mock=sprintf('cfg=struct(''fixtureStage'',%d);mkdir(outputDir);save(fullfile(outputDir,''settings.mat''),''cfg'');assert(isempty(which(''ejc_study34_verify'')));p07_path_probe(''cold_study%d'');\n',j,j);
 if j==3 || j==4
  tail=strfind(text,'if isempty(options.VerificationAdapter)');assert(isscalar(tail));
  text=[prefix mock text(tail:end)];
 else
  % Retain the original validity/report dispatch and exit cleanup as well as
  % setup. Only fixture calculations behind those calls are replaced.
  if j==1 || j==2
   marker=study+"_verify_results(outputDir,cfg);";
  elseif j==5
   marker="summary = study5_summarize(outputDir,cfg);";
  else
   marker="verification = study6_verify_results(outputDir);";
  end
  tail=strfind(text,marker);assert(isscalar(tail));
  text=[prefix mock text(tail:end)];
 end
 write(fullfile(f.root,"run_"+study+".m"),text);
end
write(fullfile(f.root,'tests/test_lifecycle_core.m'),sprintf(['function t=test_lifecycle_core\nt=functiontests(localfunctions);end\n' ...
 'function test_nested_cold_path(t)\nverifyTrue(t,isempty(which(''ejc_study34_verify'')));end\n']));
write(fullfile(f.root,'p07_path_probe.m'),sprintf(['function p07_path_probe(event,varargin)\n' ...
 'root=fileparts(mfilename(''fullpath''));file=fullfile(root,''trace.mat'');trace=struct(''event'',{},''study'',{},''source'',{},''cfg'',{},''output'',{},''resolved'',{},''cwd'',{},''path'',{});\n' ...
 'if isfile(file),z=load(file);trace=z.trace;end\n' ...
 'r=struct(''event'',event,''study'','''',''source'','''',''cfg'',struct,''output'','''',''resolved'',which(''ejc_study34_verify''),''cwd'',pwd,''path'',path);\n' ...
 'if numel(varargin)==4,r.study=varargin{1};r.source=varargin{2};r.cfg=varargin{3};r.output=varargin{4};end\n' ...
 'trace(end+1)=r;save(file,''trace'');end\n']));
stub(f,'ejc_output_path','function p=ejc_output_path(~,p),p=char(p);end');
stub(f,'ejc_source_revision','function r=ejc_source_revision,r=struct(''sourceSHA'',''ISOLATED_MOCK_NOT_A_CANDIDATE'',''clean'',true);end');
stub(f,'ejc_portable_candidate','function r=ejc_portable_candidate(varargin),r=ejc_source_revision;r.policySHA256=''FIXTURE_ONLY'';end','studies/p07');
referenceCode=fileread(fullfile(original,'ejc_reference_sources.m'));
referenceCode=strrep(referenceCode,"root = fileparts(mfilename('fullpath'));","root = '"+string(original)+"';");
write(fullfile(f.root,'ejc_reference_sources.m'),referenceCode);
stub(f,'ejc_archive_integrity','function r=ejc_archive_integrity(varargin),r=struct(''fileCount'',3022,''totalBytes'',1357579926,''allPassed'',true);end');
stub(f,'ejc_assert_writable','function ejc_assert_writable(varargin),end');
for j=[1 2 5 6]
 name="study"+j+"_verify_results";
 stub(f,name,"function r="+name+"(varargin),p07_path_probe('validity_dispatch_study"+j+"');r=struct;end","studies/study"+j);
end
for j=[1 2 5],stub(f,"study"+j+"_summarize","function r=study"+j+"_summarize(varargin),r=struct;end");end
for j=3:4
 stub(f,"study"+j+"_summarize","function r=study"+j+"_summarize(varargin),r=struct;end");
 stub(f,"study"+j+"_verify_results","function study"+j+"_verify_results(varargin),error('p07fixture:UnexpectedStrict','Strict fallback forbidden in this portable fixture.');end","studies/study"+j);
end
stub(f,'ejc_study34_extract',sprintf(['function r=ejc_study34_extract(study,source,cfg,output)\n' ...
 'p07_path_probe(''original_entry'',study,source,cfg,output);root=fileparts(fileparts(fileparts(mfilename(''fullpath''))));\n' ...
 'file=fullfile(root,''control.json'');if isfile(file),c=jsondecode(fileread(file));if string(c.failStage)==study,cd(fullfile(root,''src''));addpath(fullfile(root,''tests''));error(''p07fixture:VerifierFailure'',''Injected after production wrapper entry.'');end,end\n' ...
 'r=struct(''originalRequirementsCompleted'',true);end\n']),'studies/p07');
stub(f,'ejc_study34_bind','function r=ejc_study34_bind(varargin),p07_path_probe(''portable_entry'');r=struct(''passed'',true);end','studies/p07');
stub(f,'ejc_compare_portable_results',sprintf(['function r=ejc_compare_portable_results(one,varargin)\n' ...
 'p07_path_probe(''comparison_dispatch'');n=0;if isfield(one,''study1''),n=2877;end\n' ...
 'a=zeros(n,1);if n>0,a(1)=2073;end;r=struct(''passed'',true,''files'',table(a,a,''VariableNames'',{''attemptedRuns'',''completedRuns''}),''exclusions'',table(strings(0,1),''VariableNames'',{''reason''}),''qualifiedInstances'',0,''claimApplicabilityInstances'',0,''rawClaimDifferences'',0);\n' ...
 'if n>0,r.exclusions=table(repmat("Approved Study 1 pilot legacy omission only",24,1),''VariableNames'',{''reason''});end,end\n']),'studies/p07');
stub(f,'ejc_validate_sources','function r=ejc_validate_sources(varargin),r=struct;end');
stub(f,'ejc_study6_source_checks','function r=ejc_study6_source_checks(varargin),r=struct(''diagnosticBatches'',329);end','studies/p07');
stub(f,'ejc_p06_portable_tests','function r=ejc_p06_portable_tests(varargin),p07_path_probe(''p06_prerequisites'');r=struct;end','studies/p07');
% Preserve the original P06 setup/dispatch, replace only its large execution.
copyfile(fullfile(original,'studies/p06/run_p06.m'),fullfile(f.root,'studies/p06/run_p06.m'));
stub(f,'p06_plan','function [p,m]=p06_plan,p=struct;m=table(1);end','studies/p06');
stub(f,'p06_execute','function p06_execute(varargin),p07_path_probe(''p06_dispatch'');end','studies/p06');
stub(f,'ejc_paper_portable','function r=ejc_paper_portable(varargin),p07_path_probe(''paper_dispatch'');c=struct(''claimApplicabilityInstances'',0,''rawClaimDifferences'',0);r=struct(''passed'',true,''exportChecks'',c,''portable'',struct(''table12'',c));end','studies/p07');
stub(f,'ejc_journal_figures','function r=ejc_journal_figures(varargin),p07_path_probe(''figure_dispatch'');r=struct;end','studies/p07');
stub(f,'ejc_acceptance_verdict','function r=ejc_acceptance_verdict(varargin),r=struct;end','studies/p07');
files=dir(fullfile(f.root,'studies/p07/*.m'));pins=struct('path',{},'sha256',{});
for k=1:numel(files),rel=['studies/p07/' files(k).name];pins(end+1)=struct('path',rel,'sha256',ejc_file_sha256(fullfile(f.root,rel)));end
for j=3:4,rel=sprintf('studies/study%d/study%d_verify_results.m',j,j);pins(end+1)=struct('path',rel,'sha256',ejc_file_sha256(fullfile(f.root,rel)));end
writeJSON(fullfile(f.root,'evidence/p07_acceptance/IMPLEMENTATION_GATE.json'),struct('policySHA256',ejc_file_sha256(fullfile(f.root,'studies/p07/p07_acceptance_policy.json')),'sourceFiles',pins));
cd(f.root);addpath(f.root,fullfile(f.root,'studies/p07'),fullfile(f.root,'studies/study3'),fullfile(f.root,'studies/study4'));
end
function stub(f,name,text,folder)
if nargin<4,folder='';end
write(fullfile(f.root,folder,string(name)+".m"),text);
end
function trace=readTrace(f),z=load(fullfile(f.root,'trace.mat'));trace=z.trace;end
function preserve(t,f)
where=getenv('P07_PATH_LIFECYCLE_EVIDENCE');if isempty(where),return;end
stack=dbstack;name=strrep(stack(2).name,'>','_');out=fullfile(where,name);assert(~isfolder(out));mkdir(out);
copyfile(fullfile(f.root,'trace.mat'),fullfile(out,'trace.mat'));
z=readTrace(f);writeJSON(fullfile(out,'trace.json'),z);
files=dir(fullfile(f.root,'**/run_manifest.json'));
for j=1:numel(files),copyfile(fullfile(files(j).folder,files(j).name),fullfile(out,sprintf('fixture_manifest_%d.json',j)));end
end
function restore(p,d),cd(d);path(p);end
function writeJSON(file,v),write(file,jsonencode(v,PrettyPrint=true));end
function write(file,text),fid=fopen(file,'w');assert(fid>=0);c=onCleanup(@()fclose(fid));fprintf(fid,'%s',text);end
