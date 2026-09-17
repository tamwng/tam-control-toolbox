classdef RlsEstimator < handle
    %RLSESTIMATOR Joint RLS in fixed scaled coordinates, Eqs. (24)-(30).
    % P0 is the covariance of beta = columnScale.*theta. rowScale multiplies
    % both sides of each measured regression. The admissibility map is used
    % only by Parameters; it never replaces the unconstrained RLS state.

    properties (SetAccess = private)
        Beta
        Covariance
        RowScale
        ColumnScale
        Forgetting
        ResidualSquares = zeros(0, 1)
    end

    properties (Dependent, SetAccess = private)
        RawParameters
        Parameters
    end

    properties (Access = private)
        Admissibility
    end

    methods
        function obj = RlsEstimator(theta0, P0, rowScale, columnScale, forgetting, admissibility)
            if nargin < 5 || isempty(forgetting)
                forgetting = struct('mode', 'none');
            end
            if nargin < 6 || isempty(admissibility)
                admissibility = @(theta) theta;
            end
            validateattributes(theta0, {'double'}, {'column', 'nonempty', 'real', 'finite'});
            n = numel(theta0);
            validateattributes(P0, {'double'}, {'size', [n n], 'real', 'finite'});
            RlsEstimator.checkCovariance(P0);
            validateattributes(rowScale, {'double'}, {'vector', 'nonempty', 'real', 'finite', 'positive'});
            validateattributes(columnScale, {'double'}, {'vector', 'numel', n, 'real', 'finite', 'positive'});
            if ~isa(admissibility, 'function_handle')
                error('RlsEstimator:InvalidMap', 'The admissibility map must be a function handle.');
            end
            RlsEstimator.checkForgetting(forgetting);
            obj.RowScale = rowScale(:);
            obj.ColumnScale = columnScale(:);
            obj.Beta = obj.ColumnScale .* theta0;
            if any(~isfinite(obj.Beta))
                error('RlsEstimator:InvalidInitialState', 'Scaled initial parameters must be finite.');
            end
            obj.Covariance = P0;
            obj.Forgetting = forgetting;
            obj.Admissibility = admissibility;
        end

        function theta = get.RawParameters(obj)
            theta = obj.Beta ./ obj.ColumnScale;
        end

        function theta = get.Parameters(obj)
            theta = obj.Admissibility(obj.RawParameters);
            if ~isa(theta, 'double') || ~isreal(theta) || ...
                    ~isequal(size(theta), size(obj.Beta)) || any(~isfinite(theta))
                error('RlsEstimator:InvalidMappedParameters', ...
                    'Mapped parameters must be a finite real column of the original size.');
            end
        end

        function info = update(obj, b, Phi)
            %UPDATE Consume one completed measured transition.
            % A rejected update retains beta and P. Finite valid residuals
            % enter the window even if the subsequent RLS arithmetic fails;
            % invalid data or nonfinite residual energy leave it unchanged.
            info = struct('accepted', false, 'lambda', NaN, 'residual', [], ...
                'energy', NaN, 'message', '');
            try
                validateattributes(b, {'double'}, {'column', 'nonempty', 'real', 'finite'});
                validateattributes(Phi, {'double'}, ...
                    {'size', [numel(b) numel(obj.Beta)], 'real', 'finite'});
                if ~isscalar(obj.RowScale) && numel(obj.RowScale) ~= numel(b)
                    error('RlsEstimator:RowScaleSize', 'Row scaling must match the response dimension.');
                end
                response = obj.RowScale .* b;
                regressor = (obj.RowScale .* Phi) ./ obj.ColumnScale.';
                residual = response - regressor * obj.Beta;
                square = sum(residual.^2);
                if any(~isfinite(response)) || any(~isfinite(regressor), 'all') || ~isfinite(square)
                    error('RlsEstimator:NonfiniteRegression', 'Scaled data and residual energy must be finite.');
                end
                info.residual = residual;
                window = [obj.ResidualSquares; square];
                switch char(obj.Forgetting.mode)
                    case 'none'
                        window = window(end);
                        lambda = 1;
                    case 'fixed'
                        window = window(end);
                        lambda = obj.Forgetting.lambda;
                    case 'variable'
                        window = window(max(1, numel(window)-obj.Forgetting.Nf+1):end);
                        % The vector residual norm is not divided by its dimension.
                        info.energy = sqrt(mean(window)) / obj.Forgetting.sigma;
                        lambda = 1;
                        if info.energy > 1
                            lambda = 1 / (1 + obj.Forgetting.eta * ...
                                min(info.energy, obj.Forgetting.gamma));
                        end
                end
                obj.ResidualSquares = window;
                info.lambda = lambda;
                if ~isfinite(lambda) || lambda <= 0
                    error('RlsEstimator:InvalidForgettingFactor', 'The realized forgetting factor must be positive.');
                end
                L = obj.Covariance / lambda;
                S = eye(numel(b)) + regressor * L * regressor.';
                if any(~isfinite(L), 'all') || any(~isfinite(S), 'all')
                    error('RlsEstimator:NonfiniteUpdate', 'The covariance update is nonfinite.');
                end
                RlsEstimator.checkCovariance(S);
                P = L - (L * regressor.') / S * (regressor * L);
                beta = obj.Beta + P * regressor.' * residual;
                RlsEstimator.checkCovariance(P);
                if any(~isfinite(beta)) || any(~isfinite(beta ./ obj.ColumnScale))
                    error('RlsEstimator:NonfiniteUpdate', 'The parameter update is nonfinite.');
                end
                obj.Covariance = P;
                obj.Beta = beta;
                info.accepted = true;
            catch exception
                info.message = exception.message;
            end
        end

        function resetResidualWindow(obj)
            %RESETRESIDUALWINDOW Begin a separate measurement record.
            % This explicit restart preserves the fitted estimate and covariance.
            obj.ResidualSquares = zeros(0, 1);
        end
    end

    methods (Static, Access = private)
        function checkCovariance(P)
            if any(~isfinite(P), 'all') || ...
                    norm(P-P.', 'fro') > 100*eps*max(norm(P, 'fro'), realmin)
                error('RlsEstimator:InvalidCovariance', 'Covariance must be finite and symmetric.');
            end
            [~, flag] = chol(P);
            if flag ~= 0
                error('RlsEstimator:InvalidCovariance', 'Covariance must be positive definite.');
            end
        end

        function checkForgetting(f)
            if ~isstruct(f) || ~isscalar(f) || ~isfield(f, 'mode') || ...
                    ~(ischar(f.mode) || (isstring(f.mode) && isscalar(f.mode))) || ...
                    ~any(strcmp(f.mode, {'none', 'fixed', 'variable'}))
                error('RlsEstimator:InvalidForgetting', 'Forgetting mode must be none, fixed, or variable.');
            end
            if strcmp(f.mode, 'fixed')
                if ~isfield(f, 'lambda')
                    error('RlsEstimator:InvalidForgetting', 'Fixed forgetting requires lambda.');
                end
                validateattributes(f.lambda, {'double'}, {'scalar', 'real', 'finite', 'positive', '<=', 1});
            elseif strcmp(f.mode, 'variable')
                fields = {'Nf', 'sigma', 'eta', 'gamma'};
                if ~all(isfield(f, fields))
                    error('RlsEstimator:InvalidForgetting', 'Variable forgetting requires Nf, sigma, eta, and gamma.');
                end
                validateattributes(f.Nf, {'double'}, {'scalar', 'real', 'finite', 'integer', 'positive'});
                for k = 2:numel(fields)
                    validateattributes(f.(fields{k}), {'double'}, {'scalar', 'real', 'finite', 'positive'});
                end
            end
        end
    end
end
