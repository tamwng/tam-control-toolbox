function demo_mimo_arx_kernel_one()
% DEMO: MIMO ARX identification with BK-RLS (ones-kernel → ARX)
% Template defaults: p=3 outputs, m=2 inputs, ℓ=2, direct feedthrough.
% You can change cfg.* to generalize.

%% -------------------- Config --------------------
cfg = struct();
cfg.p = 3;                 % outputs
cfg.m = 2;                 % inputs
cfg.ell = 2;               % past outputs y_{t-1:t-ℓ}, inputs u_{t:t-ℓ}
cfg.T = 1000;               % samples
cfg.lambda = 0.999;        % forgetting
cfg.rho = 1e-6;            % ridge (P0 = I/rho)
cfg.eps = 1e-12;           % numeric jitter
cfg.seed = 7;              % RNG seed
% cfg.noise_std = 5e-3;      % output noise (per component)
cfg.noise_std = 0.0;       % output noise (per component)

% True MIMO ARX:
% y_t = A1*y_{t-1} + A2*y_{t-2} + D*u_t + B1*u_{t-1} + B2*u_{t-2} + v_t
% Choose stable, lightly coupled dynamics.
A1 = [0.45  0.05  0.00;
      0.00  0.35  0.04;
      0.02  0.00  0.40];
A2 = [-0.10  0.00  0.00;
       0.00 -0.06  0.00;
       0.00  0.01  0.08];
D  = [0.30  0.10;
      0.00  0.20;
      0.15  0.05];
B1 = [0.10  0.00;
      0.05  0.08;
      0.00  0.06];
B2 = zeros(cfg.p, cfg.m);   % included in regressor, but set to zero here

%% -------------------- Persistent excitation --------------------
rng(cfg.seed);
u = [prbs_signal(cfg.T, 9, 1.0), ...   % input 1
     prbs_signal(cfg.T, 7, 1.0)];      % input 2   → T×2
y = zeros(cfg.T, cfg.p);

% Simulate plant with safe indexing (zero before data starts)
for t = 1:cfg.T
    y1 = zeros(cfg.p,1); y2 = zeros(cfg.p,1);
    u0 = u(t,:).'; u1 = zeros(cfg.m,1); u2 = zeros(cfg.m,1);
    if t-1 >= 1, y1 = y(t-1,:).'; u1 = u(t-1,:).'; end
    if t-2 >= 1, y2 = y(t-2,:).'; u2 = u(t-2,:).'; end
    y(t,:)= (A1*y1 + A2*y2 + D*u0 + B1*u1 + B2*u2 + cfg.noise_std*randn(cfg.p,1)).';
end

%% -------------------- BK-RLS setup --------------------
stW = window('init', cfg.p, cfg.m, cfg.ell);   % window manager
spec = struct('type','ones');                  % ARX reduction
stR = struct('theta', [], 'P', [], 'lambda', cfg.lambda, 'eps', cfg.eps);

% Logs
traceP = [];                                   % trace(P_k)
mse = zeros(0, cfg.p);                         % per-output one-step MSE
theta_hist = {};                               % store occasional snapshots

%% -------------------- Online identification --------------------
ready_seen = false;
snap_every = 500;   % snapshot cadence for visual checks

for k = 1:cfg.T
    [stW, s_k, ready, ~] = window('push', stW, u(k,:).', y(k,:).');
    if ~ready, continue; end

    % Initialize RLS dimensions at first ready step
    if ~ready_seen
        [phi0, meta0] = regressor(s_k, spec, cfg.p, cfg.m);
        stR.theta = zeros(meta0.d,1);
        stR.P     = eye(meta0.d)/cfg.rho;
        ready_seen = true;
    else
        [phi0, ~] = regressor(s_k, spec, cfg.p, cfg.m);
    end

    % RLS update
    [stR, ~] = rls_update(stR, phi0, y(k,:).');

    % Logs
    yhat = phi0*stR.theta;
    mse(end+1,:) = (y(k,:).' - yhat).^2;          %#ok<AGROW>
    traceP(end+1,1) = trace(stR.P);               %#ok<AGROW>
    if mod(k, snap_every) == 0
        theta_hist{end+1} = stR.theta;            %#ok<AGROW>
    end
end

%% -------------------- Recover Θ and compare to truth --------------------
% With ones-kernel: Θ ∈ R^{p×d0} where d0 = 1 + pℓ + m(ℓ+1)
d0 = 1 + cfg.p*cfg.ell + cfg.m*(cfg.ell+1);
Theta_hat = reshape(stR.theta, cfg.p, d0);   % column-major inverse of vec

% Build Θ_true to match regressor's ψ order:
% ψ = [1; vec(y_{t-1}); vec(y_{t-2}); vec(u_t); vec(u_{t-1}); vec(u_{t-2})]
Theta_true = zeros(cfg.p, d0);
col = 1;
% bias column
col = col + 1;
% y_{t-1} block: p columns → A1 multiplies that vector
Theta_true(:, col:col+cfg.p-1) = A1;  col = col + cfg.p;
% y_{t-2} block
Theta_true(:, col:col+cfg.p-1) = A2;  col = col + cfg.p;
% u_t block: m columns
Theta_true(:, col:col+cfg.m-1) = D;   col = col + cfg.m;
% u_{t-1} block
Theta_true(:, col:col+cfg.m-1) = B1;  col = col + cfg.m;
% u_{t-2} block
Theta_true(:, col:col+cfg.m-1) = B2;  col = col + cfg.m;

% Blockwise Frobenius errors (useful, compact visual)
blk = blockspec(cfg.p, cfg.m, cfg.ell);
err = struct();
err.A1 = norm(Theta_hat(:, blk.y1) - A1, 'fro');
err.A2 = norm(Theta_hat(:, blk.y2) - A2, 'fro');
err.D  = norm(Theta_hat(:, blk.u0) - D,  'fro');
err.B1 = norm(Theta_hat(:, blk.u1) - B1, 'fro');
err.B2 = norm(Theta_hat(:, blk.u2) - B2, 'fro');

fprintf('Block Frobenius errors:\n');
fprintf('  ||A1_hat - A1||_F = %.3e\n', err.A1);
fprintf('  ||A2_hat - A2||_F = %.3e\n', err.A2);
fprintf('  ||D_hat  - D ||_F = %.3e\n', err.D);
fprintf('  ||B1_hat - B1||_F = %.3e\n', err.B1);
fprintf('  ||B2_hat - B2||_F = %.3e\n', err.B2);

%% -------------------- Visualization --------------------

% Unpacked block-wise Θ into "hat | true | error"
[A1h,A2h,Dh,B1h,B2h] = unpack_theta_blocks(Theta_hat, cfg.p, cfg.m, cfg.ell);

figure('Name','Block-wise Θ: hat | true | error');
tiledlayout(5,3,'Padding','compact','TileSpacing','compact');

blocks = {A1h,A1,'A1'; A2h,A2,'A2'; Dh,D,'D'; B1h,B1,'B1'; B2h,B2,'B2'};
for i = 1:size(blocks,1)
    H = blocks{i,1}; T = blocks{i,2}; name = blocks{i,3};
    nexttile; imagesc(H); colorbar; axis image; title([name,' hat']);
    nexttile; imagesc(T); colorbar; axis image; title([name,' true']);
    nexttile; imagesc(H-T); colorbar; axis image; title([name,' error']);
end

figure('Name','MIMO ARX BK-RLS');
% 1) Per-output MSE (log scale) with moving mean
subplot(2,2,1);
mm = movmean(mse, 200, 1);
semilogy(mm); grid on; xlabel('k'); ylabel('MSE (log)');
legend(arrayfun(@(i) sprintf('y_%d',i), 1:cfg.p, 'UniformOutput', false));
title('One-step prediction MSE per output');

% 2) Covariance trace
subplot(2,2,2);
plot(traceP); grid on; xlabel('k'); ylabel('trace(P)'); title('Covariance trace');

% 3) Trajectories of block errors at snapshot times (uses theta_hist)
if ~isempty(theta_hist)
    d0 = 1 + cfg.p*cfg.ell + cfg.m*(cfg.ell+1);
    E = zeros(numel(theta_hist),5);
    for j = 1:numel(theta_hist)
        Theta_j = reshape(theta_hist{j}, cfg.p, d0);
        E(j,1) = norm(Theta_j(:, blk.y1) - A1, 'fro');
        E(j,2) = norm(Theta_j(:, blk.y2) - A2, 'fro');
        E(j,3) = norm(Theta_j(:, blk.u0) - D,  'fro');
        E(j,4) = norm(Theta_j(:, blk.u1) - B1, 'fro');
        E(j,5) = norm(Theta_j(:, blk.u2) - B2, 'fro');
    end
    subplot(2,2,3);
    semilogy(E); grid on;
    xlabel('snapshot # (× snap\_every)'); ylabel('||·||_F');
    legend('A1','A2','D','B1','B2','Location','best');
    title('Convergence of block errors');
end

% 3) Block Frobenius errors (bar, log scale)
subplot(2,2,4);
errs = [err.A1, err.A2, err.D, err.B1, err.B2];
bar(errs);
set(gca,'YScale','log');
set(gca,'XTickLabel',{'A1','A2','D','B1','B2'});
ylabel('||·||_F'); title('Block Frobenius errors');
grid on;

end

%% -------- Helpers --------

function u = prbs_signal(T, order, amp)
% Max-length PRBS of given order, scaled to ±amp.
n = 2^order - 1;
reg = ones(1, order); taps = [order 1]; % simple taps
seq = zeros(1,n);
for i=1:n
    seq(i) = reg(end);
    fb = mod(sum(reg(taps)),2);
    reg = [fb reg(1:end-1)];
end
u = repmat(seq, 1, ceil(T/n)); u = u(1:T);
u = 2*(u-0.5); u = amp*u(:);
end

function blk = blockspec(p,m,ell)
% Column indices for each block of Θ aligned with ψ order.
% ψ = [1; vec(y_{t-1}); vec(y_{t-2}); vec(u_t); vec(u_{t-1}); vec(u_{t-2})]
d0 = 1 + p*ell + m*(ell+1);
col = 1;
blk.bias = col; col = col+1;
blk.y1 = col:(col+p-1); col = col+p;
blk.y2 = col:(col+p-1); col = col+p;
blk.u0 = col:(col+m-1); col = col+m;
blk.u1 = col:(col+m-1); col = col+m;
blk.u2 = col:(col+m-1); col = col+m;
assert(col-1 == d0);
end

function labs = theta_labels(p,m,ell)
% Text labels for Θ columns (bias, y-blocks, u-blocks)
labs = cell(1, 1 + p*ell + m*(ell+1));
idx = 1; labs{idx} = '1'; idx=idx+1;
for j=1:ell, for i=1:p, labs{idx} = sprintf('y_{t-%d}(%d)', j, i); idx=idx+1; end, end
labs{idx}='u_t(1)'; idx=idx+1; for i=2:m, labs{idx}=sprintf('u_t(%d)',i); idx=idx+1; end
for j=1:ell
    for i=1:m, labs{idx}=sprintf('u_{t-%d}(%d)', j, i); idx=idx+1; end
end
end

function draw_block_separators(p,m,ell)
% Vertical lines separating Θ blocks.
blk = blockspec(p,m,ell);
xs = [blk.bias, blk.y1(end), blk.y2(end), blk.u0(end), blk.u1(end), blk.u2(end)] + 0.5;
yl = ylim;
for x = xs, xline(x, ':', 'Color', [0 0 0]); end
ylim(yl);
end

function [A1h,A2h,Dh,B1h,B2h] = unpack_theta_blocks(Theta_hat,p,m,ell)
% Columns follow ψ = [1 | vec(y_{t-1}) | vec(y_{t-2}) | vec(u_t) | vec(u_{t-1}) | vec(u_{t-2})]
d0 = 1 + p*ell + m*(ell+1);
assert(size(Theta_hat,2)==d0);
col = 1;          % bias
col = col + 1;
A1h = Theta_hat(:, col:col+p-1); col = col+p;
A2h = Theta_hat(:, col:col+p-1); col = col+p;
Dh  = Theta_hat(:, col:col+m-1); col = col+m;
B1h = Theta_hat(:, col:col+m-1); col = col+m;
B2h = Theta_hat(:, col:col+m-1);
end
