function [b,Phi] = model_regression(model,previousState,currentMeasurement,previousInput)
%MODEL_REGRESSION Form a regression using only the completed transition.
%   At k, PREVIOUSINPUT is u(k-1); the already committed u(k) is not used.
%   Direct models use Eq. (8); physical models use endpoint Eq. (21).
validateattributes(previousState,{'numeric'},{'real','finite','size',[model.n,1]});
validateattributes(currentMeasurement,{'numeric'},{'real','finite','size',[model.p,1]});
validateattributes(previousInput,{'numeric'},{'real','finite','size',[model.m,1]});
switch model.kind
    case 'direct'
        z = [previousState;previousInput];
        phi = model.features(z);
        validateattributes(phi,{'numeric'},{'real','finite','size',[model.featureCount,1]});
        if isempty(model.known)
            supplied = zeros(model.p,1);
        else
            supplied = model.known(z);
            validateattributes(supplied,{'numeric'},{'real','finite','size',[model.p,1]});
        end
        b = currentMeasurement-supplied;
        Phi = kron(phi.',eye(model.p))*model.sharing;
    case 'physical'
        b = model.Ts*previousInput;
        Phi = [currentMeasurement-previousState, ...
            (model.Ts/2)*(previousState^3+currentMeasurement^3)];
    otherwise
        error('ejc:UnknownModel','Unknown model kind.');
end
end
