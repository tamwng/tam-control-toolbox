function identity=ejc_portable_candidate(expected)
%EJC_PORTABLE_CANDIDATE Fail closed before any fresh quick/full computation.
if nargin<1,expected=[];end
root=fileparts(fileparts(fileparts(mfilename('fullpath'))));
identity=ejc_source_revision;
assert(identity.clean,'ejc:DirtySource','A clean frozen candidate is required, including quick.');
policyFile=fullfile(root,'studies/p07/p07_acceptance_policy.json');
p=jsondecode(fileread(policyFile));identity.policySHA256=ejc_file_sha256(policyFile);
identity.policyID=p.policy_id;
assert(p.active && strcmp(p.status,'AUTHOR_APPROVED_FROZEN_REQUIREMENTS'), ...
    'ejc:InactivePolicy','Portable policy is not activated after its implementation gates.');
file=fullfile(root,'evidence/p07_acceptance/IMPLEMENTATION_GATE.json');
assert(isfile(file),'ejc:MissingImplementationGate','Completed implementation evidence is required.');
g=jsondecode(fileread(file));
assert(strcmp(g.status,'PASSED') && strcmp(g.policySHA256,identity.policySHA256) && ...
    g.tests.failed==0 && g.tests.incomplete==0 && g.tests.passed==g.tests.total && ...
    g.tests.total>0 && g.savedData.failed==0 && g.savedData.blocked==0 && g.savedData.complete && ...
    g.integrity.fileCount==3022 && g.integrity.totalBytes==1357579926 && g.integrity.allPassed, ...
    'ejc:ImplementationGate','Required implementation, saved-data or integrity gate is incomplete.');
assert(~isempty(g.sourceFiles),'ejc:ImplementationGate','Missing checker source identities.');
for r=reshape(g.sourceFiles,1,[])
    assert(strcmp(r.sha256,ejc_file_sha256(fullfile(root,r.path))), ...
        'ejc:StaleImplementationGate','An implementation dependency changed: %s.',r.path);
end
identity.implementationGateSHA256=ejc_file_sha256(file);
[status,text]=system(sprintf('git --no-optional-locks -C "%s" rev-parse --show-toplevel --absolute-git-dir',root));
assert(status==0,'ejc:Git','Cannot identify the checkout root/Git directory.');
identity.checkoutIdentity=strtrim(text);
if ~isempty(expected)
    assert(strcmp(identity.sourceSHA,expected.sourceSHA) && ...
        strcmp(identity.policySHA256,expected.policySHA256) && ...
        strcmp(identity.implementationGateSHA256,expected.implementationGateSHA256), ...
        'ejc:CandidateChanged','Candidate or effective verification policy changed.');
end
end
