function [phi_k, meta, z_k] = regressor(s_k, spec, p_opt, m_opt)
% BK-RLS regressor builder
%
% Role
%   Given a past window s_k = (y_{k-ℓ:k-1}, u_{k-ℓ:k}) and a kernel spec,
%   construct the block-structured regressor used by RLS:
%       ψ_k  = [ 1 ; vec(y_{k-1},...,y_{k-ℓ}) ; vec(u_k,...,u_{k-ℓ}) ]
%       g_k  = kernel('eval', spec, s_k)
%       z_k  = (intercept-aware; see below)
%       φ_k  = z_k' ⊗ I_p   ∈ R^{p × (p·effective_width)}
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
%   φ_k   : p × d    where d = p·(length of z_k)
%   meta  : struct with fields
%           .p, .m, .ell, .d0, .q, .d
%           .shapes.y, .shapes.u
%           .notes  (string) brief description
%   z_k   : column vector; intercept-aware construction (see below)
%
% Notes
%   - Requires a READY window (no NaNs). Upstream window.m enforces this.
%   - Intercept-aware z_k:
%         if has_const:   z_k = [ g_1·ψ_k ; (g_{2:q} ⊗ ψ_k(2:end)) ]
%         else:            z_k = (g_k ⊗ ψ_k(2:end))

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
    g_k = kernel('eval', spec, s_k);
    q   = numel(g_k);

    % ---- z_k (intercept-aware) ----
    has_const = kernel_has_const(spec);  % structural flag

    if has_const
        % single C-block carried by g_1
        z_k  = [ g_k(1) * psi_k ; kron(g_k(2:end), psi_k(2:end)) ];
        zlen = d0 + (q-1)*(d0-1);
    else
        % no C anywhere → drop ψ_k(1)
        psi_bar = psi_k(2:end);
        z_k  = kron(g_k, psi_bar);
        zlen = q * (d0-1);
    end

    % ---- φ_k = z_k' ⊗ I_p ----
    phi_k = kron(z_k.', eye(p));

    % ---- metadata ----
    meta = struct();
    meta.p     = p;
    meta.m     = m;
    meta.ell   = ell;
    meta.d0    = d0;
    meta.q     = q;
    meta.d     = p * zlen;
    meta.shapes = struct('y', [p, ell], 'u', [m, ell+1]);
    meta.notes  = "φ_k uses intercept-aware z_k; drop ψ_k(1) when dictionary has no constant.";
    meta.zk     = z_k;

end

% ---------- helper ----------
function tf = kernel_has_const(spec)
% True iff the dictionary includes a constant feature in the FIRST block.
    t = lower(spec.type);
    switch t
        case 'ones'
            tf = true;
        case 'linear'
            % legacy linear often includes [1;s]; keep true
            tf = true;
        case 'poly'
            % legacy poly often includes constant; keep true
            tf = true;
        case 'rbf'
            tf = false;
        case 'mix'
            parts = getfield(spec,'parts',{});
            assert(~isempty(parts), 'regressor: mix.parts must be nonempty.');
            tf = kernel_has_const(parts{1});  % ONLY first sub-kernel may carry the 1
        otherwise
            tf = false;
    end
end
