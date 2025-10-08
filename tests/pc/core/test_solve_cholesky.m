classdef test_solve_cholesky < matlab.unittest.TestCase
    properties, tol = 1e-10; end
    methods (TestClassSetup)
        function addPaths(tc)
            here = mfilename('fullpath'); root = fileparts(fileparts(here));
            addpath(fullfile(root,'pc'));
        end
    end

    methods (Test)
        function testMatchesBackslash(tc)
            n = 20;
            A = randn(n); H = A'*A + 1e-2*eye(n);    % SPD
            h = randn(n,1);

            out = solve_cholesky(H,h,struct('assert',true,'J0',3.14));
            U_ref = -H\h;

            tc.verifyLessThan(norm(out.U - U_ref), tc.tol);
            tc.verifyLessThan(out.grad_norm, 1e-12);

            % Optimal cost consistency
            J_ref = 3.14 + 0.5*U_ref.'*H*U_ref + h.'*U_ref;
            tc.verifyLessThan(abs(out.J - J_ref), 1e-10);
        end

        function testNonSPDBehavior(tc)
            n=10; H = diag([ones(1,n-1), 0]); h = randn(n,1);
            % assert=true → error
            tc.verifyError(@() solve_cholesky(H,h,struct('assert',true)), 'MATLAB:posdef');
            % assert=false → status reported
            out = solve_cholesky(H,h,struct('assert',false));
            tc.verifyFalse(out.status.ok);
            tc.verifyEqual(out.status.code,1);
        end

        function testDeterminismAndSymmetrization(tc)
            rng(0);                         % stabilize randomness
            n=8; R = randn(n); H = R.'*R;  % SPD
            h = randn(n,1);
        
            % Inject tiny asymmetry
            Hns = H + 1e-12*triu(H,1);
        
            o1 = solve_cholesky(H,h,struct('assert',true));
            o2 = solve_cholesky(Hns,h,struct('assert',true));
        
            % Relative tolerance for solver output
            rel = norm(o1.U - o2.U) / max(1, norm(o1.U));
            tc.verifyLessThan(rel, 1e-8);
        
            % Also compare optimal objective values
            Jref1 = 0.5*o1.U.'*H*o1.U + h.'*o1.U;
            Jref2 = 0.5*o2.U.'*Hns*o2.U + h.'*o2.U;
            tc.verifyLessThan(abs(Jref1 - Jref2), 1e-9);
        end
    end
end
