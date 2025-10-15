classdef test_cost_assemble < matlab.unittest.TestCase
    properties
        tol = 1e-8;
    end

    %% ---------- SISO baseline (p=1, m=1, N=4) ----------
    methods (Test)
        function testDimensionsAndManualSISO(tc)
            N=4; p=1; m=1;
            a=[0.2; -0.1];                 % y-lags
            b=[0.7; 0.3];                  % u-lags (incl. b0)
            [Ty,Tu] = buildToeplitzSISO(N,a,b);
            ofs = (1:N).';
            Qy  = eye(p*N);
            Ru  = 1e-3*eye(m*N);
            R   = zeros(p*N,1);

            out = cost_assemble(Ty,Tu,ofs,Qy,Ru,R,struct('assert',true));
            % Dimensions
            tc.verifySize(out.S, [p*N,1]);
            tc.verifySize(out.G, [p*N,m*N]);
            tc.verifySize(out.H, [m*N,m*N]);
            tc.verifySize(out.h, [m*N,1]);

            % Manual assembly (dk=0 here since u_k not provided)
            S  = (eye(p*N)-Ty)\ofs;
            G  = (eye(p*N)-Ty)\Tu;
            D  = out.D; dk = zeros(m*N,1);
            Hm = 0.5*((G.'*(Qy*G) + D.'*(Ru*D)) + (G.'*(Qy*G) + D.'*(Ru*D)).');
            hm = G.'*(Qy*(S - R)) - D.'*(Ru*dk);
            J0m= 0.5*(S - R).'*(Qy*(S - R)) + 0.5*(dk.'*(Ru*dk));

            tc.verifyLessThan(norm(out.S - S), tc.tol);
            tc.verifyLessThan(norm(out.G - G), tc.tol);
            tc.verifyLessThan(norm(out.H - Hm,'fro'), tc.tol);
            tc.verifyLessThan(norm(out.h - hm), tc.tol);
            tc.verifyLessThan(abs(out.J0 - J0m), tc.tol);
        end

        function testQuadraticIdentityAndGradientSISO(tc)
            N=4; p=1; m=1;
            a=[0.15; -0.05]; b=[0.6; 0.25];
            [Ty,Tu] = buildToeplitzSISO(N,a,b);
            ofs = randn(p*N,1);
            Qy = diag(1+rand(p*N,1));
            Ru = diag(1e-2 + rand(m*N,1));
            R  = randn(p*N,1);
            uk = 0.7;  % nonzero to exercise dk

            out = cost_assemble(Ty,Tu,ofs,Qy,Ru,R,struct('assert',true,'m',m,'N',N,'u_k',uk));
            H=out.H; h=out.h; J0=out.J0; S=out.S; G=out.G; D=out.D;
            dk = zeros(m*N,1); dk(1)=uk;

            % Quadratic identity J(U) equality with move penalty
            U = randn(m*N,1);
            J1 = 0.5*(S+G*U-R).'*Qy*(S+G*U-R) + 0.5*(D*U - dk).'*Ru*(D*U - dk);
            J2 = 0.5*U.'*H*U + h.'*U + J0;
            tc.verifyLessThan(abs(J1-J2), tc.tol);

            % Gradient check: ∇J = H U + h
            g_analytic = H*U + h;
            eps = 1e-6; v = randn(m*N,1);
            Jp = 0.5*(S+G*(U+eps*v)-R).'*Qy*(S+G*(U+eps*v)-R) + ...
                 0.5*(D*(U+eps*v)-dk).'*Ru*(D*(U+eps*v)-dk);
            Jm = 0.5*(S+G*(U-eps*v)-R).'*Qy*(S+G*(U-eps*v)-R) + ...
                 0.5*(D*(U-eps*v)-dk).'*Ru*(D*(U-eps*v)-dk);
            g_fd_v = (Jp - Jm)/(2*eps);
            tc.verifyLessThan(abs(g_fd_v - v.'*g_analytic), 1e-6);
        end

        function testDirectionalHessianCheckSISO(tc)
            N=4; p=1; m=1;
            [Ty,Tu] = buildToeplitzSISO(N,[0.1;0.05],[0.9;0.2]);
            ofs = randn(p*N,1);
            Qy = eye(p*N);
            Ru = eye(m*N);
            R  = zeros(p*N,1);
            uk = 0.3;

            out = cost_assemble(Ty,Tu,ofs,Qy,Ru,R,struct('assert',true,'m',m,'N',N,'u_k',uk));
            H=out.H; S=out.S; G=out.G; D=out.D; dk=zeros(m*N,1); dk(1)=uk;

            rng(42);
            U = randn(m*N,1); v = randn(m*N,1);
            J = @(x) 0.5*(S+G*x-R).'*Qy*(S+G*x-R) + 0.5*(D*x - dk).'*Ru*(D*x - dk);

            h1 = 1e-4;
            sec1 = (J(U+h1*v) - 2*J(U) + J(U-h1*v))/(h1^2);
            h2 = h1/2;
            sec2 = (J(U+h2*v) - 2*J(U) + J(U-h2*v))/(h2^2);
            sec_rich = (4*sec2 - sec1)/3;
            tc.verifyLessThan(abs(sec_rich - v.'*H*v), 5e-6);
        end

        function test_move_penalty_offset_equivalence(tc)
            p=1;m=1;N=8; pN=p*N; mN=m*N;
            Ty=tril(randn(pN),-1); Tu=randn(pN,mN); ofs=randn(pN,1);
            Qy=eye(pN); Ru=10*eye(mN); R=zeros(pN,1); uk=0.7;

            cfg = struct('m',m,'N',N,'u_k',uk,'assert',true,'eps',0); % no jitter
            out = cost_assemble(Ty,Tu,ofs,Qy,Ru,R,cfg);
            H=out.H; h=out.h; G=out.G; S=out.S; D=out.D;

            dk=zeros(mN,1); dk(1)=uk;

            % Change of variables: U = T (w + dk), with D*T = I
            Linv = tril(ones(N)); T = kron(Linv, speye(m));
            A = G*T;
            b = (S - R) + G*(T*dk);              % <-- include GT*dk

            H_w = A.'*Qy*A + Ru;
            h_w = A.'*Qy*b;

            w  = - H_w \ h_w;
            U2 = T*(w + dk);

            U1 = - H \ h;

            tc.verifyLessThan(norm(U1-U2), tc.tol);
        end
    end

    %% ---------- MIMO smoke tests (p=2, m=2, N=3) ----------
    methods (Test)
        function testMIMOManual(tc)
            p=2; m=2; N=3;

            % Ty_s: strictly lower with two subdiagonals [a1, a2]
            a1=0.2; a2=-0.1;
            Ty_s = diag(a1*ones(N-1,1), -1) + diag(a2*ones(N-2,1), -2);

            % Tu_s: upper-triangular Toeplitz with b0 on main, b1 on +1
            b0=0.7; b1=0.3; b2=0.0;
            Tu_s = b0*eye(N) + diag(b1*ones(N-1,1), +1);
            if N>2, Tu_s = Tu_s + diag(b2*ones(N-2,1), +2); end

            Ty = kron(Ty_s, eye(p));                    % (pN x pN)
            Tu = kron(Tu_s, eye(p,m));                  % (pN x mN), here p=m=2

            ofs = randn(p*N,1);
            Qy  = kron(eye(N), diag([1.0, 2.0]));
            Ru  = kron(eye(N), 1e-2*eye(m));
            R   = randn(p*N,1);

            out = cost_assemble(Ty,Tu,ofs,Qy,Ru,R,struct('assert',true,'m',m,'N',N));
            S = (eye(p*N)-Ty)\ofs;  G = (eye(p*N)-Ty)\Tu;  D = out.D; dk=zeros(m*N,1);
            Hm = 0.5*((G.'*(Qy*G) + D.'*(Ru*D)) + (G.'*(Qy*G) + D.'*(Ru*D)).');
            hm = G.'*(Qy*(S - R)) - D.'*(Ru*dk);

            tc.verifyLessThan(norm(out.H - Hm,'fro'), tc.tol);
            tc.verifyLessThan(norm(out.h - hm), tc.tol);

            Ustar = -out.H \ out.h;
            J = @(x) 0.5*(S+G*x-R).'*Qy*(S+G*x-R) + 0.5*(D*x - dk).'*Ru*(D*x - dk);
            tc.verifyLessThanOrEqual(J(Ustar) - J(zeros(m*N,1)), 1e-12);
        end
    end

    %% ---------- Symmetry and edge conditions ----------
    methods (Test)
        function testSymmetrizationOfWeights(tc)
            N=3; p=1; m=1;
            [Ty,Tu] = buildToeplitzSISO(N,[0.2],[0.8]);
            ofs = randn(p*N,1);

            % Make Qy PSD and Ru PD
            A = randn(p*N); Qy = A'*A;
            B = randn(m*N); Ru = B'*B + 1e-2*eye(m*N);

            % Add tiny asymmetry
            Qy_ns = Qy + 1e-12*triu(Qy,1);
            Ru_ns = Ru + 1e-12*triu(Ru,1);

            out1 = cost_assemble(Ty,Tu,ofs,Qy_ns,Ru_ns,zeros(p*N,1),struct('assert',true));
            tc.verifyLessThan(norm(out1.H - out1.H.','fro'), 1e-12);

            out2 = cost_assemble(Ty,Tu,ofs,0.5*(Qy_ns+Qy_ns.'),0.5*(Ru_ns+Ru_ns.'),zeros(p*N,1),struct('assert',true));
            tc.verifyLessThan(norm(out1.H - out2.H,'fro'), 1e-12);
            tc.verifyLessThan(norm(out1.h - out2.h), 1e-12);
        end

        function testZeroQyCase(tc)
            N=3; p=1; m=1;
            [Ty,Tu] = buildToeplitzSISO(N,[0.1],[0.9]);
            ofs = randn(p*N,1);
            Qy = zeros(p*N);
            Ru = eye(m*N);
            R  = randn(p*N,1);

            out = cost_assemble(Ty,Tu,ofs,Qy,Ru,R,struct('assert',true));
            D   = out.D; dk=zeros(m*N,1);

            tc.verifyLessThan(norm(out.h + D.'*(Ru*dk)), tc.tol);     % h = -D'Ru dk = 0 here
            tc.verifyLessThan(norm(out.H - D.'*(Ru*D),'fro'), tc.tol); % H = D'RuD
            tc.verifyEqual(out.J0, 0);                                 % dk=0 → 0
        end
    end

    %% ---------- SPD behavior and status ----------
    methods (Test)
        function testSPDStatusWhenAssertFalse(tc)
            N=3; p=1; m=1;
            [Ty,Tu] = buildToeplitzSISO(N,[0.1],[0.5]);
            ofs = zeros(p*N,1);
            Qy  = zeros(p*N);
            Ru  = zeros(m*N);                 % H = 0 (non-SPD)

            cfg = struct('assert',false,'eps',0,'m',m,'N',N);  % disable jitter
            out = cost_assemble(Ty,Tu,ofs,Qy,Ru,zeros(p*N,1),cfg);

            tc.verifyFalse(out.status.ok);
            tc.verifyEqual(out.status.code, 1);
        end
    end
end

%% ---------- helpers ----------
function [Ty,Tu] = buildToeplitzSISO(N, a, b)
% a: ny x 1, y-lag coefficients a1..any on subdiagonals 1..ny
% b: nu x 1, u-lag coefficients b0..b_{nu-1} on diagonals 0..nu-1 of Tu
    Ty = zeros(N,N);
    for j = 1:numel(a)
        for i = (j+1):N
            Ty(i,i-j) = a(j);
        end
    end
    Tu = zeros(N,N);
    for j = 0:(numel(b)-1)
        Tu = Tu + diag(b(j+1)*ones(N-j,1), j);
    end
end
