%% demo_brlspc_arx_template.m
% Completely reproducible BRLS-PC demo on a simple ARX plant.
% Plant (true system) is ARX. The controller model uses kernel BK-RLS.
% They are separate by design.

clear; clc; close all;

%% -------------------- Config: plant + identification --------------------
cfg = struct();
cfg.p = 1;                 % outputs
cfg.m = 1;                 % inputs
cfg.ell = 2;               % ARX order (history length)
cfg.Twarm = 10;            % warmup steps (open-loop PRBS for ID)
cfg.Tctrl = 50;            % closed-loop control steps
cfg.lambda = 1.0;          % RLS forgetting
cfg.rho = 1e-6;            % RLS ridge (P0 = I/rho)
cfg.eps = 1e-12;           % numeric jitter
cfg.seed = 42;             % RNG seed
cfg.noise_std = 0.0;       % measurement noise (set >0 to test robustness)

% True SISO ARX with direct feedthrough:
% y_t = a1*y_{t-1} + a2*y_{t-2} + b1*u_{t-1} + d*u_t + v_t
plant.a = [0.6; -0.15];
plant.b = [0.25];
plant.d = 0.2;

% BK-RLS kernel model (separate from the plant's ARX):
% choose a non-ARX basis to emphasize separation
spec = struct('type','poly','degree',2);   % alt: struct('type','rbf','sigma',1.0)

% Predictive control horizon and weights
N = 20;
Ru = 1e-2 * speye(cfg.m*N);                % PD input weight
Qy = speye(cfg.p*N);                       % PSD output weight
r_set = 0.0;                               % setpoint
% Reference stack for horizon N (constant setpoint)
R_stack = @(r) kron(ones(N,1), r * ones(cfg.p,1));

rng(cfg.seed);

%% -------------------- Preallocate signals --------------------
T = cfg.Twarm + cfg.Tctrl + 1;             % +1 to allow last-step indexing
u = zeros(T,1);
y = zeros(T,1);

% Warmup PRBS to excite plant and seed RLS
u(1:cfg.Twarm) = prbs_signal(cfg.Twarm, 7, 1.0);

%% -------------------- BK-RLS state --------------------
% Sliding window of past signals s_k = (y_{k-ell:k-1}, u_{k-ell:k})
W = window('init', cfg.p, cfg.m, cfg.ell);
% RLS containers (dimension set on first "ready")
stR = struct('theta', [], 'P', [], 'lambda', cfg.lambda, 'eps', cfg.eps);
ready_seen = false;

%% -------------------- Simulation loop --------------------
for t = 1:(T-1)
    % ----- Plant update (y(t)) from previously applied u(t) -----
    % Safe past access
    y1 = (t-1>=1) * y(max(t-1,1));
    y2 = (t-2>=1) * y(max(t-2,1));
    u1 = (t-1>=1) * u(max(t-1,1));
    u0 = u(t); % already applied
    y(t) = plant.a(1)*y1 + plant.a(2)*y2 + plant.b(1)*u1 + plant.d*u0 ...
           + cfg.noise_std*randn;

    % ----- Update window with current measurement and applied input -----
    [W, s_k, ready, ~] = window('push', W, u(t), y(t));
    if ~ready, continue; end

    % ----- Build regressor and do RLS update -----
    [phi_k, meta] = regressor(s_k, spec, cfg.p, cfg.m);  % φ_k: (p x d)
    if ~ready_seen
        stR.theta = zeros(size(phi_k,2),1);
        stR.P     = eye(size(phi_k,2))/cfg.rho;
        ready_seen = true;
    end
    [stR, ~] = rls_update(stR, phi_k, y(t));

    % ----- After warmup: run BRLS-PC to compute u(t+1) -----
    if t >= cfg.Twarm
        % kernel basis at s_k (frozen over horizon)
        gamma = kernel('eval', spec, s_k);   % q x 1

        % reshape θ → Θ matrix with column order consistent with regressor
        Theta = theta_vec_to_matrix(stR.theta, cfg.p);  % (p x W)

        % y_hist and u_hist for toeplitz at time t: include y_t and u_t
        y_hist = zeros(cfg.p, cfg.ell);
        u_hist = zeros(cfg.m, cfg.ell);
        for i = 1:cfg.ell
            yi = t-(cfg.ell-i);  ui = t-(cfg.ell-i);
            y_hist(:,i) = (yi>=1)*y(max(1,yi));
            u_hist(:,i) = (ui>=1)*u(max(1,ui));
        end

        % Build prediction operators
        [Ty, Tu, sigma_k, ~] = toeplitz(Theta, gamma, y_hist, u_hist, N, cfg.ell);

        % Assemble cost (reference is constant stack here)
        R = R_stack(r_set);
        C = cost_assemble(Ty, Tu, sigma_k, Qy, Ru, R, struct('assert',true,'eps',cfg.eps));

        % Solve and apply first control block → u(t+1)
        Sln = solve_cholesky(C.H, C.h, struct('assert',true,'J0',C.J0));
        u(t+1) = Sln.U(1:cfg.m);
    else
        % During warmup keep PRBS going one step ahead (bounded)
        if t+1 <= cfg.Twarm, u(t+1) = u(t+1); else, u(t+1) = 0; end
    end
end

%% -------------------- Simple plot --------------------
% No styling, minimal – edit as needed.
figure; 
subplot(2,1,1); stairs(y(1:T-1)); ylabel('y'); title('Output');
subplot(2,1,2); stairs(u(1:T-1)); ylabel('u'); xlabel('time');

%% -------------------- Helpers --------------------
function x = prbs_signal(T, order, amp)
% Simple PRBS generator (maximal-length LFSR-based toggling).
    if nargin<3, amp=1; end
    n = max(2, order);
    reg = ones(1,n);
    taps = [n, n-1]; % primitive for small n
    x = zeros(T,1);
    for k=1:T
        fb = mod(sum(reg(taps)),2);
        out = reg(end);
        reg = [fb, reg(1:end-1)];
        x(k) = amp*(2*out-1);
    end
end

function Theta = theta_vec_to_matrix(theta_vec, p)
% Map RLS vector θ to matrix Θ with p rows.
% Column order must match the regressor construction used in your codebase.
% This template assumes φ_k * θ == Θ * z_k with column-major vec.
    d = numel(theta_vec);
    W = d / p;
    if abs(W - round(W)) > 1e-12
        error('theta_vec length not divisible by p.');
    end
    Theta = reshape(theta_vec, p, W);
end
