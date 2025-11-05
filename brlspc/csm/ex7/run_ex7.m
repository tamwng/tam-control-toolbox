function run_ex7(spec, seed, outdir)

if nargin < 1, spec = struct('type','ones'); end
if nargin < 2, seed = 42; end
if nargin < 3, outdir = 'results'; end
if ~exist(outdir,'dir'), mkdir(outdir); end

%% -------------------- Config (agreed spec) --------------------
cfg = struct();
% cfg.p = 7;                                          % outputs
cfg.p = 6;                                          % outputs
cfg.m = 3;                                          % inputs
cfg.ell = 1;                                        % known lag (regressor length)
cfg.N_total = 400;                                  % total simulation length (can adjust ad hoc)
cfg.Twarm = 100;                                      % warm-up to fill window (no long Phase I)
cfg.lambda = 1.0;                                   % no forgetting (time-invariant, noise-free)
cfg.ridge  = 1e-9;                                  % small ridge for numerical stability
cfg.eps    = 1e-12;                                 % numeric jitter
cfg.seed   = seed;
cfg.noise_std = 0.0;                                % noise-free baseline
cfg.d_flat = cfg.p*cfg.ell + cfg.m*(cfg.ell+1);     % |s| = |vec(y_{t-1:ℓ})| + |vec(u_{t:ℓ})|

%% -------------------- Plant (ground truth) --------------------
plant = struct( ...
    'J', diag([0.5 1.5 1]), ...    % inertia matrix (3x3 SPD)
    'Ts', 0.05, ...               % sampling period [s]
    'renorm', true, ...           % re-normalize quaternion each step
    'g', [0; 0; 0], ...           % optional: gravity in body/world frame (unused now)
    'disturb', [0; 0; 0] ...      % optional: external disturbance torque
);

% Horizon and weights (single horizon: N_c = N)
N = 30;
rho = 1e-2;                         % differential-u penalty; keep small to avoid SSE
Qy = speye(cfg.p * N);              % unit tracking weight
Ru = rho * speye(cfg.m * N);        % small effort weight

T = cfg.N_total;

eul1 = [0 0 0];                        % initial
eul2 = [30 0 0] * pi/180;              % step 1: roll 30 deg
eul3 = [30 20 0] * pi/180;             % step 2: pitch 20 deg
eul4 = [30 20 45] * pi/180;            % step 3: yaw 45 deg

q1 = eul2quat(eul1, 'ZYX').';  % column 4x1
q2 = eul2quat(eul2, 'ZYX').';
q3 = eul2quat(eul3, 'ZYX').';
q4 = eul2quat(eul4, 'ZYX').';

q1 = q1 / norm(q1);
q2 = q2 / norm(q2);
q3 = q3 / norm(q3);
q4 = q4 / norm(q4);

qd                                                  = kron(ones(T,1), q1.');
% qd((cfg.Twarm+1):(cfg.Twarm+segment),:)             = kron(ones(segment,1), q2.');
% qd((cfg.Twarm+segment+1):(cfg.Twarm+2*segment),:)   = kron(ones(segment,1), q3.');
% qd((cfg.Twarm+2*segment+1):(cfg.Twarm+3*segment),:) = kron(ones(segment,1), q4.');

% Smooth trajectory
% A_deg = [3, 2, 1.75];
% f_hz = 0.05;
% qd = make_qd_sinusoid(T, plant.Ts, A_deg, f_hz);

% r = [qd, zeros(size(qd,1), 3)];
r = zeros(T, cfg.p);

% Dither (APRBS): higher during warm-up, smaller thereafter
dither.phase1_amp = 0.1;
dither.phase2_amp = 0.05;
dither.dwell_min  = 5;
dither.dwell_max  = 15;

% RBF config
if (strcmpi(spec.type,'rbf'))
    spec.centers = randn(spec.q, cfg.d_flat);      % deterministic with seed
end

rng(cfg.seed);

%% -------------------- Preallocate --------------------
tau = zeros(T,cfg.m);   % applied input
y = zeros(T,cfg.p);   % output
p = aprbs_two_phase(T, dither.dwell_min, dither.dwell_max, ...
                    dither.phase1_amp, dither.phase2_amp, cfg.Twarm, cfg.m);
tau(1:cfg.Twarm, :) = p(1:cfg.Twarm, :);

% BK-RLS state
W = window('init', cfg.p, cfg.m, cfg.ell);
stR = struct('theta', [], 'P', [], 'lambda', cfg.lambda, 'eps', cfg.eps);
ready_seen = false;

% Diagnostics
yhat = nan(T,cfg.p);     % one-step prediction before update
e    = nan(T,cfg.p);     % one-step prediction error
theta_hist = [];         % store θ for unitary kernel
lpv_coeff = struct('Ak', cell(T,1), 'Bk', cell(T,1), 'Ck', []);

% Initial conditions
state.q = q3;
state.w = [0; 0; 0];      % zero angular rate
state_hist = cell(T,1);

%% -------------------- Simulation loop --------------------
for t = 1:(T-1)

    fprintf('Progress: %.2f%%\n', t/T * 100);

    % Plant update
    % y(t,:) = [state.q; state.w];
    y(t,:) = att_output(state, qd(t,:).');
    state_hist{t} = state;
    state = att_dyn_step(state, tau(t,:).', plant);

    % Update window with applied u(t) and measured y(t)
    [W, s_k, ready] = window('push', W, tau(t,:).', y(t,:).');
    if ~ready, continue; end

    % Build regressor, predict BEFORE update, then RLS update
    [phi_k, meta] = regressor(s_k, spec, cfg.p, cfg.m); %#ok<ASGLU>
    if ~ready_seen
        stR.theta = zeros(size(phi_k,2),1);
        stR.P     = eye(size(phi_k,2))/cfg.ridge;
        ready_seen = true;
    end
    yhat(t,:) = (phi_k * stR.theta);
    e(t,:)    = y(t) - yhat(t);
    [stR, ~]  = rls_update(stR, phi_k, y(t,:).');

    % Basis and operators for multi-step prediction
    gamma = kernel('eval', spec, s_k);
    Theta = theta_vec_to_matrix(stR.theta, cfg.p);
    [y_hist, u_hist] = histories(y, tau, t, cfg.m, cfg.p, cfg.ell);
    [Ty, Tu, sigma_k, meta_tp] = toeplitz(Theta, gamma, y_hist, u_hist, N, cfg.ell);
    lpv_coeff(t).Ak = meta_tp.Ak;
    lpv_coeff(t).Bk = meta_tp.Bk;
    lpv_coeff(t).Ck = meta_tp.Ck;

    % After warm-up: ABRLS-PC, unconstrained, apply first move + dither
    if t >= cfg.Twarm
        % Reference stack over horizon
        R = ref_stack(r, t, N, cfg.p);

        % Assemble cost and solve via Cholesky; apply first control block
        C = cost_assemble(Ty, Tu, sigma_k, Qy, Ru, R, ...
            struct('assert',true,'eps',cfg.eps,'m',cfg.m,'N',N,'u_k',tau(t,:).'));
        Sln = solve_cholesky(C.H, C.h, struct('assert',true,'J0',C.J0));
        tau(t+1,:) = Sln.U(1:cfg.m);
    else
        % During warm-up, just dither (keeps window filling simple)
        tau(t+1,:) = p(t+1,:);
    end
end

% Final sample y(T) for completeness
state = att_dyn_step(state, tau(T,:).', plant);
state_hist{T} = state;
% y(T,:) = [state.q; state.w];
y(t,:) = att_output(state, qd(T,:).');

%% -------------------- Metrics --------------------
% Phase-II indices
idx2 = (cfg.Twarm+1) : (cfg.N_total);

% Errors (T2 x 3)
E = r(idx2,:) - y(idx2,:);

% --- Output metrics (per output and overall) ---
rmse2_per_y = sqrt(mean(E.^2, 1));                % 1x3
rmse2_all   = sqrt(mean(sum(E.^2, 2)));           % scalar

iae2_per_y  = sum(abs(E), 1);                     % 1x3
iae2_all    = sum(abs(E(:)));                     % scalar

% --- Input metrics (per input and overall) ---
Ud          = diff(tau(idx2,:), 1, 1);              % (T2-1) x 2
tv_u_per    = sum(abs(Ud), 1);                    % 1x2
tv_u_all    = sum(abs(Ud(:)));                    % scalar

peak_u_per  = max(abs(tau(idx2,:)), [], 1);         % 1x2
peak_u_all  = max(peak_u_per);                    % scalar

% Optional: package results
metrics = struct( ...
  'rmse2_per_y', rmse2_per_y, ...
  'rmse2_all',   rmse2_all, ...
  'iae2_per_y',  iae2_per_y, ...
  'iae2_all',    iae2_all, ...
  'tv_u_per',    tv_u_per, ...
  'tv_u_all',    tv_u_all, ...
  'peak_u_per',  peak_u_per, ...
  'peak_u_all',  peak_u_all ...
);

%% -------------------- Package and save --------------------
Results = struct();
Results.spec    = spec;
Results.cfg     = cfg;
Results.horizon = struct('N', N);
Results.weights = struct('Qy','I','Ru_rho',rho);
Results.metrics = metrics;
Results.series  = struct('y', y, 'u', tau);
Results.state   = state_hist;
Results.ref     = qd;
Results.meta    = run_metadata();
Results.plant   = plant;

fname = fullfile(outdir, filename_ex7(spec, seed));
save(fname, 'Results');
fprintf('Saved %s\n', fname);

end % function


%% -------------------- Helpers (local) --------------------

%% --- Reference trajectory ---

% make_qd_sinusoid.m
% Sinusoidal quaternion reference via rotation-vector exponential map.
% Inputs:
%   T, Ts         : length and sample time
%   A_deg         : 3x1 amplitudes [deg] for roll/pitch/yaw-like axes
%   f_hz          : 3x1 frequencies [Hz] for each axis
% Output:
%   qd_traj       : 4xT unit quaternions [eta; eps] (columns)

function qd_traj = make_qd_sinusoid(T, Ts, A_deg, f_hz)
    % Sinusoidal quaternion reference, output size T×4.
    % Each row: [w x y z]

    t = (0:T-1)*Ts;
    A = deg2rad(A_deg(:));      % radians amplitudes
    w = 2*pi*f_hz(:);           % rad/s
    qd_traj = zeros(T,4);

    for k = 1:T
        r = A .* sin(w*t(k));        % rotation vector (axis-angle)
        q = quat_from_rotvec(r);     % 1×4 row quaternion
        qd_traj(k,:) = q;            % assign row
    end
end

% --- helper: exponential map S^3 ← R^3 ---
function q = quat_from_rotvec(r)
    th = norm(r);
    if th < 1e-12
        q = [1 0 0 0];
    else
        s = sin(0.5*th)/th;
        q = [cos(0.5*th) s*r(:).'];  % ensure row vector
    end
    q = q / norm(q);
end

%% ---- Attitude dynamics (quaternion) ----

function state_next = att_dyn_step(state, tau, plant)
    % att_dyn_step.m
    % Discrete-time rigid-body attitude step (quaternion + angular rate).
    % Inputs:
    %   state.q  : 4x1 unit quaternion [eta; eps] (column)
    %   state.w  : 3x1 body angular velocity (rad/s)
    %   tau      : 3x1 body torque (N·m)
    %   plant.J  : 3x3 SPD inertia matrix
    %   plant.Ts : sampling period (s)
    %   plant.renorm (optional, default true): re-normalize quaternion
    % Output:
    %   state_next with fields q (4x1), w (3x1)

    % --- guards ---
    if ~isfield(plant,'renorm'), plant.renorm = true; end
    assert(isvector(state.q) && numel(state.q)==4, 'state.q must be 4x1');
    assert(isvector(state.w) && numel(state.w)==3, 'state.w must be 3x1');
    assert(all(size(plant.J)==[3 3]), 'plant.J must be 3x3');
    assert(isscalar(plant.Ts) && plant.Ts>0, 'plant.Ts must be > 0');
    q = state.q(:);  w = state.w(:);  J = plant.J;  Ts = plant.Ts;  tau = tau(:);

    % --- quaternion kinematics via exponential map (unit-norm preserving) ---
    theta = norm(w)*Ts;                         % rotation angle over step
    dq = [cos(0.5*theta); 0.5*Ts*sinc1(0.5*theta)*w];  % Delta quaternion
    q_next = quat_mul(dq, q);                   % left-multiply increment
    if plant.renorm, q_next = q_next / norm(q_next); end

    % --- rigid-body dynamics (explicit Euler) ---
    wdot  = J \ (tau - cross(w, J*w));
    w_next = w + Ts*wdot;

    state_next.q = q_next;
    state_next.w = w_next;
end

function y = sinc1(x)
    % sin(x)/x with robust x→0 limit
    tol = 1e-12;
    y = ones(size(x));
    mask = abs(x) > tol;
    y(mask) = sin(x(mask))./x(mask);
end

function q = quat_mul(p, r)
    % Hamilton product q = p ⊗ r, both 4x1 as [eta; eps]
    eta_p = p(1); eps_p = p(2:4);
    eta_r = r(1); eps_r = r(2:4);
    q = [ eta_p*eta_r - dot(eps_p, eps_r);
          eta_p*eps_r + eta_r*eps_p + cross(eps_p, eps_r) ];
end

%% --- Observer ---

function [y, err] = att_output(state, qd)
    % att_output.m
    % Observer/measurement helper: maps full state to output y = [tilde_eps; w].
    % Inputs:
    %   state.q : 4x1 unit quaternion (current attitude)
    %   state.w : 3x1 body angular velocity
    %   qd      : 4x1 unit quaternion (desired attitude)
    % Outputs:
    %   y       : 6x1 vector [tilde_eps; w]
    %   err     : struct with fields tilde_q (4x1), tilde_eta (scalar), tilde_eps (3x1)

    q  = state.q(:);
    w  = state.w(:);
    qd = qd(:);

    % quaternion error: tilde_q = qd^{-1} ⊗ q
    qd_inv   = [qd(1); -qd(2:4)];                 % unit-quaternion inverse
    tilde_q  = quat_mul(qd_inv, q);

    % shortest-path convention: enforce tilde_eta >= 0
    if tilde_q(1) < 0
        tilde_q = -tilde_q;
    end

    y = [tilde_q(2:4); w];

    if nargout > 1
        err.tilde_q  = tilde_q;
        err.tilde_eta = tilde_q(1);
        err.tilde_eps = tilde_q(2:4);
    end
end

%% --- Others ----
function v = getv(x, k, dim)
    if k>=1 && k<=numel(x), v = x(k,:).'; else, v = zeros(dim,1); end
end

function R = ref_stack(r, t, N, p)
    T = size(r,1);
    idx = min(t+1:t+N, T);
    R = r(idx, :);
    R = reshape(R.', 1, []).';
end

function [y_hist, u_hist] = histories(y,u,t,m,p,ell)
    y_hist = zeros(p,ell);
    u_hist = zeros(m,ell);
    for i=1:ell
        yi = t-(ell-i);
        ui = t-(ell-i);
        y_hist(:, i) = getv(y, yi, p);
        u_hist(:, i) = getv(u, ui, m);
    end
end

function s = aprbs_two_phase(T, dwell_min, dwell_max, amp1, amp2, N1, m)
    s = zeros(T,m);
    val = 1;
    for i = 1:m
        k = 1;
        while k <= T
            dwell = randi([dwell_min, dwell_max],1,1);
            amp = (k <= N1) * amp1 + (k > N1) * amp2;
            k_end = min(T, k + dwell - 1);
            s(k:k_end, i) = amp * val;
            val = -val;
            k = k_end + 1;
        end
    end
end


function meta = run_metadata()
    meta = struct();
    meta.when = datestr(now, 'yyyy-mm-ddTHH:MM:SS');
    meta.matlab = version;
    try, meta.host = char(java.net.InetAddress.getLocalHost.getHostName); catch, meta.host = ''; end
end

function name = filename_ex7(spec, seed)
    switch lower(spec.type)
        case 'ones'
            tag = 'ones';
        case 'linear'
            tag = 'linear';
        case 'poly'
            tag = sprintf('poly_deg%d', spec.degree);
        case 'rbf'
            % avoid dot in filename
            tag = sprintf('rbf_sig%s', strrep(num2str(spec.sigma,'%0.3g'),'.','p'));
        otherwise
            tag = 'unknown';
    end
    name = sprintf('ex7_%s_seed%d.mat', tag, seed);
end

function [Theta, meta] = theta_vec_to_matrix(theta_vec, p, ell, m, gamma_len)
% Map RLS vector θ to matrix Θ with p rows.
% Optional validation if ell, m, and gamma_len (q) are provided.

    d = numel(theta_vec);
    W = d / p;
    if abs(W - round(W)) > 1e-12
        error('theta_vec length not divisible by p.');
    end
    W = round(W);

    % Default: simple reshape, no extra checks
    Theta = reshape(theta_vec, p, W);
    meta = struct('validated', false);

    % Optional validation/inference
    if nargin >= 4 && ~isempty(ell) && ~isempty(m)
        cols1 = 1 + ell*p + (ell+1)*m;   % with C
        colsR = cols1 - 1;               % without C

        % Try layouts
        q_none = W / colsR; ok_none = abs(q_none - round(q_none)) < 1e-12 && q_none >= 1;
        q_head = (W - cols1)/colsR + 1;  ok_head = abs(q_head - round(q_head)) < 1e-12 && q_head >= 1;
        q_each = W / cols1;              ok_each = abs(q_each - round(q_each)) < 1e-12 && q_each >= 1;

        if     ok_head, layout = "head"; has_const = true;  q = round(q_head);
        elseif ok_none, layout = "none"; has_const = false; q = round(q_none);
        elseif ok_each, layout = "each"; has_const = true;  q = round(q_each);
        else
            error('theta_vec_to_matrix: incompatible sizes. W=%d, cols1=%d, colsR=%d.', W, cols1, colsR);
        end

        % Optional cross-check with provided gamma_len
        if nargin >= 5 && ~isempty(gamma_len) && gamma_len ~= q
            warning('theta_vec_to_matrix:qMismatch', 'Inferred q=%d differs from gamma_len=%d.', q, gamma_len);
        end

        meta = struct('validated', true, 'W', W, 'q', q, 'has_const', has_const, 'layout', char(layout), ...
                      'cols1', cols1, 'colsR', colsR);
    end
end


