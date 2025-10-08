classdef test_rls_update < matlab.unittest.TestCase
    methods (Test)

        function testBadDimAndNaNGuards(tc)
            % State
            d = 4;
            st = struct('theta', zeros(d,1), ...
                        'P',     eye(d)*1e4, ...   % ridge ρ=1e-4
                        'lambda',1.0, ...
                        'eps',   1e-12);

            % BAD_DIM: phi size mismatch and y size mismatch
            phi_bad = randn(2,d);          % p=2 but y will be scalar
            y_bad  = 1;                    % scalar
            st0 = st;
            [st1, status1] = rls_update(st, phi_bad, y_bad);
            tc.verifyFalse(status1.ok);
            tc.verifyEqual(status1.code, 'BAD_DIM');
            tc.verifyEqual(st1, st0);      % state unchanged

            % NAN_INPUT
            phi = randn(1,d); y = NaN;
            [st2, status2] = rls_update(st, phi, y);
            tc.verifyFalse(status2.ok);
            tc.verifyEqual(status2.code, 'NAN_INPUT');
            tc.verifyEqual(st2, st0);
        end

        function testOneStepSISOFormula(tc)
            rng(0);
            d = 3; p = 1;
            theta0 = [0.1; -0.2; 0.3];
            P0 = eye(d)*1e3;    % ρ = 1e-3
            st = struct('theta', theta0, 'P', P0, 'lambda', 1.0, 'eps', 1e-12);

            phi = randn(p,d);                 % 1×d
            y   = 0.5;                        % arbitrary scalar
            % Manual update per algorithm
            yhat = phi*theta0;
            r = y - yhat;
            L = P0 / st.lambda;
            S = eye(p) + phi * (L * phi.');
            K = (L * phi.') / S;              % d×1 since p=1
            theta_exp = theta0 + K * r;
            P_exp = L - K * (phi * L);
            P_exp = (P_exp + P_exp')/2;

            [st1, status] = rls_update(st, phi, y);
            tc.verifyTrue(status.ok);
            tc.verifyLessThan(norm(st1.theta - theta_exp), 1e-12*(1+norm(theta_exp)));
            tc.verifyLessThan(norm(st1.P - P_exp, 'fro'), 1e-10*(1+norm(P_exp,'fro')));

            % SPD
            [~,flag] = chol(st1.P,'upper');
            tc.verifyEqual(flag, 0);   % 0 ⇒ SPD
        end

        function testBatchEquivalenceLambdaOne_SISO(tc)
            rng(1);
            d = 5; p = 1; T = 500;
            theta_true = randn(d,1);
            rho = 1e-4;  P0 = eye(d)/rho;     % P0 = 1/ρ I
            st = struct('theta', zeros(d,1), 'P', P0, 'lambda', 1.0, 'eps', 1e-12);

            Phi = randn(T,d);
            y   = Phi*theta_true;             % noiseless

            % Stream RLS
            for k=1:T
                [st, status] = rls_update(st, Phi(k,:), y(k));
                tc.verifyTrue(any(strcmp(status.code, {'OK','P_ADJUSTED'})));
            end

            % Batch ridge solution
            H = Phi.'*Phi + rho*eye(d);
            b = Phi.'*y;
            theta_batch = H \ b;

            tc.verifyLessThan(norm(st.theta - theta_batch, inf), 1e-10);
            % λ=1 → trace(P) non-increasing
            traces = zeros(T,1);
            st2 = struct('theta', zeros(d,1), 'P', P0, 'lambda', 1.0, 'eps', 1e-12);
            for k=1:T
                [st2, ~] = rls_update(st2, Phi(k,:), y(k));
                traces(k) = trace(st2.P);
            end
            tc.verifyTrue(all(diff(traces) <= 1e-12));
        end

        function testDeterminism(tc)
            rng(2);
            d=6; p=1; T=200;
            rho=1e-3; P0=eye(d)/rho;
            Phi = randn(T,d);
            y   = randn(T,1);

            stA = struct('theta', zeros(d,1), 'P', P0, 'lambda', 0.995, 'eps', 1e-12);
            stB = stA;

            for k=1:T
                [stA, ~] = rls_update(stA, Phi(k,:), y(k));
                [stB, ~] = rls_update(stB, Phi(k,:), y(k));
            end
            tc.verifyEqual(stA.theta, stB.theta, 'AbsTol', 0);
            tc.verifyEqual(stA.P,     stB.P,     'AbsTol', 0);
        end

        function testMultiOutputBatchEquivalence(tc)
            rng(3);
            d = 4; p = 2; T = 400;
            rho = 1e-4; P0 = eye(d)/rho;
            st = struct('theta', zeros(d,1), 'P', P0, 'lambda', 1.0, 'eps', 1e-12);

            % Build φ_k ∈ R^{p×d} and y_k = φ_k θ_true
            theta_true = randn(d,1);
            Phi_cells = cell(T,1);
            y_cells   = cell(T,1);
            H = rho*eye(d); b = zeros(d,1);
            for k=1:T
                Phi_k = randn(p,d);
                y_k   = Phi_k * theta_true;
                Phi_cells{k} = Phi_k;
                y_cells{k}   = y_k;
                H = H + Phi_k.' * Phi_k;
                b = b + Phi_k.' * y_k;
            end

            % Stream RLS
            for k=1:T
                [st, status] = rls_update(st, Phi_cells{k}, y_cells{k});
                tc.verifyTrue(any(strcmp(status.code, {'OK','P_ADJUSTED'})));
            end

            theta_batch = H \ b;
            tc.verifyLessThan(norm(st.theta - theta_batch, 2)/max(1,norm(theta_batch,2)), 1e-10);
        end

        function testGainAndMinEigDiagnostics(tc)
            rng(4);
            d=3; p=1;
            st = struct('theta', zeros(d,1), 'P', eye(d)*1e4, 'lambda', 1.0, 'eps', 1e-12);
            phi = randn(p,d); y = randn(p,1);
            [st1, status] = rls_update(st, phi, y);
            tc.verifyTrue(status.ok);
            tc.verifyGreaterThanOrEqual(status.gain_norm, 0);
            tc.verifyTrue(isfinite(status.gain_norm));
            tc.verifyTrue(isfinite(status.min_eig_P) || isnan(status.min_eig_P));
            % Ensure P stayed SPD
            [~,flag] = chol(st1.P,'upper');
            tc.verifyEqual(flag, 0);
        end

    end
end
