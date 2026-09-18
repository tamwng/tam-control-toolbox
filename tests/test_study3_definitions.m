function tests = test_study3_definitions
%TEST_STUDY3_DEFINITIONS Gain protocol and independent streams, not rankings.
tests = functiontests(localfunctions);
end

function setupOnce(testCase)
testCase.TestData.previousPath = path;
root = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(root,'studies','study1'),fullfile(root,'studies','study3'));
end

function teardownOnce(testCase)
path(testCase.TestData.previousPath);
end

function testGainBoundaryAndDrift(testCase)
k = [0,499,500,501,700,899,900,901,1200];
verifyEqual(testCase,study3_gain(k,'abrupt',0.1), ...
    [0.45,0.45,0.30,0.30,0.30,0.30,0.30,0.30,0.30],'AbsTol',1e-15);
verifyEqual(testCase,study3_gain(k,'drift',0.1), ...
    [0.45,0.45,0.45,0.449625,0.375,0.300375,0.30,0.30,0.30],'AbsTol',1e-15);
verifyEqual(testCase,size(study3_gain(k.','abrupt',0.1)),size(k.'));
verifyError(testCase,@() study3_gain(500,'activation',0.1),'study3:UnknownScenario');
end

function testPlantRetainsNominalOffsetAndCoupling(testCase)
x = [-0.8,0,0.7]; u = [0.3,-0.5,0.8]; w = [0.001,-0.002,0.003];
verifyEqual(testCase,study3_plant(x,u,0.45,zeros(size(x))), ...
    study1_plant(x,u),'AbsTol',1e-15);
verifyEqual(testCase,study3_plant(x,u,[0.45,0.375,0.30],w), ...
    0.03+0.65*x+[0.45,0.375,0.30].*(1+0.35*x).*u+w,'AbsTol',1e-15);
model = study1_model('S');
for b = [0.45,0.375,0.30]
    verifyEqual(testCase,forward_map(model,-0.4,0.6,[0.03;0.65;b]), ...
        study3_plant(-0.4,0.6,b,0),'AbsTol',1e-15);
end
end

function testCasesSupplyOnlyModelsModesAndForgetting(testCase)
cfg = study3_settings;
verifyEqual(testCase,cfg.caseIds,{'A_none','A_fixed','A_vrf','S_none','S_fixed', ...
    'S_vrf','S_pretrained','S_prior','K'});
verifyEqual(testCase,cfg.noisyCases,{'S_none','S_fixed','S_vrf','S_pretrained','K'});
expectedModels = {'A','A','A','S','S','S','S','S','K'};
expectedModes = {'adaptive','adaptive','adaptive','adaptive','adaptive', ...
    'adaptive','pretrained','prior','known'};
for j = 1:numel(cfg.caseIds)
    item = study3_case(cfg.caseIds{j});
    verifyEqual(testCase,item.id,cfg.caseIds{j});
    verifyEqual(testCase,item.modelId,expectedModels{j});
    verifyEqual(testCase,item.mode,expectedModes{j});
    verifyNotEmpty(testCase,item.name);
    verifyEqual(testCase,sort(fieldnames(item)), ...
        sort({'id';'name';'modelId';'mode';'forgetting'}));
    if endsWith(item.id,'_vrf')
        verifyEqual(testCase,item.forgetting, ...
            struct('mode','variable','Nf',10,'sigma',0.03,'eta',0.02,'gamma',10));
    elseif endsWith(item.id,'_fixed')
        verifyEqual(testCase,item.forgetting,struct('mode','fixed','lambda',0.99));
    else
        verifyEqual(testCase,item.forgetting,struct('mode','none'));
    end
end
verifyError(testCase,@() study3_case('S_reset'),'study3:UnknownCase');
end

function testCommonSettingsAndPriors(testCase)
cfg = study3_settings; common = study1_settings;
for field = {'Ts','N','duration','K','fitSteps','horizons','anchors','control'}
    verifyEqual(testCase,cfg.(field{1}),common.(field{1}));
end
verifyEqual(testCase,cfg.scenarios,{'abrupt','drift'});
verifyEqual(testCase,cfg.noiseTrials,40);
verifyEqual(testCase,[cfg.measurementSigma,cfg.processSigma],[0.01,0.005]);
verifyEqual(testCase,cfg.representativeTrial,1);
verifyEqual(testCase,cfg.campaign,'pilot');
verifyFalse(testCase,isfield(cfg,'confirmation'));
for id = {'A','S'}
    [~,theta0] = study1_model(id{1});
    verifyEqual(testCase,theta0,[0;0.5;0.25]);
end
end

function testPreparedRecordsAndNoiseRemainIndependent(testCase)
fixture = testCase.applyFixture(matlab.unittest.fixtures.TemporaryFolderFixture);
output = fullfile(fixture.Folder,'prepared');
cfg = study3_settings;
before = rng;
study3_prepare(output,cfg);
verifyEqual(testCase,rng,before);
saved = load(fullfile(output,'records.mat'),'records'); r = saved.records;
verifyEqual(testCase,r.initialization,study1_record(200,0.5,cfg.inputSeed,cfg));
verifyEqual(testCase,r.evaluation,study1_record(600,0.5,cfg.evaluationSeed,cfg));
verifyNotEqual(testCase,r.initialization.target,r.evaluation.target(1:200));
verifyEqual(testCase,size(r.initialMeasurementNoise),[40,201]);
verifyEqual(testCase,size(r.initialProcessNoise),[40,200]);
verifyEqual(testCase,size(r.controlMeasurementNoise),[40,1201]);
verifyEqual(testCase,size(r.controlProcessNoise),[40,1200]);
stream = RandStream('mt19937ar','Seed',cfg.initialMeasurementBase+1);
verifyEqual(testCase,r.initialMeasurementNoise(1,:),0.01*randn(stream,1,201));
stream = RandStream('mt19937ar','Seed',cfg.initialProcessBase+1);
verifyEqual(testCase,r.initialProcessNoise(1,:),0.005*randn(stream,1,200));
stream = RandStream('mt19937ar','Seed',cfg.controlMeasurementBase+1);
verifyEqual(testCase,r.controlMeasurementNoise(1,:),0.01*randn(stream,1,1201));
stream = RandStream('mt19937ar','Seed',cfg.controlProcessBase+1);
verifyEqual(testCase,r.controlProcessNoise(1,:),0.005*randn(stream,1,1200));
verifyNotEqual(testCase,r.initialMeasurementNoise(1,:),r.controlMeasurementNoise(1,1:201));
verifyNotEqual(testCase,r.initialProcessNoise(1,:),r.controlProcessNoise(1,1:200));
verifyNotEqual(testCase,r.initialMeasurementNoise(1,1:200)/0.01,r.initialProcessNoise(1,:)/0.005);
verifyNotEqual(testCase,r.controlMeasurementNoise(1,1:1200)/0.01,r.controlProcessNoise(1,:)/0.005);
verifyNotEqual(testCase,r.initialMeasurementNoise(1,:),r.initialMeasurementNoise(2,:));
verifyNotEqual(testCase,r.controlProcessNoise(1,:),r.controlProcessNoise(2,:));
for folder = {'fits','evaluation','runs'}
    verifyTrue(testCase,isfolder(fullfile(output,folder{1})));
end
verifyError(testCase,@() study3_prepare(output,cfg),'study3:ExistingOutput');
verifyEqual(testCase,load(fullfile(output,'records.mat'),'records'),saved);
end
