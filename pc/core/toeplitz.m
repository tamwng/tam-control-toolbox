function [Ty, Tu, sigma_k, meta] = toeplitz(Theta, gamma, y_hist, u_hist, N, ell)
%TOEPLITZ  Build LPV-ARX stacked prediction operators (paper-exact form).
%
%   [Ty, Tu, sigma_k, meta] = toeplitz(Theta, gamma, y_hist, u_hist, N, ell)
%
%Inputs
%   Theta : (p x W) parameter matrix at step k+1, horizontally concatenated as
%           [ C^(1) ... C^(q) | A_1^(1) ... A_1^(q) | ... | A_ell^(1) ... A_ell^(q) | ... | B_0^(1) ... B_ell^(q) ]
%           where C^(j)∈R^{p×1}, A_i^(j)∈R^{p×p}, B_i^(j)∈R^{p×m}.
%   gamma : (q x 1) kernel basis evaluations γ_j(s_k), frozen over the horizon.
%   y_hist: (p x ell) past outputs in chronological order [y_{k-ell+1}, ..., y_k].
%   u_hist: (m x ell) past inputs  in chronological order [u_{k-ell+1}, ..., u_k].
%   N     : prediction horizon (integer ≥ 1).
%   ell   : ARX lag/order (integer ≥ 1).
%
%Outputs
%   Ty      : (pN x pN) strictly block lower-triangular matrix \sum_{i=1}^ell S_i ⊗ A_{k,i}.
%   Tu      : (pN x mN) block lower-triangular matrix \sum_{i=0}^ell S_i ⊗ B_{k,i}.
%   sigma_k : (pN x 1) offset vector (\mathbf{1}_N ⊗ C_k) + Σ (F_i ⊗ A_{k,i})Y_init^{(i)} + Σ (F_i ⊗ B_{k,i})U_init^{(i)}.
%   meta    : struct with fields p,m,q,Ck,Ak,Bk,S,F for diagnostics (lightweight where possible).
%
%Notes
% - This function implements the paper equations verbatim:
%     T_y     = Σ_{i=1}^ell S_i ⊗ A_{k,i},  T_u = Σ_{i=0}^ell S_i ⊗ B_{k,i},
%     sigma_k = (1_N ⊗ C_k) + Σ (F_i ⊗ A_{k,i})Y_init^{(i)} + Σ (F_i ⊗ B_{k,i})U_init^{(i)}.
%   It does not form (I - T_y)^{-1}. Forward solves can be done by callers.
% - y_hist, u_hist must cover exactly ell past samples up to time k (inclusive for u, y).
% - All large Kronecker matrices are built as sparse for efficiency.
%
%Copyright
%   BSD-3-Clause. Intended for clarity and reuse.

% ---------- Basic validation ----------
[p, W] = size(Theta);
if ~(isscalar(N) && N>=1 && N==fix(N)), error('N must be a positive integer.'); end
if ~(isscalar(ell) && ell>=1 && ell==fix(ell)), error('ell must be a positive integer.'); end
if size(y_hist,2) ~= ell, error('y_hist must have ell columns (chronological).'); end
m = size(u_hist,1);
if size(u_hist,2) ~= ell, error('u_hist must have ell columns (chronological).'); end

% Infer q from Theta width and dimensions
cols_per_j = 1 + ell*p + (ell+1)*m; % C:1, A:ell blocks of p, B:(ell+1) blocks of m
q = W / cols_per_j;
if q ~= fix(q) || q < 1
    error('Theta width incompatible with (p,m,ell). Got W=%d, expected multiple of %d.', W, cols_per_j);
end
if isrow(gamma), gamma = gamma.'; end
if length(gamma) ~= q
    error('gamma length mismatch: got %d, expected q=%d.', length(gamma), q);
end

% ---------- Partition Theta into basis blocks ----------
C_hat = cell(q,1);                 % each p×1
A_hat = cell(ell,1);  % each cell: {q blocks of p×p}
B_hat = cell(ell+1,1);% each cell: {q blocks of p×m}
for i = 1:ell,     A_hat{i} = cell(q,1); end
for i = 0:ell,     B_hat{i+1} = cell(q,1); end

for j = 1:q
    base = (j-1)*cols_per_j + 1;
    t = base;
    % C^(j) : p×1
    C_hat{j} = Theta(:, t); t = t + 1;
    % A_i^(j) : p×p for i=1..ell
    for i = 1:ell
        cols = t:(t+p-1);
        A_hat{i}{j} = Theta(:, cols); % p×p
        t = t + p;
    end
    % B_i^(j) : p×m for i=0..ell
    for i = 0:ell
        cols = t:(t+m-1);
        B_hat{i+1}{j} = Theta(:, cols); % p×m
        t = t + m;
    end
end

% ---------- Compile LPV coefficients at step k ----------
Ck  = zeros(p,1);
Ak  = cell(ell,1);
Bk  = cell(ell+1,1);
for i = 1:ell,  Ak{i}   = zeros(p,p); end
for i = 0:ell,  Bk{i+1} = zeros(p,m); end

for j = 1:q
    gj = gamma(j);
    Ck = Ck + gj * C_hat{j};
    for i = 1:ell
        Ak{i} = Ak{i} + gj * A_hat{i}{j};
    end
    for i = 0:ell
        Bk{i+1} = Bk{i+1} + gj * B_hat{i+1}{j};
    end
end

% ---------- Build shift S_i and selector F_i ----------
S = cell(ell+1,1); F = cell(ell,1);
S{1} = speye(N);
for i = 1:ell
    % Shift S_i: zero if i>N
    if i <= N
        S{i+1} = spdiags(ones(N-i,1), -i, N, N);
    else
        S{i+1} = sparse(N, N);
    end
    % Selector F_i ∈ R^{N×i}: picks first i rows; when i>N, use [I_N 0]
    r = min(N, i);
    Fi_top = [speye(r), sparse(r, i-r)];
    F{i}   = [Fi_top; sparse(N-r, i)];
end


% ---------- Assemble T_y and T_u ----------
pN = p*N; mN = m*N;
Ty = sparse(pN, pN);
Tu = sparse(pN, mN);
for i = 1:ell
    Ty = Ty + kron(S{i+1}, Ak{i}); % i≥1 → S_{i}
end
for i = 0:ell
    Tu = Tu + kron(S{i+1}, Bk{i+1}); % i=0..ell → S_{i}
end

% ---------- Assemble offset sigma_k ----------
% Y_init^{(i)} = [ y_{k+1-i}; ... ; y_k ]  ∈ R^{pi}
% U_init^{(i)} = [ u_{k+1-i}; ... ; u_k ]  ∈ R^{mi}
onesN = ones(N,1);
s_ofs = kron(onesN, Ck); % (1_N ⊗ C_k)

% Past outputs terms
for i = 1:ell
    Yi = stack_recent(y_hist, i);      % (p*i)×1
    s_ofs = s_ofs + kron(F{i}, Ak{i}) * Yi;
end
% Past inputs terms (exclude i=0 per paper; i=0 is direct feedthrough handled in Tu)
for i = 1:ell
    Ui = stack_recent(u_hist, i);      % (m*i)×1
    s_ofs = s_ofs + kron(F{i}, Bk{i+1}) * Ui; % note index: B_{k,i}
end

% Output naming aligned with paper
sigma_k = s_ofs;

% ---------- Diagnostics meta ----------
meta = struct();
meta.p = p; meta.m = m; meta.q = q; meta.N = N; meta.ell = ell;
meta.Ck = Ck; meta.Ak = Ak; meta.Bk = Bk;
meta.S = S;  meta.F = F; %#ok<STRNU>

% ---------- Sanity checks ----------
% Strict block lower-triangular for Ty (zero diagonal blocks)
blkdiag_Ty = zeros(p, p);
for b = 1:N
    rows = (b-1)*p + (1:p);
    cols = (b-1)*p + (1:p);
    blkdiag_Ty = blkdiag_Ty + full(Ty(rows, cols));
end
if norm(blkdiag_Ty, 'fro') > 1e-12
    warning('toeplitz:TyDiagNonzero', 'Ty has nonzero diagonal blocks above tolerance.');
end

end % function toeplitz

% ===== helpers =====
function vec = stack_recent(X, i)
%STACK_RECENT Stack the most recent i columns of X vertically in chronological order.
%   X: r×L with columns [x_{k-L+1}, ..., x_k]. Returns [x_{k+1-i}; ... ; x_k].
    if size(X,2) < i
        error('Not enough history: need %d columns, have %d.', i, size(X,2));
    end
    Xi = X(:, end-i+1:end);     % r×i, chronological
    vec = reshape(Xi, [], 1);   % (r*i)×1, column-stacked
end
