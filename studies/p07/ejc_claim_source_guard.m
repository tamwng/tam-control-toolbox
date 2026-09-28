function proof=ejc_claim_source_guard(root,rows)
%EJC_CLAIM_SOURCE_GUARD C0 sources plus the exact authorized B2 interface hash.
if nargin<1,root=fileparts(fileparts(fileparts(mfilename('fullpath'))));end
file=fullfile(root,'evidence/p07_acceptance/freezing_identity/C0_SCIENTIFIC_DEPENDENCIES.json');
if nargin<2,rows=jsondecode(fileread(file));end
hooks={};
for row=reshape(rows,1,[])
    actual=ejc_file_sha256(fullfile(root,row.path));matching=strcmp(actual,row.sha256);
    if ~matching
        hook=ejc_reporting_hook_integrity(root,row,actual);
        matching=hook.applied;if matching,hooks{end+1,1}=hook;end %#ok<AGROW>
    end
    assert(matching, ...
        'ejc:ClaimSourceChanged','Pinned scientific definition changed: %s.',row.path);
end
manifestHash="test supplied dependency rows";if isfile(file),manifestHash=string(ejc_file_sha256(file));end
proof=struct('passed',true,'dependencyCount',numel(rows),'manifestSHA256',manifestHash, ...
    'baseCandidate',"894eba817eaa43b882f849c5f830f64a8d6dbe39",'authorizedReportingHooks',{hooks});
end
