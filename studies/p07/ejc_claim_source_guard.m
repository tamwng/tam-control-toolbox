function proof=ejc_claim_source_guard(root,rows)
%EJC_CLAIM_SOURCE_GUARD Bind algebraic interpretation to unchanged C0 sources.
if nargin<1,root=fileparts(fileparts(fileparts(mfilename('fullpath'))));end
file=fullfile(root,'evidence/p07_acceptance/freezing_identity/C0_SCIENTIFIC_DEPENDENCIES.json');
if nargin<2,rows=jsondecode(fileread(file));end
for row=reshape(rows,1,[])
    assert(strcmp(ejc_file_sha256(fullfile(root,row.path)),row.sha256), ...
        'ejc:ClaimSourceChanged','Pinned scientific definition changed: %s.',row.path);
end
manifestHash="test supplied dependency rows";if isfile(file),manifestHash=string(ejc_file_sha256(file));end
proof=struct('passed',true,'dependencyCount',numel(rows),'manifestSHA256',manifestHash, ...
    'baseCandidate',"894eba817eaa43b882f849c5f830f64a8d6dbe39");
end
