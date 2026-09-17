function results = run_verification
%RUN_VERIFICATION Complete one-click Phase 1 core verification.
% From the repository root in a clean session, enter RUN_VERIFICATION.
% Requires MATLAB and Optimization Toolbox; tested with R2026a Update 5.
% RUN_TESTS contains the independent mathematical checks as well as software
% tests; this entry point runs that single suite without duplicating checks.
% This verifies the reusable core only. It does not reproduce paper studies.

fprintf('EJC numerical core verification\nMATLAB %s\n', version);
results = run_tests;
solver = ver('optim');
fprintf('Optimization Toolbox %s\n', solver.Version);
fprintf('Phase 1 core verification completed successfully.\n');
end
