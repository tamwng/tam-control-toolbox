function tests = test_study5_figure_data
%TEST_STUDY5_FIGURE_DATA Archive selections, units, and absence of rescaling.
tests = functiontests(localfunctions);
end
function setupOnce(testCase)
testCase.TestData.previousPath = path;
root = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(root,'studies','study5'));
folder = fullfile(root,'results','study5_pilot_20260922');
testCase.TestData.folder = folder;
testCase.TestData.values = study5_figure_data(folder);
end
function teardownOnce(testCase)
path(testCase.TestData.previousPath);
end
function testQuadratureIsAlreadyNormalized(testCase)
points = testCase.TestData.values; left = points(points.panel == "a",:);
source = sortrows(readtable(fullfile(testCase.TestData.folder,'tables','quadrature.csv')),'Ts');
verifyEqual(testCase,height(left),6);
verifyEqual(testCase,left.horizontalValue,repmat([.025;.05;.1],2,1));
verifyEqual(testCase,left.value,[source.trapezoidResidualRMS_Nm;source.trapezoidResidualMax_Nm]);
verifyEqual(testCase,unique(left.series),["Maximum";"RMS"]);
verifyTrue(testCase,all(left.unit == "N m" & left.horizontalUnit == "s" & left.queryCount == 441));
end
function testNonlinearForecastIncludesItsOwnOneStepScores(testCase)
points = testCase.TestData.values; right = points(points.panel == "b",:);
folder = testCase.TestData.folder;
source = readtable(fullfile(folder,'tables','forecasts.csv'),'TextType','string');
initialization = readtable(fullfile(folder,'tables','initialization.csv'),'TextType','string');
verifyEqual(testCase,height(right),20);
verifyEqual(testCase,unique(right.horizontalValue),[1;2;5;10;20]*.1);
verifyTrue(testCase,all(right.fittingTransitions == 200 & right.inputMode == "rateLimited" & right.queryCount == 29));
verifyTrue(testCase,all(right.unit == "rad/s" & right.horizontalUnit == "s"));
verifyFalse(testCase,any(right.series == "Known-model reference"));
for name = ["Integrated physical","Euler-informed direct","Affine","Complete cubic"]
    block = right(right.series == name,:);
    expected = sortrows(source(source.model == name & source.inputMode == "rateLimited" & source.fittingTransitions == 200,:),'horizon');
    verifyEqual(testCase,block.value,expected.predictionRMS);
    other = initialization(initialization.model == name & initialization.fittingTransitions == 200,:);
    verifyNotEqual(testCase,block.value(1),other.predictionRMS);
end
end
