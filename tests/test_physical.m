function tests = test_physical
%TEST_PHYSICAL Minimal integrated-identification and propagation fixtures.
tests = functiontests(localfunctions);
end

function test_endpointRegressionAndIndependentIntegral(testCase)
J = 1.1; d = 0.6; x0 = 0.9; Ts = 0.1;
model = physical_model(Ts);
x1 = x0/sqrt(1+2*d*Ts*x0^2/J);
[b,Phi] = model_regression(model,x0,x1,0);
verifyEqual(testCase,b,0);
verifyEqual(testCase,Phi,[x1-x0,(Ts/2)*(x0^3+x1^3)],'AbsTol',2e-15);
% The exact zero-input trajectory supplies an evaluator-only integral.
exactIntegral = integral(@(t) (x0./sqrt(1+2*d*x0^2*t/J)).^3,0,Ts, ...
    'AbsTol',1e-13,'RelTol',1e-12);
verifyEqual(testCase,J*(x1-x0)+d*exactIntegral,0,'AbsTol',2e-14);
verifyGreaterThan(testCase,abs(Phi*[J;d]-b),1e-6);
verifyEqual(testCase,model.nSubsteps,5);
verifyEqual(testCase,advance_history(model,x0,x1,0),x1);
end

function test_endpointQuadratureRefinement(testCase)
J = 1.1; d = 0.6; x0 = 0.9;
sampling = [0.1,0.05,0.025];
errors = zeros(size(sampling));
for j = 1:numel(sampling)
    Ts = sampling(j);
    x1 = x0/sqrt(1+2*d*Ts*x0^2/J);
    exactIntegral = (J/d)*(x0-x1);
    trapezoid = Ts*(x0^3+x1^3)/2;
    errors(j) = abs(trapezoid-exactIntegral);
end
% A single-interval trapezoid has third-order local quadrature error.
verifyGreaterThan(testCase,errors(1)/errors(2),7);
verifyGreaterThan(testCase,errors(2)/errors(3),7);
verifyLessThan(testCase,errors(1)/errors(2),9);
verifyLessThan(testCase,errors(2)/errors(3),9);
end

function test_zeroInputSolutionAndRK4Refinement(testCase)
theta = [0.8;0.7]; x0 = 1.1; Ts = 0.2;
exact = x0/sqrt(1+2*theta(2)*Ts*x0^2/theta(1));
steps = [5 10 20];
errors = zeros(size(steps));
for j = 1:numel(steps)
    value = forward_map(physical_model(Ts,steps(j)),x0,0,theta);
    errors(j) = abs(value-exact);
end
verifyLessThan(testCase,errors(1),2e-7);
verifyLessThan(testCase,errors(2),errors(1)/10);
verifyLessThan(testCase,errors(3),errors(2)/10);
end

function test_nonzeroInputAgainstIndependentSolver(testCase)
theta = [1.2;0.7]; xi = -0.8; u = 0.4; Ts = 0.15;
options = odeset('RelTol',1e-12,'AbsTol',1e-13);
[~,reference] = ode45(@(~,x) (u-theta(2)*x.^3)/theta(1),[0 Ts],xi,options);
coarse = forward_map(physical_model(Ts,5),xi,u,theta);
fine = forward_map(physical_model(Ts,10),xi,u,theta);
verifyEqual(testCase,coarse,reference(end),'AbsTol',1e-8);
verifyLessThan(testCase,abs(fine-reference(end)),abs(coarse-reference(end))/10);
end

function test_sensitivitiesDifferentiateSameRK4Map(testCase)
model = physical_model(0.2,5);
theta = [0.9;0.5]; xi = 0.8; u = -0.3; h = 1e-6;
[value,A,B] = forward_map(model,xi,u,theta);
finiteState = (forward_map(model,xi+h,u,theta)-forward_map(model,xi-h,u,theta))/(2*h);
finiteInput = (forward_map(model,xi,u+h,theta)-forward_map(model,xi,u-h,theta))/(2*h);
verifyEqual(testCase,A,finiteState,'AbsTol',2e-10);
verifyEqual(testCase,B,finiteInput,'AbsTol',2e-10);
[Af,Bf,c] = freeze_predictor(model,xi,u,theta);
verifyEqual(testCase,c+Af*xi+Bf*u,value,'AbsTol',2e-15);
verifyEqual(testCase,[Af Bf],[A B]);
end

function test_affinePhysicalLimitAtEveryHorizon(testCase)
model = physical_model(0.1);
theta = [1.3;0]; xi = -0.2;
inputs = [0.1 0.15 -0.2 0.3 -0.1 0.05];
[A,B,c] = freeze_predictor(model,xi,inputs(1),theta);
verifyEqual(testCase,A,1,'AbsTol',2e-15);
verifyEqual(testCase,B,model.Ts/theta(1),'AbsTol',2e-15);
verifyEqual(testCase,c,0,'AbsTol',2e-15);
nonlinear = xi; affine = xi;
for i = 1:numel(inputs)
    nonlinear = forward_map(model,nonlinear,inputs(i),theta);
    affine = c+A*affine+B*inputs(i);
    analytical = xi+model.Ts*sum(inputs(1:i))/theta(1);
    verifyEqual(testCase,nonlinear,analytical,'AbsTol',2e-15);
    verifyEqual(testCase,affine,nonlinear,'AbsTol',2e-15);
end
end

function test_reconstructionRequiresMappedPhysicalParameters(testCase)
model = physical_model(0.1);
verifyError(testCase,@() forward_map(model,0.3,0.2,[0;0.5]),'ejc:InadmissibleParameters');
verifyError(testCase,@() forward_map(model,0.3,0.2,[1;-0.5]),'ejc:InadmissibleParameters');
end
