function tests = test_study2_reporting
%TEST_STUDY2_REPORTING Analytical rank checks and stored-report fixtures.
tests = functiontests(localfunctions);
end

function setupOnce(testCase)
testCase.TestData.previousPath = path;
root = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(root,'studies','study2'));
end

function teardownOnce(testCase)
path(testCase.TestData.previousPath);
end

function testFullRankConditionAndScale(testCase)
[rank,condition,valid] = study2_gram_diagnostic(diag([4,2,1]));
verifyTrue(testCase,valid);
verifyEqual(testCase,rank,3);
verifyEqual(testCase,condition,4);
[scaledRank,scaledCondition,scaledValid] = study2_gram_diagnostic(1e-6*diag([4,2,1]));
verifyTrue(testCase,scaledValid);
verifyEqual(testCase,scaledRank,rank);
verifyEqual(testCase,scaledCondition,condition,'AbsTol',1e-14);
end

function testThresholdIsStrict(testCase)
[rank,condition,valid] = study2_gram_diagnostic(diag([1,1e-10]));
verifyTrue(testCase,valid);
verifyEqual(testCase,rank,1);
verifyEqual(testCase,condition,Inf);
[rank,condition] = study2_gram_diagnostic(diag([1,1.01e-10]));
verifyEqual(testCase,rank,2);
verifyEqual(testCase,condition,1/(1.01e-10),'RelTol',1e-14);
[rank,condition] = study2_gram_diagnostic(diag([1,0.99e-10]));
verifyEqual(testCase,rank,1);
verifyEqual(testCase,condition,Inf);
end

function testZeroAndDeficientMatrices(testCase)
[rank,condition,valid] = study2_gram_diagnostic(zeros(3));
verifyTrue(testCase,valid);
verifyEqual(testCase,rank,0);
verifyEqual(testCase,condition,Inf);
[rank,condition,valid] = study2_gram_diagnostic(diag([3,2,0]));
verifyTrue(testCase,valid);
verifyEqual(testCase,rank,2);
verifyEqual(testCase,condition,Inf);
end

function testInvalidMatricesAreNotDeficientWindows(testCase)
for G = {diag([1,NaN]),diag([1,Inf]),zeros(2,3),zeros(0),[1,1i;0,1]}
    [rank,condition,valid] = study2_gram_diagnostic(G{1});
    verifyFalse(testCase,valid);
    verifyTrue(testCase,isnan(rank));
    verifyTrue(testCase,isnan(condition));
end
end

function testReportRetainsInfInvalidCountsAndPrefixBoundary(testCase)
folder = testCase.applyFixture(matlab.unittest.fixtures.TemporaryFolderFixture);
mkdir(fullfile(folder.Folder,'runs'));
result = fixture_run('A','Affine',3);
result.nSteps = 53; result.completed = false;
result.gram(:,:,51) = eye(3);
result.gram(:,:,52) = diag([1,1,0]);
result.gram(:,:,53) = diag([1,1,NaN]);
result.gram(:,:,54:55) = 0; % These allocated future entries must not count.
save(fullfile(folder.Folder,'runs','amplitude_01_A.mat'),'result');
result = fixture_run('K','Known model',0);
result.gramCount(:) = 0;
save(fullfile(folder.Folder,'runs','amplitude_01_K.mat'),'result');
report = study2_gram_report(folder.Folder);
verifyEqual(testCase,height(report),2);
row = report(report.model == "A",:);
verifyTrue(testCase,row.applicable);
verifyEqual(testCase,row.modelName,"Affine");
verifyEqual(testCase,row.status,"numerically rank deficient; invalid windows; incomplete run");
verifyEqual(testCase,[row.rankMin,row.rankMax],[2,3]);
verifyEqual(testCase,[row.recordedFullWindowCount,row.validFullWindowCount, ...
    row.invalidFullWindowCount,row.deficientWindowCount],[3,2,1,1]);
verifyEqual(testCase,row.fractionDeficient,0.5);
verifyEqual(testCase,[row.conditionMin,row.conditionMax],[1,Inf]);
known = report(report.model == "K",:);
verifyFalse(testCase,known.applicable);
verifyEqual(testCase,known.status,"N/A");
verifyEqual(testCase,known.parameterCount,0);
verifyEqual(testCase,known.recordedFullWindowCount,0);
verifyTrue(testCase,isnan(known.rankMin) && isnan(known.conditionMax));
end

function testReportWithoutAFullWindow(testCase)
folder = testCase.applyFixture(matlab.unittest.fixtures.TemporaryFolderFixture);
mkdir(fullfile(folder.Folder,'runs'));
result = fixture_run('A','Affine',3);
result.nSteps = 49;
save(fullfile(folder.Folder,'runs','amplitude_01_A.mat'),'result');
report = study2_gram_report(folder.Folder);
verifyEqual(testCase,report.status,"no full windows");
verifyEqual(testCase,report.recordedFullWindowCount,0);
verifyEqual(testCase,report.validFullWindowCount,0);
verifyTrue(testCase,isnan(report.rankMin) && isnan(report.fractionDeficient));
end

function testReferenceCrosscheckKeepsStoredAndCorrectedConditionsDistinct(testCase)
folder = testCase.applyFixture(matlab.unittest.fixtures.TemporaryFolderFixture);
mkdir(fullfile(folder.Folder,'runs'));
result = fixture_run('A','Affine',3);
result.gram = repmat(diag([1,1,0]),1,1,55);
result.gramCondition(51:55) = [10,20,30,40,50];
save(fullfile(folder.Folder,'runs','amplitude_01_A.mat'),'result');
reference = table("A","Affine",0.2,3,5,2,2,5,50,1e-10,'VariableNames', ...
    {'model','modelName','amplitude','coefficients','fullWindows','rankMin', ...
    'rankMax','rankDeficientWindows','maxStoredCondition','relative_singular_value_threshold'});
referenceFile = fullfile(folder.Folder,'reference.csv');
writetable(reference,referenceFile);
report = study2_gram_report(folder.Folder,referenceFile);
verifyEqual(testCase,report.conditionMax,Inf);
verifyFalse(testCase,ismember('maxStoredCondition',report.Properties.VariableNames));
verifyEqual(testCase,report.status,"numerically rank deficient");
reference.maxStoredCondition = Inf;
writetable(reference,referenceFile);
verifyError(testCase,@() study2_gram_report(folder.Folder,referenceFile), ...
    'study2:GramReferenceMismatch');
reference.maxStoredCondition = 50; reference.rankMax = 3;
writetable(reference,referenceFile);
verifyError(testCase,@() study2_gram_report(folder.Folder,referenceFile), ...
    'study2:GramReferenceMismatch');
end

function r = fixture_run(id,name,n)
r = struct('id',id,'name',name,'kind','amplitude','amplitude',0.2, ...
    'nSteps',55,'nEstimated',n,'completed',true, ...
    'gramCount',min(0:54,50),'gram',repmat(eye(n),1,1,55), ...
    'gramCondition',ones(1,55));
end
