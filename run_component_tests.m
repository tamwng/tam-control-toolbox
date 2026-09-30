function results = run_component_tests
%RUN_COMPONENT_TESTS Run the explicit small public regression selection.
% Nine existing files cover the numerical core, short Study 1 fixtures and
% synthetic comparison/representation negatives. No archive is required.
% This is a component selection; full author verification remains separate.
% Test bodies, thresholds and the original complete-suite discovery are unchanged.
[context,root] = public_context; %#ok<ASGLU>
assert(exist('quadprog','file')==2 && license('test','Optimization_Toolbox'), ...
    'ejc:MissingSolver','Optimization Toolbox with a licensed quadprog is required.');
folder = fullfile(root,'tests'); addpath(folder);
files = {'test_controller.m','test_estimation.m','test_models.m','test_physical.m', ...
    'test_qp.m','test_study1.m','test_verification_acceptance_numeric.m', ...
    'test_verification_representation.m','test_verification_comparison.m'};
suite = matlab.unittest.TestSuite.fromFile(fullfile(folder,files{1}));
for j = 2:numel(files)
    suite = [suite matlab.unittest.TestSuite.fromFile(fullfile(folder,files{j}))]; %#ok<AGROW>
end
assert(~isempty(suite),'ejc:NoTests','The required test suite is empty.');
runner = matlab.unittest.TestRunner.withTextOutput('OutputDetail',matlab.unittest.Verbosity.Concise);
results = runner.run(suite);
fprintf('Component tests: %d passed, %d failed, %d incomplete (%d total).\n', ...
    nnz([results.Passed]),nnz([results.Failed]),nnz([results.Incomplete]),numel(results));
assert(all([results.Passed]) && ~any([results.Incomplete]), ...
    'ejc:VerificationFailed','Required checks failed or did not execute.');
end
