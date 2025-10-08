classdef test_regressor < matlab.unittest.TestCase
    % Unit tests for bkrls/regressor.m

    methods (Test)

        function testShapesAndMetaSISO(tc)
            % SISO, ℓ=2 → d0 = 1 + pℓ + m(ℓ+1) = 1+2+3 = 6
            p=1; m=1; ell=2;
            s = make_sk(p,m,ell, [10 20], [1 2 3]);
            spec = struct('type','ones');   % q=1
            [phi, meta, z] = regressor(s, spec, p, m);

            tc.verifySize(z,   [1*6, 1]);        % q*d0 × 1
            tc.verifySize(phi, [p, p*1*6]);      % p × d
            tc.verifyEqual(meta.p, p);
            tc.verifyEqual(meta.m, m);
            tc.verifyEqual(meta.ell, ell);
            tc.verifyEqual(meta.d0, 6);
            tc.verifyEqual(meta.q, 1);
            tc.verifyEqual(meta.d, p*meta.q*meta.d0);
            tc.verifyEqual(meta.shapes.y, [p,ell]);
            tc.verifyEqual(meta.shapes.u, [m,ell+1]);
        end

        function testVectorizationIdentity(tc)
            % Verify Θ z = φ vec(Θ) for random Θ (core algebraic identity)
            p=2; m=1; ell=2;
            s = make_sk(p,m,ell, [1 2 3 4], [5 6 7]);
            spec = struct('type','linear','d', numel([s.y(:); s.u(:)]));
            [phi, meta, z] = regressor(s, spec, p, m);

            Theta = randn(p, meta.q*meta.d0);  % arbitrary coefficients
            lhs = Theta * z;
            rhs = phi * Theta(:);
            tc.verifyLessThan(norm(lhs - rhs), 1e-12*(1+norm(lhs)));
        end

        function testARXReductionOnesKernel(tc)
            % ones-kernel must reduce to ARX: z = ψ and φ uses ψ only
            p=1; m=1; ell=2;
            s = make_sk(p,m,ell, [7 11], [13 17 19]);     % ψ = [1;y;u]
            spec = struct('type','ones');                 % g = [1]
            [phi, meta, z] = regressor(s, spec, p, m);

            psi_expected = [1; s.y(:); s.u(:)];
            tc.verifyEqual(z, psi_expected);
            % Check a random Θ maps via ψ exactly
            Theta = randn(p, meta.q*meta.d0);
            yhat1 = Theta * z;
            yhat2 = Theta * psi_expected;
            tc.verifyEqual(yhat1, yhat2, 'AbsTol', 1e-12);
        end

        function testDirectFeedthroughContent(tc)
            % Validate that ψ contains u_k as its first u column and excludes y_k
            p=1; m=1; ell=3;
            ycols = [100 200 300];   % corresponds to [y_{k-1}, y_{k-2}, y_{k-3}]
            ucols = [9 8 7 6];       % corresponds to [u_k, u_{k-1}, u_{k-2}, u_{k-3}]
            s = make_sk(p,m,ell, ycols, ucols);
            spec = struct('type','ones');
            [~, meta, z] = regressor(s, spec, p, m);
            d0 = meta.d0;

            % Recover ψ from z (since g=[1]) and check order
            psi = z(1:d0);
            tc.verifyEqual(psi(1), 1);
            tc.verifyEqual(psi(2:1+ell), ycols(:));  % y_{k-1: k-ell}
            tc.verifyEqual(psi(2+ell:end), ucols(:));% [u_k, u_{k-1}, ...]
        end

        function testDeterminism(tc)
            % Same inputs → identical outputs
            p=2; m=3; ell=2;
            s = make_sk(p,m,ell, 1: (p*ell), 101: (101+m*(ell+1)-1));
            spec = struct('type','poly','degree',2,'cross','pairwise','d', numel([s.y(:); s.u(:)]));
            [phi1, meta1, z1] = regressor(s, spec, p, m);
            [phi2, meta2, z2] = regressor(s, spec, p, m);
            tc.verifyEqual(z1, z2, 'AbsTol', 0);
            tc.verifyEqual(phi1, phi2, 'AbsTol', 0);
            tc.verifyEqual(meta1, meta2);
        end

        function testSizeConsistencyMIMO(tc)
            p=2; m=2; ell=1;
            % y: p×ell = 2×1 → 2 elems; u: m×(ell+1) = 2×2 → 4 elems
            s = make_sk(p,m,ell, [1 2], [3 4 5 6]);
            d_flat = numel([s.y(:); s.u(:)]);
            lin = struct('type','linear','d', d_flat);
            C = [zeros(1,d_flat); ones(1,d_flat); 2*ones(1,d_flat)];
            rbf = struct('type','rbf','centers', C, 'sigma', 1.0);
            spec = struct('type','mix','parts', {{lin, rbf}}); % q = (1+d) + 3
        
            [phi, meta, z] = regressor(s, spec, p, m);
            q = (1 + d_flat) + 3;
            d0 = 1 + p*ell + m*(ell+1);
            tc.verifyEqual(meta.q, q);
            tc.verifyEqual(meta.d0, d0);
            tc.verifySize(z,   [q*d0, 1]);
            tc.verifySize(phi, [p, p*q*d0]);
        end

        function testPMismatchError(tc)
            p=1; m=2; ell=1;
            s = make_sk(p,m,ell,[1],[2 3 4 5]);
            spec = struct('type','ones');
        
            % p mismatch
            threw=false; ME=[];
            try, regressor(s,spec,99,m); catch ME, threw=true; end
            tc.verifyTrue(threw);
            tc.verifyTrue(contains(ME.message,'p mismatch'));
        
            % m mismatch
            threw=false; ME=[];
            try, regressor(s,spec,p,99); catch ME, threw=true; end
            tc.verifyTrue(threw);
            tc.verifyTrue(contains(ME.message,'m mismatch'));
        end

        function testNaNWindowError(tc)
            p=1; m=1; ell=1;
            s = make_sk(p,m,ell, [NaN], [5 6]);  % NaN in y
            spec = struct('type','ones');
        
            threw = false; ME = [];
            try
                regressor(s, spec, p, m);
            catch ME
                threw = true;
            end
            tc.verifyTrue(threw);
            tc.verifyTrue(contains(ME.message, 'window contains NaN/Inf'), ...
                'Expected NaN/Inf guard to trigger.');
        end

        function testZBlockStructure(tc)
            % z must be [g1*ψ; g2*ψ; ...], verify by reshaping
            p=1; m=1; ell=2;
            s = make_sk(p,m,ell, [4 5], [6 7 8]);
            d_flat = numel([s.y(:); s.u(:)]);
            lin = struct('type','linear','d', d_flat);      % g = [1; svec]
            [~, meta, z] = regressor(s, lin, p, m);
            d0 = meta.d0; q = meta.q;

            psi = [1; s.y(:); s.u(:)];
            Zblocks = reshape(z, d0, q); % each column should be g_j * ψ
            % First column: 1*ψ
            tc.verifyEqual(Zblocks(:,1), psi);
            % Second column: s_1*ψ
            svec = [s.y(:); s.u(:)];
            tc.verifyEqual(Zblocks(:,2), svec(1)*psi);
        end

    end
end

%% ---- local helper ----
function s = make_sk(p,m,ell, yvals, uvals)
    % Build a window struct with shapes:
    %   y: p×ell, columns [y_{k-1},...,y_{k-ell}]
    %   u: m×(ell+1), columns [u_k, u_{k-1},...,u_{k-ell}]
    y = reshape(yvals, p, ell);
    u = reshape(uvals, m, ell+1);
    s = struct('y', y, 'u', u);
end
