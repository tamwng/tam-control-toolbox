function tests = test_p07_comparison
%TEST_P07_COMPARISON Protect comparison coverage and explicit exclusions.
% Small synthetic files only; no historical output or controller run.
tests = functiontests(localfunctions);
end

function setupOnce(t)
t.TestData.previousPath = path;
root = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(root,'studies','p07'));
end

function teardownOnce(t)
path(t.TestData.previousPath);
end

function testExactScientificValuesAndTimingExclusions(t)
[sources,references,output] = fixture(t);
file = fullfile(sources.study3,'record.mat'); saved = load(file);
saved.value.controlTime = 700;
saved.value.sourceFile = 'new/source.mat';
saved.value.cfg.execution = 'Fresh candidate';
saved.value.cfg.sourceDirectories = {'new-source'};
saved.value.cfg.sourceMode = 'fresh';
save(file,'-struct','saved');
report = ejc_compare_results(sources,references,output);
verifyTrue(t,report.passed); verifyEqual(t,height(report.files),7);
verifyTrue(t,all(report.files.maximumAbsoluteDifference == 0));
verifyTrue(t,any(contains(report.exclusions.quantity,'controlTime')));
verifyTrue(t,isfile(fullfile(output,'comparison.mat')));
verifyError(t,@() ejc_compare_results(sources,references,output),'ejc:ExistingComparison');
end

function testConditioningIsScientificAndReportsMaximum(t)
[sources,references,output] = fixture(t);
file = fullfile(sources.study2,'record.mat'); saved = load(file);
saved.value.qpCondition(2) = saved.value.qpCondition(2)+.25;
save(file,'-struct','saved');
report = ejc_compare_results(sources,references,output);
verifyFalse(t,report.passed);
row = report.files(report.files.study == "study2",:);
verifyEqual(t,row.maximumAbsoluteDifference,.25);
verifyEqual(t,row.maximumLinearIndex,2);
verifyTrue(t,endsWith(row.maximumField,'.qpCondition'));
verifyEqual(t,height(report.failures),1);
end

function testNonfiniteMasksAndDiscreteFieldsAreExact(t)
[sources,references,output] = fixture(t);
file = fullfile(sources.study4,'record.mat'); saved = load(file);
saved.value.x(3) = Inf; saved.value.caseId = 'different';
save(file,'-struct','saved');
report = ejc_compare_results(sources,references,output);
verifyFalse(t,report.passed);
row = report.files(report.files.study == "study4",:);
verifyEqual(t,row.nonfiniteMaskMismatches,1);
verifyEqual(t,row.failedChecks,2);
end

function testMissingAndUnexpectedFilesFail(t)
[sources,references,output] = fixture(t);
% Both files remain within this test fixture; no archive paths are touched.
movefile(fullfile(sources.study5,'record.mat'),fullfile(sources.study5,'unexpected.mat'));
report = ejc_compare_results(sources,references,output);
verifyFalse(t,report.passed);
verifyEqual(t,nnz(~report.inventory.passed),2);
verifyEqual(t,nnz(~report.files.passed),2);
verifyEqual(t,height(report.failures),2);
verifyEqual(t,sort(report.failures.relativePath),["record.mat";"unexpected.mat"]);
end

function testEmptyStructSchemaCannotDisappear(t)
[sources,references,output] = fixture(t);
file = fullfile(sources.study6,'record.mat'); saved = load(file);
saved.value.events = struct('other',{});
save(file,'-struct','saved');
report = ejc_compare_results(sources,references,output);
verifyFalse(t,report.passed);
verifyTrue(t,any(contains(report.failures.quantity,'.events.')));
end

function testTableCountsAndRowOrderAreCompared(t)
[sources,references,output] = fixture(t);
counts = table([1;2],[40;39],[.1;.2],'VariableNames',{'trial','completePairs','median'});
writetable(counts,fullfile(references.p06,'counts.csv'));
counts = counts([2 1],:); writetable(counts,fullfile(sources.p06,'counts.csv'));
report = ejc_compare_results(sources,references,output);
verifyFalse(t,report.passed);
verifyTrue(t,any(contains(report.failures.quantity,'completePairs')));
end

function testIndividualStudyStillRequiresAllItsFiles(t)
[sources,references,output] = fixture(t);
sources = struct('study3',sources.study3);
report = ejc_compare_results(sources,references,output);
verifyTrue(t,report.passed);
verifyEqual(t,height(report.files),1);
verifyEqual(t,report.files.study,"study3");
end

function [sources,references,output] = fixture(t)
temporary = t.applyFixture(matlab.unittest.fixtures.TemporaryFolderFixture);
root = temporary.Folder; sources = struct; references = struct;
for group = ["study1","study2","study3","study4","study5","study6","p06"]
    sources.(group) = fullfile(root,'current',group);
    references.(group) = fullfile(root,'reference',group);
    mkdir(sources.(group)); mkdir(references.(group));
    value = struct('caseId','fixed','x',[1 2 NaN Inf -Inf], ...
        'qpCondition',[2 3 4],'controlTime',.01,'sourceFile','old/source.mat', ...
        'cfg',struct('Ts',.1,'execution','Historical'), ...
        'events',struct('index',{},'message',{}));
    save(fullfile(references.(group),'record.mat'),'value');
    save(fullfile(sources.(group),'record.mat'),'value');
end
output = fullfile(root,'comparison'); mkdir(output);
end
