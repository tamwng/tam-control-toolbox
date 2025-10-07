function varargout = window(op, varargin)
% BK-RLS window manager (indexing and alignment)
%
% Purpose
%   Maintain a rolling window s_k = ( y_{k-ℓ:k-1}, u_{k-ℓ:k} ) with explicit
%   direct-feedthrough alignment (u_k included, y_k excluded).
%
% Usage pattern (per time step k)
%   % once
%   state = window('init', p, m, ell, opts);
%
%   % each step with current input u_k and measured output y_k
%   [state, s_k, ready, status] = window('push', state, u_k, y_k);
%   if ready
%       % use s_k to build φ_k (regressor), then run RLS with (φ_k, y_k)
%   end
%
% Design
%   - y_hist stores [ y_{k-1}, y_{k-2}, ..., y_{k-ℓ} ]  (p×ℓ)
%   - u_hist stores [ u_{k}, u_{k-1}, ..., u_{k-ℓ} ]    (m×(ℓ+1))
%   - 'push' constructs s_k using pre-update y_hist and u_hist plus u_k,
%     then commits u_k and y_k into histories for the next step.
%
% Public ops
%   init(p, m, ell, opts) -> state
%   push(state, u_k, y_k) -> state, s_k, ready, status
%   get(state)            -> s_k, ready
%   reset(state)          -> state
%
% Status codes
%   'OK'           : normal operation
%   'NOT_READY'    : not enough history to emit s_k
%   'BAD_DIM'      : dimension mismatch in u_k or y_k
%   'NAN_INPUT'    : NaN/Inf detected in u_k or y_k
%
% Notes
%   - Double precision only.
%   - No plotting here. Tests handle verification.
%   - Deterministic: no RNG usage.

switch lower(op)
    case 'init'
        varargout = {op_init(varargin{:})};
    case 'push'
        [state, s_k, ready, status] = op_push(varargin{:});
        varargout = {state, s_k, ready, status};
    case 'get'
        [s_k, ready] = op_get(varargin{:});
        varargout = {s_k, ready};
    case 'reset'
        varargout = {op_reset(varargin{:})};
    otherwise
        error('bkrls.window: unknown op "%s". Use init|push|get|reset.', op);
end
end

%% --- Implementation ---

function state = op_init(p, m, ell, opts)
% state = window('init', p, m, ell, opts)
% p   : output dimension
% m   : input dimension
% ell : window length (positive integer)
% opts: struct with optional fields:
%       .assert  (logical, default true)  - run dimension checks
%       .eps     (double,  default 1e-12) - numeric epsilon
%
% Returns struct:
%   state.p, state.m, state.ell
%   state.y_hist  (p×ell)   initialized to NaN
%   state.u_hist  (m×(ell+1)) initialized to NaN
%   state.nY, state.nU  (# of valid past y and u samples available)
%   state.t       (time step count, starts at 0)
%   state.assert, state.eps

    arguments
        p   (1,1) {mustBeInteger, mustBePositive}
        m   (1,1) {mustBeInteger, mustBePositive}
        ell (1,1) {mustBeInteger, mustBePositive}
        opts.assert (1,1) logical = true
        opts.eps    (1,1) double  = 1e-12
    end

    state.p    = double(p);
    state.m    = double(m);
    state.ell  = double(ell);
    state.y_hist = NaN(p, ell);
    state.u_hist = NaN(m, ell+1);
    state.nY   = 0;           % valid columns in y_hist
    state.nU   = 0;           % valid past u's (excludes current u_k)
    state.t    = 0;           % steps processed
    state.assert = opts.assert;
    state.eps    = opts.eps;
end

function [state, s_k, ready, status] = op_push(state, u_k, y_k)
% [state, s_k, ready, status] = window('push', state, u_k, y_k)
% Inputs:
%   state : from 'init' or previous 'push'
%   u_k   : current input  (m×1)
%   y_k   : current output (p×1)
%
% Outputs:
%   state : updated histories for next step
%   s_k   : struct with fields:
%           .y  (p×ell)   = [y_{k-1}, ..., y_{k-ell}]
%           .u  (m×(ell+1)) = [u_k, u_{k-1}, ..., u_{k-ell}]
%   ready : true if both y and u histories are fully populated
%   status: struct with .ok (logical), .code (char), .msg (char)

    status = make_status(true, 'OK', 'ok');

    % Basic dimension checks
    if state.assert
        if ~isnumeric(u_k) || ~isequal(size(u_k), [state.m, 1])
            status = make_status(false,'BAD_DIM','u_k must be (m×1).');
        elseif ~isnumeric(y_k) || ~isequal(size(y_k), [state.p, 1])
            status = make_status(false,'BAD_DIM','y_k must be (p×1).');
        end
        if ~status.ok
            s_k = struct('y', [], 'u', []);
            ready = false;
            return
        end
    end

    % NaN/Inf guard
    if any(~isfinite(u_k),'all') || any(~isfinite(y_k),'all')
        status = make_status(false,'NAN_INPUT','u_k or y_k contains NaN/Inf.');
        s_k = struct('y', [], 'u', []);
        ready = false;
        return
    end

    % Construct s_k BEFORE committing y_k (exclude y_k) and AFTER including u_k
    % u window includes current input at the first column
    u_win = [u_k, state.u_hist(:, 1:state.ell)];   % m×(ell+1)
    y_win = state.y_hist;                           % p×ell (still y_{k-1:})

    % Emit readiness: need ℓ past y's and ℓ past u's (current u_k provided)
    ready = (state.nY >= state.ell) && (state.nU >= state.ell);

    if ~ready
        status = make_status(false,'NOT_READY','history not yet full.');
    end

    s_k = struct('y', y_win, 'u', u_win);

    % ---- Commit current samples for next step ----
    % Commit u_k: the built u_win already has u_k at column 1
    state.u_hist = u_win;

    % Commit y_k: shift right and insert at column 1 to become y_{k} for step k+1
    if state.ell > 1
        state.y_hist(:, 2:end) = state.y_hist(:, 1:end-1);
    end
    state.y_hist(:, 1) = y_k;

    % Update counters
    state.nY = min(state.nY + 1, state.ell);
    % For u: we just added u_k to u_hist; for *past* u count used at next step:
    state.nU = min(state.nU + 1, state.ell);
    state.t  = state.t + 1;
end

function [s_k, ready] = op_get(state)
% [s_k, ready] = window('get', state)
% Return the current window without changing the state.
% This is the s_{k+1} *template* prior to receiving u_{k+1}:
%   - y = [y_k, y_{k-1}, ..., y_{k-ell+1}]
%   - u = current stored u_hist = [u_k, ..., u_{k-ell}] (last committed)
%
% Note: for forming s_{k+1} you will still need to supply the new u_{k+1}.
    s_k = struct('y', state.y_hist, 'u', state.u_hist);
    ready = (state.nY >= state.ell) && (state.nU >= state.ell);
end

function state = op_reset(state)
% state = window('reset', state)
% Clear histories while keeping dimensions and options.
    state.y_hist(:) = NaN;
    state.u_hist(:) = NaN;
    state.nY = 0;
    state.nU = 0;
    state.t  = 0;
end

function s = make_status(ok, code, msg)
    s.ok = logical(ok);
    s.code = char(code);
    s.msg  = char(msg);
end
