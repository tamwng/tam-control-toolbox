function tests = test_study4
%TEST_STUDY4 Scientific definitions and boundary conventions only.
tests = functiontests(localfunctions);
end
function setupOnce(testCase)
testCase.TestData.previousPath = path;
root = fileparts(fileparts(mfilename('fullpath')));
for s = 1:4, addpath(fullfile(root,'studies',sprintf('study%d',s))); end
end
function teardownOnce(testCase)
path(testCase.TestData.previousPath);
end
function testLinearPlantAndChangeTiming(testCase)
cfg = study4_settings; x = -.37; u = .62;
verifyEqual(testCase,study4_plant(0,0,0,0),0);
verifyEqual(testCase,study4_plant(x,u,0,0),.65*x+.45*u);
for scenario = string(cfg.scenarios)
    [h,rho] = study4_schedule([0 499 500 501],scenario,cfg);
    verifyEqual(testCase,h(1:2),[0 0]); verifyEqual(testCase,rho(1:2),[0 0]);
    if scenario == "represented", verifyEqual(testCase,h,[0 0 .08 .08]);
    elseif scenario == "unrepresented", verifyEqual(testCase,rho,[0 0 cfg.rhoStar cfg.rhoStar]);
    else, verifyEqual(testCase,[h rho],zeros(1,8)); end
end
verifyEqual(testCase,cfg.rhoStar^2*(.5-sin(4)/8),.08^2/5,'AbsTol',1e-17);
common = study1_settings;
verifyEqual(testCase,cfg.control,common.control);
verifyEqual(testCase,[cfg.Ts cfg.K cfg.N cfg.duration],[.1 1200 10 120]);
verifyEqual(testCase,[cfg.measurementSigma cfg.processSigma],[0 0]);
verifyEqual(testCase,cfg.forgetting,struct('mode','variable','Nf',10,'sigma',.03,'eta',.02,'gamma',10));
verifyEqual(testCase,cfg.modelIds,{'A','Aplus','P2','K'});
end
function testCompleteOrderInitialMapsAndExactVectors(testCase)
x = -.37; u = .62; expected = [1 x u x^2 x*u u^2];
for id = ["A","Aplus","P2"]
    [model,theta] = study4_model(id); n = model.ntheta;
    [b,Phi] = model_regression(model,x,.7,u);
    verifyEqual(testCase,b,.7); verifyEqual(testCase,Phi,expected(1:n),'AbsTol',1e-15);
    verifyEqual(testCase,theta,[0;.5;.25;zeros(n-3,1)]);
    verifyEqual(testCase,forward_map(model,x,u,theta),.5*x+.25*u,'AbsTol',1e-15);
    for h = [0 .08]
        if n == 3 && h > 0, continue; end
        target = [0;.65;.45;zeros(n-3,1)]; if n > 3, target(4) = h; end
        verifyEqual(testCase,forward_map(model,x,u,target),study4_plant(x,u,h,0),'AbsTol',1e-15);
    end
end
end
function testFreshInitializationAndFixedScaling(testCase)
cfg = study4_settings; before = rng;
r = study4_record(200,.5,cfg.inputSeed,cfg);
verifyEqual(testCase,rng,before);
verifyEqual(testCase,r,study4_record(200,.5,cfg.inputSeed,cfg));
verifyEqual(testCase,r.x(2:end),.65*r.x(1:end-1)+.45*r.u,'AbsTol',1e-15);
verifyEqual(testCase,r.x(1),0); verifyEqual(testCase,r.u(1),0);
verifyEqual(testCase,reshape(r.target,5,[]),repmat(r.target(1:5:end),5,1));
verifyLessThanOrEqual(testCase,max(abs(diff(r.u))),.25);
old = study1_record(200,.5,cfg.inputSeed,cfg);
verifyEqual(testCase,r.u,old.u); verifyNotEqual(testCase,r.x,old.x);
[x,u] = ndgrid(linspace(-1.2,1.2,41),linspace(-1,1,41));
F = [ones(numel(x),1),x(:),u(:),x(:).^2,x(:).*u(:),u(:).^2];
for id = ["A","Aplus","P2"]
    f = study4_fit(id,r,cfg); n = f.nEstimated;
    verifyEqual(testCase,f.D,sqrt(mean(F(:,1:n).^2)).','AbsTol',1e-14);
    verifyEqual(testCase,f.P0,100/n*eye(n)); verifyTrue(testCase,all(f.accepted));
    verifyEqual(testCase,f.lambda,ones(1,200));
end
end
function testKnownMapAndCurrentFrozenSnapshot(testCase)
cfg = study4_settings; model = study4_model('K'); x = .6; u = .2;
for scenario = string(cfg.scenarios)
    for k = [499 500 501]
        [h,rho] = study4_schedule(k,scenario,cfg); theta = [0;.65;.45;h;rho];
        preview = study1_reference((k+(1:10))*.1);
        [next,prediction,control] = study3_fixed_step(model,theta,x,u,preview,cfg.control);
        verifyTrue(testCase,control.accepted);
        value = .65*x+.45*u+h*x^2+rho*sin(2*x);
        a = .65+2*h*x+2*rho*cos(2*x);
        verifyEqual(testCase,[prediction.A prediction.B prediction.c prediction.value], ...
            [a .45 value-a*x-.45*u value],'AbsTol',1e-15);
        verifyEqual(testCase,next,control.U(1));
        state = x; inputs = [u;control.U(:)];
        for j = 1:10
            state = a*state+.45*inputs(j)+prediction.c;
            verifyEqual(testCase,control.Y(j),state,'AbsTol',1e-12);
        end
    end
end
end
function testRecoveryEndpointsCensoringAndIncomplete(testCase)
r = struct('scenario','represented','Ts',.1,'nSteps',1200,'completed',true, ...
    'time',(0:1200)*.1,'x',ones(1,1201),'r',zeros(1,1201));
for scenario = ["represented","unrepresented"]
    r.scenario = scenario; a = r; a.x(501:520) = .04;
    out = study4_recovery(a); verifyEqual(testCase,[out.recoveryDelay,out.dwellEnd],[0 52]);
    a = r; a.x(581:600) = 0; a.x(601) = 1;
    out = study4_recovery(a); verifyEqual(testCase,[out.recoveryDelay,out.dwellEnd],[8 60]);
    a.x(590) = .04+eps(.04); out = study4_recovery(a);
    verifyEqual(testCase,out.status,"rightCensored"); verifyTrue(testCase,isnan(out.recoveryDelay));
    verifyEqual(testCase,out.censorTime,60);
    a = r; a.nSteps = 550; a.completed = false;
    out = study4_recovery(a); verifyEqual(testCase,out.status,"terminatedBeforeCensor");
    verifyEqual(testCase,out.recordStatus,"incomplete"); verifyFalse(testCase,out.rightCensored);
end
r.scenario = 'no_change'; out = study4_recovery(r); verifyFalse(testCase,out.applicable);
end
function testCorrectedRankAndInfiniteCondition(testCase)
for smallest = [0 1e-10 1.01e-10]
    G = diag([1 .1 smallest]);
    [rank,condition,valid] = study2_gram_diagnostic(G);
    verifyTrue(testCase,valid);
    if smallest <= 1e-10
        verifyEqual(testCase,rank,2); verifyEqual(testCase,condition,Inf);
    else
        verifyEqual(testCase,rank,3); verifyEqual(testCase,condition,1/smallest);
    end
    verifyEqual(testCase,G,diag([1 .1 smallest]));
end
[rank,condition] = study2_gram_diagnostic(zeros(4));
verifyEqual(testCase,[rank condition],[0 Inf]);
end
