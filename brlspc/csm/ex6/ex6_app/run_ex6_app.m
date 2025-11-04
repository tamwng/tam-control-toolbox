function run_ex6_app(spec, seed, outdir)

if nargin < 1, spec = struct('type','ones'); end
if nargin < 2, seed = 42; end
if nargin < 3, outdir = 'results'; end
if ~exist(outdir,'dir'), mkdir(outdir); end

%% -------------------- Config (agreed spec) --------------------
cfg = struct();
cfg.p = 1;                                          % outputs
cfg.m = 1;                                          % inputs
cfg.ell = 2;                                        % known lag (regressor length)
cfg.N_total = 1600;                                  % total simulation length (can adjust ad hoc)
cfg.Twarm = 10;                                     % warm-up to fill window (no long Phase I)
cfg.lambda = 0.999;                                   % no forgetting (time-invariant, noise-free)
cfg.ridge  = 1e-4;                                  % small ridge for numerical stability
cfg.eps    = 1e-12;                                 % numeric jitter
cfg.seed   = seed;
cfg.noise_std = 1e-3;                                % noise-free baseline
cfg.d_flat = cfg.p*cfg.ell + cfg.m*(cfg.ell+1);     % |s| = |vec(y_{t-1:ℓ})| + |vec(u_{t:ℓ})|

% Horizon and weights (single horizon: N_c = N)
N = 30;                             % covers ≈95% decay for |p|=0.837
rho = 2.25*1e4;                         % differential-u penalty; keep small to avoid SSE
Qy = speye(cfg.p * N);              % unit tracking weight
Ru = rho * speye(cfg.m * N);        % small effort weight

% Reference: three 300-step steps after warm-up
T = cfg.N_total;
segment = 400;
r = zeros(T,1);
r((cfg.Twarm+1):(cfg.Twarm+segment))   = 0.5;
r((cfg.Twarm+segment+1):(cfg.Twarm+2*segment)) = 1.5;
r((cfg.Twarm+2*segment+1):(cfg.Twarm+3*segment)) = 3.0;

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
% Hammerstein
plant.alpha = 1.6;
plant.beta = 1.1;
plant.a1 = [2.0; -1.01];
plant.b1 = [0.0; 0.5; -0.65];
plant.hammerstein2 = plant.alpha * plant.b1;
plant.hammerstein3 = plant.beta * plant.b1;

%% -------------------- Preallocate --------------------
u = zeros(T,1);   % applied input
yn = zeros(T,1);   % output
y = yn;
p = aprbs_two_phase(T, dither.dwell_min, dither.dwell_max, ...
                    dither.phase1_amp, dither.phase2_amp, cfg.Twarm);
u(1:cfg.Twarm) = p(1:cfg.Twarm);

% BK-RLS state
W = window('init', cfg.p, cfg.m, cfg.ell);
stR = struct('theta', [], 'P', [], 'lambda', cfg.lambda, 'eps', cfg.eps);
ready_seen = false;

% Diagnostics
yhat = nan(T,1);     % one-step prediction before update
e    = nan(T,1);     % one-step prediction error
lpv_coeff = struct('Ak', cell(T,1), 'Bk', cell(T,1), 'Ck', []);
theta_hist = cell(T,1);

%% -------------------- Simulation loop --------------------
for t = 1:(T-1)

    % Plant update: y(t) from current/past u and past y (discrete-time)
    y1 = getv(yn, t-1);          % y_{t-1}
    y2 = getv(yn, t-2);          % y_{t-2}
    u0 = u(t);                  % u_{t}
    u1 = getv(u, t-1);          % u_{t-1}
    u2 = getv(u, t-2);          % u_{t-2}

    y(t) = plant.a1(1)*y1 + plant.a1(2)*y2 + plant.b1(1)*u0 + plant.b1(2)*u1 + plant.b1(3)*u2 ...
         + plant.hammerstein2(1)*u0^2 + plant.hammerstein2(2)*u1^2 + plant.hammerstein2(3)*u2^2 ...
         + plant.hammerstein3(1)*u0^3 + plant.hammerstein3(2)*u1^3 + plant.hammerstein3(3)*u2^3;
    yn(t) = y(t) + cfg.noise_std*randn;

    % Update window with applied u(t) and measured y(t)
    [W, s_k, ready] = window('push', W, u(t), yn(t));
    if ~ready, continue; end

    % Build regressor, predict BEFORE update, then RLS update
    [phi_k, meta] = regressor(s_k, spec, cfg.p, cfg.m); %#ok<ASGLU>
    if ~ready_seen
        stR.theta = zeros(size(phi_k,2),1);
        stR.P     = eye(size(phi_k,2))/cfg.ridge;
        ready_seen = true;
    end
    yhat(t) = (phi_k * stR.theta);
    e(t)    = yn(t) - yhat(t);
    [stR, ~] = rls_update(stR, phi_k, yn(t));
    theta_hist{t} = stR.theta;

    % Basis and operators for multi-step prediction
    gamma = kernel('eval', spec, s_k);
    Theta = theta_vec_to_matrix(stR.theta, cfg.p);
    [y_hist, u_hist] = histories(yn, u, t, cfg.ell);
    [Ty, Tu, sigma_k, meta_tp] = toeplitz(Theta, gamma, y_hist, u_hist, N, cfg.ell);
    lpv_coeff(t).Ak = meta_tp.Ak;
    lpv_coeff(t).Bk = meta_tp.Bk;
    lpv_coeff(t).Ck = meta_tp.Ck;

    % After warm-up: ABRLS-PC, unconstrained, apply first move + dither
    if t >= cfg.Twarm
        % Reference stack over horizon
        R = ref_stack(r, t, N);

        % Assemble cost and solve via Cholesky; apply first control block
        C = cost_assemble(Ty, Tu, sigma_k, Qy, Ru, R, ...
            struct('assert',true,'eps',cfg.eps,'m',cfg.m,'N',N,'u_k',u(t)));
        Sln = solve_cholesky(C.H, C.h, struct('assert',true,'J0',C.J0));
        % u(t+1) = Sln.U(1:cfg.m) + p(t+1);  % NO clipping in 1
        u(t+1) = Sln.U(1:cfg.m);  % NO clipping in 1
    else
        % During warm-up, just dither (keeps window filling simple)
        u(t+1) = p(t+1);
    end
end

% Final sample y(T) for completeness
y1 = getv(yn, t-1);          % y_{t-1}
y2 = getv(yn, t-2);          % y_{t-2}
u0 = u(t);                  % u_{t}
u1 = getv(u, t-1);          % u_{t-1}
u2 = getv(u, t-2);          % u_{t-2}

y(T) = plant.a1(1)*y1 + plant.a1(2)*y2 + plant.b1(1)*u0 + plant.b1(2)*u1 + plant.b1(3)*u2 ...
    + plant.hammerstein2(1)*u0^2 + plant.hammerstein2(2)*u1^2 + plant.hammerstein2(3)*u2^2 ...
    + plant.hammerstein3(1)*u0^3 + plant.hammerstein3(2)*u1^3 + plant.hammerstein3(3)*u2^3;
yn(T) = y(T) + cfg.noise_std*randn;

%% -------------------- Metrics --------------------
idx2 = (cfg.Twarm+1):(cfg.N_total);      % Phase-II window
rmse2 = sqrt(mean((r(idx2) - y(idx2)).^2));
iae2  = sum(abs(r(idx2) - y(idx2)));
tv_u  = sum(abs(diff(u)));
peak_u = max(abs(u));

%% -------------------- Package and save --------------------
Results = struct();
Results.spec    = spec;
Results.cfg     = cfg;
Results.horizon = struct('N', N);
Results.weights = struct('Qy','I','Ru_rho',rho);
Results.metrics = struct('RMSE_PhaseII', rmse2, ...
                         'IAE_PhaseII',  iae2, ...
                         'TV_u',         tv_u, ...
                         'Peak_u',       peak_u);
Results.series  = struct('y', y, 'u', u, 'r', r, 'e', e(cfg.ell+1:T-1), ...
                         'lpv_coeff', lpv_coeff);
Results.theta_id = struct('theta', theta_hist);
Results.meta    = run_metadata();

fname = fullfile(outdir, filename_ex1(spec, seed));
save(fname, 'Results');
fprintf('Saved %s\n', fname);

end % function


%% -------------------- Helpers (local) --------------------
function v = getv(x, k)
    if k>=1 && k<=numel(x), v = x(k); else, v = 0; end
end

function R = ref_stack(r, t, N)
    T = numel(r);
    idx = min(t+1:t+N, T);
    R = r(idx);  % p=1 => (N x 1)
end

function [y_hist, u_hist] = histories(y,u,t,ell)
    y_hist = zeros(1,ell);
    u_hist = zeros(1,ell);
    for i=1:ell
        yi = t-(ell-i);
        ui = t-(ell-i);
        y_hist(i) = getv(y, yi);
        u_hist(i) = getv(u, ui);
    end
end

function s = aprbs_two_phase(T, dwell_min, dwell_max, amp1, amp2, N1)
    s = zeros(T,1);
    val = 1;
    k = 1;
    while k <= T
        dwell = randi([dwell_min, dwell_max],1,1);
        amp = (k <= N1) * amp1 + (k > N1) * amp2;
        k_end = min(T, k + dwell - 1);
        s(k:k_end) = amp * val;
        val = -val;
        k = k_end + 1;
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

function name = filename_ex1(spec, seed)
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
    name = sprintf('ex1_%s_seed%d.mat', tag, seed);
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


