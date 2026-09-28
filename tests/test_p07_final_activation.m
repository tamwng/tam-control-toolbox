function tests=test_p07_final_activation
tests=functiontests(localfunctions);
end
function setupOnce(t)
t.TestData.root=fileparts(fileparts(mfilename('fullpath')));t.TestData.path=path;
addpath(t.TestData.root,fullfile(t.TestData.root,'src'),fullfile(t.TestData.root,'studies/p07'));
for k=1:6,addpath(fullfile(t.TestData.root,'studies',sprintf('study%d',k)));end
end
function teardownOnce(t),path(t.TestData.path);end

function test_valid_clean_frozen_gate_and_expected_identity(t)
f=fixture(t);r=p07_fixture_candidate;verifyTrue(t,r.clean);
verifyEqual(t,r.policySHA256,ejc_file_sha256(f.policy));
verifyEqual(t,p07_fixture_candidate(r),r);
bad=r;bad.policySHA256=repmat('0',1,64);
verifyError(t,@()p07_fixture_candidate(bad),'ejc:CandidateChanged');
bad=r;bad.implementationGateSHA256=repmat('0',1,64);
verifyError(t,@()p07_fixture_candidate(bad),'ejc:CandidateChanged');
end
function test_dirty_candidate_still_fails_before_execution(t)
f=fixture(t);write(fullfile(f.root,'unexpected.txt'),'uncommitted');
verifyError(t,@p07_fixture_candidate,'ejc:DirtySource');
verifyEqual(t,fileread(fullfile(f.root,'unexpected.txt')),'uncommitted');
end
function test_inactive_or_unfrozen_policy_fails_on_clean_commit(t)
for which=1:2
 f=fixture(t);p=jsondecode(fileread(f.policy));
 if which==1,p.active=false;else,p.status='AUTHOR_APPROVED_DIAGNOSTIC_DEVELOPMENT_REQUIREMENTS';end
 writeJSON(f.policy,p);commitFixture(f.root);
 verifyError(t,@p07_fixture_candidate,'ejc:InactivePolicy');
end
end
function test_missing_stale_or_incomplete_gate_fails(t)
for which=1:5
 f=fixture(t);g=jsondecode(fileread(f.gate));expected='ejc:ImplementationGate';
 if which==1
  movefile(f.gate,fullfile(f.root,'preserved_gate.json'));expected='ejc:MissingImplementationGate';
 else
  if which==2,g.policySHA256=repmat('0',1,64);end
  if which==3,g.tests.failed=1;end
  if which==4,g.savedData.blocked=1;end
  if which==5,g.integrity.allPassed=false;end
  writeJSON(f.gate,g);
 end
 commitFixture(f.root);verifyError(t,@p07_fixture_candidate,expected);
end
end
function test_source_pin_still_rejects_committed_dependency_change(t)
f=fixture(t);write(fullfile(f.root,'dependency.txt'),'changed');commitFixture(f.root);
verifyError(t,@p07_fixture_candidate,'ejc:StaleImplementationGate');
end
function test_production_figure_dispatch_executes_all_six_saved_paths(t)
refs=ejc_reference_sources;before=ejc_input_snapshot(refs,refs);
f=t.applyFixture(matlab.unittest.fixtures.TemporaryFolderFixture);
r=ejc_journal_figures(fullfile(f.Folder,'figures'),refs,true);
verifyTrue(t,r.passed);verifyEqual(t,r.figureCount,6);
verifyTrue(t,r.study2.passed);verifyEqual(t,r.study2.gram.adaptiveRows,15);
verifyEqual(t,r.study2.totalRows,18);verifyEqual(t,r.study2.knownModelNARows,3);
verifyEqual(t,r.study2.exactPlottedPoints,33);verifyTrue(t,r.study2.sourceValuesExact);
verifyEqual(t,r.study2.gram.selectedParentChecks,11250);
verifyEqual(t,ejc_input_snapshot(refs,refs),before);
% Historical source self-check only; this is not fresh/cross-platform evidence.
end
function test_production_figure_dispatch_does_not_skip_failed_B2(t)
refs=ejc_reference_sources;bad=refs;bad.study2=refs.study1;
f=t.applyFixture(matlab.unittest.fixtures.TemporaryFolderFixture);out=fullfile(f.Folder,'failed');
failure="";
try,ejc_journal_figures(out,bad,true);catch e,failure=string(e.identifier);end
verifyNotEqual(t,failure,"");verifyFalse(t,isfolder(fullfile(out,'figures','study3')));
verifyError(t,@()ejc_journal_figures(out,refs,"skip"),'ejc:FigureMode');
end

function f=fixture(t)
% Run the exact lifecycle code in a tiny isolated Git fixture. Only helper
% symbols are renamed so production functions/path caches remain untouched.
folder=t.applyFixture(matlab.unittest.fixtures.TemporaryFolderFixture);f.root=folder.Folder;
sub=fullfile(f.root,'studies/p07');mkdir(sub);mkdir(fullfile(f.root,'evidence/p07_acceptance'));
names={'ejc_portable_candidate','p07_fixture_candidate';'ejc_source_revision','p07_fixture_revision';'ejc_file_sha256','p07_fixture_sha'};
for k=1:3
 src=which(names{k,1});text=fileread(src);
 for j=1:3,text=strrep(text,names{j,1},names{j,2});end
 target=sub;if k==2,target=f.root;end
 write(fullfile(target,[names{k,2},'.m']),text);
end
t.applyFixture(matlab.unittest.fixtures.PathFixture(f.root));t.applyFixture(matlab.unittest.fixtures.PathFixture(sub));
clear p07_fixture_candidate p07_fixture_revision p07_fixture_sha
f.policy=fullfile(sub,'p07_acceptance_policy.json');f.gate=fullfile(f.root,'evidence/p07_acceptance/IMPLEMENTATION_GATE.json');
writeJSON(f.policy,struct('active',true,'status','AUTHOR_APPROVED_FROZEN_REQUIREMENTS','policy_id','LIFECYCLE_TEST_ONLY'));
write(fullfile(f.root,'dependency.txt'),'unchanged');
g=struct('status','PASSED','policySHA256',ejc_file_sha256(f.policy), ...
 'tests',struct('failed',0,'incomplete',0,'passed',1,'total',1), ...
 'savedData',struct('failed',0,'blocked',0,'complete',true), ...
 'integrity',struct('fileCount',3022,'totalBytes',1357579926,'allPassed',true), ...
 'sourceFiles',struct('path','dependency.txt','sha256',ejc_file_sha256(fullfile(f.root,'dependency.txt'))));
writeJSON(f.gate,g);
[status,message]=system(sprintf('git -C "%s" init --quiet',f.root));assert(status==0,'test:Git','%s',message);commitFixture(f.root);
end
function commitFixture(root)
[status,message]=system(sprintf('git -C "%s" add --all',root));assert(status==0,'test:Git','%s',message);
[status,message]=system(sprintf('git -C "%s" -c core.hooksPath=/dev/null -c commit.gpgsign=false -c user.name="P07 Fixture" -c user.email="p07-fixture@localhost" commit --quiet -m "Lifecycle fixture"',root));
assert(status==0,'test:Git','%s',message);
end
function writeJSON(file,value),write(file,jsonencode(value,PrettyPrint=true));end
function write(file,value)
fid=fopen(file,'w');assert(fid>=0);c=onCleanup(@()fclose(fid));fprintf(fid,'%s',value);
end
