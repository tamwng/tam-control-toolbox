function tests=test_p07_reporting_hook_integrity
tests=functiontests(localfunctions);
end
function setupOnce(t)
t.TestData.path=path;t.TestData.root=fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(t.TestData.root,'studies/p07'));
end
function teardownOnce(t),path(t.TestData.path);end
function test_exact_authorized_hook_preserves_original_manifest(t)
root=t.TestData.root;proof=ejc_claim_source_guard(root);
verifyTrue(t,proof.passed);verifyEqual(t,proof.dependencyCount,60);verifyEqual(t,numel(proof.authorizedReportingHooks),1);
verifyEqual(t,proof.manifestSHA256,"5ac3c1c6a9465236b1b8c5a35c99b092d5f66e17aa883eba27c6a3fe91822cd1");
end
function test_every_unlisted_source_or_hash_still_fails(t)
root=t.TestData.root;a=jsondecode(fileread(fullfile(root,'evidence/p07_acceptance/blocker_repairs/REPORTING_HOOK_INTEGRITY_ANNEX.json')));
for entry=reshape(a.entries,1,[])
 row=struct('path',entry.path,'sha256',entry.oldSHA256);
 p=ejc_reporting_hook_integrity(root,row,entry.newSHA256);verifyTrue(t,p.applied);
 p=ejc_reporting_hook_integrity(root,row,repmat('0',1,64));verifyFalse(t,p.applied);
 row.sha256=entry.newSHA256;p=ejc_reporting_hook_integrity(root,row,entry.newSHA256);verifyFalse(t,p.applied);
 row.path='src/solve_mpc.m';p=ejc_reporting_hook_integrity(root,row,entry.newSHA256);verifyFalse(t,p.applied);
end
end
function test_missing_modified_annex_authority_and_manifest_fail_closed(t)
root=t.TestData.root;relative='evidence/p07_acceptance/blocker_repairs/REPORTING_HOOK_INTEGRITY_ANNEX.json';
a=jsondecode(fileread(fullfile(root,relative)));entry=a.entries(1);row=struct('path',entry.path,'sha256',entry.oldSHA256);
for changed=["missing","annex","authority","manifest"]
 f=t.applyFixture(matlab.unittest.fixtures.TemporaryFolderFixture);
 for file=[string(relative),string(a.authority),string(a.originalScientificManifest)]
  dest=fullfile(f.Folder,file);if ~isfolder(fileparts(dest)),mkdir(fileparts(dest));end;copyfile(fullfile(root,file),dest);
 end
 if changed=="missing",target=fullfile(f.Folder,'missing-root');
 else
  target=f.Folder;file=relative;if changed=="authority",file=a.authority;elseif changed=="manifest",file=a.originalScientificManifest;end
  fid=fopen(fullfile(target,file),'a');fprintf(fid,'changed');fclose(fid);
 end
 p=ejc_reporting_hook_integrity(target,row,entry.newSHA256);verifyFalse(t,p.applied);
end
end
