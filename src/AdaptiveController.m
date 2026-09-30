classdef AdaptiveController < handle
    % ADAPTIVECONTROLLER Measurement-to-next-input sequencing, Eqs. (8), (40).
    %  At step k, CurrentInput is the already committed u(k). PreviousInput
    %  generated the measured transition ending at k. STEP returns u(k+1);
    %  the plant must still apply the committed u(k) for the current interval.
    %  The estimator is a handle carrying fitted coefficients and covariance.
    %  Initialization clears its residual window and invents no transition.
    %  Measurement has model.p entries; reference is model.p-by-N. The state
    %  comes from measured outputs/history, never from evaluator-only truth.
    %  INFO retains identification, frozen prediction and solver diagnostics.
    %  A rejected control holds the committed input; valid identification may
    %  still have occurred. Raw estimates remain separate from mapped parameters.
    properties (SetAccess = private)
        Model
        Estimator
        Settings
        CurrentInput
        PreviousState = []
        PreviousInput = []
        InitialState
        Index = 0
    end

    methods
        function obj = AdaptiveController(model, estimator, settings, initialState, initialInput)
            validateattributes(initialState, {'double'}, ...
                {'real','finite','vector','numel',model.n});
            validateattributes(initialInput, {'double'}, ...
                {'real','finite','vector','numel',model.m});
            if isfield(settings,'Hu') && ~isempty(settings.Hu)
                assert(isfield(settings,'hu') && size(settings.Hu,2) == model.m ...
                    && numel(settings.hu) == size(settings.Hu,1) ...
                    && all(isfinite(settings.Hu(:))) && all(isfinite(settings.hu(:))), ...
                    'AdaptiveController:InputBounds', 'Input-bound dimensions and values must be valid.');
                assert(all(settings.Hu*initialInput(:) <= settings.hu(:)), ...
                    'AdaptiveController:InitialInput', 'The initial committed input must satisfy its bounds.');
            end
            assert(numel(estimator.RawParameters) == model.ntheta, ...
                'AdaptiveController:Parameters', 'Model and estimator dimensions differ.');

            obj.Model = model;
            obj.Estimator = estimator;
            obj.Settings = settings;
            obj.InitialState = initialState(:);
            obj.CurrentInput = initialInput(:);

            % Starting a new record carries the fitted coefficients and
            % covariance, but has no transition and an empty residual window.
            obj.Estimator.resetResidualWindow();
        end

        function [nextInput, info] = step(obj, measurement, reference)
            %STEP Consume only the current measurement and reference preview.
            % History at the first call is supplied in InitialState. Later
            % history states are formed solely from measured transitions.
            validateattributes(measurement, {'double'}, ...
                {'real','vector','numel',obj.Model.p});
            measurement = measurement(:);
            committed = obj.CurrentInput;

            info.index = obj.Index;
            info.committedInput = committed;
            info.transitionInput = obj.PreviousInput;
            info.identification = struct('attempted',false,'accepted',false, ...
                'message','No completed transition is available at initialization.');

            if isempty(obj.PreviousState)
                state = obj.InitialState;
                state(1:obj.Model.p) = measurement;
            else
                state = advance_history(obj.Model, obj.PreviousState, ...
                    measurement, obj.PreviousInput);
                try
                    [b, Phi] = model_regression(obj.Model, obj.PreviousState, ...
                        measurement, obj.PreviousInput);
                    info.identification = obj.Estimator.update(b, Phi);
                    info.identification.attempted = true;
                catch exception
                    info.identification = struct('attempted',true,'accepted',false, ...
                        'message',exception.message);
                end
            end

            info.state = state;
            info.rawParameters = obj.Estimator.RawParameters;
            info.parameters = [];
            info.mappingActivated = false;
            info.prediction = [];
            nextInput = committed;

            try
                parameters = obj.Estimator.Parameters;
                info.parameters = parameters;
                info.mappingActivated = any(parameters ~= info.rawParameters);
                [A, B, c, value] = freeze_predictor(obj.Model, state, committed, parameters);
                info.prediction = struct('A',A,'B',B,'c',c,'value',value);
                qp = assemble_qp(A, B, c, obj.Model.C, state, committed, reference, obj.Settings);
                info.control = solve_mpc(qp);
                if info.control.accepted
                    nextInput = info.control.uNext;
                end
            catch exception
                info.control = struct('accepted',false,'uNext',committed, ...
                    'message',exception.message);
            end

            info.fallback = ~info.control.accepted;
            info.nextInput = nextInput;

            % Even an invalid measurement occupies its actual sample index;
            % never bridge missing data into a fictitious measured transition.
            obj.PreviousState = state;
            obj.PreviousInput = committed;
            obj.CurrentInput = nextInput;
            obj.Index = obj.Index + 1;
        end
    end
end
