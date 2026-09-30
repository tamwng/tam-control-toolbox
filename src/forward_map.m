function [next,A,B] = forward_map(model,xi,u,theta)
% FORWARD_MAP Reconstruct a nonlinear predictor with fixed coefficients.
%  XI, U and THETA are columns of lengths model.n, model.m and model.ntheta.
%  NEXT is model.n-by-1; A and B are its n-by-n and n-by-m Jacobians with
%  THETA held fixed. A has state/state units and B has state/input units.
%  Direct models reconstruct the output and shift the measured-history state.
%  Physical prediction requires J>0 and d>=0. Its state and sensitivities use
%  the same RK4 stages; this numerical flow need not be linear in theta.
%  Nonfinite predictions or derivatives raise an error; no value is clipped.
validateattributes(xi,{'numeric'},{'real','finite','size',[model.n,1]});
validateattributes(u,{'numeric'},{'real','finite','size',[model.m,1]});
validateattributes(theta,{'numeric'},{'real','finite','size',[model.ntheta,1]});
switch model.kind
    case 'direct'
        z = [xi;u];
        [phi,Jphi] = model.features(z);
        validateattributes(phi,{'numeric'},{'real','finite','size',[model.featureCount,1]});
        validateattributes(Jphi,{'numeric'},{'real','finite','size',[model.featureCount,model.n+model.m]});
        if isempty(model.known)
            supplied = zeros(model.p,1);
            Jknown = zeros(model.p,model.n+model.m);
        else
            [supplied,Jknown] = model.known(z);
            validateattributes(supplied,{'numeric'},{'real','finite','size',[model.p,1]});
            validateattributes(Jknown,{'numeric'},{'real','finite','size',[model.p,model.n+model.m]});
        end
        % Reconstruct output coefficients before applying the known history shifts.
        coefficients = reshape(model.sharing*theta,model.p,model.featureCount);
        output = supplied+coefficients*phi;
        Joutput = Jknown+coefficients*Jphi;
        next = advance_history(model,xi,output,u);
        A = zeros(model.n);
        B = zeros(model.n,model.m);
        A(1:model.p,:) = Joutput(:,1:model.n);
        B(1:model.p,:) = Joutput(:,model.n+1:end);
        if model.ell > 1
            shiftedOutputs = model.p*(model.ell-1);
            A(model.p+1:model.p*model.ell,1:shiftedOutputs) = eye(shiftedOutputs);
            B(model.p*model.ell+(1:model.m),:) = eye(model.m);
            shiftedInputs = model.m*(model.ell-2);
            A(model.p*model.ell+model.m+(1:shiftedInputs), ...
                model.p*model.ell+(1:shiftedInputs)) = eye(shiftedInputs);
        end
    case 'physical'
        if theta(1) <= 0 || theta(2) < 0
            error('ejc:InadmissibleParameters','Physical prediction requires J>0 and d>=0.');
        end
        h = model.Ts/model.nSubsteps;
        state = [xi;1;0];
        for j = 1:model.nSubsteps
            k1 = cubic_tangent(state,u,theta);
            k2 = cubic_tangent(state+h*k1/2,u,theta);
            k3 = cubic_tangent(state+h*k2/2,u,theta);
            k4 = cubic_tangent(state+h*k3,u,theta);
            state = state+(h/6)*(k1+2*k2+2*k3+k4);
        end
        next = state(1);
        A = state(2);
        B = state(3);
    otherwise
        error('ejc:UnknownModel','Unknown model kind.');
end
if any(~isfinite([next(:);A(:);B(:)]))
    error('ejc:InvalidPrediction','Prediction or derivative is nonfinite.');
end
end

function derivative = cubic_tangent(state,u,theta)
J = theta(1);
d = theta(2);
slope = -3*d*state(1)^2/J;
derivative = [(u-d*state(1)^3)/J;slope*state(2);slope*state(3)+1/J];
end
