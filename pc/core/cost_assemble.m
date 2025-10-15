function out = cost_assemble(Ty, Tu, ofs, Qy, Ru, R, cfg)
% COST_ASSEMBLE  Assemble quadratic cost for BRLS-PC with increment penalty.
% Uses S_k = (I - T_y)\ofs and G_k = (I - T_y)\T_u.
% Penalizes input increments ΔU = D U - d_k, so:
%   H = G'Q_y G + D' R_u D
%   h = G'Q_y (S - R) - D' R_u d_k
%   J0 = 0.5*(S - R)' Q_y (S - R) + 0.5*d_k' R_u d_k
%
% Inputs:
%   Ty  : (pN x pN) strictly lower-triangular Toeplitz T_y (zero diagonal)
%   Tu  : (pN x mN) Toeplitz T_u
%   ofs : (pN x 1)  sigma_k (offset)
%   Qy  : (pN x pN) output weight, PSD
%   Ru  : (mN x mN) increment weight, PD
%   R   : (pN x 1)  reference trajectory
%   cfg : struct with optional fields:
%         .assert (default true), .eps (default 1e-12)
%         .m (inputs), .N (horizon), .u_k (m×1 current input)

    if nargin < 7 || isempty(cfg), cfg = struct(); end
    if ~isfield(cfg,'assert'), cfg.assert = true; end
    if ~isfield(cfg,'eps'),    cfg.eps    = 1e-12; end

    [pN1,pN2] = size(Ty);
    if cfg.assert
        assert(pN1==pN2, 'Ty must be square (pN x pN).');
        assert(all(diag(Ty)==0), 'Ty must have zero diagonal.');
    end
    pN = pN1;

    [pN_Tu, mN] = size(Tu);
    if cfg.assert
        assert(pN_Tu==pN, 'Tu must have pN rows to match Ty.');
        assert(isequal(size(Qy),[pN pN]), 'Qy must be (pN x pN).');
        assert(isequal(size(Ru),[mN mN]), 'Ru must be (mN x mN).');
        assert(isvector(ofs) && numel(ofs)==pN, 'ofs length mismatch.');
        assert(isvector(R)   && numel(R)==pN,   'R length mismatch.');
    end
    ofs = ofs(:); R = R(:);

    if isfield(cfg,'m') && isfield(cfg,'N')
        m = cfg.m; N = cfg.N;
        if cfg.assert, assert(m*N==mN, 'm*N must equal size(Tu,2).'); end
    else
        m = 1; N = mN;    % single-input default
        if cfg.assert, assert(N==round(N), 'Provide cfg.m and cfg.N.'); end
    end

    IminusTy = speye(pN) - Ty;
    S = IminusTy \ ofs;
    G = IminusTy \ Tu;

    D  = diff_operator(m, N);
    dk = zeros(m*N,1);
    if isfield(cfg,'u_k') && ~isempty(cfg.u_k)
        uk = cfg.u_k(:);  assert(numel(uk)==m,'cfg.u_k must be m×1');
        dk(1:m) = uk; % Δu_0 = u_{0|k} - u_k
    end

    Qy = 0.5*(Qy + Qy.');
    Ru = 0.5*(Ru + Ru.');

    H  = G.'*(Qy*G) + D.'*(Ru*D);
    H  = 0.5*(H + H.');
    h  = G.'*(Qy*(S - R)) - D.'*(Ru*dk);
    J0 = 0.5*(S - R).'*(Qy*(S - R)) + 0.5*(dk.'*(Ru*dk));

    H = H + max(cfg.eps, 1e-10*norm(H,1))*speye(mN);

    status.ok = true; status.code = 0; status.msg = '';
    [~,pchol] = chol(H);
    if pchol>0
        status.ok = false; status.code = 1;
        status.msg = 'H is not SPD (Cholesky failed). Ensure D'' R_u D \succ 0.';
        if cfg.assert, error('%s', status.msg); end
    end

    out = struct('H',H,'h',h,'J0',J0,'S',S,'G',G,'D',D,'status',status);
end

function D = diff_operator(m, N)
% ΔU = D U - d_k, with first block Δu_0 = u_{0|k} - u_k.
    Im = speye(m);
    D  = kron(speye(N), Im) - kron(spdiags(ones(N-1,1), -1, N, N), Im);
end
