function results = run_tests
%RUN_TESTS Run all Phase 1 unit, integration, and mathematical checks.
% From the repository root in a clean session, enter RUN_TESTS.
% Requires MATLAB and Optimization Toolbox; tested with R2026a Update 5.
% Paths are established locally and restored on exit. No saved data or
% workspace variables are required. Failed or incomplete checks raise an error.

root = fileparts(mfilename('fullpath'));
previousPath = path;
restorePath = onCleanup(@() path(previousPath));
restoredefaultpath;
addpath(root, fullfile(root,'src'), fullfile(root,'tests'));
assert(exist('quadprog','file') == 2 && license('test','Optimization_Toolbox'), ...
    'ejc:MissingSolver', 'Optimization Toolbox with a licensed quadprog is required.');
suite = matlab.unittest.TestSuite.fromFolder(fullfile(root,'tests'));
assert(~isempty(suite), 'ejc:NoTests', 'The required test suite is empty.');
runner = matlab.unittest.TestRunner.withTextOutput( ...
    'OutputDetail',matlab.unittest.Verbosity.Concise);
results = runner.run(suite);
fprintf('\nPhase 1 checks: %d passed, %d failed, %d incomplete (%d total).\n', ...
    nnz([results.Passed]), nnz([results.Failed]), nnz([results.Incomplete]), numel(results));
assert(all([results.Passed]) && ~any([results.Incomplete]), ...
    'ejc:VerificationFailed', 'Required checks failed or did not execute.');
end
