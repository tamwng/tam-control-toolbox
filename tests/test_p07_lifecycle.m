function tests=test_p07_lifecycle
tests=functiontests(localfunctions);
end
function setupOnce(t)
root=fileparts(fileparts(mfilename('fullpath')));t.TestData.path=path;t.TestData.root=root;
addpath(root,fullfile(root,'studies/p07'));
end
function teardownOnce(t)
path(t.TestData.path);
end
function test_quick_full_cannot_overwrite_or_bypass_gate(t)
f=t.applyFixture(matlab.unittest.fixtures.TemporaryFolderFixture);
marker=fullfile(f.Folder,'preserve.txt');fid=fopen(marker,'w');fprintf(fid,'existing evidence');fclose(fid);
revision=ejc_source_revision;p=jsondecode(fileread(fullfile(t.TestData.root,'studies/p07/p07_acceptance_policy.json')));
expected='ejc:ExistingOutput';
if ~revision.clean,expected='ejc:DirtySource';elseif ~p.active,expected='ejc:InactivePolicy';end
before=rng;
for mode={'quick','full'}
    verifyError(t,@()run_ejc(mode{1},OutputDirectory=f.Folder),expected);
    verifyEqual(t,fileread(marker),'existing evidence');verifyEqual(t,rng,before);
end
verifyEqual(t,numel(dir(fullfile(f.Folder,'*'))),3);
end
function test_missing_original_checks_cannot_run_binding(t)
f=t.applyFixture(matlab.unittest.fixtures.TemporaryFolderFixture);
e=struct('study',"study3",'originalRequirementsCompleted',false,'status',"FAILED_ORIGINAL_REQUIREMENT");
verifyError(t,@()ejc_study34_bind(e,struct,fullfile(f.Folder,'incomplete')), 'ejc:MissingOriginalChecks');
end
function test_source_identity_guard_is_read_only(t)
r=ejc_source_revision;before=rng;
if ~r.clean,verifyError(t,@()ejc_portable_candidate,'ejc:DirtySource');end
verifyEqual(t,rng,before);verifyEqual(t,ejc_source_revision,r);
end
