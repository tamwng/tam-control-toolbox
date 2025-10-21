function [Ty, Tu, sigma_k, meta] = toeplitz(Theta, gamma, y_hist, u_hist, N, ell)
%TOEPLITZ  Build LPV-ARX stacked prediction operators (paper-exact form).
%
%   [Ty, Tu, sigma_k, meta] = toeplitz(Theta, gamma, y_hist, u_hist, N, ell)

% ---------- Basic validation ----------
[p, W] = size(Theta);
if ~(isscalar(N) && N>=1 && N==fix(N)), error('N must be a positive integer.'); end
if ~(isscalar(ell) && ell>=1 && ell==fix(ell)), error('ell must be a positive integer.'); end
if size(y_hist,2) ~= ell, error('y_hist must have ell columns (chronological).'); end
m = size(u_hist,1);
if size(u_hist,2) ~= ell, error('u_hist must have ell columns (chronological).'); end

cols1 = 1 + ell*p + (ell+1)*m;   % d0  = [C | A_1..A_ell | B_0..B_ell]
colsR = cols1 - 1;               % d0-1 = [A_1..A_ell | B_0..B_ell]
if isrow(gamma), gamma = gamma.'; end
qg = length(gamma);  q = qg;

% ---------- Infer C-block layout from Θ width ----------
if W == cols1 + (qg-1)*colsR
    has_const = true;            % C only in block j=1  ("head")
elseif W == qg*colsR
    has_const = false;           % no C anywhere        ("none", e.g., RBF)
elseif W == qg*cols1
    has_const = true;            % C in every block     ("each", discouraged)
    warning('toeplitz:ConstInEveryBlock','Θ has a C-block in every j (layout="each"). Ensure this is intended.');
else
    error('Theta width incompatible with (p,m,ell). W=%d.', W);
end

% ---------- Per-block indexer ----------
if has_const
    cols_per_j_vec = [cols1, repmat(colsR,1,q-1)];   % j=1: d0; j>=2: d0-1
else
    cols_per_j_vec = repmat(colsR,1,q);              % all blocks: d0-1
end
col_start = [0, cumsum(cols_per_j_vec(1:end-1))];
block_j   = @(j) (col_start(j)+1):(col_start(j)+cols_per_j_vec(j));

% ---------- Partition Θ ----------
C_hat = cell(q,1);
A_hat = cell(ell,1);     for i = 1:ell,     A_hat{i}   = cell(q,1); end
B_hat = cell(ell+1,1);   for i = 0:ell,     B_hat{i+1} = cell(q,1); end

for j = 1:q
    J = block_j(j); pos = 1;
    if has_const && j==1
        C_hat{1} = Theta(:, J(pos)); pos = pos + 1;
    else
        C_hat{j} = zeros(p,1);
    end
    for i = 1:ell
        cols = J(pos:(pos+p-1)); pos = pos + p;
        A_hat{i}{j} = Theta(:, cols); % p×p
        if ~isequal(size(A_hat{i}{j}), [p,p]), error('A_{%d}^{(%d)} size error.', i, j); end
    end
    for i = 0:ell
        cols = J(pos:(pos+m-1)); pos = pos + m;
        B_hat{i+1}{j} = Theta(:, cols); % p×m
        if ~isequal(size(B_hat{i+1}{j}), [p,m]), error('B_{%d}^{(%d)} size error.', i, j); end
    end
end

% ---------- Compile LPV coefficients ----------
Ck  = zeros(p,1);
Ak  = cell(ell,1);  for i = 1:ell,  Ak{i}   = zeros(p,p); end
Bk  = cell(ell+1,1);for i = 0:ell,  Bk{i+1} = zeros(p,m); end

for j = 1:q
    gj = gamma(j);
    Ck = Ck + gj * C_hat{j};
    for i = 1:ell, Ak{i}   = Ak{i}   + gj * A_hat{i}{j}; end
    for i = 0:ell, Bk{i+1} = Bk{i+1} + gj * B_hat{i+1}{j}; end
end

% ---------- Build shifts and selectors ----------
S = cell(ell+1,1); F = cell(ell,1);
S{1} = speye(N);
for i = 1:ell
    if i <= N, S{i+1} = spdiags(ones(N-i,1), -i, N, N);
    else,      S{i+1} = sparse(N, N);
    end
    r = min(N, i);
    Fi_top = [speye(r), sparse(r, i-r)];
    F{i}   = [Fi_top; sparse(N-r, i)];
end

% ---------- Assemble T_y and T_u ----------
pN = p*N; mN = m*N;
Ty = sparse(pN, pN);
Tu = sparse(pN, mN);
for i = 1:ell, Ty = Ty + kron(S{i+1}, Ak{i});    end
for i = 0:ell, Tu = Tu + kron(S{i+1}, Bk{i+1});  end

% ---------- Assemble offset σ_k ----------
onesN = ones(N,1);
s_ofs = kron(onesN, Ck);  % (1_N ⊗ C_k); if no-const, Ck≡0
for i = 1:ell
    Yi = stack_recent(y_hist, i);
    s_ofs = s_ofs + kron(F{i}, Ak{i})   * Yi;
end
for i = 1:ell
    Ui = stack_recent(u_hist, i);
    s_ofs = s_ofs + kron(F{i}, Bk{i+1}) * Ui;  % B_{k,i}
end
sigma_k = s_ofs;

% ---------- Diagnostics ----------
meta = struct();
meta.p = p; meta.m = m; meta.q = q; meta.N = N; meta.ell = ell;
meta.has_const = has_const;
meta.Ck = Ck; meta.Ak = Ak; meta.Bk = Bk;
meta.S = S; meta.F = F;
end

% ===== helpers =====
function vec = stack_recent(X, i)
%STACK_RECENT Stack the most recent i columns of X vertically in chronological order.
    if size(X,2) < i
        error('Not enough history: need %d columns, have %d.', i, size(X,2));
    end
    Xi = X(:, end-i+1:end);
    vec = reshape(Xi, [], 1);
end
