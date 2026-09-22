function tests = test_study6_figure_data
%TEST_STUDY6_FIGURE_DATA Saved-table selection and transparent log omission.
tests = functiontests(localfunctions);
end
function setupOnce(testCase)
testCase.TestData.previousPath = path;
root = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(root,'studies','study6'));
folder = fullfile(root,'results','study6_pilot_20260922');
testCase.TestData.folder = folder;
testCase.TestData.values = study6_figure_data(folder);
end
function teardownOnce(testCase)
path(testCase.TestData.previousPath);
end
function testExactTableSelectionsAndUnits(testCase)
v = testCase.TestData.values;
t = readtable(fullfile(testCase.TestData.folder,'tables','primary.csv'),'TextType','string');
verifyEqual(testCase,height(v),40);
verifyTrue(testCase,all(v.attemptedQueries == 29 & v.finiteQueries == 29));
verifyEqual(testCase,unique(v.horizon),[1;2;5;10;20]);
verifyEqual(testCase,v.horizonSeconds,v.horizon*.1);
for j = 1:height(v)
    r = v(j,:); study = 2; range = 1.1; unit = "dimensionless state";
    if r.panel == "b", study = 5; range = .6; unit = "rad/s"; end
    source = t(t.kind == "commonData" & t.sourceCampaign == "pilot" & t.trial == 0 & ...
        t.fittingTransitions == 200 & t.inputMode == "rateLimited" & t.initialization == "clean" & ...
        t.sourceStudy == study & t.plant == r.plant & t.evaluationRange == range & ...
        t.modelId == r.modelId & t.horizon == r.horizon,:);
    verifyEqual(testCase,height(source),1);
    verifyEqual(testCase,r.value,source.(r.sourceColumn));
    verifyEqual(testCase,r.unit,unit);
end
verifyEqual(testCase,unique(v.modelId),["A";"E";"I"]);
end
function testFirstStepFreezingRetainedWithoutFloor(testCase)
v = testCase.TestData.values; omitted = v(v.plotted == 0,:);
verifyEqual(testCase,height(omitted),2);
verifyTrue(testCase,all(omitted.horizon == 1 & omitted.errorComponent == "Freezing error"));
verifyTrue(testCase,all(omitted.value > 0 & omitted.value < 1e-15));
verifyEqual(testCase,nnz(v.plotted),38);
verifyTrue(testCase,all(v.plotted(v.errorComponent ~= "Freezing error") == 1));
for panel = ["a","b"]
    curve = v(v.panel == panel & v.errorComponent == "Freezing error" & v.plotted == 1,:);
    verifyEqual(testCase,curve.horizon,[2;5;10;20]);
end
end
