function results = run_tests(scope)
% RUN_TESTS Run existing unit, numerical, archive and interface checks.
%  RUN_TESTS('quick') selects bounded core and Study 1 component tests.
%  RUN_TESTS or RUN_TESTS('all') selects the complete suite, which requires
%  retained archives and verification fixtures. Neither is full generation.
%  Run from the repository root with MATLAB and Optimization Toolbox.
%  Paths are restored on exit. RESULTS contains matlab.unittest results;
%  failed or incomplete checks raise an error. No caller variables are needed.

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
