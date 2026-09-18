function tests = test_study3_timing
%TEST_STUDY3_TIMING Gain schedules, causal adaptation, and fixed controls.
tests = functiontests(localfunctions);
end

function setupOnce(testCase)
testCase.TestData.previousPath = path;
root = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(root,'studies','study1'),fullfile(root,'studies','study2'), ...
    fullfile(root,'studies','study3'));
end

function teardownOnce(testCase)
path(testCase.TestData.previousPath);
end

function testExactGainTimingAndFixedRepresentation(testCase)
k = [0,499,500,501,899,900,1199];
verifyEqual(testCase,study3_gain(k,'abrupt',.1), ...
    [.45,.45,.30,.30,.30,.30,.30],'AbsTol',1e-15);
verifyEqual(testCase,study3_gain(k,'drift',.1), ...
    [.45,.45,.45,.449625,.300375,.30,.30],'AbsTol',1e-15);
x = -.37; u = .62;
model = study1_model('S');
for scenario = {'abrupt','drift'}
    for index = k
        b = study3_gain(index,scenario{1},.1);
        expected = .03+.65*x+b*(1+.35*x)*u;
        verifyEqual(testCase,forward_map(model,x,u,[.03;.65;b]),expected,'AbsTol',1e-15);
    end
end
end

function testPrescribedComparisonsAndForgetting(testCase)
cfg = study3_settings;
verifyEqual(testCase,cfg.caseIds,{'A_none','A_fixed','A_vrf','S_none','S_fixed', ...
    'S_vrf','S_pretrained','S_prior','K'});
verifyEqual(testCase,cfg.noisyCases,{'S_none','S_fixed','S_vrf','S_pretrained','K'});
verifyEqual(testCase,[cfg.noiseTrials,cfg.measurementSigma,cfg.processSigma],[40,.01,.005]);
verifyEqual(testCase,[cfg.Ts,cfg.K,cfg.duration],[.1,1200,120]);
for model = {'A','S'}
    item = study3_case([model{1} '_none']);
    verifyEqual(testCase,item.forgetting,struct('mode','none'));
    item = study3_case([model{1} '_fixed']);
    verifyEqual(testCase,item.forgetting,struct('mode','fixed','lambda',.99));
    item = study3_case([model{1} '_vrf']);
    verifyEqual(testCase,item.forgetting, ...
        struct('mode','variable','Nf',10,'sigma',.03,'eta',.02,'gamma',10));
end
end

function testFixedForgettingCarriesCovarianceAcrossEventIndex(testCase)
item = study3_case('S_fixed');
estimator = RlsEstimator(0,2,1,1,item.forgetting);
for k = 1:502
    % A zero regressor isolates forgetting, including the event indices.
    response = 0; if k >= 501, response = 1; end
    info = estimator.update(response,0);
    verifyTrue(testCase,info.accepted,info.message);
    verifyEqual(testCase,info.lambda,.99);
    if ismember(k,[1,499,500,501,502])
        verifyEqual(testCase,estimator.Covariance,2/.99^k,'RelTol',2e-13);
        verifyEqual(testCase,estimator.RawParameters,0);
    end
end
end

function testManuscriptResidualWindowThresholdCapAndRestart(testCase)
item = study3_case('S_vrf');
estimator = RlsEstimator(0,2,1,1,item.forgetting);
response = [.03,.03,1,zeros(1,12),.02];
product = 1;
for j = 1:numel(response)
    info = estimator.update(response(j),0);
    first = max(1,j-9);
    energy = norm(response(first:j))/sqrt(j-first+1)/.03;
    lambda = 1;
    % The first two windows have exactly the prescribed threshold energy.
    if j > 2 && energy > 1, lambda = 1/(1+.02*min(energy,10)); end
    verifyTrue(testCase,info.accepted,info.message);
    verifyEqual(testCase,info.energy,energy,'AbsTol',2e-14);
    verifyEqual(testCase,info.lambda,lambda,'AbsTol',2e-15);
    verifyEqual(testCase,estimator.ResidualSquares,response(first:j).'.^2);
    product = product*lambda;
    verifyEqual(testCase,estimator.Covariance,2/product,'RelTol',2e-14);
end
before = estimator.Covariance;
estimator.resetResidualWindow;
verifyEmpty(testCase,estimator.ResidualSquares);
verifyEqual(testCase,estimator.Covariance,before);
info = estimator.update(.02,0);
verifyEqual(testCase,info.lambda,1);
verifyEqual(testCase,info.energy,2/3,'AbsTol',2e-15);
end

function testChangedTransitionArrivesAfterCommittedInput(testCase)
cfg = study3_settings; cfg.K = 502;
record = study1_record(200,.5,cfg.inputSeed,cfg);
[~,fit] = study1_fit('S',record,cfg);
noise = struct('measurement',zeros(1,cfg.K+1),'process',zeros(1,cfg.K));
abrupt = study3_trajectory('S_vrf',fit,'abrupt',0,noise,cfg);
drift = study3_trajectory('S_vrf',fit,'drift',0,noise,cfg);
verifyTrue(testCase,abrupt.completed && drift.completed);
% All measurements through x(500) and the computation of u(501) are paired.
verifyEqual(testCase,abrupt.x(1:501),drift.x(1:501));
verifyEqual(testCase,abrupt.y(1:501),drift.y(1:501));
verifyEqual(testCase,abrupt.theta(:,1:501),drift.theta(:,1:501));
verifyEqual(testCase,abrupt.covariance(:,:,1:501),drift.covariance(:,:,1:501));
verifyEqual(testCase,abrupt.lambda(1:501),drift.lambda(1:501));
verifyEqual(testCase,abrupt.u(1:502),drift.u(1:502));
expectedDifference = -.15*(1+.35*abrupt.x(501))*abrupt.u(501);
verifyEqual(testCase,abrupt.x(502)-drift.x(502),expectedDifference,'AbsTol',1e-14);
verifyGreaterThan(testCase,abs(expectedDifference),1e-8);
verifyGreaterThan(testCase,norm(abrupt.theta(:,502)-drift.theta(:,502)),1e-8);
for result = {abrupt,drift}
    r = result{1};
    for j = [500,501,502]
        [beta,P] = online_batch(r,j);
        verifyEqual(testCase,r.beta(:,j),beta,'AbsTol',1e-9);
        verifyEqual(testCase,r.covariance(:,:,j),P,'AbsTol',1e-8);
    end
end
end

function testFrozenControlsRetainTheirDeclaredStart(testCase)
cfg = study3_settings; cfg.K = 4;
record = study1_record(200,.5,cfg.inputSeed,cfg);
[~,fit] = study1_fit('S',record,cfg);
noise = struct('measurement',zeros(1,cfg.K+1),'process',zeros(1,cfg.K));
for id = {'S_pretrained','S_prior'}
    r = study3_trajectory(id{1},fit,'abrupt',0,noise,cfg);
    expected = fit.theta(:,end);
    if strcmp(id{1},'S_prior'), expected = fit.theta0; end
    verifyTrue(testCase,r.completed);
    verifyEqual(testCase,r.theta,repmat(expected,1,cfg.K),'AbsTol',2e-15);
    verifyFalse(testCase,any(r.idAttempted));
    verifyFalse(testCase,any(r.idAccepted));
    verifyTrue(testCase,all(isnan(r.lambda)));
end
end

function testKnownReferenceUsesOnlyCurrentFrozenSnapshot(testCase)
cfg = study3_settings; model = study1_model('K');
measurement = .4; committed = .2;
for k = [499,500,501]
    current = study3_gain(k,'abrupt',cfg.Ts);
    theta = [.03;.65;current];
    preview = study1_reference((k+(1:cfg.N))*cfg.Ts);
    [next,prediction,control] = study3_fixed_step( ...
        model,theta,measurement,committed,preview,cfg.control);
    verifyTrue(testCase,control.accepted);
    value = .03+.65*measurement+current*(1+.35*measurement)*committed;
    A = .65+.35*current*committed;
    B = current*(1+.35*measurement);
    c = .03-.35*current*measurement*committed;
    verifyEqual(testCase,[prediction.A,prediction.B,prediction.c,prediction.value], ...
        [A,B,c,value],'AbsTol',1e-15);
    expected = measurement;
    allInputs = [committed;control.U(:)];
    for h = 1:cfg.N
        expected = A*expected+B*allInputs(h)+c;
        verifyEqual(testCase,control.Y(h),expected,'AbsTol',1e-12);
    end
    verifyEqual(testCase,next,control.U(1));
end
verifyEqual(testCase,nargin(@study3_fixed_step),6);
end

function testRejectedControlRetainsCommittedInput(testCase)
cfg = study3_settings; cfg.K = 3; cfg.control.R = 0;
training = study1_record(200,.5,cfg.inputSeed,cfg);
[~,fit] = study1_fit('S',training,cfg);
noise = struct('measurement',zeros(1,4),'process',zeros(1,3));
for id = {'S_vrf','S_pretrained','K'}
    r = study3_trajectory(id{1},fit,'abrupt',0,noise,cfg);
    verifyTrue(testCase,r.completed);
    verifyFalse(testCase,any(r.controlAccepted));
    verifyEqual(testCase,r.u,zeros(1,4));
    verifyEqual(testCase,nnz(strcmp({r.events.stage},'control')),3);
end
end

function [beta,P] = online_batch(r,last)
% Independent augmented weighted least squares from the carried posterior.
accepted = find(r.idAccepted(2:last))+1;
lambda = r.lambda(accepted);
root = chol(r.initialCovariance\eye(numel(r.initialBeta)));
A = sqrt(prod(lambda))*root; b = A*r.initialBeta;
for n = 1:numel(accepted)
    j = accepted(n);
    row = [1,r.y(j-1),(1+.35*r.y(j-1))*r.u(j-1)]./r.D.';
    weight = sqrt(prod(lambda(n+1:end)));
    A = [A;weight*row]; b = [b;weight*r.y(j)]; %#ok<AGROW>
end
beta = A\b;
[~,R] = qr(A,0); P = R\(R.'\eye(size(R,2)));
end
