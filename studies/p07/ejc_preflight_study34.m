function report=ejc_preflight_study34(study,source,cfg,output)
%EJC_PREFLIGHT_STUDY34 All original science checks and independent bound rows.
% Only the diagnostic orchestrator uses this callback. Production retains its
% fail-closed callback; an unsuccessful portable verdict here stays FAILED.
addpath(fileparts(mfilename('fullpath')));
assert(~isfolder(output),'ejc:ExistingEvidence','New evidence required.');mkdir(output);
original=ejc_study34_extract(study,source,cfg,fullfile(output,'original_requirements'));
assert(original.originalRequirementsCompleted,'ejc:OriginalValidity','Original science requirement failed; dependency blocked.');
report=ejc_study34_bind(original,cfg,fullfile(output,'portable_assertions'),"COLLECT_DIAGNOSTIC_FAILURES");
end
