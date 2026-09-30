function sources = reference_test_sources
%REFERENCE_TEST_SOURCES Explicit saved fixtures for the optional reference tests.
% The caller supplies studyReferenceTestInputs and removes it after the suite.
% No historical repository path is inferred or silently substituted.
sources=getappdata(0,'studyReferenceTestInputs');
assert(isstruct(sources) && ~isempty(fieldnames(sources)), ...
    'test:ReferenceUnavailable','Explicit saved reference-test inputs are required.');
end
