function run_ex3(spec, seed, outdir)

%% -------------------- Config (agreed spec) --------------------
cfg = struct();
cfg.p = 3;                                          % outputs
cfg.m = 2;                                          % inputs
cfg.ell = 2;                                        % known lag (regressor length)
cfg.N_total = 300;                                  % total simulation length (can adjust ad hoc)
cfg.Twarm = 5;                                      % warm-up to fill window (no long Phase I)
cfg.lambda = 1.0;                                   % no forgetting (time-invariant, noise-free)
cfg.ridge  = 1e-9;                                  % small ridge for numerical stability
cfg.eps    = 1e-12;                                 % numeric jitter
cfg.seed   = seed;
cfg.noise_std = 0.0;                                % noise-free baseline
cfg.d_flat = cfg.p*cfg.ell + cfg.m*(cfg.ell+1);     % |s| = |vec(y_{t-1:ℓ})| + |vec(u_{t:ℓ})|

% Horizon and weights (single horizon: N_c = N)
N = 10;
rho = 1e2;                         % differential-u penalty; keep small to avoid SSE
Qy = speye(cfg.p * N);              % unit tracking weight
Ru = rho * speye(cfg.m * N);        % small effort weight

T = cfg.N_total;
segment = 100;
N_phase2 = 3 * segment;
r = zeros(T,cfg.p);
r((cfg.Twarm+1):(cfg.Twarm+segment),:)             = kron(ones(segment,1), [1.0, -0.5, 2.0]);
r((cfg.Twarm+segment+1):(cfg.Twarm+2*segment),:)   = kron(ones(segment,1), [-0.5, 1.3, -0.5]);
r((cfg.Twarm+2*segment+1):(cfg.Twarm+3*segment),:) = kron(ones(segment,1), [0.0, 0.0, 0.0]);

% Dither (APRBS): higher during warm-up, smaller thereafter
dither.phase1_amp = 0.10;
dither.phase2_amp = 0.05;
dither.dwell_min  = 5;
dither.dwell_max  = 15;

% RBF config
if (strcmpi(spec.type,'rbf'))
    spec.centers = randn(spec.q, cfg.d_flat);      % deterministic with seed
end

rng(cfg.seed);

%% -------------------- Plant (ground truth) --------------------
% y_k = A1 y_{k-1} + A2 y_{k-2} + B0 u_k + B1 u_{k-1} + B2 u_{k-1}
plant.A1 = diag([1.7, 1.473, 1.8]);
plant.A2 = diag([-0.6, -0.7225, -0.81]);
plant.B0 = [ 0.4,  0.1
             0.2,  0.3
            -0.1,  0.5 ];
plant.B1 = [ 0.1,   0.0
            -0.05,  0.2
             0.0,   -0.1 ];
plant.B2 = [ 0.0,  0.05
             0.0,  0.0
             0.08, 0.0 ];
coeff_true.A = {plant.A1, plant.A2};
coeff_true.B = {plant.B0, plant.B1, plant.B2};
coeff_true.C = zeros(cfg.p, 1);

%% -------------------- Preallocate --------------------
u = zeros(T,cfg.m);   % applied input
y = zeros(T,cfg.p);   % output
p = aprbs_two_phase(T, dither.dwell_min, dither.dwell_max, ...
                    dither.phase1_amp, dither.phase2_amp, cfg.Twarm, cfg.m);
u(1:cfg.Twarm, :) = p(1:cfg.Twarm, :);

% BK-RLS state
W = window('init', cfg.p, cfg.m, cfg.ell);
stR = struct('theta', [], 'P', [], 'lambda', cfg.lambda, 'eps', cfg.eps);
ready_seen = false;

% Diagnostics
yhat = nan(T,cfg.p);     % one-step prediction before update
e    = nan(T,cfg.p);     % one-step prediction error
theta_hist = [];         % store θ for unitary kernel
lpv_coeff = struct('Ak', cell(T,1), 'Bk', cell(T,1), 'Ck', []);
A_err_fro = nan(T,1);
B_err_fro = nan(T,1);
C_err_fro = nan(T,1);

%% -------------------- Simulation loop --------------------
for t = 1:(T-1)

    % Plant update: y(t) from current/past u and past y (discrete-time)
    y1 = getv(y, t-1, cfg.p);         % y_{t-1}
    y2 = getv(y, t-2, cfg.p);         % y_{t-2}
    u0 = u(t, :).';                        % u_{t}
    u1 = getv(u, t-1, cfg.m);          % u_{t-1}
    u2 = getv(u, t-2, cfg.m);          % u_{t-2}
    y(t,:) = plant.A1*y1 + plant.A2*y2 ...
         + plant.B0*u0 + plant.B1*u1 + plant.B2*u2 ...
         + cfg.noise_std*randn(cfg.p, 1);

    % Update window with applied u(t) and measured y(t)
    [W, s_k, ready] = window('push', W, u(t,:).', y(t,:).');
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

    if strcmpi(spec.type,'ones')
        theta_hist(:,end+1) = stR.theta(:);
    end

    % Basis and operators for multi-step prediction
    gamma = kernel('eval', spec, s_k);
    Theta = theta_vec_to_matrix(stR.theta, cfg.p);
    [y_hist, u_hist] = histories(y, u, t, cfg.m, cfg.p, cfg.ell);
    [Ty, Tu, sigma_k, meta_tp] = toeplitz(Theta, gamma, y_hist, u_hist, N, cfg.ell);
    lpv_coeff(t).Ak = meta_tp.Ak;
    lpv_coeff(t).Bk = meta_tp.Bk;
    lpv_coeff(t).Ck = meta_tp.Ck;

    A_err_fro(t) = norm(meta_tp.Ak{1} - coeff_true.A{1}, 'fro') ...
        + norm(meta_tp.Ak{2} - coeff_true.A{2}, 'fro');

    B_err_fro(t) = norm(meta_tp.Bk{1} - coeff_true.B{1}, 'fro') ...
        + norm(meta_tp.Bk{2} - coeff_true.B{2}, 'fro') ...
        + norm(meta_tp.Bk{3} - coeff_true.B{3}, 'fro');

    C_err_fro(t) = norm(meta_tp.Ck - coeff_true.C, 'fro');

    % After warm-up: ABRLS-PC, unconstrained, apply first move + dither
    if t >= cfg.Twarm
        % Reference stack over horizon
        R = ref_stack(r, t, N, cfg.p);

        % Assemble cost and solve via Cholesky; apply first control block
        C = cost_assemble(Ty, Tu, sigma_k, Qy, Ru, R, ...
            struct('assert',true,'eps',cfg.eps,'m',cfg.m,'N',N,'u_k',u(t,:).'));
        Sln = solve_cholesky(C.H, C.h, struct('assert',true,'J0',C.J0));
        u(t+1,:) = Sln.U(1:cfg.m);
    else
        % During warm-up, just dither (keeps window filling simple)
        u(t+1,:) = p(t+1,:);
    end
end

% Final sample y(T) for completeness
y(T,:) = plant.A1*getv(y,T-1) + plant.A2*getv(y,T-2) ...
     + plant.B0*u(T,:).' + plant.B1*getv(u,T-1) + plant.B2*getv(u,T-2) ...
     + cfg.noise_std*randn(cfg.p,1);

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
Ud          = diff(u(idx2,:), 1, 1);              % (T2-1) x 2
tv_u_per    = sum(abs(Ud), 1);                    % 1x2
tv_u_all    = sum(abs(Ud(:)));                    % scalar

peak_u_per  = max(abs(u(idx2,:)), [], 1);         % 1x2
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
Results.series  = struct('y', y, 'u', u, 'r', r, 'e', e(cfg.ell+1:T-1), ...
                         'theta_hist', theta_hist, ...
                         'lpv_coeff', lpv_coeff, ...
                         'A_err_fro', A_err_fro, ...
                         'B_err_fro', B_err_fro, ...
                         'C_err_fro', C_err_fro);
Results.meta    = run_metadata();
Results.coeff_true = coeff_true;

fname = fullfile(outdir, filename_ex3(spec, seed));
save(fname, 'Results');
fprintf('Saved %s\n', fname);

end % function


%% -------------------- Helpers (local) --------------------
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

function z = ewma(x, L, varargin)
% x: series (e.g., e.^2)
% L: "equivalent window" length
% varargin{1}: reset_indices (vector of k where EWMA restarts), optional

alpha = 2/(L+1);
z = nan(size(x));
acc = 0; seen = false;

reset_idx = [];
if ~isempty(varargin)
    reset_idx = varargin{1}(:).';
end

for i = 1:numel(x)
    xi = x(i);
    if any(i == reset_idx)
        seen = false;           % force fresh seed at this index
    end
    if ~isnan(xi)
        if ~seen
            acc = xi;           % seed with first valid sample
            seen = true;
        else
            acc = alpha*xi + (1-alpha)*acc;
        end
        z(i) = acc;
    end
end
end


function meta = run_metadata()
    meta = struct();
    meta.when = datestr(now, 'yyyy-mm-ddTHH:MM:SS');
    meta.matlab = version;
    try, meta.host = char(java.net.InetAddress.getLocalHost.getHostName); catch, meta.host = ''; end
end

function name = filename_ex3(spec, seed)
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
    name = sprintf('ex3_%s_seed%d.mat', tag, seed);
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


