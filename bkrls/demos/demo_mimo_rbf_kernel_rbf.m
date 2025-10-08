function demo_mimo_rbf_kernel_rbf()
% DEMO: MIMO BK-RLS with RBF kernel for BOTH ground-truth generation and identification.
% - True system: p=3 outputs, m=2 inputs, ℓ=2 lags, LPV via RBF(s_k)
% - ID system:   same dimensions and same RBF dictionary (centers, sigma)
% You can swap the kernel spec on either side to study mismatch.

%% -------------------- Config --------------------
cfg = struct();
cfg.p = 3;                 % outputs
cfg.m = 2;                 % inputs
cfg.ell = 2;               % past outputs y_{t-1:t-ℓ}, inputs u_{t:t-ℓ}
cfg.T = 800;               % samples
cfg.lambda = 1.0;          % forgetting (1.0 → batch-equivalence)
cfg.rho = 1e-6;            % ridge (P0 = I/rho)
cfg.eps = 1e-12;           % numeric jitter
cfg.seed = 21;             % RNG seed
cfg.noise_std = 0.0;       % output noise; set >0 for robustness tests

% RBF dictionary
cfg.q = 12;                % number of RBF centers
cfg.sigma = 3.0;           % bandwidth (scalar). Increase if features are too spiky.

% Notes:
% - We keep RBF in RAW s-space (center=zeros, scale=ones) for simplicity.
% - RBF outputs are in (0,1], so no polynomial blow-ups.

rng(cfg.seed);

%% -------------------- Derived sizes --------------------
p = cfg.p; m = cfg.m; ell = cfg.ell;
d0 = 1 + p*ell + m*(ell+1);    % ψ length
d_flat = p*ell + m*(ell+1);    % |s| = |vec(y_{t-1:ℓ})| + |vec(u_{t:ℓ})|
d = p * cfg.q * d0;            % θ length

%% -------------------- Shared RBF kernel spec --------------------
% centers in raw s-space (size: q×d_flat)
C = randn(cfg.q, d_flat);      % deterministic with seed
spec_true = struct('type','rbf', 'centers',C, 'sigma',cfg.sigma);
spec_id   = spec_true;         % SAME dictionary for identifiability

%% -------------------- Build ground-truth Θ (structured but small) --------------------
% Θ_true is p×(q*d0). For each RBF j, we fill a p×d0 block:
% [bias (p×1) | A1_j (p×p) | A2_j (p×p) | D_j (p×m) | B1_j (p×m) | B2_j (p×m)]
Theta_true = zeros(p, cfg.q*d0);
scaleA = 0.30; scaleD = 0.20; scaleB = 0.10;  % keep stable magnitudes

for j = 1:cfg.q
    % Lightly coupled, stable-ish local dynamics at center j
    A1 = tril(0.05*randn(p), -1) + diag(0.35 + 0.05*rand(p,1));  % dominant diagonal
    A2 = 0.08*diag(2*rand(p,1)-1);                                % small second lag
    D  = 0.15*randn(p,m);                                         % direct feedthrough
    B1 = 0.08*randn(p,m);  B2 = 0.00*randn(p,m);                  % small input lags

    A1 = scaleA*A1; A2 = scaleA*A2; D = scaleD*D; B1 = scaleB*B1; B2 = scaleB*B2;

    % Pack into Θ_true(:, block j)
    cols = block_cols(j, p, m, ell);   % column indices for block j within Θ
    col = cols.start;
    % bias
    Theta_true(:, col) = 0;  col = col + 1;
    % y_{t-1} (p cols), y_{t-2} (p cols)
    Theta_true(:, col:col+p-1) = A1;   col = col + p;
    Theta_true(:, col:col+p-1) = A2;   col = col + p;
    % u_t (m cols), u_{t-1} (m cols), u_{t-2} (m cols)
    Theta_true(:, col:col+m-1) = D;    col = col + m;
    Theta_true(:, col:col+m-1) = B1;   col = col + m;
    Theta_true(:, col:col+m-1) = B2;   % col = col + m;
end

theta_star = Theta_true(:);  % vec(Θ_true) ∈ R^{d}

%% -------------------- Signals (PE inputs) --------------------
u = [prbs_signal(cfg.T, 9, 1.0), ...   % input 1
     prbs_signal(cfg.T, 7, 1.0)];      % input 2   → T×2
y = zeros(cfg.T, p);

%% -------------------- Simulate ground-truth system --------------------
% We simulate y(t) = φ_true(s_k) * θ_star + v(t).
% s_k uses (y_{t-1:t-ℓ}, u_{t:t-ℓ}). We form s_k from window state BEFORE
% committing y(t), then commit y(t) at the end of the step.

stSim = window('init', p, m, ell);   % window for simulation only

for t = 1:cfg.T
    % Build window from histories; replace NaN/Inf with zeros for early steps
    s_k = struct();
    s_k.y = stSim.y_hist;                          % p×ell: [y_{t-1}, y_{t-2}]
    s_k.u = [u(t,:).', stSim.u_hist(:,1:ell)];     % m×(ell+1): [u_t, u_{t-1}, u_{t-2}]
    s_k.y(~isfinite(s_k.y)) = 0;
    s_k.u(~isfinite(s_k.u)) = 0;

    % True regressor and output
    [phi_true] = regressor(s_k, spec_true, p, m);  %  p×(p*q*d0)
    y_t = (phi_true * theta_star) + cfg.noise_std*randn(p,1);
    y(t,:) = y_t.';                                 % store row

    % Commit current sample into sim-window (alignment: u_t, then y_t)
    [stSim, ~, ~] = window('push', stSim, u(t,:).', y_t);
end

%% -------------------- Identification (same dictionary) --------------------
stW = window('init', p, m, ell);
stR = struct('theta', [], 'P', [], 'lambda', cfg.lambda, 'eps', cfg.eps);

traceP = [];
mse = zeros(0, p);

ready_seen = false;
for t = 1:cfg.T
    [stW, s_k, ready, ~] = window('push', stW, u(t,:).', y(t,:).');
    if ~ready, continue; end

    [phi_k, meta] = regressor(s_k, spec_id, p, m);
    if ~ready_seen
        stR.theta = zeros(meta.d,1);
        stR.P     = eye(meta.d)/cfg.rho;
        ready_seen = true;
    end

    [stR, ~] = rls_update(stR, phi_k, y(t,:).');
    yhat = phi_k * stR.theta;

    mse(end+1,:)  = (y(t,:).' - yhat).^2;   %#ok<AGROW>
    traceP(end+1) = trace(stR.P);           %#ok<AGROW>
end

%% -------------------- Diagnostics --------------------
Theta_hat = reshape(stR.theta, p, cfg.q*d0);
param_err = norm(Theta_hat - Theta_true, 'fro') / max(1, norm(Theta_true,'fro'));

% Block-wise errors per RBF
Eblk = zeros(cfg.q,1);
for j=1:cfg.q
    cols = block_cols(j,p,m,ell);
    Eblk(j) = norm(Theta_hat(:, cols.start:cols.stop) - ...
                   Theta_true(:, cols.start:cols.stop), 'fro');
end

fprintf('Final trace(P): %.3e\n', traceP(end));
fprintf('Relative parameter Frobenius error: %.3e\n', param_err);

%% -------------------- Plots --------------------
figure('Name','MIMO RBF BK-RLS');

% 1) Per-output MSE (log scale, moving mean)
subplot(2,2,1);
mm = movmean(mse, 200, 1);
semilogy(mm); grid on; xlabel('k'); ylabel('MSE (log)');
legend(arrayfun(@(i) sprintf('y_%d',i), 1:p, 'UniformOutput', false));
title('One-step prediction MSE per output');

% 2) Covariance trace
subplot(2,2,2);
plot(traceP); grid on; xlabel('k'); ylabel('trace(P)');
title('Covariance trace');

% 3) Parameter error per RBF block
subplot(2,2,3);
stem(Eblk, 'filled'); grid on;
xlabel('RBF block j'); ylabel('||Θ̂_j - Θ_j||_F');
title('Block-wise Frobenius errors');

% 4) Global parameter comparison (optional: heavy)
subplot(2,2,4);
plot(Theta_hat(:), '.', 'DisplayName','hat'); hold on;
plot(Theta_true(:), '.', 'DisplayName','true'); grid on;
legend; title('Θ entries: hat vs true (scatter by index)');
xlabel('index'); ylabel('value');

end

%% -------------------- Helpers --------------------

function cols = block_cols(j, p, m, ell)
% Column range [start:stop] for kernel block j in Θ (p×(q*d0)).
% Within each block: [1 | p | p | m | m | m] columns for [bias | y1 | y2 | u0 | u1 | u2]
d0 = 1 + p*ell + m*(ell+1);
cols.start = (j-1)*d0 + 1;
cols.stop  = j*d0;
end

function u = prbs_signal(T, order, amp)
% Max-length PRBS of given order, scaled to ±amp. Returns T×1.
n = 2^order - 1;
reg = ones(1, order); taps = [order 1];
seq = zeros(1,n);
for i=1:n
    seq(i) = reg(end);
    fb = mod(sum(reg(taps)),2);
    reg = [fb reg(1:end-1)];
end
u = repmat(seq, 1, ceil(T/n)); u = u(1:T);
u = 2*(u-0.5); u = amp*u(:);
end
