function [applied,proof] = verification_sensitivity_record_hash(a,b,key,c)
%VERIFICATION_SENSITIVITY_RECORD_HASH Bind each metadata hash to its own exact input.
% This scope never waives a scientific field, unknown hash, or changed record.
applied=false;proof=struct;
if string(c.study)~="p06" || ~isfield(c,'sensitivityRecords'),return;end
csvScope=any(string(c.file)==["P06_RUN_MANIFEST.csv","tables/runs.csv","tables/deterministic.csv"]) && ...
    key=="value.recordSHA256";
matScope=startsWith(string(c.file),"runs/") && endsWith(string(c.file),".mat") && ...
    any(key==["value[].item[].recordSHA256","value[].result[].p06[].recordSHA256"]);
if ~csvScope && ~matScope,return;end
applied=true;identity=c.sensitivityRecords;
proof=struct('passed',false,'currentFileSHA256',identity.currentSHA256, ...
    'referenceFileSHA256',identity.referenceSHA256,'contentRequirement',identity.requirement);
proof.passed=identity.passed && isstring(a) && isscalar(a) && isstring(b) && isscalar(b) && ...
    a==string(identity.currentSHA256) && b==string(identity.referenceSHA256);
end
