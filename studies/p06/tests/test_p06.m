function tests = test_p06
%TEST_P06 No new plant trajectories, study fits, forecasts, or QP runs.
tests=functiontests(localfunctions);
end

function setupOnce(t)
folder=fileparts(mfilename('fullpath'));
s=load(fullfile(folder,'fixtures','pre_interface.mat'),'oracle');
t.TestData.oracle=s.oracle;
f=t.applyFixture(matlab.unittest.fixtures.TemporaryFolderFixture);t.TestData.output=f.Folder;
cfg=study1_settings;
[t.TestData.plan,t.TestData.manifest]=p06_design(cfg,'','','');
t.TestData.records=study1_records(cfg,'confirmation');
archive=getappdata(0,'sensitivityTestReference');
if ~isempty(archive),t.TestData.plan.archive=archive;end
end

function testDefaultFitExactlyMatchesPrechange(t)
o=t.TestData.oracle;
for j=1:6
    [a,default]=study1_fit(o.ids{j},o.record,o.cfg);
    [b,explicit]=study1_fit(o.ids{j},o.record,o.cfg,1);
    verifyEqual(t,default,o.fits{j}); verifyEqual(t,explicit,o.fits{j});
    if j<6
        verifyEqual(t,a.Beta,b.Beta); verifyEqual(t,a.Covariance,b.Covariance);
    end
end
end

function testPriorMultiplierOnlyChangesInitialCovariance(t)
o=t.TestData.oracle;
for j=1:5
    old=o.fits{j}; n=old.nEstimated;
    for alpha=[.1 10]
        [est,fit]=study1_fit(o.ids{j},o.record,o.cfg,alpha);
        verifyEqual(t,fit.P0,alpha*((100/n)*eye(n)));
        verifyEqual(t,fit.covariance(:,:,1),fit.P0);
        verifyEqual(t,fit.theta0,old.theta0); verifyEqual(t,fit.D,old.D);
        verifyEqual(t,fit.labels,old.labels); verifyEqual(t,fit.beta(:,1),old.beta(:,1));
        verifyEqual(t,fit.theta(:,1),old.theta(:,1));
        verifyEqual(t,fit.lambda,old.lambda);
        verifyEqual(t,est.Beta,fit.beta(:,end));
        verifyEqual(t,est.Covariance,fit.covariance(:,:,end));
        % Independent matching batch objective on synthetic observations.
        model=study1_model(o.ids{j}); Phi=zeros(12,n);
        for k=1:12
            [~,Phi(k,:)]=model_regression(model,o.record.y(k),o.record.y(k+1),o.record.u(k));
        end
        X=Phi./fit.D.'; precision=fit.P0\eye(n);
        expected=(precision+X.'*X)\eye(n);
        beta=expected*(precision*(fit.D.*fit.theta0)+X.'*o.record.y(2:end).');
        verifyEqual(t,est.Covariance,expected,'AbsTol',1e-10);
        verifyEqual(t,est.Beta,beta,'AbsTol',1e-10);
    end
end
end

function testKnownPriorIsNotIdentification(t)
o=t.TestData.oracle;
for alpha=[.1 1 10]
    [est,fit]=study1_fit('K',o.record,o.cfg,alpha);
    verifyEmpty(t,est); verifyEqual(t,fit,o.fits{6});
end
end

function testInvalidPriorRejected(t)
o=t.TestData.oracle;
for alpha={0,-1,Inf,NaN,[1 2]}
    caught=false;
    try, study1_fit('A',o.record,o.cfg,alpha{1}); catch, caught=true; end
    verifyTrue(t,caught);
end
end

function testOriginalTwoArgumentSummaryExactlyMatchesPrechange(t)
output=fullfile(t.TestData.output,'legacy_after');
cfg=p06_legacy_fixture(output,t.TestData.plan.archive);
actual=study1_summarize(output,cfg);
verifyEqual(t,actual,t.TestData.oracle.summary);
end

function testPublicScoresEqualOriginalInternalScores(t)
p=t.TestData.plan;
s=load(fullfile(p.archive,'data','confirmation_S_000.mat'),'result'); r=s.result;
h=study1_summarize('p06_helpers');
base=struct('campaign',"confirmation",'model',"S",'trial',0,'noise',false);
old=t.TestData.oracle.summary;
metrics=struct2table(h.scoreRun(r,base,p.cfg));
verifyEqual(t,metrics,old.metrics(old.metrics.campaign=="confirmation",:));
fits=struct2table(h.scoreFit(r,base,p.cfg));
verifyEqual(t,fits,old.initialization(old.initialization.campaign=="confirmation",:));
d=old.diagnostics(old.diagnostics.campaign=="confirmation",:);
d.measuredAuditInvalid=[];
verifyEqual(t,struct2table(h.diagnoseRun(r,base,p.cfg)),d);
end

function testWindowsAndTerminalInputConvention(t)
h=study1_summarize('p06_helpers'); cfg=study1_settings;
r=struct('id','A','completed',true,'nSteps',1200,'x',zeros(1,1201), ...
    'y',zeros(1,1201),'u',ones(1,1201),'r',zeros(1,1201), ...
    'prediction',zeros(1,1200),'theta',zeros(3,1200));
r.u(end)=1e9; r.x(end)=3;
a=h.scoreRun(r,struct,cfg);
verifyEqual(t,a(1).expectedSamples,1200); verifyEqual(t,a(2).expectedSamples,600);
verifyEqual(t,[a.inputRMS],[1 1]); verifyEqual(t,[a.meanAbsoluteIncrement],[0 0]);
verifyEqual(t,[a.trackingRMS],[0 0]);
verifyEqual(t,h.percentile([1 3 6 10],.25),2.5);
end

function testSevenOneFactorConfigurations(t)
c=t.TestData.plan.configurations;
verifyEqual(t,height(c),7);
verifyEqual(t,c.configuration,["baseline";"R_half";"R_double";"prior_tenth";"prior_tenfold";"fit_50";"fit_100"]);
values=c{:,2:4}; verifyEqual(t,values(1,:),[.05 1 200]);
verifyEqual(t,sum(values(2:end,:)~=values(1,:),2),ones(6,1));
end

function testManifestCountAndKnownAliases(t)
m=t.TestData.manifest; p=t.TestData.plan;
verifyEqual(t,height(m),1558); verifyEqual(t,numel(unique(m.runId)),1558);
verifyEqual(t,nnz(~m.noisy),38); verifyEqual(t,nnz(m.noisy),1520);
verifyEqual(t,nnz(m.baselineGate),12);
k=m(m.modelId=="K",:); verifyEqual(t,height(k),123);
verifyTrue(t,all(isnan(k.alphaP) & isnan(k.fittingTransitions) & ~k.identificationApplicable));
verifyEqual(t,p.knownAliases.knownReferenceConfiguration(4:7),repmat("baseline",4,1));
verifyTrue(t,all(m.controlInstants==1200 & m.executionStatus=="PROPOSED_NOT_RUN"));
end

function testPairedPrefixesAndIndependentControlStream(t)
p=t.TestData.plan; records=t.TestData.records;
for trial=[0 1 40]
    all=cell(1,3); inputs=cell(1,3);
    lengths=[50 100 200];
    for j=1:3
        c=table(.05,lengths(j),'VariableNames',{'R','fittingTransitions'});
        [all{j},inputs{j},cfg]=p06_trial(records,trial,c,p.cfg);
        verifyEqual(t,cfg.K,1200); verifyEqual(t,cfg.fitSteps,lengths(j));
        verifyEqual(t,all{j}.u,records.initialization.u(1:cfg.fitSteps));
    end
    verifyEqual(t,all{1}.y,all{3}.y(1:51)); verifyEqual(t,all{2}.y,all{3}.y(1:101));
    verifyEqual(t,inputs{1},inputs{3}); verifyEqual(t,inputs{2},inputs{3});
end
end

function testRChangesLeaveSyntheticFittingIdentical(t)
o=t.TestData.oracle; a=o.cfg; b=o.cfg;
a.control.R=.025; b.control.R=.1;
[~,left]=study1_fit('S',o.record,a);
[~,right]=study1_fit('S',o.record,b);
verifyEqual(t,left,right);
verifyTrue(t,contains(t.TestData.plan.cachePolicy,'No fit-state cache'));
end

function testRestartCarriesBothFittedStatesWithoutTransition(t)
o=t.TestData.oracle;
[est,fit]=study1_fit('S',o.record,o.cfg,10);
beta=est.Beta; covariance=est.Covariance;
controller=AdaptiveController(study1_model('S'),est,o.cfg.control,0,0);
verifyEqual(t,est.Beta,beta); verifyEqual(t,est.Covariance,covariance);
verifyEqual(t,est.Covariance,fit.covariance(:,:,end));
verifyEmpty(t,controller.PreviousState); verifyEmpty(t,controller.PreviousInput);
verifyEmpty(t,est.ResidualSquares); verifyEqual(t,controller.Index,0);
verifyEqual(t,controller.CurrentInput,0); verifyEqual(t,controller.InitialState,0);
% No controller.step or QP is called in this test.
end

function testCaseWiresMocksOnly(t)
p=t.TestData.plan; m=t.TestData.manifest;
row=m(m.configuration=="fit_50" & m.modelId=="S" & m.trial==1,:);
count=zeros(1,4); sentinel=struct('Beta',[11;12;13],'Covariance',diag([2 3 4]));
ops=struct('fit',@fakeFit,'trajectory',@fakeTrajectory,'evaluate',@fakeEvaluate,'score',@fakeScore);
[r,s]=p06_case(row,p,t.TestData.records,ops);
verifyEqual(t,count,ones(1,4)); verifyEqual(t,s,17);
verifyEqual(t,r.p06.fittingTransitions,50);
    function [est,fit]=fakeFit(id,record,cfg,alpha)
        count(1)=count(1)+1; verifyEqual(t,id,'S'); verifyEqual(t,numel(record.u),50);
        verifyEqual(t,alpha,1); verifyEqual(t,cfg.fitSteps,50); est=sentinel; fit=struct('token',31);
    end
    function r=fakeTrajectory(id,fit,est,noise,cfg)
        count(2)=count(2)+1; verifyEqual(t,est,sentinel); verifyEqual(t,fit.token,31);
        verifyEqual(t,noise,t.TestData.records.controlNoise(1,:)); verifyEqual(t,cfg.K,1200);
        r=struct('id',id,'fit',fit);
    end
    function f=fakeEvaluate(~,record,cfg)
        count(3)=count(3)+1; verifyEqual(t,record,t.TestData.records.evaluation);
        verifyEmpty(t,cfg.anchors); f=struct('oneStepErrors',zeros(600,1));
    end
    function s=fakeScore(~,~), count(4)=count(4)+1; s=17; end
end

function testPairedSignCountsAndAnalysisRng(t)
globalState=rng;
left=table([3;1;2],[4;2;NaN],[true;true;false],'VariableNames',{'trial','value','complete'});
right=table([1;2;3],[1;5;3],true(3,1),'VariableNames',{'trial','value','complete'});
stream=RandStream('mt19937ar','Seed',7401);
r=p06_contrast(left,right,stream,2000);
verifyEqual(t,[r.attemptedPairs r.completePairs r.finitePairs],[3 2 2]);
verifyEqual(t,[r.medianDifference r.lower95 r.upper95],[1 1 1]);
verifyEqual(t,rng,globalState);
left.complete(:)=true;
r=p06_contrast(left,right,stream,2000); verifyTrue(t,isnan(r.medianDifference));
verifyEqual(t,r.completePairs,3); verifyEqual(t,r.finitePairs,2);
verifyError(t,@() p06_contrast(left([1 1],:),right,stream,2000),'p06:DuplicateTrial');
end

function testBaselineGateSelectionAndMismatch(t)
p=t.TestData.plan; s=load(fullfile(p.archive,'data','confirmation_S_000.mat'),'result');
r=s.result; r.forecasts.oneStepErrors=r.forecasts.oneStepErrors(:,end);
r.fit.checkpointTheta=r.fit.checkpointTheta(:,end);
checks=p06_gate(r,s.result,p.cfg); verifyTrue(t,all(checks.passed));
r.x(1)=.001; checks=p06_gate(r,s.result,p.cfg); verifyFalse(t,all(checks.passed));
end

function testSyntheticSummariesRetainFailureDenominator(t)
plan=t.TestData.plan; m=t.TestData.manifest;
r=m(m.trial>=1 & m.trial<=3,:); n=height(r);
r.completed=true(n,1); r.predictionCompleted=true(n,1);
r.predictionRMS=ones(n,1); r.trackingRMS=2*ones(n,1);
r.inputRMS=3*ones(n,1); r.meanAbsoluteIncrement=4*ones(n,1);
r.completed(1)=false; r.trackingRMS(1)=NaN;
[s,c,a]=p06_summarize(r,plan);
verifyEqual(t,height(s),152); verifyEqual(t,height(c),116);
row=s(s.configuration=="baseline" & s.modelId=="A" & s.metric=="trackingRMS",:);
verifyEqual(t,[row.attempted row.completedControl row.eligibleScores],[3 2 2]);
verifyEqual(t,row.median,2); verifyEqual(t,a.seed,7401);
verifyEqual(t,numel(a.contrastStates),116);
verifyEqual(t,c.left(1),"baseline:S"); verifyEqual(t,c.right(1),"baseline:A");
verifyEqual(t,c.left(57),"R_half:A"); verifyEqual(t,c.right(57),"baseline:A");
end

function testDryRunWritesOnlyManifestAndCallsNoCampaign(t)
output=fullfile(t.TestData.output,'dry_run');
profile clear; profile on;
stop=onCleanup(@() profile('off'));
run_sensitivity('plan',OutputDirectory=output);
profile off; p=profile('info'); names=string({p.FunctionTable.FunctionName});
for forbidden=["p06_execute","study1_fit","study1_trajectory","study1_forecasts","study1_plant","study1_record","solve_mpc"]
    verifyFalse(t,any(names==forbidden),forbidden);
end
files=dir(output); files=files(~[files.isdir]);
verifyEqual(t,sort(string({files.name})),["P06_RUN_MANIFEST.csv","sensitivity_manifest.json"]);
verifyError(t,@() run_sensitivity('plan',OutputDirectory=output),'ejc:ExistingOutput');
verifyError(t,@() run_sensitivity('all',OutputDirectory=fullfile(t.TestData.output,'not_created')),'study:ExpensiveSelection');
verifyFalse(t,isfolder(fullfile(t.TestData.output,'not_created')));
end
