function tests = test_study3_reporting
%TEST_STUDY3_REPORTING Journal histories remain exact, causal archive views.
tests = functiontests(localfunctions);
end

function setupOnce(testCase)
testCase.TestData.previousPath = path;
root = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(root,'studies','study3'));
testCase.TestData.source = fullfile(root,'results','study3_pilot_20260918');
testCase.TestData.values = study3_figure_data(testCase.TestData.source);
end

function teardownOnce(testCase)
path(testCase.TestData.previousPath);
end

function testExactSavedHistoriesAndInclusiveEndpoints(testCase)
values = testCase.TestData.values;
ids = {'S_none','S_fixed','S_vrf','S_pretrained','K'};
for scenario = ["abrupt","drift"]
    block = values(values.scenario == scenario,:);
    indices = 451:651;
    if scenario == "drift", indices = 451:1001; end
    verifyEqual(testCase,height(block),numel(indices));
    for j = 1:5
        s = load(fullfile(testCase.TestData.source,'runs', ...
            sprintf('%s_%s_000.mat',scenario,ids{j})),'result');
        r = s.result;
        verifyEqual(testCase,block.timeSeconds,r.time(indices).');
        verifyEqual(testCase,block{:,2+j},(r.x(indices)-r.r(indices)).');
        if j <= 4, verifyEqual(testCase,block{:,7+j},r.theta(3,indices).'); end
        if j <= 3, verifyEqual(testCase,block{:,12+j},r.lambda(indices).'); end
        verifyEqual(testCase,block.currentTrueGain,r.trueGain(indices).');
    end
end
end

function testOnlyRequiredTracesHaveColumns(testCase)
values = testCase.TestData.values;
names = string(values.Properties.VariableNames);
verifyEqual(testCase,size(values),[752 15]);
verifyEqual(testCase,nnz(startsWith(names,"trackingError")),5);
verifyEqual(testCase,nnz(startsWith(names,"gainEstimate")),4);
verifyEqual(testCase,names(startsWith(names,"forgettingFactor")), ...
    ["forgettingFactorNoForgetting","forgettingFactorFixedForgetting", ...
    "forgettingFactorVariableRateForgetting"]);
verifyFalse(testCase,any(contains(names,"gainEstimateKnown")));
end

function testEventExtremaAndActivationAreNotResampled(testCase)
values = testCase.TestData.values;
for scenario = ["abrupt","drift"]
    block = values(values.scenario == scenario,:);
    for id = ["S_fixed","S_vrf"]
        s = load(fullfile(testCase.TestData.source,'runs', ...
            sprintf('%s_%s_000.mat',scenario,id)),'result'); r = s.result;
        mask = r.time(1:end-1) >= block.timeSeconds(1) & ...
            r.time(1:end-1) <= block.timeSeconds(end);
        if id == "S_fixed"
            [minimum,index] = min(r.theta(3,mask));
            [plotted,plottedIndex] = min(block.gainEstimateFixedForgetting);
            verifyEqual(testCase,plotted,minimum);
            verifyEqual(testCase,plottedIndex,index);
        else
            first = find(r.lambda < 1 & mask,1);
            plottedFirst = find(block.forgettingFactorVariableRateForgetting < 1,1);
            verifyEqual(testCase,block.timeSeconds(plottedFirst),r.time(first));
        end
    end
end
end
