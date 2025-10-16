function [phi_k, meta, z_k] = regressor(s_k, spec, p_opt, m_opt)
% BK-RLS regressor builder
%
% Role
%   Given a past window s_k = (y_{k-ℓ:k-1}, u_{k-ℓ:k}) and a kernel spec,
%   construct the block-structured regressor used by RLS:
%       ψ_k  = [ 1 ; vec(y_{k-1},...,y_{k-ℓ}) ; vec(u_k,...,u_{k-ℓ}) ]
%       g_k  = kernel('eval', spec, s_k)
%       z_k  = g_k ⊗ ψ_k
%       φ_k  = z_k' ⊗ I_p   ∈ R^{p × (p·q·d0)}
%
% Usage
%   [φ_k, meta]        = regressor(s_k, spec)
%   [φ_k, meta, z_k]   = regressor(s_k, spec)   % also returns z_k
%   ... with optional dimension checks:
%   [φ_k, meta]        = regressor(s_k, spec, p, m)
%
% Inputs
%   s_k.y : p×ℓ      columns [y_{k-1},...,y_{k-ℓ}]
%   s_k.u : m×(ℓ+1)  columns [u_k, u_{k-1},...,u_{k-ℓ}]
%   spec  : kernel specification (see bkrls/kernel.m)
%   p_opt : (optional) expected p; checked against size(s_k.y,1)
%   m_opt : (optional) expected m; checked against size(s_k.u,1)
%
% Outputs
%   φ_k   : p × d    where d = p·q·d0
%   meta  : struct with fields
%           .p, .m, .ell, .d0, .q, .d
%           .shapes.y, .shapes.u
%           .notes  (string) brief description
%   z_k   : (optional) q·d0 × 1 vector equal to g_k ⊗ ψ_k
%
% Notes
%   - Requires a READY window (no NaNs). Upstream window.m enforces this.
%   - Uses simple, readable formulas. For speed, replace kron() with
%     block-scaling or preallocated patterns later (unchanged API).

    % ---- shape extraction and basic checks ----
    y = s_k.y;  u = s_k.u;
    assert(isnumeric(y) && ismatrix(y), 'regressor: s_k.y must be numeric p×ℓ.');
    assert(isnumeric(u) && ismatrix(u), 'regressor: s_k.u must be numeric m×(ℓ+1).');

    [p, ell] = size(y);
    [m, ucols] = size(u);
    assert(ucols == ell+1, 'regressor: s_k.u must have ℓ+1 columns (includes u_k).');

    if nargin>=3 && ~isempty(p_opt) && p_opt~=p
        error('bkrls:regressor:PMismatch','regressor: p mismatch.');
    end
    if nargin>=4 && ~isempty(m_opt) && m_opt~=m
        error('bkrls:regressor:MMismatch','regressor: m mismatch.');
    end

    % Window must be READY: no NaN/Inf allowed
    assert(all(isfinite(y),'all') && all(isfinite(u),'all'), ...
        'regressor: window contains NaN/Inf; call only when ready.');

    % ---- base vector ψ_k ----
    % Column-major flattening matches the documented order.
    % d0 = 1 + p·ℓ + m·(ℓ+1)
    psi_k = [1; y(:); u(:)];
    d0    = numel(psi_k);

    % ---- kernel evaluation g_k ----
    % Deterministic; spec may include center/scale for conditioning.
    g_k = kernel('eval', spec, s_k);
    q   = numel(g_k);

    % ---- z_k = g_k ⊗ ψ_k ----
    % NEW: intercept-aware construction to avoid duplicate columns when g_k includes a constant.
    tol = 10*eps(class(g_k));
    is_const = abs(g_k - 1) <= tol;
    if any(is_const)
        % coalesce constants: move the first constant to the front, drop the others
        first_const = find(is_const, 1, 'first');
        keep_idx = true(q,1); keep_idx(is_const) = false;  % drop all constants for now
        g_front = g_k(first_const);
        g_rest  = g_k(keep_idx);                           % non-constant features only
        psi_rest = psi_k(2:end);                           % non-intercept part
        z_k = [ g_front * psi_k ; kron(g_rest, psi_rest) ];
        zlen = d0 + numel(g_rest)*(d0-1);
    else
        % standard Kronecker
        z_k = kron(g_k, psi_k);
        zlen = q * d0;
    end

    % ---- φ_k = z_k' ⊗ I_p ----
    % Size: p × (p·q·d0). Keeps the model linear in parameters.
    phi_k = kron(z_k.', eye(p));

    % ---- metadata for assertions and logging ----
    meta = struct();
    meta.p     = p;
    meta.m     = m;
    meta.ell   = ell;
    meta.d0    = d0;
    meta.q     = q;
    meta.d     = p * zlen;  % effective width with intercept-aware z_k
    meta.shapes = struct('y', [p, ell], 'u', [m, ell+1]);
    meta.notes  = "φ_k = (g_k ⊗ ψ_k)' ⊗ I_p; intercept-aware z_k when a constant kernel feature is present.";

    % Optional: lightweight self-check in debug scenarios
    % (disable in hot paths if needed)
    % Theta_dbg = randn(p, zlen);
    % lhs = Theta_dbg * z_k;
    % rhs = phi_k * Theta_dbg(:);
    % assert(norm(lhs - rhs) <= 1e-10*(1+norm(lhs)), 'regressor: kron identity failed.');

end