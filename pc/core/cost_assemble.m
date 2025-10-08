function out = cost_assemble(Ty, Tu, ofs, Qy, Ru, R, cfg)
% COST_ASSEMBLE  Assemble quadratic cost terms for BRLS-PC.
% Forms H, h, J0 using S_k = (I - T_y)\ofs and G_k = (I - T_y)\T_u.
%
% Inputs:
%   Ty  : (pN x pN) Toeplitz T_y
%   Tu  : (pN x mN) Toeplitz T_u
%   ofs : (pN x 1)  sigma_k (offset)
%   Qy  : (pN x pN) output weight, PSD
%   Ru  : (mN x mN) input weight, PSD (make PD if you will Cholesky)
%   R   : (pN x 1)  reference trajectory
%   cfg : optional struct
%         .assert      (default true) shape/SPD checks
%         .eps         (default 1e-12) numeric tol
%
% Output struct:
%   out.H   : (mN x mN) = G'Q_y G + R_u   (symmetrized)
%   out.h   : (mN x 1)  = G'Q_y (S - R)
%   out.J0  : scalar    = 0.5*(S - R)'Q_y(S - R)
%   out.S   : (pN x 1)  S_k
%   out.G   : (pN x mN) G_k
%   out.status : struct with ok/code/msg

    if nargin < 7 || isempty(cfg), cfg = struct(); end
    if ~isfield(cfg,'assert'), cfg.assert = true; end
    if ~isfield(cfg,'eps'),    cfg.eps    = 1e-12; end

    % Basic size checks
    [pN1,pN2] = size(Ty);
    if cfg.assert
        assert(pN1==pN2, 'Ty must be square (pN x pN).');
    end
    pN = pN1;
    [pN_Tu, mN] = size(Tu);
    if cfg.assert
        assert(pN_Tu==pN, 'Tu must have pN rows to match Ty.');
        assert(all(size(Qy)==[pN pN]), 'Qy must be (pN x pN).');
        assert(all(size(Ru)==[mN mN]), 'Ru must be (mN x mN).');
        assert(isvector(ofs) && numel(ofs)==pN, 'ofs must be length pN.');
        assert(isvector(R)   && numel(R)==pN,   'R must be length pN.');
    end
    ofs = ofs(:); R = R(:);

    % Solve without forming inverses
    IminusTy = eye(pN) - Ty;
    % If Ty is strictly lower block-Toeplitz, IminusTy is unit-lower and nonsingular.
    S = IminusTy \ ofs;     % S_k
    G = IminusTy \ Tu;      % G_k

    % Assemble cost terms
    % Symmetrize Qy and Ru lightly to remove numerical skew
    Qy = 0.5*(Qy + Qy.');
    Ru = 0.5*(Ru + Ru.');

    H = G.'*(Qy*G) + Ru;
    H = 0.5*(H + H.');                         % enforce symmetry
    h = G.'*(Qy*(S - R));
    J0 = 0.5*(S - R).'*(Qy*(S - R));

    % SPD check on H (required for Cholesky downstream)
    status.ok = true; status.code = 0; status.msg = '';
    if cfg.assert
        try
            chol(H); % will error if not SPD
        catch ME
            status.ok = false; status.code = 1;
            status.msg = 'H is not SPD (Cholesky failed). Ensure Ru ≻ 0 or weights yield SPD.';
            rethrow(ME);
        end
    else
        % Non-asserting mode: report but do not throw
        try
            chol(H);
        catch
            status.ok = false; status.code = 1;
            status.msg = 'H is not SPD (Cholesky failed).';
        end
    end

    out = struct('H',H,'h',h,'J0',J0,'S',S,'G',G,'status',status);
end
