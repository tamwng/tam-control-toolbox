function report=ejc_study34_verify(study,source,cfg,output)
%EJC_STUDY34_VERIFY Complete original-plus-portable verification, no simulation.
previous=path;restore=onCleanup(@()path(previous));
addpath(fileparts(mfilename('fullpath')));
ejc_assert_writable(output);
assert(~isfolder(output) && ~isfile(output),'ejc:ExistingEvidence','New verification evidence required.');
mkdir(output);
original=ejc_study34_extract(study,source,cfg,fullfile(output,'original_requirements'));
assert(original.originalRequirementsCompleted,'ejc:OriginalValidity', ...
    'An unchanged original requirement failed. See original_requirements evidence.');
report=ejc_study34_bind(original,cfg,fullfile(output,'portable_assertions'));
assert(report.passed,'ejc:PortableAssertion','A required portable assertion failed. See portable_assertions evidence.');
end
