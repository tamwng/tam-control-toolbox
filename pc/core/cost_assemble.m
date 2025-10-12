function out = cost_assemble(Ty, Tu, ofs, Qy, Ru, R, cfg)
% COST_ASSEMBLE  Assemble quadratic cost for BRLS-PC with increment penalty.
% Forms H, h, J0 using S_k = (I - T_y)\ofs and G_k = (I - T_y)\T_u,
% and penalizes input increments via ΔU = D U - d_k with H = G'Q_y G + D' R_u D.
%
% Inputs:
%   Ty  : (pN x pN) strictly lower-triangular Toeplitz T_y (zero diagonal)
%   Tu  : (pN x mN) Toeplitz T_u
%   ofs : (pN x 1)  sigma_k (offset)
%   Qy  : (pN x pN) output weight, PSD
%   Ru  : (mN x mN) increment weight, PD (for Cholesky)
%   R   : (pN x 1)  reference trajectory
%   cfg : optional struct
%         .assert  (default true)   shape/SPD checks
%         .eps     (default 1e-12)  numeric tol
%         .m       (optional)       number of inputs
%         .N       (optional)       horizon length (Nc = N)
%         .u_k     (optional m x 1) current applied input for ΔU's first block
%
% Outputs:
%   out.H   : (mN x mN) = G'Q_y G + D' R_u D     (symmetrized)
%   out.h   : (mN x 1)  = G'Q_y (S - R)
%   out.J0  : scalar    = 0.5*(S - R)' Q_y (S - R)
%   out.S   : (pN x 1)  S_k
%   out.G   : (pN x mN) G_k
%   out.D   : (mN x mN) first-difference operator
%   out.status : struct with ok/code/msg

    if nargin < 7 || isempty(cfg), cfg = struct(); end
    if ~isfield(cfg,'assert'), cfg.assert = true; end
    if ~isfield(cfg,'eps'),    cfg.eps    = 1e-12; end

    % ---------- Basic size checks ----------
    [pN1,pN2] = size(Ty);
    if cfg.assert, assert(pN1==pN2, 'Ty must be square (pN x pN).'); end
    pN = pN1;

    [pN_Tu, mN] = size(Tu);
    if cfg.assert
        assert(pN_Tu==pN, 'Tu must have pN rows to match Ty.');
        assert(all(size(Qy)==[pN pN]), 'Qy must be (pN x pN).');
        assert(all(size(Ru)==[mN mN]), 'Ru must be (mN x mN).');
        assert(isvector(ofs) && numel(ofs)==pN, 'ofs must be length pN.');
        assert(isvector(R)   && numel(R)==pN,   'R must be length pN.');
    end
    ofs = ofs(:); R = R(:);

    % ---------- Infer (m,N) if not provided ----------
    if isfield(cfg,'m') && isfield(cfg,'N')
        m = cfg.m; N = cfg.N;
        if cfg.assert, assert(m*N==mN, 'm*N must equal number of columns in Tu.'); end
    else
        % Default to single-input and infer N
        m = 1;
        N = mN / m;
        if cfg.assert, assert(abs(N-round(N))<1e-12, 'Cannot infer integer N from mN. Provide cfg.m and cfg.N.'); end
        N = round(N);
    end

    % ---------- Triangular solves: S_k and G_k ----------
    % Never form (I - Ty)^{-1} explicitly.
    IminusTy = speye(pN) - Ty;                  % unit-lower + well-conditioned if Ty built correctly
    S = IminusTy \ ofs;                          % S_k
    G = IminusTy \ Tu;                           % G_k

    % ---------- Increment operator D (ΔU = D U - d_k) ----------
    D = diff_operator(m, N);                     % (mN x mN) block first-difference
    % Note: the linear term 'h' does not contain d_k; d_k only affects the constant term
    % when writing cost in ΔU. We keep the absolute-U form for h,J0 as standard.

    % ---------- Assemble cost terms ----------
    % Light symmetrization to remove numerical skew.
    Qy = 0.5*(Qy + Qy.');
    Ru = 0.5*(Ru + Ru.');

    H = G.'*(Qy*G) + D.'*(Ru*D);
    H = 0.5*(H + H.');                           % enforce symmetry

    h = G.'*(Qy*(S - R));
    J0 = 0.5*(S - R).'*(Qy*(S - R));

    % Optional tiny ridge to ensure SPD in finite precision
    H = H + max(cfg.eps, 1e-10*norm(H,1))*speye(mN);

    % ---------- SPD check ----------
    status.ok = true; status.code = 0; status.msg = '';
    if cfg.assert
        [~,pchol] = chol(H);
        if pchol>0
            status.ok = false; status.code = 1;
            status.msg = 'H is not SPD (Cholesky failed). Ensure D'' R_u D \succ 0 and operators are well-posed.';
            error('%s', status.msg);
        end
    else
        [~,pchol] = chol(H);
        if pchol>0
            status.ok = false; status.code = 1;
            status.msg = 'H is not SPD (Cholesky failed).';
        end
    end

    out = struct('H',H,'h',h,'J0',J0,'S',S,'G',G,'D',D,'status',status);
end

% ====== Helpers ======

function D = diff_operator(m, N)
%DIFF_OPERATOR  Block first-difference operator for stacked inputs U ∈ R^{mN}.
% ΔU = D U - d_k, where
% D = blkdiag_k(I_m) with subdiagonal -I_m:
%   [ I  0  0 ... 0
%    -I  I  0 ... 0
%     0 -I  I ... 0
%     .  .  .  .  .
%     0 ... -I  I ]
    Im = speye(m);
    % main diagonal blocks
    D = kron(speye(N), Im);
    % subdiagonal -I blocks
    E = kron(spdiags(ones(N-1,1), -1, N, N), Im);
    D = D - E;
end
