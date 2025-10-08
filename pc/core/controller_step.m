function out = controller_step(Theta, gamma, y_hist, u_hist, N, ell, Qy, Ru, R, cfg)
% CONTROLLER_STEP  Toeplitz → cost → Cholesky → u_k (one-call control step)
%
% Inputs:
%   Theta    : RLS parameter matrix at k+1
%   gamma    : (q x 1) frozen kernel basis at s_k
%   y_hist   : (p x ell) outputs [y_{k-ell+1},...,y_k]
%   u_hist   : (m x ell) inputs  [u_{k-ell+1},...,u_k]
%   N, ell   : horizon and ARX order
%   Qy       : (pN x pN) PSD output weight
%   Ru       : (mN x mN) PD  input weight
%   R        : (pN x 1) reference
%   cfg      : struct optional: .assert=true, .eps=1e-12, .J0 (passed to solve)
%
% Outputs:
%   out.u_k    : control to apply at time k (m x 1)
%   out.U_star : full optimal sequence (mN x 1)
%   out.cost   : struct from cost_assemble
%   out.solve  : struct from solve_cholesky
%   out.meta   : diagnostic meta from toeplitz

    if nargin < 10 || isempty(cfg), cfg = struct(); end
    if ~isfield(cfg,'assert'), cfg.assert = true; end
    if ~isfield(cfg,'eps'),    cfg.eps    = 1e-12; end

    [p,ell_y] = size(y_hist); [m,ell_u] = size(u_hist);
    if ell_y~=ell || ell_u~=ell, error('controller_step:ell','y_hist/u_hist must have %d cols.',ell); end
    pN = p*N; mN = m*N;

    if numel(R) ~= pN, error('controller_step:R'), end
    if ~isequal(size(Qy),[pN,pN]), error('controller_step:Qy'), end
    if ~isequal(size(Ru),[mN,mN]), error('controller_step:Ru'), end
    R = R(:);

    % 1) Toeplitz prediction operators
    [Ty, Tu, sigma_k, meta] = toeplitz(Theta, gamma, y_hist, u_hist, N, ell);

    % 2) Cost assembly
    C = cost_assemble(Ty, Tu, sigma_k, Qy, Ru, R, struct('assert',cfg.assert,'eps',cfg.eps));

    % 3) Cholesky solve (safe optional J0)
    J0opt = 0;
    if isfield(cfg,'J0'), J0opt = cfg.J0; end
    solv = solve_cholesky(C.H, C.h, struct('assert',cfg.assert,'J0',J0opt));

    % 4) First control block
    u_k = solv.U(1:m);

    out = struct('u_k',u_k, 'U_star',solv.U, 'cost',C, 'solve',solv, 'meta',meta);
end
