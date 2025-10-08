classdef test_toeplitz < matlab.unittest.TestCase
%TEST_PC_TOEPLITZ  Unit tests for pc/toeplitz.m
%
% Strategy
%   1) SISO ARX manual rollout vs stacked operators (paper equations).
%   2) MIMO ARX manual rollout vs stacked operators (indexing & Kronecker).
%   3) Kernel freeze: q>1, coefficients as convex combo via gamma.
%   4) Structure checks: sizes, strict block lower-triangular Ty, nilpotence.
%   5) Direct feedthrough placement: impulse in U affects y_{1|k} only via B0.
%
% Notes
%   - The test builds Theta in the layout expected by the current implementation:
%       for each basis j=1..q, a contiguous block
%         [ C^(j) | A_1^(j) | ... | A_ell^(j) | B_0^(j) | ... | B_ell^(j) ]
%       concatenated across j. If your implementation switches to the "group-by-type"
%       paper layout, update helper buildTheta_groupByJ accordingly.
%   - We intentionally capture the 3rd output as 'ofs' to decouple from naming
%     changes (s_k vs sigma_k).

    methods (Test)
        function test_SISO_ARX_manual_rollout(test)
            % SISO, ell=2, N=4, q=1 (pure ARX, no LPV variation across basis)
            p=1; m=1; ell=2; N=4; q=1;
            C  = 0.10;            % scalar
            A1 = 0.20; A2 = -0.10;
            B0 = 0.50; B1 = 0.30; B2 = 0.00;
            y_hist = [0.7, -0.2]; % [y_{k-1}, y_k]
            u_hist = [0.1,  0.4]; % [u_{k-1}, u_k]
            Usteps = [0.6; -0.1; 0.2; -0.3]; % u_{1|k}..u_{4|k}
    
            Theta = buildTheta_groupByJ(p,m,ell,q, ...
                {C}, {A1, A2}, {B0, B1, B2});
            gamma = 1; % q=1
    
            [Ty, Tu, ofs, meta] = toeplitz(Theta, gamma, y_hist, u_hist, N, ell);
            It = speye(p*N);
            Y_from_ops = (It - Ty) \ (ofs + Tu * Usteps);
    
            % Manual rollout
            Y_manual = rolloutSISO([A1 A2], [B0 B1 B2], C, y_hist, u_hist, Usteps, N);
    
            test.verifyEqual(size(Ty), [p*N, p*N]);
            test.verifyEqual(size(Tu), [p*N, m*N]);
            test.verifySize(ofs, [p*N, 1]);
            test.verifyLessThan(norm(Y_from_ops - Y_manual), 1e-12);
    
            % Coefficient compilation check
            test.verifyEqual(meta.Ck, C, 'AbsTol', 0);
            test.verifyEqual(meta.Ak{1}, A1, 'AbsTol', 0);
            test.verifyEqual(meta.Ak{2}, A2, 'AbsTol', 0);
            test.verifyEqual(meta.Bk{1}, B0, 'AbsTol', 0);
            test.verifyEqual(meta.Bk{2}, B1, 'AbsTol', 0);
            test.verifyEqual(meta.Bk{3}, B2, 'AbsTol', 0);
        end
    
        function test_MIMO_ARX_manual_rollout(test)
            % MIMO p=2, m=2, ell=2, N=3, q=1
            p=2; m=2; ell=2; N=3; q=1;
            C  = [0.1; -0.2];
            A1 = [0.3  -0.1; 0.05 0.2];
            A2 = [-0.2 0.0; 0.1 -0.15];
            B0 = [0.5 0.1; -0.2 0.4];
            B1 = [0.2 0.0; 0.1 0.1];
            B2 = zeros(p,m);
            y_hist = [ [0.2; -0.1], [0.05; 0.3] ]; % columns [y_{k-1}, y_k]
            u_hist = [ [0.1; 0.4],   [0.2; -0.3] ]; % columns [u_{k-1}, u_k]
            Usteps = [ 0.6; -0.1;  -0.2; 0.3;  0.1; 0.0 ]; % stacked u1,u2,u3
    
            Theta = buildTheta_groupByJ(p,m,ell,q, {C}, {A1, A2}, {B0, B1, B2});
            gamma = 1;
    
            [Ty, Tu, ofs] = toeplitz(Theta, gamma, y_hist, u_hist, N, ell);
            It = speye(p*N);
            Y_from_ops = (It - Ty) \ (ofs + Tu * Usteps);
    
            Y_manual = rolloutMIMO({A1, A2}, {B0, B1, B2}, C, y_hist, u_hist, Usteps, N, p, m);
            test.verifyLessThan(norm(Y_from_ops - Y_manual), 1e-11);
        end
    
        function test_KernelFreeze_q2(test)
            % q=2 basis, gamma mixes coefficients linearly. Verify compilation.
            p=1; m=1; ell=2; N=3; q=2;
            % basis 1
            C1=0.0; A11=0.2; A21=0.0; B01=0.1; B11=0.0; B21=0.0;
            % basis 2
            C2=0.5; A12=0.0; A22=0.1; B02=0.0; B12=0.3; B22=0.0;
            alpha = 0.3; gamma = [alpha; 1-alpha];
    
            y_hist = [0.0, 1.0]; u_hist = [0.2, -0.1];
            Usteps = [0.4; -0.2; 0.0];
    
            Theta = buildTheta_groupByJ(1,1,2,2, ...
                {C1, C2}, {A11, A12; A21, A22}, {B01, B02; B11, B12; B21, B22});
    
            [Ty, Tu, ofs, meta] = toeplitz(Theta, gamma, y_hist, u_hist, N, ell);
    
            % Expected compiled coefficients
            C = alpha*C1 + (1-alpha)*C2;
            A1= alpha*A11 + (1-alpha)*A12;
            A2= alpha*A21 + (1-alpha)*A22;
            B0= alpha*B01 + (1-alpha)*B02;
            B1= alpha*B11 + (1-alpha)*B12;
            B2= alpha*B21 + (1-alpha)*B22;
            test.verifyEqual(meta.Ck, C, 'AbsTol', 0);
            test.verifyEqual(meta.Ak{1}, A1, 'AbsTol', 0);
            test.verifyEqual(meta.Ak{2}, A2, 'AbsTol', 0);
            test.verifyEqual(meta.Bk{1}, B0, 'AbsTol', 0);
            test.verifyEqual(meta.Bk{2}, B1, 'AbsTol', 0);
            test.verifyEqual(meta.Bk{3}, B2, 'AbsTol', 0);
    
            % Numerical rollout comparison
            It = speye(p*N);
            Y_ops = (It - Ty) \ (ofs + Tu * Usteps);
            Y_manual = rolloutSISO([A1 A2], [B0 B1 B2], C, y_hist, u_hist, Usteps, N);
            test.verifyLessThan(norm(Y_ops - Y_manual), 1e-12);
        end
    
        function test_Structure_and_Nilpotence(test)
            % Random small MIMO. Check block structure and Ty^N=0.
            rng(42);
            p=2; m=1; ell=3; N=4; q=1;
            C  = randn(p,1);
            A  = arrayfun(@(~)randn(p,p)*0.1, 1:ell, 'uni', 0);
            B  = arrayfun(@(~)randn(p,m)*0.1, 0:ell, 'uni', 0);
            y_hist = randn(p,ell);
            u_hist = randn(m,ell);
            Theta = buildTheta_groupByJ(p,m,ell,q, {C}, A, B);
            gamma = 1;
            [Ty, Tu, ofs] = toeplitz(Theta, gamma, y_hist, u_hist, N, ell);
    
            % Strict block lower-triangular diagonal check
            for b=1:N
                rows = (b-1)*p + (1:p); cols = rows;
                test.verifyLessThan(norm(full(Ty(rows,cols)),'fro'), 1e-12);
            end
            % Nilpotence
            Ty_pow = Ty; Z = sparse(p*N,p*N);
            for r=1:N
                if r < N
                    test.verifyLessThan(norm(Ty_pow,'fro'), 1e2); % just ensure not inf/nan
                end
                Ty_pow = Ty_pow*Ty;
            end
            test.verifyLessThan(norm(Ty_pow - Z,'fro'), 1e-12);
    
            % Size checks
            test.verifyEqual(size(Ty), [p*N, p*N]);
            test.verifyEqual(size(Tu), [p*N, m*N]);
            test.verifyEqual(size(ofs), [p*N, 1]);
        end
    
        function test_DirectFeedthrough_Impulse(test)
            % Ensure B0 only affects same-step through Tu with S_0.
            p=1; m=1; ell=2; N=3; q=1;
            C=0; A1=0.2; A2=0; B0=1.0; B1=0; B2=0;  % pure direct feedthrough + A1
            y_hist=[0,0]; u_hist=[0,0];
            Usteps=[1;0;0]; % impulse at first planned input only
            Theta = buildTheta_groupByJ(p,m,ell,q,{C},{A1,A2},{B0,B1,B2});
            gamma=1;
    
            [Ty, Tu, ofs] = toeplitz(Theta, gamma, y_hist, u_hist, N, ell);
            It = speye(p*N);
            Y_ops = (It - Ty) \ (ofs + Tu * Usteps);
    
            % y1 = B0*1 = 1, y2 = A1*y1 = 0.2, y3 = A1*y2 = 0.04
            Y_expected = [1; 0.2; 0.04];
            test.verifyLessThan(norm(Y_ops - Y_expected), 1e-12);
        end
    
        function test_IndexMapping_SISO_ImpulseColumns(test)
            % Each column block of Tu should map u_j only to rows >= j.
            p=1;m=1;ell=2;N=4;q=1;
            C=0;A1=0.0;A2=0.0;B0=1;B1=0;B2=0; % pure B0 to isolate Tu structure
            y_hist=[0,0]; u_hist=[0,0];
            Theta = buildTheta_groupByJ(p,m,ell,q,{C},{A1,A2},{B0,B1,B2});
            [Ty,Tu,ofs] = toeplitz(Theta,1,y_hist,u_hist,N,ell); %#ok<ASGLU>
            It = speye(p*N);
            for j=1:N
                Uimp = zeros(m*N,1); Uimp((j-1)*m+1) = 1; % unit impulse at step j
                Y = (It - Ty) \ (ofs + Tu*Uimp);
                % Expect y_i = 0 for i<j and y_j = 1, others 0 because A=0, B1=B2=0
                expY = zeros(N,1); expY(j)=1;
                test.verifyLessThan(norm(Y-expY),1e-12);
            end
        end
    
        function test_IndexMapping_PastHistoryOffsets(test)
            % F_i ⊗ A_i and F_i ⊗ B_i should land only in first i block rows.
            p=1;m=1;ell=3;N=5;q=1;
            C=0;A1=1;A2=2;A3=3;B0=0;B1=4;B2=5;B3=6; % integers to track weights
            y_hist=[10,20,30]; % y_{k-2}, y_{k-1}, y_k
            u_hist=[7,8,9];    % u_{k-2}, u_{k-1}, u_k
            Theta = buildTheta_groupByJ(p,m,ell,q,{C},{A1,A2,A3},{B0,B1,B2,B3});
            [Ty,Tu,ofs] = toeplitz(Theta,1,y_hist,u_hist,N,ell); %#ok<ASGLU>
            % Only first i rows get contributions from i-step history
            % Row 1: A1*y_k + B1*u_k
            % Row 2: A1*y_{k-1}+A2*y_k + B1*u_{k-1}+B2*u_k
            % Row 3: A1*y_{k-2}+A2*y_{k-1}+A3*y_k + B1*u_{k-2}+B2*u_{k-1}+B3*u_k
            % Rows 4..5: zero (since F_i zeroes below block i)
            
            % y_hist = [y_{k-2}, y_{k-1}, y_k] = [10,20,30]
            % u_hist = [u_{k-2}, u_{k-1}, u_k] = [7,8,9]
            yk2=10; yk1=20; yk=30; uk2=7; uk1=8; uk=9;
            
            exp = zeros(N,1);
            % Row 1: A1*y_k + A2*y_{k-1} + A3*y_{k-2} + B1*u_k + B2*u_{k-1} + B3*u_{k-2}
            exp(1) = A1*yk + A2*yk1 + A3*yk2 + B1*uk + B2*uk1 + B3*uk2;
            % Row 2: A2*y_k + A3*y_{k-1} + B2*u_k + B3*u_{k-1}
            exp(2) = A2*yk + A3*yk1 + B2*uk + B3*uk1;
            % Row 3: A3*y_k + B3*u_k
            exp(3) = A3*yk + B3*uk;
            % Rows 4..N: zero (F_i zero below i)

            test.verifyLessThan(norm(ofs-exp),1e-12);
        end
    
        function test_BlockShifts_in_Ty_and_Tu_MIMO(test)
            % Verify that Ty and Tu place subdiagonals correctly for MIMO.
            p=2;m=2;ell=2;N=3;q=1;
            C=[0;0];
            A1=eye(p); A2=2*eye(p); % diagonal to make checking easy
            B0=3*eye(p, m); B1=4*eye(p, m); B2=5*eye(p, m);
            y_hist=zeros(p,ell); u_hist=zeros(m,ell);
            Theta = buildTheta_groupByJ(p,m,ell,q,{C},{A1,A2},{B0,B1,B2});
            [Ty,Tu,~] = toeplitz(Theta,1,y_hist,u_hist,N,ell);
            % Build reference Ty_ref and Tu_ref explicitly by block placement
            Ty_ref = zeros(p*N); Tu_ref = zeros(p*N, m*N);
            % Ty: A1 on first subdiag, A2 on second
            for r=2:N
                Ty_ref((r-1)*p+(1:p),(r-2)*p+(1:p)) = A1;
            end
            for r=3:N
                Ty_ref((r-1)*p+(1:p),(r-3)*p+(1:p)) = A2;
            end
            % Tu: B0 on main block diag, B1 on first subdiag, B2 on second
            for r=1:N
                Tu_ref((r-1)*p+(1:p),(r-1)*m+(1:m)) = B0;
            end
            for r=2:N
                Tu_ref((r-1)*p+(1:p),(r-2)*m+(1:m)) = B1;
            end
            for r=3:N
                Tu_ref((r-1)*p+(1:p),(r-3)*m+(1:m)) = B2;
            end
            test.verifyLessThan(norm(full(Ty)-Ty_ref,'fro'),1e-12);
            test.verifyLessThan(norm(full(Tu)-Tu_ref,'fro'),1e-12);
        end
    
        function test_Neq1_OneStep_Exact(test)
            % N=1 must reduce to the one-step predictor exactly for any ell.
            p=1;m=1;ell=3;N=1;q=1;
            C=0.7; A={0.2,-0.3,0.1}; B={0.5,0.4,-0.2,0.0};
            y_hist=[1.1, -0.5, 0.8]; % y_{k-2}, y_{k-1}, y_k
            u_hist=[0.3, -0.7, 0.2];
            u1 = -0.4; U = u1; % only one planned input
            Theta = buildTheta_groupByJ(p,m,ell,q,{C},A,B);
            [Ty,Tu,ofs] = toeplitz(Theta,1,y_hist,u_hist,N,ell);
            Y = (speye(p*N)-Ty) \ (ofs + Tu*U);
            % Manual one-step
            y1 = C + A{1}*y_hist(end) + A{2}*y_hist(end-1) + A{3}*y_hist(end-2) ...
                     + B{2}*u_hist(end) + B{3}*u_hist(end-1) + B{4}*u_hist(end-2) ...
                     + B{1}*u1;
            test.verifyLessThan(abs(Y - y1),1e-12);
        end
    
        function test_EllGTN_Nilpotence_And_FSelectors(test)
            % ell > N: ensure S_i zeros for i>N and F_i handles i>N via [I_N 0].
            p=1;m=1;ell=5;N=3;q=1;
            C=0.0; A={1,2,3,4,5}; B={10,20,30,40,50,60};
            y_hist=[7,8,9,10,11]; u_hist=[1,2,3,4,5];
            Theta = buildTheta_groupByJ(p,m,ell,q,{C},A,B);
            [Ty,Tu,ofs] = toeplitz(Theta,1,y_hist,u_hist,N,ell); %#ok<ASGLU>
            % Nilpotence
            Ty_pow = Ty; for r=1:N, Ty_pow = Ty_pow*Ty; end
            test.verifyLessThan(norm(Ty_pow,'fro'), 1e-12);
            % Check that ofs equals explicit build using Fi with r=min(N,i)
            ofs_ref = zeros(N,1) + C;
            for i=1:ell
                r = min(N,i);
                Yi = reshape(y_hist(:, end-i+1:end), [], 1);
                Ui = reshape(u_hist(:, end-i+1:end), [], 1);
                Fi = [eye(r), zeros(r, i-r); zeros(N-r, i)];
                ofs_ref = ofs_ref + kron(Fi, A{i})*Yi + kron(Fi, B{i+1})*Ui;
            end
            test.verifyLessThan(norm(ofs - ofs_ref), 1e-12);
        end
    
        function test_PureOffset_OnlyC(test)
            % A_i=0 and all B_i=0 ⇒ Y = 1_N ⊗ C.
            p=2;m=1;ell=3;N=4;q=1;
            C=[0.2;-0.5]; A={zeros(p),zeros(p),zeros(p)}; B={zeros(p,m),zeros(p,m),zeros(p,m),zeros(p,m)};
            y_hist=randn(p,ell); u_hist=randn(m,ell); U=randn(m*N,1);
            Theta = buildTheta_groupByJ(p,m,ell,q,{C},A,B);
            [Ty,Tu,ofs] = toeplitz(Theta,1,y_hist,u_hist,N,ell);
            Y = (speye(p*N)-Ty) \ (ofs + Tu*U);
            test.verifyLessThan(norm(Y - kron(ones(N,1), C)), 1e-12);
        end
    
        function test_PureHistory_NoDirect_SISO(test)
            % C=0, B0=0, A=0, B1≠0 ⇒ y_j depends only on u_{j-1}, not u_j.
            p=1;m=1;ell=2;N=4;q=1;
            C=0; A={0,0}; B={0, 3.0, 0};
            y_hist=[0,0]; u_hist=[0,0];
            U = [1; 2; 3; 4];
            Theta = buildTheta_groupByJ(p,m,ell,q,{C},A,B);
            [Ty,Tu,ofs] = toeplitz(Theta,1,y_hist,u_hist,N,ell);
            Y = (speye(p*N)-Ty) \ (ofs + Tu*U);
            % Expected: y1=0, y2=3*1, y3=3*2, y4=3*3
            expY = [0; 3; 6; 9];
            test.verifyLessThan(norm(Y-expY),1e-12);
        end
    
        function test_MIMO_Permutation_Equiv(test)
            % Permute input/output channels and verify equivariance.
            p=2;m=2;ell=2;N=3;q=1;
            C=[0.1; -0.3];
            A1=[0.2 0.1; 0 0.3]; A2=[-0.1 0; 0.05 -0.2];
            B0=[1 0; 0 2]; B1=[0.5 0.1; -0.2 0.3]; B2=zeros(p,m);
            y_hist=randn(p,ell); u_hist=randn(m,ell); U=randn(m*N,1);
            Theta = buildTheta_groupByJ(p,m,ell,q,{C},{A1,A2},{B0,B1,B2});
            [Ty,Tu,ofs] = toeplitz(Theta,1,y_hist,u_hist,N,ell);
            Y = (speye(p*N)-Ty) \ (ofs + Tu*U);
            % Permute with swap matrices
            Py = [0 1; 1 0]; Pu = [0 1; 1 0];
            C2 = Py*C; A12 = Py*A1*Py'; A22 = Py*A2*Py';
            B02 = Py*B0*Pu'; B12 = Py*B1*Pu'; B22 = Py*B2*Pu';
            y_hist2 = Py*y_hist; u_hist2 = Pu*u_hist; U2 = kron(speye(N), Pu)*U;
            Theta2 = buildTheta_groupByJ(p,m,ell,q,{C2},{A12,A22},{B02,B12,B22});
            [Ty2,Tu2,ofs2] = toeplitz(Theta2,1,y_hist2,u_hist2,N,ell);
            Y2 = (speye(p*N)-Ty2) \ (ofs2 + Tu2*U2);
            test.verifyLessThan(norm(Y2 - kron(speye(N), Py)*Y), 1e-12);
        end
    end
end

% ================== Helpers ==================
function Theta = buildTheta_groupByJ(p,m,ell,q, C_list, A_list, B_list)
% Build Theta in the layout expected by toeplitz.m implementation:
%   Theta = [ block(j=1) | block(j=2) | ... | block(j=q) ]
%   block(j) = [ C^(j) | A_1^(j) | ... | A_ell^(j) | B_0^(j) | ... | B_ell^(j) ]
% Inputs
%   C_list : length q cell of p×1 or scalars
%   A_list : ell×q cells or 1×ell cell when q=1
%   B_list : (ell+1)×q cells or 1×(ell+1) when q=1
    Theta = [];
    for j=1:q
        % C
        Cj = ensure_col(C_list, j, p, 1);
        block = Cj;
        % A_i
        for i=1:ell
            Aij = ensure_mat(A_list, i, j, p, p);
            block = [block, Aij]; %#ok<AGROW>
        end
        % B_i, i=0..ell
        for i=0:ell
            Bij = ensure_mat(B_list, i+1, j, p, m);
            block = [block, Bij]; %#ok<AGROW>
        end
        Theta = [Theta, block]; %#ok<AGROW>
    end
end

% function M = ensure_mat(cellMat, i, j, r, c)
%     if iscell(cellMat)
%         if ndims(cellMat) == 2 && ~isscalar(cellMat)
%             M = cellMat{i, j};     % correct 2-D cell indexing
%         else
%             M = cellMat{i};        % 1-D cell (q=1) case
%         end
%     else
%         M = cellMat;
%     end
%     if isscalar(M), M = M*ones(r,c); end
%     M = reshape(M, r, c);
% end


function M = ensure_mat(cellMat, i, j, r, c)
    % Works for:
    %  - numeric (broadcast if scalar)
    %  - 1-D cell (q=1): {i}
    %  - 2-D cell (ell×q or (ell+1)×q): {i,j}
    if iscell(cellMat)
        if ismatrix(cellMat) && ~isscalar(cellMat) ...
                && size(cellMat,1) >= i && size(cellMat,2) >= j
            M = cellMat{i, j};          % 2-D cell case
        elseif numel(cellMat) >= i
            M = cellMat{i};             % 1-D cell (q=1) case
        else
            error('ensure_mat: index out of range');
        end
    else
        M = cellMat;                    % numeric
    end
    if isscalar(M), M = M*ones(r,c); end
    M = reshape(M, r, c);
end


function c = ensure_col(C_list, j, r, cdim)
    if iscell(C_list)
        if numel(C_list) == 1
            c = C_list{1};
        else
            c = C_list{j};
        end
    else
        c = C_list;
    end
    if isscalar(c), c = c*ones(r,1); end
    c = reshape(c, r, cdim);
end

function Y = rolloutSISO(A, B, C, y_hist, u_hist, Usteps, N)
% SISO LPV-ARX rollout (frozen coeffs). Matches paper and Toeplitz build.
% A = [A1 ... A_ell], B = [B0 B1 ... B_ell], histories are chronological.

    % normalize shapes
    A = A(:).';                 % 1×ell
    B = B(:).';                 % 1×(ell+1)
    ell = numel(A);
    if numel(B) ~= ell+1, error('B must have length ell+1.'); end
    y_hist = y_hist(:).';       % 1×ell  [y_{k-ell+1},...,y_k]
    u_hist = u_hist(:).';       % 1×ell  [u_{k-ell+1},...,u_k]
    Usteps = Usteps(:);         % N×1    [u_{1|k};...;u_{N|k}]
    if numel(y_hist)~=ell || numel(u_hist)~=ell, error('hist len≠ell'); end
    if numel(Usteps)~=N, error('Usteps len≠N'); end

    y = zeros(N,1);
    for j = 1:N
        acc = 0;
        for i = 1:ell
            idx = j - i;                 % horizon offset
            if idx <= 0
                r = i - j;               % r≥0
                y_i = y_hist(end - r);   % y_{k+(j-i)}
                u_i = u_hist(end - r);   % u_{k+(j-i)}
            else
                y_i = y(idx);            % y_{j-i|k}
                u_i = Usteps(idx);       % u_{j-i|k}
            end
            acc = acc + A(i)*y_i + B(i+1)*u_i;  % B(i+1) = B_i, i≥1
        end
        y(j) = C + acc + B(1)*Usteps(j);       % B(1) = B0
    end
    Y = y;
end

function Y = rolloutMIMO(Acell, Bcell, C, y_hist, u_hist, U, N, p, m)
% MIMO LPV-ARX rollout (frozen coeffs). Matches paper and Toeplitz build.
% Acell = {A1,...,A_ell}, A_i ∈ R^{p×p}
% Bcell = {B0,B1,...,B_ell}, B_i ∈ R^{p×m}
% C ∈ R^{p}, y_hist ∈ R^{p×ell} [y_{k-ell+1},...,y_k]
% u_hist ∈ R^{m×ell} [u_{k-ell+1},...,u_k]
% U ∈ R^{mN} stacked [u_{1|k};...;u_{N|k}]

    ell = numel(Acell);
    if numel(Bcell) ~= ell+1, error('Bcell must have length ell+1.'); end
    if size(y_hist,2) ~= ell || size(u_hist,2) ~= ell, error('hist len≠ell'); end
    if numel(U) ~= m*N, error('U length must be mN.'); end

    Usteps = reshape(U, m, N);         % columns are u_{j|k}
    y = zeros(p, N);

    for j = 1:N
        acc = zeros(p,1);
        for i = 1:ell
            idx = j - i;                % horizon offset
            if idx <= 0
                r = i - j;              % r≥0
                y_i = y_hist(:, end - r);   % y_{k+(j-i)}
                u_i = u_hist(:, end - r);   % u_{k+(j-i)}
            else
                y_i = y(:, idx);            % y_{j-i|k}
                u_i = Usteps(:, idx);       % u_{j-i|k}
            end
            acc = acc + Acell{i} * y_i + Bcell{i+1} * u_i; % i≥1 term
        end
        y(:, j) = C + acc + Bcell{1} * Usteps(:, j);       % B0 on step j
    end

    Y = y(:);
end
