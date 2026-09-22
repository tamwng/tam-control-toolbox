function tests = test_study6
%TEST_STUDY6 Mechanism identities and saved-query contracts, never rankings.
tests = functiontests(localfunctions);
end
function setupOnce(testCase)
testCase.TestData.previousPath = path;
root = fileparts(fileparts(mfilename('fullpath'))); testCase.TestData.root = root;
for s = 1:6, addpath(fullfile(root,'studies',sprintf('study%d',s))); end
end
function teardownOnce(testCase)
path(testCase.TestData.previousPath);
end
function testIndicesAndCommonInputs(testCase)
cfg = study6_settings; root = testCase.TestData.root;
saved = load(fullfile(root,'results',cfg.sources{1},'data','records_pilot.mat'),'records');
r = saved.records.evaluation; before = r;
q = study6_queries(r,cfg.anchors,'clean');
verifyEqual(testCase,q.matlabColumns,21:20:581); verifyEqual(testCase,q.x,r.x(21:20:581).');
verifyEqual(testCase,q.x,q.y); verifyEqual(testCase,r,before);
for a = 1:29
    j = q.matlabColumns(a);
    verifyEqual(testCase,q.inputs(a,:,1),repmat(r.u(j),1,20));
    verifyEqual(testCase,q.inputs(a,:,2),r.u(j:j+19));
end
verifyEqual(testCase,cfg.onlineIndices,[499 550 599 950]);
verifyEqual(testCase,cfg.changeIndices,[495 499]);
end
function testQueryContactAndFixedAffinePropagation(testCase)
for plant = ["A","B","C"]
    id = "S"; theta = [.02;.6;.4];
    if plant == "B", id = "E"; elseif plant == "C", id = "I"; theta = [.9;.55]; end
    [model,~,unit] = study6_model(plant,id,study5_settings);
    inputs = .4*sin((1:20)/5); x = -.37; p = study6_paths(model,theta,x,inputs);
    [A,B,c,value] = freeze_predictor(model,x,inputs(1),theta);
    verifyEqual(testCase,[p.A p.B p.c],[A B c]); verifyEqual(testCase,p.nonlinear(2),value);
    delta = 1e-6;
    finiteDifference = [(forward_map(model,x+delta,inputs(1),theta)-forward_map(model,x-delta,inputs(1),theta))/(2*delta), ...
        (forward_map(model,x,inputs(1)+delta,theta)-forward_map(model,x,inputs(1)-delta,theta))/(2*delta)];
    verifyEqual(testCase,[A B],finiteDifference,'AbsTol',2e-10);
    state = x;
    for h = 1:20
        state = c+A*state+B*inputs(h); verifyEqual(testCase,p.affine(h+1),state);
    end
    verifyEqual(testCase,p.freezeCount,1); verifyEqual(testCase,p.affine(2),p.nonlinear(2),'AbsTol',1e-11);
    if plant == "C", verifyEqual(testCase,unit,'rad/s'); else, verifyEqual(testCase,unit,'dimensionless state'); end
end
end
function testCompleteAffineMapAllHorizons(testCase)
model = study1_model('A'); theta = [.03;.65;.45];
for inputs = [repmat(.4,20,1),.5*sin((1:20).'/3)]
    p = study6_paths(model,theta,.31,inputs.');
    verifyEqual(testCase,p.affine,p.nonlinear,'AbsTol',1e-11);
end
end
function testSnapshotSelectionAndPhysicalMapping(testCase)
root = testCase.TestData.root; cfg = study6_settings;
saved = load(fullfile(root,'results',cfg.sources{5},'fits','fit_I.mat'),'fit'); fit = saved.fit;
verifyEqual(testCase,fit.checkpointTheta,fit.theta(:,cfg.fitSteps+1));
q = fixture_queries; q.y = q.x; q = study6_truth(q,'A',.45);
raw = [-.2;2.5]; mapped = study5_map('I',raw); copy = raw;
[model,name,unit] = study6_model('C','I',study5_settings);
meta = study6_meta('test',5,'C','I',name,unit,'fixture',.6);
o = study6_evaluate(model,raw,mapped,q,meta);
verifyEqual(testCase,raw,copy); verifyEqual(testCase,o.rawTheta,raw);
verifyEqual(testCase,o.mappedTheta,[.2;2]);
verifyEqual(testCase,o.nonlinear(1,2,1),forward_map(model,q.x,q.inputs(1,1,1),mapped));
end
function testInitializationChangeAndSquaredIdentities(testCase)
q = fixture_queries; q = study6_truth(q,'A',.45,[.45 .3*ones(1,19)]);
model = study1_model('S'); theta = [.025;.62;.43];
meta = study6_meta('test',3,'A','S','Shared','dimensionless state','fixture',.5);
o = study6_evaluate(model,theta,theta,q,meta); study6_check(o,q);
verifyEqual(testCase,o.initializationError,q.truthY-q.truthX);
verifyEqual(testCase,o.changeError,q.truthX-q.truthFuture);
verifyEqual(testCase,o.combinedError,o.modelError+o.freezingError+o.initializationError+o.changeError,'AbsTol',1e-11);
rows = study6_summary(o,q);
verifyEqual(testCase,rows.totalMSE,rows.modelMSE+rows.freezingMSE+rows.meanCrossTerm,'AbsTol',1e-11);
verifyEqual(testCase,rows.combinedMSE,rows.modelMSE+rows.freezingMSE+rows.initializationMSE+rows.changeMSE+rows.meanCombinedCrossTerm,'AbsTol',1e-11);
verifyTrue(testCase,all(rows.attemptedQueries == 1 & rows.failedQueries == 0));
end
function testFutureInformationDoesNotEnterLearnedPaths(testCase)
q = fixture_queries; q = study6_truth(q,'A',.45,[.45 .3*ones(1,19)]);
other = study6_truth(q,'A',.45,[.45 .1*ones(1,19)]);
model = study1_model('K'); theta = [.03;.65;.45];
meta = study6_meta('test',3,'A','K','Known-model reference','dimensionless state','fixture',.5);
one = study6_evaluate(model,theta,theta,q,meta); two = study6_evaluate(model,theta,theta,other,meta);
verifyEqual(testCase,one.nonlinear,two.nonlinear); verifyEqual(testCase,one.affine,two.affine);
verifyEqual(testCase,one.mappedTheta,two.mappedTheta); verifyNotEqual(testCase,one.changeError,two.changeError);
for name = {'study6_paths','study6_evaluate'}
    source = fileread(which(name{1}));
    verifyFalse(testCase,contains(source,'RlsEstimator(') || contains(source,'AdaptiveController(') || contains(source,'solve_mpc('));
end
end
function testNonfiniteQueriesRemainInCounts(testCase)
record = struct('x',[0 1 zeros(1,20)],'y',[0 1 zeros(1,20)],'u',zeros(1,21));
q = study6_queries(record,[0 1],'clean'); q = study6_truth(q,'A',.45*ones(2,1));
model = direct_model(1,1,1,1,@square_feature);
meta = study6_meta('test',1,'A','S','Divergence fixture','dimensionless state','fixture',.5);
o = study6_evaluate(model,[1e200 1e200],[1e200 1e200],q,meta);
rows = study6_summary(o,q);
verifyTrue(testCase,all(rows.attemptedQueries == 2 & rows.finiteQueries == 1 & rows.failedQueries == 1));
verifyTrue(testCase,all(isnan(rows.totalRMSE))); verifyEqual(testCase,numel(o.failures),2);
verifyTrue(testCase,any(~isfinite(o.nonlinear(2,:,:)),'all'));
end
function testConstraintBenchmarkFromArchive(testCase)
root = testCase.TestData.root; cfg = study6_settings;
for id = ["A","O3","E","K"]
    saved = load(fullfile(root,'results',cfg.sources{2},'runs',"constraint_"+id+".mat"),'result'); r = saved.result;
    verifyEqual(testCase,[r.x(1)-.85,r.x(2)-.85],[.55 .09],'AbsTol',1e-11);
    verifyEqual(testCase,r.time(2)-r.time(1),.1);
    verifyEqual(testCase,r.x(2),study2_plant(r.x(1),r.u(1)));
    if id == "K", verifyGreaterThanOrEqual(testCase,r.slack(1,1,1),.09-1e-7); end
end
end
function q = fixture_queries
record = struct('x',.2*ones(1,21),'y',.23*ones(1,21),'u',.3*sin((1:20)/4));
q = study6_queries(record,0,'measured');
end
function [value,J] = square_feature(z)
value = z(1)^2; J = [2*z(1) 0];
end
