function results = run_p06_tests(output)
%RUN_P06_TESTS Synthetic and saved-case checks only, never the global suite.
assert(nargin==1 && ~isfolder(output) && ~isfile(output), ...
    'p06:ExistingOutput','Specify a fresh test-output directory.');
folder=fileparts(mfilename('fullpath')); root=fileparts(fileparts(folder));
previous=path; restore=onCleanup(@() path(previous));
addpath(fullfile(root,'src'),fullfile(root,'studies','study1'),fullfile(folder,'tests'));
mkdir(output);
setappdata(0,'p06TestOutput',output);
clearContext=onCleanup(@() rmappdata(0,'p06TestOutput'));
results=runtests(fullfile(folder,'tests','test_p06.m'));
names=string({results.Name}).'; passed=[results.Passed].';
failed=[results.Failed].'; incomplete=[results.Incomplete].'; seconds=[results.Duration].';
report=table(names,passed,failed,incomplete,seconds);
writetable(report,fullfile(output,'local_test_results.csv'));
save(fullfile(output,'local_test_results.mat'),'results','-v7');
assert(all(passed) && ~any(incomplete),'p06:TestsFailed','Local checks did not all pass.');
end
