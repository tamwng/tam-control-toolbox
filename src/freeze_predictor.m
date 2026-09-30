function [A,B,c,value] = freeze_predictor(model,xi,u,theta)
% FREEZE_PREDICTOR Retain value and Jacobian at one prediction origin.
%  For column state XI and committed input U, return A (n-by-n), B (n-by-m),
%  C (n-by-1 affine offset) and VALUE=F(XI,U;THETA), Eqs. (32)-(34).
%  The lowercase output c has state units; it is not the output selector C.
%  Keep A, B and c fixed over the whole horizon. The offset gives contact
%  at the origin; it does not make the nonlinear predictor globally affine.
[value,A,B] = forward_map(model,xi,u,theta);
c = value-A*xi-B*u;
end
