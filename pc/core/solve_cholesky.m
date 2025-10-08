function out = solve_cholesky(H, h, cfg)
% SOLVE_CHOLESKY  Solve argmin 0.5*U'HU + h'U (+ J0) with Cholesky.
% H must be SPD. Returns U*, factor L, and intermediate z.
%
% Inputs:
%   H   : (n x n) SPD Hessian
%   h   : (n x 1) linear term
%   cfg : struct (optional)
%         .assert = true     % throw if not SPD
%         .J0     = 0        % optional constant for logging J*
%
% Outputs:
%   out.U   : minimizer = -H\h
%   out.L   : Cholesky factor (lower), H = L*L'
%   out.z   : intermediate vector in solves (n x 1)
%   out.J   : optimal cost = J0 - 0.5*h'*(H\h)
%   out.grad_norm : ||HU+h||_2 at solution
%   out.status : struct with ok/code/msg

    if nargin < 3, cfg = struct(); end
    if ~isfield(cfg,'assert'), cfg.assert = true; end
    if ~isfield(cfg,'J0'),     cfg.J0     = 0;    end

    % Enforce symmetry numerically
    H = 0.5*(H + H.');

    n = size(H,1);
    if ~isequal(size(H,2), n), error('H must be square.'); end
    if ~isvector(h) || numel(h) ~= n, error('h must be length n.'); end
    h = h(:);

    % Cholesky factorization
    status.ok = true; status.code = 0; status.msg = '';
    [L,p] = chol(H, 'lower');
    if p ~= 0
        status.ok = false; status.code = 1;
        status.msg = 'H is not SPD (Cholesky failed).';
        if cfg.assert
            error('MATLAB:posdef','%s',status.msg);
        else
            out = struct('U',NaN(size(h)), 'L',NaN(size(H)), ...
                         'z',NaN(size(h)), 'J',NaN, ...
                         'grad_norm',NaN, 'status',status);
            return;
        end
    end

    % Solve HU = -h via forward/back substitution
    z = L \ (-h);       % L z = -h
    U = L.' \ z;        % L' U = z

    % Optimal cost using H^{-1} without forming inverse
    t = L \ h;                  % t = L^{-1} h
    Jopt = cfg.J0 - 0.5*(t.'*t);

    grad = H*U + h;
    out = struct('U',U,'L',L,'z',z,'J',Jopt,'grad_norm',norm(grad), 'status',status);
end
