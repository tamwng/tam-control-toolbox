function tests = test_study2_figure_data
%TEST_STUDY2_FIGURE_DATA Reporting selection, independent of model ranking.
tests = functiontests(localfunctions);
end

function testSavedFigurePointsAndWindows(testCase)
root = fileparts(fileparts(mfilename('fullpath')));
oldPath = path;
cleanup = onCleanup(@() path(oldPath));
addpath(fullfile(root,'studies','study2'));
folder = fullfile(root,'results','study2_pilot_20260918');
points = study2_figure_data(folder);
left = points(points.panel == "a",:);
right = points(points.panel == "b",:);
verifyEqual(testCase,[height(left),height(right)],[15 18]);
verifyEqual(testCase,unique(left.horizontalValue),[.25;.70;1.10]);
verifyEqual(testCase,unique(right.horizontalValue),[.2;.6;1]);
verifyFalse(testCase,any(left.model == "Known model"));
verifyEqual(testCase,nnz(right.model == "Known model"),3);
verifyTrue(testCase,all(left.fittingTransitions == 200));
verifyTrue(testCase,all(right.window == "20 <= t < 80 s" & right.scoredSamples == 600));
source = readtable(fullfile(folder,'tables','run_metrics.csv'),'TextType','string');
for j = 1:height(right)
    p = right(j,:);
    row = source(source.model == p.modelId & source.amplitude == p.horizontalValue & ...
        source.kind == "amplitude" & source.window == "principal",:);
    verifyEqual(testCase,p.metricValue,row.trackingRMS);
end
end
