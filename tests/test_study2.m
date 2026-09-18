function tests = test_study2
%TEST_STUDY2 Plant B definitions and experiment logic, without ranking tests.
tests = functiontests(localfunctions);
end

function testPilotWrapperRetainsRejectedControl(testCase)
cfg = study2_settings;
record = study2_record(200,1.10,cfg.inputSeed,cfg);
cfg.K = 3;
cfg.control.R = 0; % Deliberately invalid QP setting checks the wrapper path.
for id = {'E','K'}
    [~,fit] = study2_fit(id{1},record,cfg);
    result = study2_trajectory(id{1},fit,.2,cfg);
    verifyTrue(testCase,result.completed);
    verifyFalse(testCase,any(result.controlAccepted));
    verifyEqual(testCase,result.u,zeros(1,4));
    verifyEqual(testCase,nnz(strcmp({result.events.stage},'control')),3);
    verifyEqual(testCase,nnz(strcmp({result.events.stage},'diagnostic')),3);
end
end

function setupOnce(testCase)
testCase.TestData.previousPath = path;
root = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(root,'studies','study2'));
end

function teardownOnce(testCase)
path(testCase.TestData.previousPath);
end

function testOrderedDictionariesAndPriors(testCase)
ids = {'A','E','O3','O5','P3'};
counts = [3,3,4,5,10];
x = -0.6; u = 0.8;
rows = {[1,x,u],[1,x,sin(u)],[1,x,u,u^3], ...
    [1,x,u,u^3,u^5],[1,x,u,x^2,x*u,u^2,x^3,x^2*u,x*u^2,u^3]};
for j = 1:numel(ids)
    [model,theta,labels,name] = study2_model(ids{j});
    [~,row] = model_regression(model,x,0,u);
    verifyEqual(testCase,model.ntheta,counts(j));
    verifyEqual(testCase,numel(labels),counts(j));
    verifyNotEmpty(testCase,name);
    verifyEqual(testCase,row,rows{j},'AbsTol',2e-15);
    [value,A,B] = forward_map(model,0,0,theta);
    verifyEqual(testCase,[value,A,B],[0,0.5,0.25],'AbsTol',1e-15);
    expected = 0.5*x+0.25*u;
    if strcmp(ids{j},'E')
        expected = 0.5*x+0.25*sin(u);
    end
    verifyEqual(testCase,forward_map(model,x,u,theta),expected,'AbsTol',1e-15);
end
verifyError(testCase,@() study2_model('S'),'study2:UnknownModel');
end

function testIndependentPowersAndDerivatives(testCase)
x = -0.3; u = 0.7;
theta = [0.1;-0.2;0.3;0.4;0.5];
[value,A,B] = forward_map(study2_model('O5'),x,u,theta);
verifyEqual(testCase,value,theta(1)+theta(2)*x+theta(3)*u+ ...
    theta(4)*u^3+theta(5)*u^5,'AbsTol',1e-15);
verifyEqual(testCase,[A,B],[theta(2),theta(3)+3*theta(4)*u^2+ ...
    5*theta(5)*u^4],'AbsTol',1e-15);
theta3 = theta(1:4);
verifyEqual(testCase,forward_map(study2_model('O3'),x,u,theta3), ...
    theta3.'*[1;x;u;u^3],'AbsTol',1e-15);
model = study2_model('P3');
theta = (1:10).'/13;
[value,A,B] = forward_map(model,x,u,theta);
verifyEqual(testCase,value,theta.'*[1;x;u;x^2;x*u;u^2;x^3;x^2*u;x*u^2;u^3], ...
    'AbsTol',1e-15);
expectedA = theta(2)+2*theta(4)*x+theta(5)*u+3*theta(7)*x^2+ ...
    2*theta(8)*x*u+theta(9)*u^2;
expectedB = theta(3)+theta(5)*x+2*theta(6)*u+theta(8)*x^2+ ...
    2*theta(9)*x*u+3*theta(10)*u^2;
verifyEqual(testCase,[A,B],[expectedA,expectedB],'AbsTol',2e-15);
end

function testExactSinePlantAndConstraintAuditFacts(testCase)
x = linspace(-1.2,1.2,13);
u = linspace(-1.2,1.2,13);
verifyEqual(testCase,study2_plant(x,u),0.03+0.65*x+0.40*sin(u));
[known,theta] = study2_model('K');
exact = study2_model('E');
verifyEqual(testCase,theta,[0.03;0.65;0.40]);
for j = 1:numel(x)
    expected = study2_plant(x(j),u(j));
    verifyEqual(testCase,forward_map(known,x(j),u(j),theta),expected,'AbsTol',1e-15);
    [value,A,B] = forward_map(exact,x(j),u(j),theta);
    verifyEqual(testCase,[value,A,B],[expected,0.65,0.40*cos(u(j))],'AbsTol',1e-15);
end
verifyGreaterThan(testCase,min(0.40*cos(u)),0);
verifyEqual(testCase,study2_plant(1.4,0),0.94,'AbsTol',2e-16);
verifyEqual(testCase,study2_plant(1.4,0)-0.85,0.09,'AbsTol',2e-16);
verifyEqual(testCase,1.4-0.85,0.55,'AbsTol',2e-16);
end

function testReferenceAndSeparateExperimentalVariables(testCase)
cfg = study2_settings;
verifyEqual(testCase,cfg.amplitudes,[0.2 0.6 1]);
verifyEqual(testCase,cfg.evaluationRanges,[0.25 0.70 1.10]);
verifyEqual(testCase,[cfg.Ts,cfg.N,cfg.duration,cfg.K],[0.1,10,80,800]);
verifyEqual(testCase,cfg.control.hu,[1.2;1.2]);
verifyEqual(testCase,cfg.control.hdu,[0.25;0.25]);
verifyEqual(testCase,cfg.control.hy,[1.2;1.2]);
verifyEqual(testCase,cfg.control.Q,reshape([ones(1,9),10],1,1,10));
verifyEqual(testCase,cfg.control.R,0.05);
verifyEqual(testCase,cfg.control.Seps,1e4*eye(2));
for amplitude = cfg.amplitudes
    verifyEqual(testCase,study2_reference([0,5,10,15,20],amplitude), ...
        0.08+amplitude*[0,1,0,-1,0],'AbsTol',1e-15);
    verifyEqual(testCase,size(study2_reference((0:3).',amplitude)),[4,1]);
end
before = study2_record(200,cfg.initializationRange,cfg.inputSeed,cfg);
changed = cfg;
changed.amplitudes = 0.4;
changed.evaluationRanges = 0.6;
verifyEqual(testCase,before,study2_record(200,cfg.initializationRange,cfg.inputSeed,changed));
end

function testIndependentRecordsAndLocalStreams(testCase)
cfg = study2_settings;
globalState = rng;
record = study2_record(200,1.10,cfg.inputSeed,cfg);
verifyEqual(testCase,rng,globalState);
verifyEqual(testCase,record,study2_record(200,1.10,cfg.inputSeed,cfg));
verifyEqual(testCase,size(record.x),[1,201]);
verifyEqual(testCase,[record.x(1),record.u(1)],[0,0]);
verifyEqual(testCase,record.y,record.x);
records = cell(1,3);
for j = 1:3
    L = cfg.evaluationRanges(j);
    records{j} = study2_record(600,L,cfg.evaluationSeeds(j),cfg);
    candidate = records{j};
    verifyEqual(testCase,size(candidate.x),[1,601]);
    verifyLessThanOrEqual(testCase,max(abs(candidate.u)),L);
    verifyLessThanOrEqual(testCase,max(abs(diff(candidate.u))),0.25+eps);
    verifyTrue(testCase,all(ismember(candidate.target,L*[-1,-0.5,0,0.5,1])));
    verifyEqual(testCase,reshape(candidate.target,5,[]), ...
        repmat(candidate.target(1:5:end),5,1));
    verifyEqual(testCase,candidate.x(2:end),0.03+0.65*candidate.x(1:end-1)+ ...
        0.40*sin(candidate.u),'AbsTol',1e-15);
    verifyNotEqual(testCase,record.target/record.L,candidate.target(1:200)/L);
end
verifyNotEqual(testCase,records{1}.target/records{1}.L,records{2}.target/records{2}.L);
verifyNotEqual(testCase,records{2}.target/records{2}.L,records{3}.target/records{3}.L);
verifyEqual(testCase,rng,globalState);
end

function testFixedCalibrationAndFitTransfer(testCase)
cfg = study2_settings;
record = study2_record(200,1.10,cfg.inputSeed,cfg);
[gridX,gridU] = ndgrid(linspace(-1.2,1.2,41),linspace(-1.2,1.2,41));
x = gridX(:); u = gridU(:);
grids = {[ones(size(x)),x,u],[ones(size(x)),x,sin(u)], ...
    [ones(size(x)),x,u,u.^3],[ones(size(x)),x,u,u.^3,u.^5], ...
    [ones(size(x)),x,u,x.^2,x.*u,u.^2,x.^3,x.^2.*u,x.*u.^2,u.^3]};
for j = 1:5
    id = cfg.modelIds{j};
    [estimator,fit] = study2_fit(id,record,cfg);
    verifyEqual(testCase,fit.D,sqrt(mean(grids{j}.^2,1)).','AbsTol',1e-14);
    verifyEqual(testCase,fit.P0,(100/fit.nEstimated)*eye(fit.nEstimated));
    verifyEqual(testCase,fit.theta(:,1),fit.theta0);
    verifyEqual(testCase,fit.beta,fit.D.*fit.theta,'AbsTol',2e-15);
    verifyEqual(testCase,fit.checkpointTheta,fit.theta(:,cfg.fitSteps+1));
    verifyEqual(testCase,fit.checkpointCovariance,fit.covariance(:,:,cfg.fitSteps+1));
    verifyTrue(testCase,all(fit.accepted));
    verifyEqual(testCase,fit.lambda,ones(1,200));
    beta = estimator.Beta;
    covariance = estimator.Covariance;
    controller = AdaptiveController(study2_model(id),estimator,cfg.control,0,0);
    [~,info] = controller.step(0,study2_reference(cfg.Ts*(1:cfg.N),0.2));
    verifyFalse(testCase,info.identification.attempted);
    verifyEqual(testCase,estimator.Beta,beta);
    verifyEqual(testCase,estimator.Covariance,covariance);
end
end

function testKnownReferenceDoesNotFitData(testCase)
cfg = study2_settings;
record = study2_record(200,1.10,cfg.inputSeed,cfg);
record.y(:) = NaN;
[estimator,fit] = study2_fit('K',record,cfg);
verifyEmpty(testCase,estimator);
verifyEqual(testCase,fit.nEstimated,0);
verifyFalse(testCase,any(fit.attempted));
verifyEqual(testCase,fit.theta,repmat([0.03;0.65;0.40],1,201));
verifyEqual(testCase,size(fit.covariance),[0,0,201]);
verifyTrue(testCase,all(isnan(fit.lambda)));
end
