function state = advance_history(model,previousState,currentMeasurement,previousInput)
%ADVANCE_HISTORY Initialize the next state with measured data (Eqs. (2),(17)).
%   PREVIOUSINPUT is the input that produced CURRENTMEASUREMENT.
%   Preserve a nonfinite sample at its time index: regression and prediction
%   reject it, rather than joining transitions across a missing measurement.
validateattributes(previousState,{'numeric'},{'real','size',[model.n,1]});
validateattributes(currentMeasurement,{'numeric'},{'real','size',[model.p,1]});
validateattributes(previousInput,{'numeric'},{'real','size',[model.m,1]});
state = currentMeasurement;
if strcmp(model.kind,'direct') && model.ell > 1
    state = [state;previousState(1:model.p*(model.ell-1)); ...
        previousInput;previousState(model.p*model.ell+1: ...
        model.p*model.ell+model.m*(model.ell-2))];
end
end
