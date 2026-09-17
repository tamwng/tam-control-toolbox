function tests = test_controller
tests = functiontests(localfunctions);
end

function testInitializationDoesNotInventTransition(testCase)
[model, estimator, settings] = fixture;
estimator.update(-0.3, [1,-0.8,0.1]);
beta = estimator.Beta;
P = estimator.Covariance;
controller = AdaptiveController(model,estimator,settings,0.2,0.1);
verifyEmpty(testCase,estimator.ResidualSquares);
[~, info] = controller.step(0.2,zeros(1,4));
verifyFalse(testCase,info.identification.attempted);
verifyEqual(testCase,estimator.Beta,beta);
verifyEqual(testCase,estimator.Covariance,P);
verifyEmpty(testCase,info.transitionInput);
verifyTrue(testCase,info.control.accepted,info.control.message);
verifyEqual(testCase,info.prediction.value, ...
    beta.'*[1;0.2;0.1],'AbsTol',1e-14);
end

function testInitialInputMustSatisfyBounds(testCase)
[model,estimator,settings] = fixture;
verifyError(testCase,@() AdaptiveController(model,estimator,settings,0,1.1), ...
    'AdaptiveController:InitialInput');
end

function testMeasuredTransitionThroughNextAppliedInput(testCase)
[model, estimator, settings] = fixture;
theta0 = estimator.RawParameters;
P0 = estimator.Covariance;
controller = AdaptiveController(model,estimator,settings,0.15,-0.05);
x = 0.15;
Phi = zeros(0,3);
b = zeros(0,1);
previousFeature = [];
for k = 0:7
    if k > 0
        Phi(end+1,:) = previousFeature.'; %#ok<AGROW>
        b(end+1,1) = x; %#ok<AGROW>
    end
    committed = controller.CurrentInput;
    [next, info] = controller.step(x,[0.25,0.2,0.15,0.1]);
    % Independent batch solution contains only transitions already observed.
    batch = (P0\eye(3)+Phi.'*Phi)\(P0\theta0+Phi.'*b);
    verifyEqual(testCase,estimator.RawParameters,batch,'AbsTol',2e-11);
    verifyTrue(testCase,info.control.accepted,info.control.message);
    verifyEqual(testCase,info.committedInput,committed);
    verifyEqual(testCase,info.prediction.value, ...
        batch.'*[1;x;committed],'AbsTol',2e-12);
    verifyEqual(testCase,info.control.Y(1),info.prediction.value,'AbsTol',2e-12);
    verifyEqual(testCase,next,info.control.U(:,1),'AbsTol',1e-14);
    verifyEqual(testCase,controller.CurrentInput,next);
    verifyLessThanOrEqual(testCase,abs(next-committed),0.3+1e-7);
    % The fixture's true coefficients are used only AFTER control returns.
    % Its current transition uses committed u(k), not newly computed u(k+1).
    previousFeature = [1;x;committed];
    x = [0.02,0.62,0.43]*previousFeature;
    verifyTrue(testCase,isfinite(x) && abs(x)<5);
end
end

function testUnobservedPlantChangeCannotEnterCurrentUpdate(testCase)
[model, estimatorA, settings] = fixture;
[~, estimatorB] = fixture;
a = AdaptiveController(model,estimatorA,settings,0.2,0.1);
b = AdaptiveController(model,estimatorB,settings,0.2,0.1);
reference = [0.3,0.3,0.3,0.3];
[u1a,~] = a.step(0.2,reference);
[u1b,~] = b.step(0.2,reference);
verifyEqual(testCase,u1a,u1b,'AbsTol',1e-14);
measured1 = 0.18;
[u2a,infoA] = a.step(measured1,reference);
[u2b,infoB] = b.step(measured1,reference);
verifyEqual(testCase,u2a,u2b,'AbsTol',1e-14);
verifyEqual(testCase,infoA.rawParameters,infoB.rawParameters);
% Different future transitions are evaluator-only until the next call.
nextMeasuredA = 0.02+0.6*measured1+0.4*u1a;
nextMeasuredB = nextMeasuredA+0.07;
verifyEqual(testCase,estimatorA.Beta,estimatorB.Beta);
a.step(nextMeasuredA,reference);
b.step(nextMeasuredB,reference);
verifyGreaterThan(testCase,norm(estimatorA.Beta-estimatorB.Beta),1e-5);
end

function testHistoryUsesMeasuredShiftAndCompletedInput(testCase)
model = direct_model(1,1,2,5,@historyFeatures,[],[]);
theta0 = [0.01;0.5;0.1;0.05;0.3];
estimator = RlsEstimator(theta0,eye(5),1,ones(5,1),struct('mode','none'));
[~,~,settings] = fixture;
initial = [0.2;-0.1;0.05];
controller = AdaptiveController(model,estimator,settings,initial,0.08);
[u1,~] = controller.step(0.2,zeros(1,4));
measurement = 0.19;
[~,info] = controller.step(measurement,zeros(1,4));
previousPhi = [1;initial;0.08].';
expected = (eye(5)+previousPhi.'*previousPhi)\ ...
    (theta0+previousPhi.'*measurement);
verifyEqual(testCase,info.rawParameters,expected,'AbsTol',2e-14);
verifyEqual(testCase,info.state,[measurement;0.2;0.08]);
verifyEqual(testCase,info.transitionInput,0.08);
verifyEqual(testCase,info.committedInput,u1);
verifyEqual(testCase,info.prediction.value(2:3),[measurement;u1]);
end

function testInvalidMeasurementDoesNotBridgeTransitions(testCase)
[model,estimator,settings] = fixture;
controller = AdaptiveController(model,estimator,settings,0.1,0.04);
controller.step(0.1,zeros(1,4));
committed = controller.CurrentInput;
beta = estimator.Beta;
P = estimator.Covariance;
[held,bad] = controller.step(NaN,zeros(1,4));
verifyFalse(testCase,bad.identification.accepted);
verifyTrue(testCase,bad.fallback);
verifyEqual(testCase,held,committed);
verifyEqual(testCase,estimator.Beta,beta);
verifyEqual(testCase,estimator.Covariance,P);
[~,recovered] = controller.step(0.12,zeros(1,4));
verifyFalse(testCase,recovered.identification.accepted);
verifyEqual(testCase,estimator.Beta,beta);
verifyTrue(testCase,recovered.control.accepted,recovered.control.message);
[~,valid] = controller.step(0.13,zeros(1,4));
verifyTrue(testCase,valid.identification.accepted);
expectedPhi = [1,0.12,held];
expected = (P\eye(3)+expectedPhi.'*expectedPhi)\ ...
    (P\beta+expectedPhi.'*0.13);
verifyEqual(testCase,estimator.Beta,expected,'AbsTol',2e-12);
end

function testRejectedControlHoldsButKeepsValidIdentification(testCase)
[model,estimator,settings] = fixture;
controller = AdaptiveController(model,estimator,settings,0.1,0.04);
controller.step(0.1,zeros(1,4));
committed = controller.CurrentInput;
before = estimator.Beta;
[held,info] = controller.step(0.3,[NaN,0,0,0]);
verifyTrue(testCase,info.identification.accepted);
verifyGreaterThan(testCase,norm(estimator.Beta-before),1e-3);
verifyTrue(testCase,info.fallback);
verifyEqual(testCase,held,committed);
verifyEqual(testCase,controller.CurrentInput,committed);
end

function testInvalidJacobianHoldsCommittedInput(testCase)
[~,estimator,settings] = fixture;
model = direct_model(1,1,1,3,@affineFeatures,@invalidJacobian,[]);
controller = AdaptiveController(model,estimator,settings,0.1,0.07);
[held,info] = controller.step(0.1,zeros(1,4));
verifyTrue(testCase,info.fallback);
verifyEqual(testCase,held,0.07);
end

function testPhysicalUpdateMapsAfterScaledIdentification(testCase)
model = physical_model(0.1);
map = @(theta) min(max(theta,[0.2;0]),[3;2]);
theta0 = [0.1;2.5];
D = [2;0.5];
P0 = 0.1*eye(2);
estimator = RlsEstimator(theta0,P0,10,D,struct('mode','none'),map);
[~,~,settings] = fixture;
controller = AdaptiveController(model,estimator,settings,0.25,0.1);
[u1,initial] = controller.step(0.25,zeros(1,4));
verifyTrue(testCase,initial.control.accepted,initial.control.message);
verifyTrue(testCase,initial.mappingActivated);
verifyEqual(testCase,initial.parameters,[0.2;2]);
% The supplied measurement is the only additional identification datum.
measurement = 0.26;
[~,info] = controller.step(measurement,zeros(1,4));
scaledPhi = 10*[measurement-0.25,0.05*(0.25^3+measurement^3)]./D.';
scaledResponse = 10*0.1*0.1;
beta = (P0\eye(2)+scaledPhi.'*scaledPhi)\ ...
    (P0\(D.*theta0)+scaledPhi.'*scaledResponse);
verifyTrue(testCase,info.identification.accepted);
verifyEqual(testCase,estimator.RawParameters,beta./D,'AbsTol',1e-13);
verifyEqual(testCase,info.parameters,map(beta./D),'AbsTol',1e-13);
verifyTrue(testCase,info.mappingActivated);
verifyTrue(testCase,info.control.accepted,info.control.message);
expected = forward_map(model,measurement,u1,map(beta./D));
verifyEqual(testCase,info.prediction.value,expected,'AbsTol',1e-13);
end

function [model,estimator,settings] = fixture
model = direct_model(1,1,1,3,@affineFeatures,[],[]);
estimator = RlsEstimator([0.01;0.5;0.3],(100/3)*eye(3), ...
    1,ones(3,1),struct('mode','none'));
settings = struct('Q',reshape([1,1,1,3],1,1,4),'R',0.1, ...
    'Hu',[1;-1],'hu',[1;1],'Hdu',[1;-1],'hdu',[0.3;0.3], ...
    'Hy',[1;-1],'hy',[0.8;0.8],'Seps',100*eye(2));
end

function [phi,J] = affineFeatures(z)
phi = [1;z];
J = [zeros(1,2);eye(2)];
end

function [phi,J] = historyFeatures(z)
phi = [1;z];
J = [zeros(1,4);eye(4)];
end

function [g,J] = invalidJacobian(~)
g = 0;
J = [NaN,0];
end
