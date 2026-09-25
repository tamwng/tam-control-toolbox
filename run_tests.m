function results = run_tests(scope)
%RUN_TESTS Existing unit, numerical, archive and P07 interface checks.
% From the repository root in a clean session, enter RUN_TESTS.
% Requires MATLAB and Optimization Toolbox; tested with R2026a Update 5.
% Paths are established locally and restored on exit. The full suite requires
% retained archives; no caller workspace variables are needed. 'quick' selects
% existing bounded core/Study 1 tests. Failed/incomplete checks raise an error.

if nargin < 1, scope = 'all'; end
assert(any(strcmp(scope,{'all','quick'})),'ejc:TestScope','Use all or quick.');
root = fileparts(mfilename('fullpath'));
previousPath = path;
restorePath = onCleanup(@() path(previousPath));
restoredefaultpath;
addpath(root, fullfile(root,'src'), fullfile(root,'tests'));
assert(exist('quadprog','file') == 2 && license('test','Optimization_Toolbox'), ...
    'ejc:MissingSolver', 'Optimization Toolbox with a licensed quadprog is required.');
suite = matlab.unittest.TestSuite.fromFolder(fullfile(root,'tests'));
if strcmp(scope,'quick')
    % Existing unit checks and the bounded Study 1 timing/fit fixture only.
    names = string({suite.Name});
    keep = startsWith(names,{'test_controller/','test_estimation/', ...
        'test_models/','test_physical/','test_qp/','test_study1/'});
    suite = suite(keep);
end
assert(~isempty(suite), 'ejc:NoTests', 'The required test suite is empty.');
runner = matlab.unittest.TestRunner.withTextOutput( ...
    'OutputDetail',matlab.unittest.Verbosity.Concise);
results = runner.run(suite);
fprintf('\nPhase 1 checks: %d passed, %d failed, %d incomplete (%d total).\n', ...
    nnz([results.Passed]), nnz([results.Failed]), nnz([results.Incomplete]), numel(results));
assert(all([results.Passed]) && ~any([results.Incomplete]), ...
    'ejc:VerificationFailed', 'Required checks failed or did not execute.');
end
