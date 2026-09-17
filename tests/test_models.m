function tests = test_models
%TEST_MODELS Deterministic construction, reconstruction, and prediction checks.
tests = functiontests(localfunctions);
end

function test_orderedMonomialsAndCenteredDerivatives(testCase)
powers = [0 0;1 0;0 1;2 0;1 1;0 3];
[phi,J] = polynomial_features([2;-1],powers,[1;1]);
verifyEqual(testCase,phi,[1;1;-2;1;-2;-8]);
verifyEqual(testCase,J,[0 0;1 0;0 1;2 0;-2 1;0 12]);
[phiAtCenter,JAtCenter] = polynomial_features([1;1],powers,[1;1]);
verifyEqual(testCase,phiAtCenter,[1;0;0;0;0;0]);
verifyEqual(testCase,JAtCenter,[0 0;1 0;0 1;0 0;0 0;0 0]);
verifyError(testCase,@() polynomial_features([1;1],[0 0;0 0]),'ejc:InvalidPowers');
end

function test_independentCoefficientOrdering(testCase)
powers = [0 0 0;1 0 0;0 0 1];
model = direct_model(2,1,1,3,@(z) polynomial_features(z,powers));
theta = [1;2;3;4;5;6];
xi = [0.7;-0.2];
u = -0.3;
verifyEqual(testCase,model.ntheta,6);
verifyEqual(testCase,model.C,eye(2));
expected = [1+3*xi(1)+5*u;2+4*xi(1)+6*u];
[b,Phi] = model_regression(model,xi,expected,u);
verifyEqual(testCase,Phi,[1 0 xi(1) 0 u 0;0 1 0 xi(1) 0 u]);
verifyEqual(testCase,b,Phi*theta,'AbsTol',2e-15);
verifyEqual(testCase,forward_map(model,xi,u,theta),expected,'AbsTol',2e-15);
end

function test_sharedCoefficientsAndKnownContribution(testCase)
powers = [0 0 0;1 0 0;0 0 1];
sharing = [1 0 0 0;0 1 0 0;0 0 1 0;0 0 2 0;0 0 0 1;0 0 0 -1];
model = direct_model(2,1,1,3,@(z) polynomial_features(z,powers),@known_pair,sharing);
theta = [0.2;-0.1;0.6;0.4];
xi = [0.35;-0.45];
u = 0.25;
expected = [theta(1)+theta(3)*xi(1)+theta(4)*u+sin(xi(2)); ...
    theta(2)+2*theta(3)*xi(1)-theta(4)*u+xi(1)*xi(2)];
[b,Phi] = model_regression(model,xi,expected,u);
verifyEqual(testCase,model.ntheta,4);
verifyEqual(testCase,b,Phi*theta,'AbsTol',2e-15);
[value,A,B] = forward_map(model,xi,u,theta);
verifyEqual(testCase,value,expected,'AbsTol',2e-15);
verifyEqual(testCase,A,[theta(3),cos(xi(2));2*theta(3)+xi(2),xi(1)],'AbsTol',2e-15);
verifyEqual(testCase,B,[theta(4);-theta(4)],'AbsTol',2e-15);
verifyError(testCase,@() direct_model(2,1,1,3,@(z) polynomial_features(z,powers),[],ones(6,2)), ...
    'ejc:InvalidSharing');
end

function test_exactNonpolynomialModel(testCase)
model = direct_model(1,1,1,3,@sine_features);
theta = [0.2;0.6;-0.3];
xi = -0.4;
u = 0.7;
[value,A,B] = forward_map(model,xi,u,theta);
verifyEqual(testCase,value,theta(1)+theta(2)*xi+theta(3)*sin(u),'AbsTol',2e-15);
verifyEqual(testCase,A,theta(2));
verifyEqual(testCase,B,theta(3)*cos(u),'AbsTol',2e-15);
[a,b,c] = freeze_predictor(model,xi,u,theta);
verifyEqual(testCase,c,theta(1)+theta(3)*(sin(u)-u*cos(u)),'AbsTol',2e-15);
verifyEqual(testCase,a,A);
verifyEqual(testCase,b,B);
end

function test_measuredAndPredictedHistoryShifts(testCase)
p = 2; m = 2; ell = 3;
n = p*ell+m*(ell-1);
model = direct_model(p,m,ell,1,@(z) polynomial_features(z,zeros(1,n+m)));
previous = (1:n).';
measurement = [-3;-4];
previousInput = [11;12];
expected = [measurement;1;2;3;4;11;12;7;8];
verifyEqual(testCase,advance_history(model,previous,measurement,previousInput),expected);
[value,A,B] = forward_map(model,previous,previousInput,measurement);
verifyEqual(testCase,value,expected);
verifyEqual(testCase,model.C*value,measurement);
verifyEqual(testCase,A(3:6,1:4),eye(4));
verifyEqual(testCase,B(7:8,:),eye(2));
verifyEqual(testCase,A(9:10,7:8),eye(2));
verifyEqual(testCase,nnz(A),6);
verifyEqual(testCase,nnz(B),2);
short = direct_model(2,2,1,1,@(z) polynomial_features(z,zeros(1,4)));
verifyEqual(testCase,advance_history(short,[1;2],measurement,previousInput),measurement);
end

function test_jacobianAgainstCentralDifferences(testCase)
powers = [0 0 0;1 0 0;0 1 0;0 0 1;2 0 0;1 1 0;0 1 2];
model = direct_model(2,1,1,7,@(z) polynomial_features(z,powers,[0.2;-0.1;0.3]),@known_pair);
theta = (1:14).'/17;
z = [-0.5;0.7;0.2];
[~,A,B] = forward_map(model,z(1:2),z(3),theta);
numeric = zeros(2,3);
h = 1e-6;
for j = 1:3
    plus = z; minus = z;
    plus(j) = plus(j)+h;
    minus(j) = minus(j)-h;
    numeric(:,j) = (forward_map(model,plus(1:2),plus(3),theta)- ...
        forward_map(model,minus(1:2),minus(3),theta))/(2*h);
end
verifyEqual(testCase,[A B],numeric,'AbsTol',5e-10);
end

function test_nonlinearAffineContactAndFirstStep(testCase)
model = direct_model(1,1,1,3,@sine_features,@known_square);
theta = [0.1;0.5;0.4];
xi = 0.7; u = -0.4;
[A,B,c,value] = freeze_predictor(model,xi,u,theta);
[nonlinear,An,Bn] = forward_map(model,xi,u,theta);
verifyEqual(testCase,c+A*xi+B*u,nonlinear,'AbsTol',2e-15);
verifyEqual(testCase,value,nonlinear);
verifyEqual(testCase,[A B],[An Bn]);
verifyEqual(testCase,A,theta(2)+2*xi,'AbsTol',2e-15);
verifyEqual(testCase,value,xi^2+theta(1)+theta(2)*xi+theta(3)*sin(u),'AbsTol',2e-15);
end

function test_completeAffineMapAtEveryHorizon(testCase)
% A history model includes known shift rows as well as its fitted output.
powers = [zeros(1,4);eye(4)];
model = direct_model(1,1,2,5,@(z) polynomial_features(z,powers));
theta = [0.03;0.5;-0.1;0.2;0.4];
initial = [0.2;-0.3;0.1];
inputs = 0.25*sin((0:19)*0.3);
[A,B,c] = freeze_predictor(model,initial,inputs(1),theta);
nonlinear = initial; affine = initial;
for i = 1:numel(inputs)
    nonlinear = forward_map(model,nonlinear,inputs(i),theta);
    affine = c+A*affine+B*inputs(i);
    verifyEqual(testCase,affine,nonlinear,'AbsTol',5e-15);
end
end

function [g,J] = known_pair(z)
g = [sin(z(2));z(1)*z(2)];
J = [0 cos(z(2)) 0;z(2) z(1) 0];
end

function [g,J] = known_square(z)
g = z(1)^2;
J = [2*z(1) 0];
end

function [phi,J] = sine_features(z)
phi = [1;z(1);sin(z(2))];
J = [0 0;1 0;0 cos(z(2))];
end
