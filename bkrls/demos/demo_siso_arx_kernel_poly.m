function demo_siso_arx_kernel_poly()
% DEMO: SISO BK-RLS with polynomial kernel (degree≥1).
% Stability guards: feature normalization (center/scale), ridge, forgetting.

%% -------------------- Config --------------------
cfg = struct();
cfg.p = 1;                 % outputs
cfg.m = 1;                 % inputs
cfg.ell = 2;               % past outputs y_{k-1:k-ell}, inputs u_{k:k-ell}
cfg.T = 300;               % samples
cfg.lambda = 1.0;          % forgetting in (0,1]
cfg.rho = 1e-6;            % ridge: P0 = I / rho
cfg.eps = 1e-12;           % numeric jitter
cfg.seed = 123;            % RNG seed
cfg.noise_std = 1e-3;      % measurement noise (std)
cfg.noise_std = 0.0;       % measurement noise (std)
cfg.degree = 2;            % polynomial degree; set 1 → linear kernel
cfg.cross  = 'pairwise';   % 'none'|'pairwise'|'full' (use 'none' if unstable)
cfg.calib  = 1000;         % calibration samples to estimate center/scale
cfg.clip_z = 1e6;          % optional guard: skip update if ||z|| too large

% True SISO plant with direct feedthrough:
% y_t = a1*y_{t-1} + a2*y_{t-2} + b1*u_{t-1} + d*u_t + v_t
truth = struct('a',[0.6; -0.15], 'b',[0.25], 'd',0.2);

%% -------------------- Signals (PE) --------------------
rng(cfg.seed);
u = prbs_signal(cfg.T, 7, 1.0);         % ±1 PRBS (order 7)
y = zeros(cfg.T,1);
for t = 1:cfg.T
    y1 = 0; y2 = 0; u1 = 0;
    if t-1>=1, y1 = y(t-1); u1 = u(t-1); end
    if t-2>=1, y2 = y(t-2); end
    y(t) = truth.a(1)*y1 + truth.a(2)*y2 + truth.b(1)*u1 + truth.d*u(t) ...
         + cfg.noise_std*randn;
end

%% -------------------- Calibration: center/scale for s_k --------------------
% Goal: keep polynomial features O(1). Compute mean/std of s_k over a burn-in window.
stCal = window('init', cfg.p, cfg.m, cfg.ell);
S = [];  % stack of s_k vectors
for t = 1:min(cfg.calib, cfg.T)
    [stCal, s_k, ready] = window('push', stCal, u(t), y(t));
    if ~ready, continue; end
    svec = [s_k.y(:); s_k.u(:)];   % flatten per our kernel definition
    S(:,end+1) = svec;             %#ok<AGROW>
end
if isempty(S)
    error('Calibration window produced no ready samples. Increase cfg.calib or T.');
end
center = mean(S,2);
scale  = std(S,0,2);
scale(scale==0) = 1;               % avoid division by zero

%% -------------------- Kernel spec --------------------
% degree=1 with cross='none' ≡ linear features g=[1;s]; larger degree adds powers.
spec = struct('type','poly', 'degree',cfg.degree, 'cross',cfg.cross, ...
              'center',center, 'scale',scale);

%% -------------------- RLS loop --------------------
stW = window('init', cfg.p, cfg.m, cfg.ell);
stR = struct('theta', [], 'P', [], 'lambda', cfg.lambda, 'eps', cfg.eps);

theta_log = [];
traceP_log = [];
mse_log = [];
znorm_log = [];

ready_seen = false;
for k = 1:cfg.T
    [stW, s_k, ready] = window('push', stW, u(k), y(k));
    if ~ready, continue; end

    % Build regressor and initialize RLS dims on first ready step
    [phi_k, meta, z_k] = regressor(s_k, spec, cfg.p, cfg.m);
    if ~ready_seen
        stR.theta = zeros(meta.d,1);
        stR.P     = eye(meta.d)/cfg.rho;
        ready_seen = true;
    end

    % Optional magnitude guard on z to avoid numerical blow-up with high-degree polys
    zn = norm(z_k);
    znorm_log(end+1) = zn; %#ok<AGROW>
    if zn > cfg.clip_z
        % Skip update; feature normalization too weak for this sample
        theta_log(:,end+1) = stR.theta; %#ok<AGROW>
        traceP_log(end+1)  = trace(stR.P); %#ok<AGROW>
        mse_log(end+1)     = NaN; %#ok<AGROW>
        continue
    end

    % RLS update
    [stR, ~] = rls_update(stR, phi_k, y(k));

    % Logging
    theta_log(:,end+1) = stR.theta;                      %#ok<AGROW>
    traceP_log(end+1)  = trace(stR.P);                   %#ok<AGROW>
    yhat = phi_k * stR.theta; mse_log(end+1) = (y(k)-yhat)^2; %#ok<AGROW>
end

%% -------------------- Basic readouts --------------------
fprintf('Final trace(P): %.3e\n', traceP_log(end));
fprintf('Median ||z||: %.3e, 99th %% ||z||: %.3e\n', median(znorm_log), prctile(znorm_log,99));

%% -------------------- Plots --------------------
figure('Name','SISO BK-RLS with polynomial kernel');
subplot(2,2,1);
semilogy(movmean(mse_log, 200)); grid on; xlabel('k'); ylabel('MSE (log)');
title('One-step prediction MSE');

subplot(2,2,2);
plot(traceP_log); grid on; xlabel('k'); ylabel('trace(P)'); title('Covariance trace');

subplot(2,2,3);
plot(theta_log.'); grid on; xlabel('k'); ylabel('\theta'); title('\theta trajectory');

subplot(2,2,4);
plot(znorm_log); grid on; xlabel('k'); ylabel('||z_k||'); title('Regressor magnitude monitor');

end

%% ---------- Helper ----------
function u = prbs_signal(T, order, amp)
% Max-length PRBS (LFSR) of given order, scaled to ±amp.
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
