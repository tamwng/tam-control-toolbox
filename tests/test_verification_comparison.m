function tests = test_verification_comparison
%TEST_VERIFICATION_COMPARISON Protect comparison coverage and explicit exclusions.
% Small synthetic files only; no historical output or controller run.
tests = functiontests(localfunctions);
end

function setupOnce(t)
t.TestData.previousPath = path;
root = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(root,'verification','functions'));
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
report = verification_compare_results(sources,references,output);
verifyTrue(t,report.passed); verifyEqual(t,height(report.files),7);
verifyTrue(t,all(report.files.maximumAbsoluteDifference == 0));
verifyTrue(t,any(contains(report.exclusions.quantity,'controlTime')));
verifyTrue(t,isfile(fullfile(output,'comparison.mat')));
verifyError(t,@() verification_compare_results(sources,references,output),'ejc:ExistingComparison');
end

function testConditioningIsScientificAndReportsMaximum(t)
[sources,references,output] = fixture(t);
file = fullfile(sources.study2,'record.mat'); saved = load(file);
saved.value.qpCondition(2) = saved.value.qpCondition(2)+.25;
save(file,'-struct','saved');
report = verification_compare_results(sources,references,output);
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
report = verification_compare_results(sources,references,output);
verifyFalse(t,report.passed);
row = report.files(report.files.study == "study4",:);
verifyEqual(t,row.nonfiniteMaskMismatches,1);
verifyEqual(t,row.failedChecks,2);
end

function testMissingAndUnexpectedFilesFail(t)
[sources,references,output] = fixture(t);
% Both files remain within this test fixture; no archive paths are touched.
movefile(fullfile(sources.study5,'record.mat'),fullfile(sources.study5,'unexpected.mat'));
report = verification_compare_results(sources,references,output);
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
report = verification_compare_results(sources,references,output);
verifyFalse(t,report.passed);
verifyTrue(t,any(contains(report.failures.quantity,'.events.')));
end

function testTableCountsAndRowOrderAreCompared(t)
[sources,references,output] = fixture(t);
counts = table([1;2],[40;39],[.1;.2],'VariableNames',{'trial','completePairs','median'});
writetable(counts,fullfile(references.p06,'counts.csv'));
counts = counts([2 1],:); writetable(counts,fullfile(sources.p06,'counts.csv'));
report = verification_compare_results(sources,references,output);
verifyFalse(t,report.passed);
verifyTrue(t,any(contains(report.failures.quantity,'completePairs')));
end

function testIndividualStudyStillRequiresAllItsFiles(t)
[sources,references,output] = fixture(t);
sources = struct('study3',sources.study3);
report = verification_compare_results(sources,references,output);
verifyTrue(t,report.passed);
verifyEqual(t,height(report.files),1);
verifyEqual(t,report.files.study,"study3");
end

function testAllTwelveLegacyPilotFilesValidateFreshFlags(t)
[fresh,legacy] = legacy_values;
names = strings(0,1);
for model = ["A","K","P2","R","S","W"]
    for trial = ["000","001"]
        names(end+1,1) = "data/pilot_"+model+"_"+trial+".mat"; %#ok<AGROW>
    end
end
[sources,references,output] = legacy_fixture(t,"study1",names,fresh,legacy);
report = verification_compare_results(sources,references,output);
verifyTrue(t,report.passed); verifyEqual(t,height(report.files),12);
verifyEqual(t,height(report.exclusions),24);
verifyTrue(t,all(report.files.maximumAbsoluteDifference == 0));
verifyEqual(t,sort(unique(report.exclusions.relativePath)),sort(names));
end

function testLegacyPilotRequiresBothFreshFlags(t)
[fresh,legacy] = legacy_values;
for flag = ["identityChecksEvaluated","firstStepCheckEvaluated"]
    changed = fresh;
    changed.result.forecasts = rmfield(changed.result.forecasts,flag);
    [sources,references,output] = legacy_fixture(t,"study1","data/pilot_A_000.mat",changed,legacy);
    report = verification_compare_results(sources,references,output);
    verifyFalse(t,report.passed,flag+" must be present even when absent historically.");
    verifyTrue(t,any(contains(report.failures.quantity,flag)));
end
end

function testLegacyPilotRejectsWrongValueClassAndShapeFlags(t)
[fresh,legacy] = legacy_values;
invalid = {false,1,[true true],false(0,0)};
for flag = ["identityChecksEvaluated","firstStepCheckEvaluated"]
    for k = 1:numel(invalid)
        changed = fresh; changed.result.forecasts.(flag) = invalid{k};
        [sources,references,output] = legacy_fixture(t,"study1","data/pilot_A_000.mat",changed,legacy);
        report = verification_compare_results(sources,references,output);
        verifyFalse(t,report.passed,flag+" must match its logical scalar definition.");
        verifyTrue(t,any(contains(report.failures.quantity,flag)));
    end
end
end

function testLegacyPilotFlagsFollowFiniteMaximumDefinitions(t)
[fresh,legacy] = legacy_values;
flags = ["identityChecksEvaluated","firstStepCheckEvaluated"];
maxima = ["maxIdentityResidual","maxFirstStepFreezingError"];
for k = 1:numel(flags)
    for maximum = [NaN Inf]
        changed = fresh; retained = legacy;
        changed.result.forecasts.(maxima(k)) = maximum;
        retained.result.forecasts.(maxima(k)) = maximum;
        changed.result.forecasts.(flags(k)) = false;
        [sources,references,output] = legacy_fixture(t,"study1","data/pilot_A_000.mat",changed,retained);
        report = verification_compare_results(sources,references,output);
        verifyTrue(t,report.passed,'A correctly unevaluated flag is not a manufactured pass.');
        changed.result.forecasts.(flags(k)) = true;
        [sources,references,output] = legacy_fixture(t,"study1","data/pilot_A_000.mat",changed,retained);
        report = verification_compare_results(sources,references,output);
        verifyFalse(t,report.passed);
    end
end
end

function testLegacyPilotRetainsExactScientificValuesAndOtherFields(t)
[fresh,legacy] = legacy_values;
changed = fresh; changed.result.forecasts.identityResidual(2) = .25;
[sources,references,output] = legacy_fixture(t,"study1","data/pilot_A_000.mat",changed,legacy);
report = verification_compare_results(sources,references,output);
verifyFalse(t,report.passed); verifyEqual(t,report.files.maximumAbsoluteDifference,.25);
verifyTrue(t,any(contains(report.failures.quantity,'identityResidual')));
changed = fresh; changed.result.forecasts.otherScientificField = true;
[sources,references,output] = legacy_fixture(t,"study1","data/pilot_A_000.mat",changed,legacy);
report = verification_compare_results(sources,references,output);
verifyFalse(t,report.passed);
verifyTrue(t,any(contains(report.failures.quantity,'otherScientificField')));
end

function testLegacyPilotDoesNotExemptOtherPathsOrTrials(t)
[fresh,legacy] = legacy_values;
for name = ["data/pilot_A_002.mat","data/pilot_Z_000.mat", ...
        "data/Pilot_A_000.mat","other/pilot_A_000.mat", ...
        "data/confirmation_A_000.mat","data/pilot_A_000_extra.mat"]
    [sources,references,output] = legacy_fixture(t,"study1",name,fresh,legacy);
    report = verification_compare_results(sources,references,output);
    verifyFalse(t,report.passed,name+" is outside the approved twelve files.");
    verifyEqual(t,height(report.exclusions),0);
end
end

function testLegacyPilotDoesNotExemptOtherStudies(t)
[fresh,legacy] = legacy_values;
for group = ["study2","study3","study4","study5","study6","p06"]
    [sources,references,output] = legacy_fixture(t,group,"data/pilot_A_000.mat",fresh,legacy);
    report = verification_compare_results(sources,references,output);
    verifyFalse(t,report.passed,group+" has no legacy pilot exception.");
    verifyEqual(t,height(report.exclusions),0);
end
end

function testLegacyPilotDoesNotExemptSameNamesAtOtherNesting(t)
[fresh,legacy] = legacy_values;
for flag = ["identityChecksEvaluated","firstStepCheckEvaluated"]
    changed = fresh; retained = legacy;
    changed.result.forecasts.nested = struct(flag,true);
    retained.result.forecasts.nested = struct;
    [sources,references,output] = legacy_fixture(t,"study1","data/pilot_A_000.mat",changed,retained);
    report = verification_compare_results(sources,references,output);
    verifyFalse(t,report.passed);
    verifyTrue(t,any(contains(report.failures.quantity,'.nested.')));
end
end

function testLegacyPilotComparesFlagsAlreadyInReferenceExactly(t)
[fresh,legacy] = legacy_values;
for flag = ["identityChecksEvaluated","firstStepCheckEvaluated"]
    retained = legacy; retained.result.forecasts.(flag) = false;
    [sources,references,output] = legacy_fixture(t,"study1","data/pilot_A_000.mat",fresh,retained);
    report = verification_compare_results(sources,references,output);
    verifyFalse(t,report.passed);
    verifyTrue(t,any(contains(report.failures.quantity,flag)));
    verifyFalse(t,any(contains(report.exclusions.quantity,flag)));
end
end

function testLegacyArchiveSelfCheckDoesNotClaimFreshFlagValidation(t)
[~,legacy] = legacy_values;
[~,references,output] = legacy_fixture(t,"study1","data/pilot_A_000.mat",legacy,legacy);
report = verification_compare_results(references,references,output);
verifyTrue(t,report.passed); verifyEqual(t,height(report.exclusions),0);
verifyEqual(t,report.files.mode,"archive self-check; no fresh computation");
end

function [fresh,legacy] = legacy_values
forecasts = struct('maxIdentityResidual',0,'maxFirstStepFreezingError',0, ...
    'identityResidual',[0 0],'identityChecksEvaluated',true,'firstStepCheckEvaluated',true);
fresh = struct('result',struct('completed',true,'forecasts',forecasts));
legacy = fresh;
legacy.result.forecasts = rmfield(forecasts,{'identityChecksEvaluated','firstStepCheckEvaluated'});
end

function [sources,references,output] = legacy_fixture(t,group,names,fresh,legacy)
temporary = t.applyFixture(matlab.unittest.fixtures.TemporaryFolderFixture);
root = temporary.Folder;
sources = struct(group,fullfile(root,'current',group));
references = struct(group,fullfile(root,'reference',group));
for name = reshape(names,1,[])
    currentFile = fullfile(sources.(group),name);
    referenceFile = fullfile(references.(group),name);
    if ~isfolder(fileparts(currentFile)), mkdir(fileparts(currentFile)); end
    if ~isfolder(fileparts(referenceFile)), mkdir(fileparts(referenceFile)); end
    save(currentFile,'-struct','fresh'); save(referenceFile,'-struct','legacy');
end
output = fullfile(root,'comparison');
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
