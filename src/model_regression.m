function [b,Phi] = model_regression(model,previousState,currentMeasurement,previousInput)
% MODEL_REGRESSION Form a regression from one completed measured transition.
%  PREVIOUSSTATE is model.n-by-1, CURRENTMEASUREMENT is model.p-by-1,
%  and PREVIOUSINPUT is model.m-by-1. At k, the latter is u(k-1); the
%  already committed u(k) did not generate the measured transition.
%  B is the response column and PHI has model.ntheta coefficient columns.
%  Direct models subtract the supplied known contribution, Eq. (8).
%  The scalar physical model uses endpoint trapezoidal integration, Eq. (21):
%  B has impulse units and PHI*theta uses theta=[J;d]. Measurement and
%  quadrature errors remain regression errors, not exact physical identities.
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
