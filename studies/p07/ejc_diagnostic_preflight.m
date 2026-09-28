function report=ejc_diagnostic_preflight(output,snapshotFile,authorization)
%EJC_DIAGNOSTIC_PREFLIGHT Consolidated development diagnostics, never certification.
assert(strcmp(authorization,'P07_DIAGNOSTIC_ONLY_AUTHORIZED'),'ejc:DiagnosticAuthorization','Explicit bounded authorization required.');
assert(~isfolder(output) && ~isfile(output),'ejc:ExistingEvidence','New diagnostic batch required; no retries.');
root=fileparts(fileparts(fileparts(mfilename('fullpath'))));
previous=path;restore=onCleanup(@()path(previous));
addpath(root,fullfile(root,'src'),fullfile(root,'studies/p07'),fullfile(root,'studies/p06'));
for j=1:6,addpath(fullfile(root,'studies',sprintf('study%d',j)));end
snapshot=jsondecode(fileread(snapshotFile));boundInputSnapshots=struct;guard;
assert(contains(version,'(R2026a) Update 5') && strcmp(getfield(ver('optim'),'Version'),'26.1'), ...
 'ejc:Environment','Required MATLAB/toolbox mismatch.');
assert(java.io.File(fileparts(output)).getUsableSpace()>=4.1e9,'ejc:Storage','Insufficient space.');
mkdir(output);started=tic;
report=struct('mode',"CONSOLIDATED_DIAGNOSTIC_PREFLIGHT_NOT_CERTIFICATION",'baseCandidate',snapshot.baseCandidate, ...
 'policySHA256',snapshot.policySHA256,'developmentSnapshotSHA256',ejc_file_sha256(snapshotFile), ...
 'status',"RUNNING",'startedUTC',string(datetime('now','TimeZone','UTC')), ...
 'stages',struct([]),'selfConsistency',struct([]),'paper',struct,'figures',struct([]));
report.environment=struct('MATLAB',version,'computer',computer,'optimization',ver('optim'), ...
 'BLAS',version('-blas'),'LAPACK',version('-lapack'),'maxNumCompThreads',maxNumCompThreads, ...
 'OMP_NUM_THREADS',getenv('OMP_NUM_THREADS'),'MKL_NUM_THREADS',getenv('MKL_NUM_THREADS'),'OPENBLAS_NUM_THREADS',getenv('OPENBLAS_NUM_THREADS'));
[~,report.environment.macOS]=system('sw_vers');[~,report.environment.CPU]=system('sysctl -n machdep.cpu.brand_string');
refs=ejc_reference_sources;sources=struct;valid=struct;agreements=struct;
expectedFiles=[535 46 316 39 34 341 1566];expectedCases=[258 22 218 12 5 0 1558];
% These counts are checked against the immutable scientific inventory below.
expected=readtable(fullfile(root,'results/p07_mac_full_de77ad7_20260927_01/expected_scientific_files.csv'),'TextType','string');
assert(height(expected)==2877,'ejc:PreflightIntegrity','Required inventory changed.');
for j=1:7
 key="study"+j;if j==7,key="p06";end
 expectedFiles(j)=nnz(expected.study==key);
end
report.expectedScientificFiles=2877;report.expectedControlCases=2073;report.expectedDiagnosticBatches=329;
saveProgress;
try
 for j=[1 2 3 4 5 7 6]
  key="study"+j;if j==7,key="p06";end
  guard;clock=tic;
  stage=struct('study',key,'source',"",'mode',"MISSING_MAC_DIAGNOSTIC_COMPUTATION",'originalValidityPassed',false, ...
   'comparisonPassed',false,'status',"NOT_RUN",'expectedFiles',expectedFiles(j),'expectedControlCases',expectedCases(j), ...
   'generatedControlCases',0,'generatedCompletedCases',0,'scientificFiles',0,'passedFiles',0,'failedFiles',0,'failedChecks',0,'attemptedControlCases',0,'completedControlCases',0, ...
   'gramQualifications',0,'claimInstances',0,'rawClaimDifferences',0,'locatorInstances',0,'locatorDifferences',0, ...
   'legacyOmissions',0,'generatingBaseCommit',string(snapshot.baseCandidate),'generatingTreeKind',"UNCOMMITTED_VERIFICATION_ONLY_DEVELOPMENT", ...
   'generatingVerificationSnapshotSHA256',string(report.developmentSnapshotSHA256),'generatingPolicySHA256',string(snapshot.policySHA256),'verifyingSnapshotSHA256',string(report.developmentSnapshotSHA256), ...
   'scientificSourceSHA256',string(snapshot.scientificSourceSHA256),'elapsedSeconds',0,'identifier',"",'exception',"");
  fprintf('PREFLIGHT STAGE %s START\n',key);
  try
   if j<=2
    target=fullfile(root,'results/p07_mac_full_de77ad7_20260927_01',key);stage.source=string(target);
    stage.mode="REUSED_DE77AD7_MAC_SAVED_OUTPUTS_NO_TRAJECTORIES";
    stage.generatingTreeKind="FROZEN_COMMIT";stage.generatingVerificationSnapshotSHA256="";
    stage.generatingPolicySHA256="8904e6c9b844da08009f3f852353f884ab8602455418873e0e16c846d8efb288";
    z=load(fullfile(target,'settings.mat'),'cfg');verifier=str2func(key+"_verify_results");verifier(target,z.cfg);
   elseif j==6
    ok=all(arrayfun(@(n)isfield(valid,"study"+n)&&valid.("study"+n),1:5));
    if ~ok
     stage.status=ejc_preflight_branch(true,true,true,false);report.stages=[report.stages;stage];saveProgress;continue
    end
    target=fullfile(output,key);stage.source=string(target);parents=rmfield_if_present(sources,'p06');
    provenance=struct('diagnosticOnly',true,'originalValidityPassed',true(1,5), ...
     'inputSnapshot',ejc_input_snapshot(parents,struct),'developmentSnapshotSHA256',report.developmentSnapshotSHA256, ...
     'parentStages',report.stages(ismember([report.stages.study],"study"+(1:5))));
    ejc_preflight_study6(target,parents,provenance);
    links=ejc_study6_source_checks(target,parents,fullfile(output,'study6_source_checks'));
    report.study6DiagnosticBatches=links.diagnosticBatches;
   elseif j==7
    target=fullfile(output,key);stage.source=string(target);ejc_p06_portable_tests(fullfile(output,'p06_prerequisites'));
    run_p06(target,'execute','P06_PRODUCTION_AUTHORIZED');
    listing=ejc_csv_read(fullfile(target,'tables/runs.csv'),"p06","tables/runs.csv");
    assert(height(listing)==1558 && all(listing.completed) && all(listing.predictionCompleted), ...
     'ejc:OriginalValidity','P06 contains missing, invalid or incomplete cases.');
   else
    target=fullfile(output,key);stage.source=string(target);runner=str2func("run_"+key);
    if any(j==[3 4])
     handle=@ejc_preflight_study34;adapter=@(d,c)handle(key,d,c,fullfile(output,"validity_"+key));
     runner(target,Figures=false,ReferenceDirectory=refs.(key),VerificationAdapter=adapter);
    else,runner(target,Figures=false,ReferenceDirectory=refs.(key));end
   end
   stage.source=string(target);sources.(key)=target;valid.(key)=true;stage.originalValidityPassed=true;
   one=struct;one.(key)=target;boundInputSnapshots.(key)=ejc_input_snapshot(one,struct);
   comparison=ejc_compare_portable_results(one,refs,fullfile(output,"comparison_"+key),sources,"COLLECT_DIAGNOSTIC_FAILURES");
   stage=counts(stage,comparison);stage.comparisonPassed=comparison.passed;
   if any(j==[3 4])
    v=load(fullfile(output,"validity_"+key,'portable_assertions/portable_summary.mat'),'report');
    stage.comparisonPassed=stage.comparisonPassed && v.report.passed;
   end
   agreements.(key)=stage.comparisonPassed;
   stage.status=ejc_preflight_branch(true,true,stage.comparisonPassed,true);
  catch e
   guard;ejc_preflight_integrity_exception(e); % Integrity always escapes the stage collector.
   stage.identifier=string(e.identifier);stage.exception=string(getReport(e,'extended','hyperlinks','off'));
   if ~stage.originalValidityPassed
    valid.(key)=false;stage.status=ejc_preflight_branch(true,false,false,true);
   else,stage.status="BLOCKED_COMPARISON_COMPONENT";end
  end
  guard;[stage.generatedControlCases,stage.generatedCompletedCases]=saved_cases(stage.source,key);stage.elapsedSeconds=toc(clock);report.stages=[report.stages;stage];saveProgress;
  fprintf('PREFLIGHT STAGE %s %s (%.3f seconds)\n',key,stage.status,stage.elapsedSeconds);
 end
 % Historical records are independent schema/own-validity exercises only.
 for j=1:7
  key="study"+j;if j==7,key="p06";end
  guard;clock=tic;s=struct('study',key,'mode',"SELF_CONSISTENCY_NOT_CROSS_PLATFORM",'passed',false, ...
   'files',0,'failedFiles',0,'failedChecks',0,'elapsedSeconds',0,'identifier',"",'exception',"");
  try
   if j<=5
    z=load(fullfile(refs.(key),'settings.mat'),'cfg');
    if any(j==[3 4]),v=ejc_preflight_study34(key,refs.(key),z.cfg,fullfile(output,"self_validity_"+key));
    else,verifier=str2func(key+"_verify_results");verifier(refs.(key),z.cfg);v=struct('passed',true);end
   else,v=struct('passed',true);end
   one=struct;one.(key)=refs.(key);
   r=ejc_compare_portable_results(one,refs,fullfile(output,"self_comparison_"+key),refs,"COLLECT_DIAGNOSTIC_FAILURES");
   s.passed=r.passed && v.passed;s.files=height(r.files);s.failedFiles=nnz(~r.files.passed);s.failedChecks=height(r.failures);
  catch e
   guard;ejc_preflight_integrity_exception(e);s.identifier=string(e.identifier);s.exception=string(getReport(e,'extended','hyperlinks','off'));
  end
  guard;s.elapsedSeconds=toc(clock);report.selfConsistency=[report.selfConsistency;s];saveProgress;
 end
 % Full source bindings are required: never silently substitute historical data.
 if numel(fieldnames(valid))==7 && all(structfun(@(x)x,valid))
  paperAttempt(sources,"MAC_DIAGNOSTIC_SOURCES",'paper_mac');
 else
  report.paper.mac=struct('status',"BLOCKED_DEPENDENCY",'passed',false,'sourceSet',sources);saveProgress;
 end
 paperAttempt(refs,"SELF_CONSISTENCY_NOT_CROSS_PLATFORM",'paper_self');
 for j=1:6
  key="study"+j;s=struct('study',key,'passed',false,'status',"BLOCKED_DEPENDENCY",'exception',"");
  if isfield(valid,key)&&valid.(key)
   try
    guard;
    if j==2
     ejc_study2_portable_report(sources.study2,refs.study2,fullfile(output,'figures',key));
    else
     plotter=str2func("plot_study"+j+"_journal");plotter(sources.(key),fullfile(output,'figures',key));
    end
    s.passed=true;s.status="DIAGNOSTIC_PLOT_DEPENDENCIES_EXECUTED";
   catch e,guard;ejc_preflight_integrity_exception(e);s.status="FAILED_PLOT_COMPONENT";s.exception=string(getReport(e,'extended','hyperlinks','off'));end
  end
  report.figures=[report.figures;s];saveProgress;
 end
 guard;report.status="DIAGNOSTIC_COLLECTION_COMPLETE_REVIEW_REQUIRED";
catch e
 report.status="STOPPED_INTEGRITY_OR_ORCHESTRATION_FAILURE";report.fatalIdentifier=string(e.identifier);
 report.fatalException=string(getReport(e,'extended','hyperlinks','off'));saveProgress;rethrow(e)
end
report.elapsedSeconds=toc(started);report.completedUTC=string(datetime('now','TimeZone','UTC'));saveProgress;
 function guard
  revision=ejc_source_revision;
  assert(strcmp(revision.sourceSHA,snapshot.baseCandidate),'ejc:PreflightIntegrity','Base commit changed.');
  for group=string(fieldnames(boundInputSnapshots)).'
   one=struct;one.(group)=sources.(group);
   assert(isequaln(boundInputSnapshots.(group),ejc_input_snapshot(one,struct)), ...
    'ejc:PreflightIntegrity','Previously validated Mac input bytes changed: %s.',group);
  end
  for record=reshape(snapshot.files,1,[])
   f=fullfile(root,record.path);info=dir(f);
   assert(isscalar(info) && info.bytes==record.bytes && strcmp(ejc_file_sha256(f),record.sha256), ...
    'ejc:PreflightIntegrity','Frozen diagnostic dependency changed: %s.',record.path);
  end
 end
 function saveProgress
  report.elapsedSeconds=toc(started);
  save(fullfile(output,'diagnostic_report.mat'),'report','-v7');
  fid=fopen(fullfile(output,'diagnostic_report.json'),'w');c=onCleanup(@()fclose(fid));fprintf(fid,'%s\n',jsonencode(report,PrettyPrint=true));
 end
 function paperAttempt(selected,mode,folder)
  try
   guard;r=ejc_paper_portable(selected,refs,fullfile(output,folder));
   s=struct('status',"FAILED_COMPARISON",'passed',r.passed,'mode',mode,'sourceSet',selected, ...
    'exportFamilies',r.exportChecks.csvFamilies,'exportFields',r.exportChecks.fieldComparisons, ...
    'conditioningFields',r.portable.conditioning.fields,'table12Fields',r.portable.table12.fields);
   if r.passed,s.status="DIAGNOSTIC_COMPONENT_PASSED";end
  catch e
   guard;ejc_preflight_integrity_exception(e);s=struct('status',"BLOCKED_PAPER_COMPONENT",'passed',false,'mode',mode,'sourceSet',selected, ...
    'identifier',string(e.identifier),'exception',string(getReport(e,'extended','hyperlinks','off')));
  end
  guard;report.paper.(folder)=s;saveProgress;
 end
end
function s=counts(s,r)
s.scientificFiles=height(r.files);s.passedFiles=nnz(r.files.passed);s.failedFiles=nnz(~r.files.passed);s.failedChecks=height(r.failures);
s.attemptedControlCases=sum(r.files.attemptedRuns);s.completedControlCases=sum(r.files.completedRuns);
s.gramQualifications=r.qualifiedInstances;s.claimInstances=r.claimApplicabilityInstances;s.rawClaimDifferences=r.rawClaimDifferences;
s.locatorInstances=r.maximumLocatorInstances;s.locatorDifferences=r.maximumLocatorDifferences;
s.legacyOmissions=nnz(startsWith(r.exclusions.reason,"Approved Study 1 pilot legacy omission only"));
end
function s=rmfield_if_present(s,name)
if isfield(s,name),s=rmfield(s,name);end
end

function [attempted,completed]=saved_cases(source,key)
attempted=0;completed=0;if strlength(source)==0 || ~isfolder(source) || key=="study6",return;end
folder="runs";pattern="*.mat";if key=="study1",folder="data";pattern="*.mat";end
for f=dir(fullfile(source,folder,pattern)).'
 z=load(fullfile(f.folder,f.name),'result');
 if isfield(z,'result') && isstruct(z.result) && isfield(z.result,'completed')
  attempted=attempted+1;completed=completed+double(z.result.completed);
 end
end
end
