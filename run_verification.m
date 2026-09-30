function results = run_verification
% RUN_VERIFICATION Run the complete existing test suite through RUN_TESTS.
%  Requires MATLAB, Optimization Toolbox, retained archives and test fixtures.
%  Includes independent mathematical and software checks. It does not
%  generate complete studies and is not a reference-free startup check.
%  Use RUN_TESTS('quick') for the bounded core/Study 1 component selection.

fprintf('EJC numerical core verification\nMATLAB %s\n', version);
results = run_tests;
solver = ver('optim');
fprintf('Optimization Toolbox %s\n', solver.Version);
fprintf('Phase 1 core verification completed successfully.\n');
end
