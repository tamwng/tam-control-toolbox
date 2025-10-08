classdef test_controller_step < matlab.unittest.TestCase
    properties
        tol = 1e-10;
        root
    end

    methods (TestClassSetup)
        function addPaths(tc)
            here = mfilename('fullpath');
            tc.root = fileparts(fileparts(here)); % repo root
            addpath(fullfile(tc.root,'pc'));
        end
    end

    methods (Test)
        function testIntegrationSanity(tc)
            rng(1);
            p=2; m=2; ell=2; q=3; N=4;
            Theta = makeTheta(p,m,q,ell);
            gamma = randn(q,1);
            y_hist = randn(p,ell);
            u_hist = randn(m,ell);

            pN = p*N; mN = m*N;
            Qy = kron(speye(N), speye(p));       % PSD
            Ru = 1e-2*speye(mN);                 % PD
            R  = zeros(pN,1);

            out = controller_step(Theta, gamma, y_hist, u_hist, N, ell, Qy, Ru, R, struct('assert',true));

            % Shapes
            tc.verifySize(out.u_k, [m,1]);
            tc.verifySize(out.U_star, [mN,1]);
            tc.verifySize(out.cost.H, [mN,mN]);
            tc.verifySize(out.cost.h, [mN,1]);

            % First block consistency
            tc.verifyLessThan(norm(out.u_k - out.U_star(1:m)), tc.tol);

            % Optimality residual
            tc.verifyLessThan(out.solve.grad_norm, 1e-9);

            % Finite outputs
            tc.verifyFalse(any(~isfinite(out.U_star)));
            tc.verifyFalse(~isfinite(out.solve.J));
        end

        function testDeterminism(tc)
            rng(2);
            p=2; m=2; ell=2; q=2; N=3;
            Theta = makeTheta(p,m,q,ell);
            gamma = randn(q,1);
            y_hist = randn(p,ell);
            u_hist = randn(m,ell);

            pN = p*N; mN = m*N;
            Qy = kron(speye(N), speye(p));
            Ru = 5e-3*speye(mN);
            R  = randn(pN,1);

            out1 = controller_step(Theta, gamma, y_hist, u_hist, N, ell, Qy, Ru, R, struct('assert',true));
            out2 = controller_step(Theta, gamma, y_hist, u_hist, N, ell, Qy, Ru, R, struct('assert',true));

            tc.verifyLessThan(norm(out1.U_star - out2.U_star), 1e-12);
            tc.verifyLessThan(norm(out1.u_k - out2.u_k), 1e-12);
            tc.verifyLessThan(abs(out1.solve.J - out2.solve.J), 1e-12);
        end

        function testNonCrashRandomLoop(tc)
            rng(3);
            p=2; m=1; ell=2; q=2; N=5;
            pN=p*N; mN=m*N;
            Qy = kron(speye(N), speye(p));
            Ru = 1e-2*speye(mN);

            for t=1:5
                Theta = makeTheta(p,m,q,ell);
                gamma = randn(q,1);
                y_hist = randn(p,ell);
                u_hist = randn(m,ell);
                R  = randn(pN,1);

                out = controller_step(Theta, gamma, y_hist, u_hist, N, ell, Qy, Ru, R, struct('assert',true));
                tc.verifySize(out.u_k, [m,1]);
                tc.verifyLessThan(out.solve.grad_norm, 1e-8);
            end
        end
    end
end

%% ---------- helpers ----------
function Theta = makeTheta(p,m,q,ell)
% Build Theta = [ C^(1..q) | A_1^(1..q) | ... | A_ell^(1..q) | B_0^(1..q) | ... | B_ell^(1..q) ]
    blocks = {};
    % C blocks
    for j=1:q
        blocks{end+1} = randn(p,1); %#ok<AGROW>
    end
    % A_i blocks
    for i=1:ell
        for j=1:q
            blocks{end+1} = 0.2*randn(p,p); %#ok<AGROW>
        end
    end
    % B_i blocks (i=0..ell)
    for i=0:ell
        for j=1:q
            blocks{end+1} = 0.2*randn(p,m); %#ok<AGROW>
        end
    end
    Theta = cell2mat(blocks);
end
