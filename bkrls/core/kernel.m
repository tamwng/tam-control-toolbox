function varargout = kernel(op, varargin)
% BK-RLS kernel dictionary
%
% Role
%   Map the past window s_k -> g_k, where g_k ∈ R^q stacks scalar basis
%   functions {γ_j(s_k)}_j. Concatenation builds mixed dictionaries.
%
% Usage
%   g  = kernel('eval', spec, s_k)   % evaluate features
%   q  = kernel('dim',  spec)        % feature count
%   ds = kernel('describe', spec)    % short human-readable description
%
% Spec (deterministic; no RNG in here)
%   spec.type ∈ {'ones','linear','poly','rbf','mix'}
%
%   Common options:
%     spec.assert  (logical, default true)  - input checks
%     spec.center  (double vector, optional) - subtract before features
%     spec.scale   (double vector, optional) - divide  before features
%
%   'ones':
%     q = 1.  g = [1].
%
%   'linear':
%     q = 1 + d.  g = [1; s], where s is the flattened window vector.
%
%   'poly':
%     spec.degree  (integer ≥1)         % default 2
%     spec.cross   ('none'|'pairwise'|'full') % default 'none'
%       'none'    : powers of each coord independently [1; s; s.^2; ...]
%       'pairwise': add all pairwise products s_i*s_j, i<j (up to degree 2)
%       'full'    : full monomial basis up to given degree (combinatorial)
%     q depends on d and options. Deterministic ordering.
%
%   'rbf':
%     spec.centers  (q × d)   % each row is a center c_j
%     spec.sigma    (scalar or length-q vector > 0)
%     g_j = exp( -0.5 * || (s - c_j) ./ σ_j ||_2^2 )
%
%   'mix':
%     spec.parts {cell}  % cell array of sub-specs; outputs concatenated
%
% Window shape (from bkrls/window.m → 'push'):
%   s_k.y : p×ℓ  holding [y_{k-1}, ..., y_{k-ℓ}]
%   s_k.u : m×(ℓ+1) holding [u_k, u_{k-1}, ..., u_{k-ℓ}]
% Flattening order is column-major then concatenation: vec(y), vec(u).

switch lower(op)
    case 'eval'
        g = op_eval(varargin{:});
        varargout = {g};
    case 'dim'
        q = op_dim(varargin{:});
        varargout = {q};
    case 'describe'
        ds = op_describe(varargin{:});
        varargout = {ds};
    otherwise
        error('bkrls.kernel: unknown op "%s". Use eval|dim|describe.', op);
end
end

%% ---- ops ----

function g = op_eval(spec, s_k)
% g = kernel('eval', spec, s_k)
% spec : dictionary spec struct (see header)
% s_k  : struct with fields .y (p×ℓ), .u (m×(ℓ+1))

    arguments
        spec (1,1) struct
        s_k  (1,1) struct
    end

    s = flatten_window(s_k);           % column vector (d×1)
    s = normalize_if_needed(spec, s);  % optional center/scale

    switch lower(spec.type)
        case 'ones'
            % single global intercept feature
            g = ones(1,1);

        case 'linear'
            % [1; s]  (intercept controlled via spec.bias)
            use_bias = getfield_with_default(spec,'bias',true);
            if use_bias
                g = [1; s];
            else
                g = s;
            end

        case 'poly'
            % polynomial features WITHOUT constant; prepend 1 if spec.bias
            deg   = getfield_with_default(spec,'degree',2);
            cross = getfield_with_default(spec,'cross','none');
            validate_degree_cross(deg, cross);
            use_bias = getfield_with_default(spec,'bias',true);
            g = poly_features_nobias(s, deg, cross);
            if use_bias, g = [1; g]; end

        case 'rbf'
            % centers: (q×d), sigma: scalar or (q×1)
            [C, sig] = validate_rbf_spec(spec, numel(s));
            % compute squared Mahalanobis with isotropic σ_j per center
            diffs = C - s.';                    % q×d
            if isscalar(sig)
                q = size(C,1);
                g = exp(-0.5 * sum(diffs.^2, 2) / (sig^2));
            else
                g = exp(-0.5 * sum((diffs ./ sig).^2, 2));
            end

        case 'mix'
            parts = getfield_with_default(spec,'parts',{});
            assert(iscell(parts) && ~isempty(parts), 'mix.parts must be a nonempty cell array of specs.');
            % enforce single global intercept: only first part may include it
            for i = 1:numel(parts)
                if i == 1
                    if ~strcmpi(getfield_with_default(parts{i},'type',''), 'ones')
                        parts{i}.bias = getfield_with_default(parts{i},'bias',true);
                    else
                        % first part is 'ones'; all later parts must have no bias
                        parts{i}.bias = true; % harmless for 'ones'
                    end
                else
                    parts{i}.bias = false;
                end
            end
            % concatenate sub-features
            g_list = cellfun(@(sp) op_eval(sp, s_k), parts, 'UniformOutput', false);
            g = vertcat(g_list{:});

        otherwise
            error('bkrls.kernel: unsupported spec.type "%s".', spec.type);
    end
end

function q = op_dim(spec)
% q = kernel('dim', spec)
    switch lower(spec.type)
        case 'ones'
            q = 1;

        case 'linear'
            % 1 + d (bias plus all coordinates)
            d = infer_d_from_spec(spec);
            use_bias = getfield_with_default(spec,'bias',true);
            q = d + (use_bias);

        case 'poly'
            deg   = getfield_with_default(spec,'degree',2);
            cross = getfield_with_default(spec,'cross','none');
            d = infer_d_from_spec(spec);
            use_bias = getfield_with_default(spec,'bias',true);
            q = poly_dim_nobias(d, deg, cross) + (use_bias);

        case 'rbf'
            C = getfield_with_default(spec,'centers',[]);
            assert(~isempty(C) && ismatrix(C), 'rbf.centers must be q×d.');
            q = size(C,1);

        case 'mix'
            parts = getfield_with_default(spec,'parts',{});
            assert(iscell(parts) && ~isempty(parts),'mix.parts must be a nonempty cell array.');
            % mirror intercept enforcement from eval
            for i = 1:numel(parts)
                if i == 1
                    if ~strcmpi(getfield_with_default(parts{i},'type',''), 'ones')
                        parts{i}.bias = getfield_with_default(parts{i},'bias',true);
                    else
                        parts{i}.bias = true;
                    end
                else
                    parts{i}.bias = false;
                end
            end
            q = 0;
            for i=1:numel(parts)
                q = q + op_dim(parts{i});
            end

        otherwise
            error('bkrls.kernel: unsupported spec.type "%s".', spec.type);
    end
end

function ds = op_describe(spec)
% ds = kernel('describe', spec)
    switch lower(spec.type)
        case 'ones'
            ds = "ones";
        case 'linear'
            ds = "linear";
        case 'poly'
            deg   = getfield_with_default(spec,'degree',2);
            cross = string(getfield_with_default(spec,'cross','none'));
            ds = "poly(deg="+deg+", cross="+cross+")";
        case 'rbf'
            C = getfield_with_default(spec,'centers',[]);
            sig = getfield_with_default(spec,'sigma',NaN);
            ds = "rbf(q="+size(C,1)+", sigma="+mat2str(sig)+")";
        case 'mix'
            parts = getfield_with_default(spec,'parts',{});
            sub = strings(1,numel(parts));
            for i=1:numel(parts), sub(i)=op_describe(parts{i}); end
            ds = "mix["+strjoin(cellstr(sub),", ")+"]";
        otherwise
            ds = "unknown";
    end
end

%% ---- helpers ----

function s = flatten_window(s_k)
% Flatten s_k into a single column vector with deterministic order:
% s = [ vec(y_{k-1}), vec(y_{k-2}), ..., vec(y_{k-ℓ}),
%       vec(u_k),    vec(u_{k-1}),  ..., vec(u_{k-ℓ}) ]
    y = s_k.y; u = s_k.u;
    assert(isnumeric(y) && ismatrix(y), 's_k.y must be numeric p×ℓ.');
    assert(isnumeric(u) && ismatrix(u), 's_k.u must be numeric m×(ℓ+1).');
    s = [y(:); u(:)];
end

function s = normalize_if_needed(spec, s)
% Apply optional centering/scaling for numerical conditioning.
% spec.center, spec.scale are 1×d or d×1 vectors matching length(s).
    if isfield(spec,'center') && ~isempty(spec.center)
        c = spec.center(:);
        assert(numel(c)==numel(s), 'spec.center length mismatch.');
        s = s - c;
    end
    if isfield(spec,'scale') && ~isempty(spec.scale)
        sc = spec.scale(:);
        assert(numel(sc)==numel(s), 'spec.scale length mismatch.');
        % avoid divide-by-zero
        sc(sc==0) = 1;
        s = s ./ sc;
    end
end

function validate_degree_cross(deg, cross)
    assert(isscalar(deg) && deg>=1 && floor(deg)==deg, 'poly.degree must be integer ≥1.');
    assert(ischar(cross) || isstring(cross), 'poly.cross must be a char/string.');
    cross = lower(string(cross));
    valid = any(cross == ["none","pairwise","full"]);
    assert(valid, 'poly.cross ∈ {"none","pairwise","full"}.');
end

function g = poly_features_nobias(s, degree, cross)
% Build polynomial features deterministically, WITHOUT the constant term.
% Ordering (conceptual):
%   degree 1: [s]
%   degree 2, cross=none    : [s; s.^2]
%   degree 2, pairwise      : [s; s.^2; {s_i*s_j}_{i<j}]
%   degree r, full          : all monomials up to r except the constant
    d = numel(s);

    switch lower(string(cross))
        case "none"
            G = cell(degree,1);
            G{1} = s;
            for r=2:degree
                G{r} = s.^r;
            end
            g = vertcat(G{:});

        case "pairwise"
            assert(degree<=2, 'pairwise implemented for degree ≤ 2.');
            squares = s.^2;
            inter = [];
            for i=1:d-1
                inter = [inter; s(i)*s(i+1:d)]; %#ok<AGROW>
            end
            g = [s; squares; inter];

        case "full"
            % enumerate all monomials up to 'degree', drop the all-zero exponent
            exps = enumerate_exponents(d, degree); % first row is zeros
            exps = exps(2:end,:);                  % remove constant
            vals = ones(size(exps,1),1);
            srow = s(:)'.';
            for k=1:size(exps,1)
                e = exps(k,:);               % 1×d
                vals(k) = prod( srow'.^e );  % scalar
            end
            g = vals;

        otherwise
            error('Unexpected poly.cross value.');
    end
    g = g(:);
end

function q = poly_dim_nobias(d, degree, cross)
% Closed-form size without the constant term.
    switch lower(string(cross))
        case "none"
            q = d*degree;
        case "pairwise"
            assert(degree<=2,'pairwise implemented for degree ≤ 2.');
            q = d + d + nchoosek(d,2); % linear + squares + pairs
        case "full"
            % total monomials up to degree r minus the constant
            q = nchoosek(d + degree, degree) - 1;
        otherwise
            error('Unexpected poly.cross value.');
    end
end

function [C, sig] = validate_rbf_spec(spec, d)
    C = getfield_with_default(spec,'centers',[]);
    assert(~isempty(C) && ismatrix(C), 'rbf.centers must be q×d.');
    assert(size(C,2)==d, 'rbf.centers second dimension must equal length(s).');
    sigma = getfield_with_default(spec,'sigma',[]);
    assert(~isempty(sigma), 'rbf.sigma must be provided.');
    if isscalar(sigma)
        sig = sigma;
        assert(sig>0, 'rbf.sigma must be > 0.');
    else
        sig = sigma(:).';
        assert(numel(sig)==size(C,1), 'rbf.sigma must be scalar or length q.');
        assert(all(sig>0), 'rbf.sigma entries must be > 0.');
        % promote to q×d by repeating per-dimension if needed
        sig = repmat(sig(:), 1, d); % q×d
    end
end

function d = infer_d_from_spec(spec)
% When only dimension is needed (e.g., for 'linear' or 'poly' dim),
% require spec.d to be provided by caller (set once from data shape).
    d = getfield_with_default(spec,'d',[]);
    assert(~isempty(d) && isscalar(d) && d>0, ...
        ['For kernel.dim on "',spec.type,'", set spec.d (flattened window length).']);
    d = double(d);
end

function exps = enumerate_exponents(d, r)
% Return all exponent vectors e ∈ N_0^d with sum(e) ≤ r, in graded lex order.
    exps = zeros(1,d); % degree 0
    for total = 1:r
        part = compositions(total, d); % all nonnegative integer tuples summing to 'total'
        exps = [exps; part]; %#ok<AGROW>
    end
end

function comps = compositions(total, d)
% All d-tuples of nonnegative integers summing to 'total', in lex order.
    if d==1
        comps = total;
        return
    end
    comps = [];
    for k=0:total
        tail = compositions(total-k, d-1);
        comps = [comps; [k*ones(size(tail,1),1), tail]]; %#ok<AGROW>
    end
end

function v = getfield_with_default(s, name, default)
    if isfield(s, name), v = s.(name); else, v = default; end
end
