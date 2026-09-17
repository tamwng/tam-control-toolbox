function [A,B,c,value] = freeze_predictor(model,xi,u,theta)
%FREEZE_PREDICTOR Value/Jacobian contact with the offset retained, Eqs. (32)-(34).
%   Keep the returned coefficients fixed throughout a prediction horizon.
[value,A,B] = forward_map(model,xi,u,theta);
c = value-A*xi-B*u;
end
