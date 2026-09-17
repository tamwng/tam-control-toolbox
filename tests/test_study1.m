function tests = test_study1
%TEST_STUDY1 Bounded protocol checks; no scientific performance ranking.
tests = functiontests(localfunctions);
end

function setupOnce(testCase)
testCase.TestData.previousPath = path;
root = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(root,'studies','study1'));
end

function teardownOnce(testCase)
path(testCase.TestData.previousPath);
end

function testOrderedModelsAndInitialContact(testCase)
ids = {'A','S','W','R','P2'};
counts = [3,3,3,4,6];
x = -0.6; u = 0.4;
rows = {[1,x,u],[1,x,(1+0.35*x)*u], ...
    [1,x,(1-0.35*x)*u],[1,x,u,x*u],[1,x,u,x^2,x*u,u^2]};
for j = 1:numel(ids)
    [model,theta] = study1_model(ids{j});
    [~,row] = model_regression(model,x,0,u);
    verifyEqual(testCase,model.ntheta,counts(j));
    verifyEqual(testCase,row,rows{j},'AbsTol',1e-15);
    [value,A,B] = forward_map(model,0,0,theta);
    verifyEqual(testCase,[value,A,B],[0,0.5,0.25],'AbsTol',1e-15);
    if any(strcmp(ids{j},{'S','R','P2'}))
        expected = 0.5*x+0.25*(1+0.35*x)*u;
        verifyEqual(testCase,forward_map(model,x,u,theta),expected,'AbsTol',1e-15);
    end
end
end

function testExactRepresentationsAndKnownModel(testCase)
x = linspace(-1.2,1.2,9);
u = linspace(-1,1,9);
ids = {'S','R','P2'};
targets = {[0.03;0.65;0.45],[0.03;0.65;0.45;0.45*0.35], ...
    [0.03;0.65;0.45;0;0.45*0.35;0]};
for m = 1:numel(ids)
    model = study1_model(ids{m});
    for j = 1:numel(x)
        expected = 0.03+0.65*x(j)+0.45*(1+0.35*x(j))*u(j);
        verifyEqual(testCase,forward_map(model,x(j),u(j),targets{m}),expected,'AbsTol',3e-15);
    end
end
[known,theta] = study1_model('K');
verifyEqual(testCase,theta,[0.03;0.65;0.45]);
verifyEqual(testCase,forward_map(known,-0.3,0.6,theta), ...
    study1_plant(-0.3,0.6),'AbsTol',1e-15);
verifyEqual(testCase,study1_plant(x,u),0.03+0.65*x+0.45*(1+0.35*x).*u);
end

function testReferenceAndPrescribedEquilibriumAuthority(testCase)
times = [0,19.9,20,39.9,40,60,80,100,120,121];
verifyEqual(testCase,study1_reference(times),[0.6,0.6,-0.5,-0.5,0.75,-0.4,0.6,0,0,0]);
verifyEqual(testCase,size(study1_reference(times.')),size(times.'));
levels = study1_reference(0:20:100);
for b = [0.45,0.30]
    equilibrium = ((1-0.65)*levels-0.03)./(b*(1+0.35*levels));
    verifyLessThanOrEqual(testCase,max(abs(equilibrium)),1);
    verifyEqual(testCase,0.03+0.65*levels+b*(1+0.35*levels).*equilibrium, ...
        levels,'AbsTol',2e-16);
end
end

function testLocalStreamsAndRateLimitedRecords(testCase)
cfg = study1_settings;
globalState = rng;
record = study1_record(200,0.5,cfg.confirmation.inputSeed,cfg);
verifyEqual(testCase,rng,globalState);
verifyEqual(testCase,record,study1_record(200,0.5,cfg.confirmation.inputSeed,cfg));
verifyEqual(testCase,size(record.x),[1,201]);
verifyEqual(testCase,record.u(1),0);
verifyEqual(testCase,record.x(1),0);
verifyEqual(testCase,record.y,record.x);
verifyLessThanOrEqual(testCase,max(abs(diff(record.u))),0.25);
verifyLessThanOrEqual(testCase,max(abs(record.u)),0.5);
verifyTrue(testCase,all(ismember(record.target,0.5*[-1,-0.5,0,0.5,1])));
verifyEqual(testCase,reshape(record.target,5,[]), ...
    repmat(record.target(1:5:end),5,1));
expected = 0.03+0.65*record.x(1:end-1)+ ...
    0.45*(1+0.35*record.x(1:end-1)).*record.u;
verifyEqual(testCase,record.x(2:end),expected,'AbsTol',1e-15);
evaluation = study1_record(600,0.5,cfg.confirmation.evaluationSeed,cfg);
verifyNotEqual(testCase,record.target,evaluation.target(1:200));
first = RandStream('mt19937ar','Seed',cfg.confirmation.initialNoiseBase+1);
second = RandStream('mt19937ar','Seed',cfg.confirmation.controlNoiseBase+1);
paired = RandStream('mt19937ar','Seed',cfg.confirmation.initialNoiseBase+1);
initialNoise = randn(first,1,201);
verifyEqual(testCase,initialNoise,randn(paired,1,201));
verifyNotEqual(testCase,initialNoise,randn(second,1,201));
end

function testScaledFitMatchesIndependentBatch(testCase)
cfg = study1_settings;
record = study1_record(200,0.5,cfg.pilot.inputSeed,cfg);
for id = {'A','S','W','R','P2'}
    [estimator,fit] = study1_fit(id{1},record,cfg);
    n = fit.nEstimated;
    x = record.y(1:end-1).'; u = record.u.';
    [gridX,gridU] = ndgrid(linspace(-1.2,1.2,41),linspace(-1,1,41));
    switch id{1}
        case 'A'
            Phi = [ones(200,1),x,u];
            grid = [ones(1681,1),gridX(:),gridU(:)];
        case 'S'
            Phi = [ones(200,1),x,(1+0.35*x).*u];
            grid = [ones(1681,1),gridX(:),(1+0.35*gridX(:)).*gridU(:)];
        case 'W'
            Phi = [ones(200,1),x,(1-0.35*x).*u];
            grid = [ones(1681,1),gridX(:),(1-0.35*gridX(:)).*gridU(:)];
        case 'R'
            Phi = [ones(200,1),x,u,x.*u];
            grid = [ones(1681,1),gridX(:),gridU(:),gridX(:).*gridU(:)];
        case 'P2'
            Phi = [ones(200,1),x,u,x.^2,x.*u,u.^2];
            grid = [ones(1681,1),gridX(:),gridU(:),gridX(:).^2, ...
                gridX(:).*gridU(:),gridU(:).^2];
    end
    D = sqrt(mean(grid.^2,1)).';
    verifyEqual(testCase,fit.D,D,'AbsTol',1e-14);
    normalized = Phi./D.';
    priorPrecision = (n/100)*eye(n);
    priorBeta = D.*fit.theta0;
    for j = 1:numel(cfg.fitSteps)
        last = cfg.fitSteps(j);
        data = normalized(1:last,:);
        batchP = (priorPrecision+data.'*data)\eye(n);
        batchBeta = batchP*(priorPrecision*priorBeta+data.'*record.y(2:last+1).');
        verifyEqual(testCase,fit.checkpointTheta(:,j),batchBeta./D,'AbsTol',1e-10);
        verifyEqual(testCase,fit.checkpointCovariance(:,:,j),batchP,'AbsTol',1e-10);
    end
    verifyTrue(testCase,all(fit.accepted));
    verifyEqual(testCase,fit.lambda,ones(1,200));
    beta = estimator.Beta; covariance = estimator.Covariance;
    controller = AdaptiveController(study1_model(id{1}),estimator,cfg.control,0,0);
    [~,info] = controller.step(0,study1_reference(cfg.Ts*(1:cfg.N)));
    verifyFalse(testCase,info.identification.attempted);
    verifyEqual(testCase,estimator.Beta,beta);
    verifyEqual(testCase,estimator.Covariance,covariance);
end
end

function testRejectedFitPreservesStateAndKnownReferenceHasNoUpdates(testCase)
cfg = study1_settings;
record = study1_record(200,0.5,cfg.pilot.inputSeed,cfg);
record.y(51) = NaN;
[~,fit] = study1_fit('S',record,cfg);
verifyFalse(testCase,fit.accepted(50));
verifyFalse(testCase,fit.accepted(51));
verifyEqual(testCase,fit.theta(:,51:52),repmat(fit.theta(:,50),1,2));
verifyEqual(testCase,fit.covariance(:,:,51),fit.covariance(:,:,50));
verifyEqual(testCase,fit.covariance(:,:,52),fit.covariance(:,:,50));
verifyTrue(testCase,fit.accepted(52));
[estimator,known] = study1_fit('K',record,cfg);
verifyEmpty(testCase,estimator);
verifyEqual(testCase,known.nEstimated,0);
verifyFalse(testCase,any(known.attempted));
verifyEqual(testCase,known.theta,repmat([0.03;0.65;0.45],1,201));
verifyEqual(testCase,size(known.covariance),[0,0,201]);
verifyTrue(testCase,all(isnan(known.lambda)));
end

function testStudyTrajectoryTimingAndRejectedComputation(testCase)
cfg = study1_settings;
training = study1_record(200,0.5,cfg.pilot.inputSeed,cfg);
cfg.K = 3;
for id = {'S','K'}
    [estimator,fit] = study1_fit(id{1},training,cfg);
    run = study1_trajectory(id{1},fit,estimator,zeros(1,4),cfg);
    verifyTrue(testCase,run.completed);
    verifyEqual(testCase,run.theta(:,1),fit.theta(:,end));
    verifyFalse(testCase,run.idAttempted(1));
    verifyEqual(testCase,run.x(2:end), ...
        .03+.65*run.x(1:end-1)+.45*(1+.35*run.x(1:end-1)).*run.u(1:end-1),'AbsTol',1e-15);
    bad = cfg; bad.control.R = 0;
    [estimator,fit] = study1_fit(id{1},training,cfg);
    held = study1_trajectory(id{1},fit,estimator,zeros(1,4),bad);
    verifyFalse(testCase,any(held.controlAccepted));
    verifyEqual(testCase,held.u,zeros(1,4));
    verifyTrue(testCase,held.completed);
    verifyEqual(testCase,nnz(strcmp({held.events.stage},'control')),3);
end
end
