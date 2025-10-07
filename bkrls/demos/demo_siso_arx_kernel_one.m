function demo_siso_arx()
% DEMO: SISO ARX identification with BK-RLS
% - Known ARX orders and direct feedthrough
% - PRBS input (PE)
% - Numerical convergence check + plots

%% -------------------- Config --------------------
cfg = struct();
cfg.p = 1;                 % outputs
cfg.m = 1;                 % inputs
cfg.ell = 2;               % past outputs y_{k-1:k-ell}, past+current inputs u_{k:k-ell}
cfg.T = 1000;              % total samples
cfg.lambda = 0.999;        % forgetting factor
cfg.rho = 1e-4;            % ridge (P0 = I/rho)
cfg.eps = 1e-12;           % numeric jitter
cfg.seed = 123;            % RNG seed for reproducibility
% cfg.noise_std = 1e-3;      % measurement noise
cfg.noise_std = 0.0;       % measurement noise

% True SISO ARX with direct feedthrough:
% y_t = a1*y_{t-1} + a2*y_{t-2} + b1*u_{t-1} + d*u_t + v_t
true_coeff.a = [0.6; -0.15];     % a1,a2
true_coeff.b = [0.25];           % b1
true_coeff.d = 0.2;              % direct term

%% -------------------- Signals (PE) --------------------
rng(cfg.seed);
u = prbs_signal(cfg.T, 7, 1.0);      % ±1 PRBS (order 7)
y = zeros(cfg.T,1);

for t = 1:cfg.T
    % Retrieve past values safely (zero before data start)
    y1 = 0; y2 = 0; u1 = 0;
    if t-1 >= 1
        y1 = y(t-1);
        u1 = u(t-1);
    end
    if t-2 >= 1
        y2 = y(t-2);
    end
    u0 = u(t);

    % true ARX dynamics
    y(t) = true_coeff.a(1)*y1 + true_coeff.a(2)*y2 + true_coeff.b(1)*u1 + true_coeff.d*u0 ...
         + cfg.noise_std*randn;
end

%% -------------------- BK-RLS objects --------------------
% window: builds s_k = (y_{k-ell:k-1}, u_{k-ell:k})
stW = window('init', cfg.p, cfg.m, cfg.ell);

% kernel: ones → ARX reduction
spec = struct('type','ones');

% RLS state; dimension set after first ready regressor
stR = struct('theta', [], 'P', [], 'lambda', cfg.lambda, 'eps', cfg.eps);

%% -------------------- Online loop --------------------
theta_log = [];          % parameter trajectory
traceP_log = [];         % trace(P) trajectory
mse_log = [];            % one-step squared error

ready_seen = false;      % ensure logical scalar
for k = 1:cfg.T
    [stW, s_k, ready, ~] = window('push', stW, u(k), y(k));
    if ~ready, continue; end

    % first ready → initialize RLS dimensions
    if ~ready_seen
        [phi0, meta0] = regressor(s_k, spec, cfg.p, cfg.m);
        stR.theta = zeros(meta0.d,1);
        stR.P     = eye(meta0.d)/cfg.rho;
        ready_seen = true;
    else
        [phi0, ~] = regressor(s_k, spec, cfg.p, cfg.m);
    end

    % RLS update
    [stR, ~] = rls_update(stR, phi0, y(k));

    % logging
    theta_log(:,end+1) = stR.theta;                           %#ok<AGROW>
    traceP_log(end+1)  = trace(stR.P);                        %#ok<AGROW>
    yhat = phi0*stR.theta;  mse_log(end+1) = (y(k)-yhat)^2;   %#ok<AGROW>
end

%% -------------------- Numerical convergence check --------------------
% Map θ to interpretable ARX parameters:
% ψ = [1; y_{t-1}; y_{t-2}; u_t; u_{t-1}; u_{t-2}] for p=1,m=1,ell=2 → length d0 = 1+2+3 = 6
% With ones-kernel, Θ is 1×6. We expect nonzero entries only at positions:
%   y_{t-1} → a1 at index 2
%   y_{t-2} → a2 at index 3
%   u_t     → d  at index 4
%   u_{t-1} → b1 at index 5
% Other entries should be ~0.
idx = struct('bias',1,'a1',2,'a2',3,'d',4,'b1',5,'u2',6);
theta_hat = theta_log(:,end);

est = struct();
est.a1 = theta_hat(idx.a1);
est.a2 = theta_hat(idx.a2);
est.d  = theta_hat(idx.d);
est.b1 = theta_hat(idx.b1);

num_rel_err = @(x,xt) abs(x-xt)/max(1,abs(xt));
rel = struct();
rel.a1 = num_rel_err(est.a1, true_coeff.a(1));
rel.a2 = num_rel_err(est.a2, true_coeff.a(2));
rel.d  = num_rel_err(est.d,  true_coeff.d);
rel.b1 = num_rel_err(est.b1, true_coeff.b(1));

fprintf('Final parameter estimates:\n');
fprintf('  a1: %.6f  (true %.6f)  rel.err=%.3e\n', est.a1, true_coeff.a(1), rel.a1);
fprintf('  a2: %.6f  (true %.6f)  rel.err=%.3e\n', est.a2, true_coeff.a(2), rel.a2);
fprintf('   d: %.6f  (true %.6f)  rel.err=%.3e\n', est.d,  true_coeff.d,   rel.d);
fprintf('  b1: %.6f  (true %.6f)  rel.err=%.3e\n', est.b1, true_coeff.b(1), rel.b1);

%% -------------------- Plots --------------------
figure('Name','SISO ARX BK-RLS');
t = (1:numel(traceP_log));
subplot(2,2,1);
semilogy(movmean(mse_log,200)); grid on
xlabel('k'); ylabel('MSE (log)');
title('One-step prediction MSE');

subplot(2,2,2);
stairs(traceP_log); grid on; xlabel('k'); ylabel('trace(P)');
title('Covariance trace');

subplot(2,2,3);
stairs(theta_log(idx.a1,:)); hold on; stairs(theta_log(idx.a2,:));
stairs(theta_log(idx.d,:));  stairs(theta_log(idx.b1,:)); grid on;
legend('a1','a2','d','b1'); xlabel('k'); ylabel('\theta');
title('\theta convergence');

subplot(2,2,4);
stem([1 2 3 4 5 6], theta_hat, 'filled'); grid on;
xticks(1:6); xticklabels({'1','y_{t-1}','y_{t-2}','u_t','u_{t-1}','u_{t-2}'});
ylabel('\theta (final)'); title('Final parameter vector (expect zeros at 1 and u_{t-2})');

end

%% ---------- Helper ----------
function u = prbs_signal(T, order, amp)
% Max-length PRBS (LFSR) of given order, scaled to ±amp
n = 2^order - 1;
reg = ones(1, order); taps = [order 1]; % simple taps for demo
seq = zeros(1,n);
for i=1:n
    seq(i) = reg(end);
    fb = mod(sum(reg(taps)),2);
    reg = [fb reg(1:end-1)];
end
u = repmat(seq, 1, ceil(T/n)); u = u(1:T);
u = 2*(u-0.5); u = amp*u(:);
end
