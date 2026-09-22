function tests = test_study5
%TEST_STUDY5 Study-specific wiring; generic physical/RLS/QP checks are reused.
tests = functiontests(localfunctions);
end
function setupOnce(testCase)
testCase.TestData.previousPath = path;
root = fileparts(fileparts(mfilename('fullpath')));
for s = [1 2 3 5], addpath(fullfile(root,'studies',sprintf('study%d',s))); end
cfg = study5_settings;
testCase.TestData.cfg = cfg;
testCase.TestData.record = study5_record(200,cfg.inputSeed,cfg);
end
function teardownOnce(testCase)
path(testCase.TestData.previousPath);
end
function testSettingsAndCompleteDirectConstruction(testCase)
cfg = testCase.TestData.cfg; common = study1_settings; common.control.hdu = [.1;.1];
verifyEqual(testCase,cfg.control,common.control);
verifyEqual(testCase,[cfg.Ts cfg.K cfg.N cfg.duration],[.1 800 10 80]);
verifyEqual(testCase,cfg.windows,[0 80;20 80]); verifyEqual(testCase,cfg.forgetting.mode,'none');
verifyEqual(testCase,cfg.modelIds,{'I','D','A','P3','K'});
verifyEqual(testCase,[cfg.plantSubsteps cfg.refinedPlantSubsteps cfg.predictorSubsteps cfg.refinedPredictorSubsteps],[20 40 5 10]);
x = -.37; u = .62; y = .4;
for id = ["D","A","P3"]
    [model,theta] = study5_model(id,cfg);
    [b,Phi] = model_regression(model,x,y,u);
    value = x+cfg.Ts/.8*u;
    if id == "D"
        verifyEqual(testCase,b,y-x); verifyEqual(testCase,Phi,[u x^3]);
    else
        expected = [1 x u x^2 x*u u^2 x^3 x^2*u x*u^2 u^3];
        verifyEqual(testCase,b,y); verifyEqual(testCase,Phi,expected(1:model.ntheta),'AbsTol',1e-15);
    end
    if id ~= "A", value = value-.3*cfg.Ts/.8*x^3; end
    verifyEqual(testCase,forward_map(model,x,u,theta),value,'AbsTol',1e-15);
    if id == "A"
        theta = [.3;-.7;.2];
        verifyEqual(testCase,forward_map(model,x,u,theta),.3-.7*x+.2*u,'AbsTol',1e-15);
    end
end
verifyEqual(testCase,study5_reference([0 5 10 15 20]),[0 .7 0 -.7 0],'AbsTol',1e-15);
end
function testNewCommonRecordAndEndpointScaling(testCase)
cfg = testCase.TestData.cfg; before = rng;
r = study5_record(200,cfg.inputSeed,cfg); verifyEqual(testCase,rng,before);
verifyEqual(testCase,r,testCase.TestData.record); verifyEqual(testCase,r.y,r.x);
verifyEqual(testCase,[r.x(1),r.u(1)],[0 0]);
verifyEqual(testCase,reshape(r.target,5,[]),repmat(r.target(1:5:end),5,1));
verifyTrue(testCase,all(ismember(r.target,.6*[-1 -.5 0 .5 1])));
verifyLessThanOrEqual(testCase,max(abs(diff(r.u))),.1+eps);
verifyNotEqual(testCase,cfg.inputSeed,cfg.evaluationSeed);
[x,dx] = ndgrid(linspace(-1.2,1.2,41),linspace(-.1,.1,41));
expected = [dx(:)/cfg.Ts, (x(:).^3+(x(:)+dx(:)).^3)/2];
fit = study5_fit('I',r,cfg);
verifyEqual(testCase,fit.rowScale,1/cfg.Ts);
verifyEqual(testCase,fit.D,sqrt(mean(expected.^2)).','AbsTol',1e-14);
verifyEqual(testCase,fit.P0,50*eye(2)); verifyEqual(testCase,fit.theta0,[.8;.3]);
verifyEqual(testCase,fit.lambda,ones(1,200));
[x,u] = ndgrid(linspace(-1.2,1.2,41),linspace(-1,1,41));
expected = [u(:),x(:).^3]; direct = study5_fit('D',r,cfg);
verifyEqual(testCase,direct.rowScale,1);
verifyEqual(testCase,direct.D,sqrt(mean(expected.^2)).','AbsTol',1e-14);
end
function testFitCannotReadIntersampleInformation(testCase)
cfg = testCase.TestData.cfg; record = testCase.TestData.record;
altered = record; altered.x(:) = NaN;
altered.refinedIntegral = 1e10*ones(1,200); altered.trueParameters = [-1;-1];
for id = ["I","D","A","P3"]
    original = study5_fit(id,record,cfg); changed = study5_fit(id,altered,cfg);
    verifyEqual(testCase,changed.theta,original.theta);
    verifyEqual(testCase,changed.covariance,original.covariance);
end
alteredCfg = cfg; alteredCfg.trueParameters = [2;1.2];
[model,theta] = study5_model('I',cfg); [same,prior] = study5_model('I',alteredCfg);
verifyEqual(testCase,theta,prior);
verifyEqual(testCase,forward_map(model,.3,.2,theta),forward_map(same,.3,.2,prior));
end
function testRawMappingRetainsEstimatorState(testCase)
cfg = testCase.TestData.cfg; cfg.K = 3;
fit = study5_fit('I',testCase.TestData.record,cfg);
fit.theta(:,end) = [.15;2.2]; fit.beta(:,end) = fit.D.*fit.theta(:,end);
r = study5_trajectory('I',fit,cfg);
verifyEqual(testCase,r.theta(:,1),[.15;2.2],'AbsTol',1e-15);
verifyEqual(testCase,r.mappedTheta(:,1),[.2;2]);
verifyTrue(testCase,r.mappingActivated(1));
verifyEqual(testCase,r.covariance(:,:,1),fit.covariance(:,:,end));
verifyEqual(testCase,r.beta(:,1),fit.beta(:,end));
verifyEqual(testCase,study5_map('I',[.1 4;-1 3]),[.2 3;0 2]);
verifyEqual(testCase,study5_map('D',[-1;4]),[-1;4]);
end
function testCommittedIntervalAndRestart(testCase)
cfg = testCase.TestData.cfg; cfg.K = 8;
for id = ["I","D","A","P3","K"]
    fit = study5_fit(id,testCase.TestData.record,cfg); r = study5_trajectory(id,fit,cfg);
    verifyTrue(testCase,r.completed); verifyFalse(testCase,r.idAttempted(1));
    verifyEqual(testCase,r.residualWindowCount(1),0);
    verifyEqual(testCase,r.theta(:,1),fit.theta(:,end),'AbsTol',1e-14);
    verifyEqual(testCase,r.covariance(:,:,1),fit.covariance(:,:,end));
    model = study5_model(id,cfg);
    for j = 1:r.nSteps
        verifyEqual(testCase,r.prediction(j),forward_map(model,r.y(j),r.u(j),r.mappedTheta(:,j)),'AbsTol',1e-14);
        if id == "K" || j == 1, continue; end
        x = r.y(j-1); y = r.y(j); u = r.u(j-1);
        if id == "I"
            verifyEqual(testCase,r.idResponse(j),cfg.Ts*u);
            verifyEqual(testCase,r.idRegressor(:,:,j),[y-x,cfg.Ts*(x^3+y^3)/2],'AbsTol',1e-15);
        elseif id == "D", verifyEqual(testCase,r.idResponse(j),y-x);
        else, verifyEqual(testCase,r.idResponse(j),y); end
        verifyEqual(testCase,r.lambda(j),1);
        if r.gramRank(j) < fit.nEstimated, verifyEqual(testCase,r.gramCondition(j),Inf); end
    end
end
end
function testConfiguredPhysicalFlowAndStageSensitivity(testCase)
cfg = testCase.TestData.cfg; [model,theta] = study5_model('I',cfg);
x = .7; u = -.3; step = 1e-5;
[value,A,B] = forward_map(model,x,u,theta);
fd = [(forward_map(model,x+step,u,theta)-forward_map(model,x-step,u,theta))/(2*step), ...
    (forward_map(model,x,u+step,theta)-forward_map(model,x,u-step,theta))/(2*step)];
verifyEqual(testCase,[A B],fd,'AbsTol',1e-9);
fine = physical_model(cfg.Ts,cfg.refinedPredictorSubsteps);
verifyEqual(testCase,value,forward_map(fine,x,u,theta),'AbsTol',1e-8);
for substeps = [5 10 20 40]
    model = physical_model(cfg.Ts,substeps);
    exact = x/sqrt(1+2*theta(2)*cfg.Ts*x^2/theta(1));
    verifyEqual(testCase,forward_map(model,x,0,theta),exact,'AbsTol',1e-8);
end
end
function testCommonForecastInputsAndFrozenSnapshots(testCase)
cfg = testCase.TestData.cfg; cfg.anchors = [20 40];
record = study5_record(600,cfg.evaluationSeed,cfg); q = study5_queries(record,cfg);
for a = 1:2
    index = cfg.anchors(a)+1;
    verifyEqual(testCase,q.inputs(a,:,1),repmat(record.u(index),1,20));
    verifyEqual(testCase,q.inputs(a,:,2),record.u(index:index+19));
    verifyLessThanOrEqual(testCase,max(abs(diff(q.inputs(a,:,2)))),.1+eps);
end
for id = ["I","D","A","P3","K"]
    fit = study5_fit(id,testCase.TestData.record,cfg); original = fit;
    f = study5_forecasts(fit,record,q,cfg);
    verifyEqual(testCase,fit,original); verifyEqual(testCase,f.frozenTheta,fit.mappedTheta(:,end));
    verifyEqual(testCase,f.states(:,1,1),q.initialStates.');
    verifyEqual(testCase,f.oneStepErrors,f.oneStepPrediction-record.x(2:end).');
    if id == "K", verifyEqual(testCase,f.states-q.truth,q.knownNumericalError); end
end
end
function testHalfOpenMetricsAndTerminalInput(testCase)
cfg = testCase.TestData.cfg;
r = struct('id','I','name','Integrated physical','nEstimated',2,'completed',true, ...
    'nSteps',800,'time',(0:800)*.1,'x',zeros(1,801),'y',zeros(1,801), ...
    'u',zeros(1,801),'r',zeros(1,801),'prediction',zeros(1,800));
r.x(201) = .6; r.x(801) = 2; r.y = r.x; r.u(201) = .1; r.u(801) = 1e9;
s = study5_metrics(r,cfg);
verifyEqual(testCase,s.scoredSamples,[800;600]); verifyEqual(testCase,s.incrementSamples,[799;600]);
verifyEqual(testCase,s.trackingRMS,[.6/sqrt(800);.6/sqrt(600)],'AbsTol',1e-15);
verifyEqual(testCase,s.totalInputVariation,[.2;.2]);
verifyEqual(testCase,s.predictionTrueRMS,[sqrt((.6^2+4)/800);2/sqrt(600)],'AbsTol',1e-15);
verifyEqual(testCase,s.inputMax,[.1;.1]);
r.completed = false; r.nSteps = 250; s = study5_metrics(r,cfg);
verifyEqual(testCase,s.scoredSamples,[250;50]); verifyEqual(testCase,s.status,["incompletePrefix";"incompletePrefix"]);
end
