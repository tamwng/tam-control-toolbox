function [st, status] = rls_update(st, phi_k, y_k)
% BK-RLS recursive least squares update (multi-output)
%
% Model
%   ŷ_k = φ_k θ_k,   with φ_k ∈ R^{p×d},  θ_k ∈ R^{d×1},  y_k ∈ R^{p×1}.
%
% Cost minimized implicitly by the recursion
%   J_k(θ) = Σ_{i=0}^k λ^{k-i} || y_i - φ_i θ ||_2^2 + λ^k (θ-θ0)' P0^{-1} (θ-θ0)
% Forgetting factor λ ∈ (0,1]; Tikhonov realized via P0 = ρ^{-1} I (set at init).
%
% Update (matrix-form, numerically stable)
%   L   = P / λ
%   S   = I_p + φ L φ'            (p×p, SPD)
%   K   = L φ' S^{-1}             (d×p)   [gain]
%   θ⁺  = θ + K (y - φ θ)         (d×1)
%   P⁺  = L - K (φ L)             (d×d)   [Joseph form: L - K S K']
%
% Inputs
%   st     : struct with fields (set by rls_init.m)
%            .theta (d×1), .P (d×d SPD), .lambda∈(0,1], .eps>0
%   phi_k  : (p×d) regressor from bkrls/regressor.m
%   y_k    : (p×1) measurement at time k
%
% Outputs
%   st     : updated state with .theta and .P
%   status : struct with fields
%            .ok (logical), .code (char), .msg (char)
%            .gain_norm (double), .min_eig_P (double)
%
% Notes
%   - Double precision only.
%   - No RNG. Deterministic given inputs.
%   - Uses Cholesky solves on S for numerical stability.
%
% Failure modes and handling
%   - BAD_DIM     : size mismatch → no update, state unchanged
%   - NAN_INPUT   : NaN/Inf in inputs → no update, state unchanged
%   - S_NOT_SPD   : S not SPD → add jitter to S, retry; if still bad, skip
%   - P_NOT_SPD   : post-update P loses SPD → add jitter εI and symmetrize

    % ---------- status scaffold ----------
    status = make_status(true,'OK','ok');
    status.gain_norm = NaN;
    status.min_eig_P = NaN;

    % ---------- basic dimension and finite checks ----------
    theta = st.theta;   % d×1
    P     = st.P;       % d×d
    lam   = st.lambda;  % scalar in (0,1]
    eps_n = st.eps;     % small epsilon for jitter

    [p_rows, d_cols] = size(phi_k);
    if ~isvector(y_k), y_k = y_k(:); end

    if size(theta,2) ~= 1
        status = make_status(false,'BAD_STATE','theta must be column vector.');
        return
    end
    d = size(theta,1);
    if d_cols ~= d || size(y_k,1) ~= p_rows || size(y_k,2) ~= 1
        status = make_status(false,'BAD_DIM','phi_k or y_k has incompatible size.');
        return
    end
    if ~isfinite(lam) || lam <= 0 || lam > 1
        status = make_status(false,'BAD_STATE','lambda must be in (0,1].');
        return
    end
    if any(~isfinite(phi_k),'all') || any(~isfinite(y_k),'all') || ...
       any(~isfinite(theta),'all') || any(~isfinite(P),'all')
        status = make_status(false,'NAN_INPUT','inputs/state contain NaN/Inf.');
        return
    end

    % ---------- prediction and innovation ----------
    y_hat = phi_k * theta;         % p×1
    r     = y_k - y_hat;           % p×1

    % ---------- scaled covariance ----------
    % L = P / λ. Symmetrize to dampen drift.
    L = (P + P') * 0.5 / lam;

    % ---------- S = I + φ L φ' ----------
    % Prefer Cholesky factorization to avoid explicit inverse.
    S = eye(p_rows) + phi_k * (L * phi_k.');
    [R, chol_flag] = chol(S, 'upper');  % S = R' * R
    if chol_flag ~= 0
        % Add a small jitter and retry once
        jitter = max(eps_n, 1e-12);
        S = S + jitter * eye(p_rows);
        [R, chol_flag] = chol(S, 'upper');
        if chol_flag ~= 0
            status = make_status(false,'S_NOT_SPD','S not SPD even after jitter; skipping update.');
            return
        end
    end

    % ---------- Gain K = L φ' S^{-1} via triangular solves ----------
    % Compute Y = S^{-1} (φ L) without forming S^{-1}.
    phiL = phi_k * L;          % (p×d)
    % Solve R' Z = phiL  →  Z = R'\phiL
    Z = R' \ phiL;
    % Solve R  Y = Z     →  Y = R\Z  = S^{-1} (φ L)
    Y = R \ Z;                 % (p×d)
    K = Y.';                   % (d×p)

    % ---------- Parameter and covariance updates ----------
    theta_new = theta + K * r;           % d×1
    P_new     = L    - K * (phiL);       % d×d

    % Symmetrize and enforce minimal SPD
    P_new = (P_new + P_new') * 0.5;
    % Guard: tiny negative eigenvalues due to round-off
    [Rc, cholP] = chol(P_new);
    if cholP ~= 0
        P_new = P_new + eps_n * eye(d);
        P_new = (P_new + P_new') * 0.5;
        % Try once more; if still not SPD, mark but accept (RLS will recover)
        [~, cholP2] = chol(P_new);
        if cholP2 ~= 0
            status = make_status(true,'P_ADJUSTED','P adjusted but near-singular.');
        end
    end

    % ---------- commit ----------
    st.theta = theta_new;
    st.P     = P_new;

    % ---------- diagnostics ----------
    status.gain_norm = norm(K, 2);
    % Cheap SPD proxy: min diag of Cholesky if available
    if cholP == 0
        status.min_eig_P = min(diag(Rc)).^2;
    else
        status.min_eig_P = NaN;
    end
end

% ---- local helper ----
function s = make_status(ok, code, msg)
    s.ok   = logical(ok);
    s.code = char(code);
    s.msg  = char(msg);
end
