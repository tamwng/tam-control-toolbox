function report=ejc_p06_portable_tests(output)
%EJC_P06_PORTABLE_TESTS Run strict sensitivity tests and scoped portable checks.
% All 17 strict outcomes are retained. Only the two named summary comparisons
% may use the separate fieldwise reporting tests; the other 15 must pass and
% no strict test may be incomplete. Portable checks retain their matrix/source
% requirements. A portable pass does not relabel a failed strict assertion.
% MATLAB's test runner changes folders. Resolve the caller's evidence path
% before that happens so generated output cannot land under the test sources.
output=char(java.io.File(char(output)).getCanonicalPath());
assert(~isfolder(output) && ~isfile(output),'ejc:ExistingOutput','New P06 test output required.');
root=fileparts(fileparts(fileparts(mfilename('fullpath'))));
previous=path;restore=onCleanup(@()path(previous));
% runtests temporarily changes folders; implicit current-folder lookup is
% insufficient for the existing root-level write guard during those tests.
addpath(root,fullfile(root,'studies/p07'),fullfile(root,'studies/p06'));
ejc_assert_writable(output);mkdir(output);
try
    run_p06_tests(fullfile(output,'original_strict'));
catch e
    if ~strcmp(e.identifier,'p06:TestsFailed'),rethrow(e);end
end
z=load(fullfile(output,'original_strict/local_test_results.mat'),'results');strict=z.results;
permitted=["test_p06/testOriginalTwoArgumentSummaryExactlyMatchesPrechange", ...
    "test_p06/testPublicScoresEqualOriginalInternalScores"];
names=string({strict.Name});assert(~any([strict.Incomplete]),'ejc:P06Incomplete','A required P06 test was incomplete.');
other=~ismember(names,permitted);
assert(all([strict(other).Passed]),'ejc:P06MandatoryFailure','An unchanged mandatory P06 check failed.');
assert(nnz(~other)==2 && numel(strict)==17,'ejc:P06TestCoverage','P06 prerequisite coverage changed.');
portable=runtests(fullfile(root,'tests/test_p07_p06_reporting.m'));
save(fullfile(output,'portable_tests.mat'),'portable','strict');
report=struct('strictPassed',nnz([strict.Passed]),'strictFailed',nnz([strict.Failed]), ...
    'unchangedMandatoryPassed',nnz([strict(other).Passed]),'portableReportingPassed',nnz([portable.Passed]), ...
    'portableReportingFailed',nnz([portable.Failed]),'portableReportingIncomplete',nnz([portable.Incomplete]), ...
    'activeMandatoryTotal',17,'originalStrictResultsPreserved',true, ...
    'passed',numel(portable)==2 && all([portable.Passed]) && ~any([portable.Incomplete]));
fid=fopen(fullfile(output,'portable_test_summary.json'),'w');cleanup=onCleanup(@()fclose(fid));
fprintf(fid,'%s\n',jsonencode(report,PrettyPrint=true));
assert(report.passed,'ejc:P06PortableFailure','Approved portable P06 assertions failed.');
end
