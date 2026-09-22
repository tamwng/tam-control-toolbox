function tests = test_study4_reporting
%TEST_STUDY4_REPORTING Exact archived journal traces; no control runs.
tests = functiontests(localfunctions);
end
function setupOnce(testCase)
testCase.TestData.previousPath = path;
root = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(root,'studies','study4'));
testCase.TestData.source = fullfile(root,'results','study4_pilot_20260922');
testCase.TestData.values = study4_figure_data(testCase.TestData.source);
end
function teardownOnce(testCase)
path(testCase.TestData.previousPath);
end
function testCoefficientOrderingFullOvershootAndLastSavedSample(testCase)
v = testCase.TestData.values;
ids = ["Aplus","P2"]; names = ["Augmented affine","Complete quadratic"];
for scenario = ["represented","unrepresented"]
    for m = 1:2
        saved = load(fullfile(testCase.TestData.source,'runs',sprintf('%s_%s.mat',scenario,ids(m))),'result');
        r = saved.result; index = find(string(r.labels) == "q_xx");
        verifyEqual(testCase,index,4);
        block = v(v.scenario == scenario & v.model == names(m) & v.quantity == "Estimated xi^2 coefficient",:);
        verifyEqual(testCase,block.timeSeconds,r.time(451:1200).');
        verifyEqual(testCase,block.value,r.theta(index,451:1200).');
        [value,where] = max(block.value); [expected,expectedWhere] = max(r.theta(index,451:1200));
        verifyEqual(testCase,[value,where],[expected,expectedWhere]);
        verifyEqual(testCase,block.timeSeconds(end),119.9,'AbsTol',2e-14);
        if scenario == "represented" && m == 2, verifyGreaterThan(testCase,value,.19); end
    end
end
end
function testSnapshotsAreExactAndEventConnectionIsBroken(testCase)
v = testCase.TestData.values;
ids = ["A","Aplus","P2"]; names = ["Affine","Augmented affine","Complete quadratic"];
for scenario = ["represented","unrepresented"]
    for m = 1:3
        saved = load(fullfile(testCase.TestData.source,'evaluation',sprintf('%s_%s.mat',scenario,ids(m))),'evaluation');
        e = saved.evaluation;
        block = v(v.scenario == scenario & v.model == names(m) & v.quantity == "Common-grid prediction RMSE",:);
        verifyEqual(testCase,block.timeSeconds,e.time(46:120).');
        verifyEqual(testCase,block.value,e.rms(46:120).');
        verifyEqual(testCase,block.timeSeconds,(45:119).');
        verifyEqual(testCase,block.segment,[ones(5,1);2*ones(70,1)]);
        verifyEqual(testCase,block.timeSeconds(find(diff(block.segment))+[0 1]),[49;50]);
    end
end
end
function testOnlyRequestedQuantitiesAndRepresentedTruth(testCase)
v = testCase.TestData.values;
verifyEqual(testCase,height(v),4200);
verifyEqual(testCase,sort(unique(v.quantity)),sort(["Estimated xi^2 coefficient"; ...
    "True xi^2 coefficient";"Common-grid prediction RMSE"]));
truth = v(v.quantity == "True xi^2 coefficient",:);
verifyEqual(testCase,height(truth),750);
verifyTrue(testCase,all(truth.scenario == "represented"));
saved = load(fullfile(testCase.TestData.source,'runs','represented_Aplus.mat'),'result');
verifyEqual(testCase,truth.value,saved.result.trueH(451:1200).');
verifyEqual(testCase,truth.value,.08*double(truth.timeSeconds >= 50));
verifyFalse(testCase,any(v.model == "Known-model reference"));
verifyFalse(testCase,any(v.scenario == "no_change"));
end
