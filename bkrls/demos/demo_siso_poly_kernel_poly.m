function demo_siso_poly_kernel_poly()
% SISO BK-RLS with polynomial kernel: generate data from known θ*, then recover it.

%% Config
p=1; m=1; ell=2; T=500;
lambda=1.0; rho=1e-6; epsn=1e-12; seed=11;
deg=2; cross='none';    % degree=2 polynomial; set 1→linear
noise_std = 0;          % 0 for exact recovery; >0 to test robustness

rng(seed);

%% Persistent excitation input
u = prbs_signal(T,7,1.0);
y = zeros(T,1);

%% Calibrate center/scale on burn-in windows to keep features O(1)
% --- Calibration: compute center/scale from ready windows ---
calib = min(1000,T);
stCal = window('init', p, m, ell);
S = [];
for t = 1:calib
    [stCal, s_k, ready] = window('push', stCal, u(t), y(t));
    if ~ready, continue; end
    S(:,end+1) = [s_k.y(:); s_k.u(:)]; %#ok<AGROW>
end
assert(~isempty(S), 'No ready samples during calibration.');
center = mean(S,2);
scale  = std(S,0,2); scale(scale==0)=1;

%% Kernel spec and a sparse θ* (choose interpretable nonzeros)
spec = struct('type','poly','degree',deg,'cross',cross,...
              'center',center,'scale',scale,'clip',3);

% Build θ* in the lifted space:
% ψ = [1; y_{k-1}; y_{k-2}; u_k; u_{k-1}; u_{k-2}]  (d0=6)
% g (deg=2,cross=none) = [1; s; s.^2] with s length 5 → q=1+5+5 = 11
% z = g ⊗ ψ ⇒ size q*d0 = 11*6; for p=1, θ ∈ R^{66}
d0 = 1 + p*ell + m*(ell+1); % 6
q  = 1 + 5 + 5;             % 11
d  = q*d0;                  % 66
theta_star = zeros(d,1);

% Place a few nonzeros (examples):
% 1) helper: index into θ for block j (1..q) and ψ index k (1..d0)
idx_blk = @(j,k) (j-1)*d0 + k;   % returns a scalar linear index
% g(1)=1 block (linear ARX-ish terms)
theta_star(idx_blk(1,2)) =  0.55;  % y_{k-1}
theta_star(idx_blk(1,3)) = -0.10;  % y_{k-2}
theta_star(idx_blk(1,4)) =  0.20;  % u_k
theta_star(idx_blk(1,5)) =  0.25;  % u_{k-1}

% 2) nonlinear term: (s_1 = y_{k-1} normalized)^2 * u_k
% s entries order here: [y_{k-1}, y_{k-2}, u_k, u_{k-1}, u_{k-2}]
j_s1_sq = 1 + 5 + 1;              % = 7
theta_star(idx_blk(j_s1_sq,4)) = 0.05;  % ψ index 4 = u_k

%% Generate data from θ*
% We use the same kernel+regressor to compute φ_k and simulate y
for t=1:T
    % Build window s_k explicitly
    % safe past values
    if t > 1
        y1 = y(t-1);
        u1 = u(t-1);
    else
        y1 = 0;
        u1 = 0;
    end
    
    if t > 2
        y2 = y(t-2);
        u2 = u(t-2);
    else
        y2 = 0;
        u2 = 0;
    end
    
    uk = u(t);

    s_k = struct('y', [y1 y2], 'u', [uk u1 u2]); % shapes p×ell=1×2, m×(ell+1)=1×3

    % Regressor
    [phi_k, ~, ~] = regressor(s_k, spec, p, m); % size 1×d
    y(t) = phi_k * theta_star + noise_std*randn;
end

%% Identification with RLS
stW = window('init', p, m, ell);
stR = struct('theta', [], 'P', [], 'lambda', lambda, 'eps', epsn);

theta_log = []; mse_log = []; traceP_log = [];
ready_seen = false;
for t=1:T
    [stW, s_k, ready] = window('push', stW, u(t), y(t));
    if ~ready, continue; end
    [phi_k, meta] = regressor(s_k, spec, p, m);
    if ~ready_seen
        stR.theta = zeros(meta.d,1);
        stR.P     = eye(meta.d)/rho;
        ready_seen = true;
    end
    [stR, ~] = rls_update(stR, phi_k, y(t));
    theta_log(:,end+1) = stR.theta;             %#ok<AGROW>
    traceP_log(end+1)  = trace(stR.P);          %#ok<AGROW>
    yhat = phi_k*stR.theta; mse_log(end+1) = (y(t)-yhat)^2; %#ok<AGROW>
end

%% Checks and plots
fprintf('||θ_T - θ*||_2 = %.3e\n', norm(stR.theta - theta_star));
figure('Name','SISO poly ground-truth');
subplot(2,2,1); semilogy(movmean(mse_log,200)); grid on; title('MSE (log)');
subplot(2,2,2); plot(traceP_log); grid on; title('trace(P)');
subplot(2,2,3); plot(theta_log.'); grid on; title('\theta trajectory');
subplot(2,2,4); stem([theta_star, stR.theta]); grid on; title('θ* vs θ_T'); legend('true','id');
end

%% helper
function u = prbs_signal(T, order, amp)
n = 2^order - 1; reg = ones(1, order); taps = [order 1]; seq = zeros(1,n);
for i=1:n, seq(i)=reg(end); fb=mod(sum(reg(taps)),2); reg=[fb reg(1:end-1)]; end
u = repmat(seq,1,ceil(T/n)); u = u(1:T); u = 2*(u-0.5); u = amp*u(:);
end
