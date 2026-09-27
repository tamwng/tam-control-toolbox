function tests = test_p07_reporting
%TEST_P07_REPORTING Source/output separation and saved-response inspection.
tests = functiontests(localfunctions);
end

function setupOnce(t)
t.TestData.previousPath = path;
root = fileparts(fileparts(mfilename('fullpath')));
t.TestData.root = root;
for study = 1:6, addpath(fullfile(root,'studies',sprintf('study%d',study))); end
addpath(fullfile(root,'studies','p06','tests'));
addpath(fullfile(root,'studies','p07'));
t.TestData.sources = ejc_reference_sources;
end

function teardownOnce(t)
path(t.TestData.previousPath);
end

function testSeparateStudy1SummaryMatchesPreinterfaceOracle(t)
fixture = t.applyFixture(matlab.unittest.fixtures.TemporaryFolderFixture);
source = fullfile(fixture.Folder,'source');
cfg = p06_legacy_fixture(source);
before = read_bytes(fullfile(source,'tables','measured_initialization_audit.csv'));
destination = fullfile(fixture.Folder,'report');
actual = study1_summarize(source,cfg,destination);
saved = load(fullfile(t.TestData.root,'studies','p06','tests','fixtures','pre_interface.mat'),'oracle');
runs=cell(2,1);campaigns={'pilot','confirmation'};
for j=1:2
    parent=load(fullfile(source,'data',[campaigns{j},'_S_000.mat']),'result');
    runs{j}=parent.result;
end
portable=ejc_covariance_report_compare(actual,saved.oracle.summary,runs,runs,cfg);
verifyTrue(t,portable.passed,portable.reason);
verifyTrue(t,isfile(fullfile(destination,'tables','run_metrics.csv')));
verifyFalse(t,isfile(fullfile(source,'tables','run_metrics.csv')));
verifyEqual(t,read_bytes(fullfile(source,'tables','measured_initialization_audit.csv')),before);
helpers = study1_summarize('p06_helpers');
verifyTrue(t,isa(helpers.scoreRun,'function_handle'));
end

function testStudy4InitializationEvidenceGoesToDestination(t)
fixture = t.applyFixture(matlab.unittest.fixtures.TemporaryFolderFixture);
source = t.TestData.sources.study4;
settings = load(fullfile(source,'settings.mat'),'cfg');
originalFile = fullfile(source,'evaluation','initialization.mat');
before = read_bytes(originalFile);
original = load(originalFile,'initialization');
destination = fullfile(fixture.Folder,'report');
summary = study4_summarize(source,settings.cfg,destination);
regenerated = load(fullfile(destination,'evaluation','initialization.mat'),'initialization');
verifyEqual(t,regenerated.initialization,original.initialization);
verifyEqual(t,read_bytes(originalFile),before);
verifyEqual(t,height(summary.counts),1);
verifyTrue(t,isfile(fullfile(destination,'tables','metrics.csv')));
end

function testSummariesRejectProtectedDestinationsBeforeWriting(t)
for study = 1:5
    key = sprintf('study%d',study);
    source = t.TestData.sources.(key);
    summarize = str2func(sprintf('study%d_summarize',study));
    verifyError(t,@() summarize(source,struct),'ejc:ProtectedOutput');
end
verifyError(t,@() study6_verify_results(t.TestData.sources.study6),'ejc:ProtectedOutput');
end

function testJournalExportersRejectExistingAndProtectedDestinations(t)
fixture = t.applyFixture(matlab.unittest.fixtures.TemporaryFolderFixture);
for study = 1:6
    source = t.TestData.sources.(sprintf('study%d',study));
    exporter = str2func(sprintf('plot_study%d_journal',study));
    verifyError(t,@() exporter(source,fixture.Folder),'ejc:ExistingOutput');
    verifyError(t,@() exporter(source,fullfile(source,'forbidden_export')),'ejc:ProtectedOutput');
    verifyFalse(t,isfolder(fullfile(source,'forbidden_export')));
end
files = dir(fixture.Folder);
verifyEmpty(t,files(~ismember({files.name},{'.','..'})));
end

function testInspectorUsesSavedAppliedSamplesAndPreservesRandomness(t)
source = t.TestData.sources.study1;
filename = fullfile(source,'data','confirmation_S_001.mat');
original = read_bytes(filename);
saved = load(filename,'result'); r = saved.result;
before = rng;
[fig,selection] = inspect_ejc(1,'confirmation_S_001',source,'Visible','off');
cleanup = onCleanup(@() close(fig));
verifyEqual(t,rng,before);
verifyEqual(t,selection.sourceFile,filename);
verifyEqual(t,selection.savedTo,'');
line = findobj(fig,'Tag','ejc.appliedInput');
verifyEqual(t,line.XData,r.time(1:r.nSteps));
verifyEqual(t,line.YData,r.u(1:r.nSteps));
line = findobj(fig,'Tag','ejc.output');
verifyEqual(t,line.YData,r.x(1:r.nSteps+1));
verifyEqual(t,read_bytes(filename),original);
end

function testInspectorSavesOnlyOnExplicitRequest(t)
fixture = t.applyFixture(matlab.unittest.fixtures.TemporaryFolderFixture);
source = t.TestData.sources.study1;
target = fullfile(fixture.Folder,'inspection.png'); before = rng;
[fig,selection] = inspect_ejc(1,'confirmation_S_001',source,'SaveTo',target,'Visible','off');
cleanup = onCleanup(@() close(fig));
verifyTrue(t,isfile(target)); verifyEqual(t,selection.savedTo,target);
verifyEqual(t,rng,before);
verifyError(t,@() inspect_ejc(1,'confirmation_S_001',source, ...
    'SaveTo',target,'Visible','off'),'ejc:ExistingOutput');
end

function testInspectorRejectsMissingCaseAndProtectedExport(t)
source = t.TestData.sources.study1;
before = rng;
verifyError(t,@() inspect_ejc(1,'missing_case',source,'Visible','off'),'ejc:MissingInspectionCase');
verifyError(t,@() inspect_ejc(1,'confirmation_S_001',source, ...
    'SaveTo',fullfile(source,'forbidden.png'),'Visible','off'),'ejc:ProtectedOutput');
verifyFalse(t,isfile(fullfile(source,'forbidden.png')));
verifyEqual(t,rng,before);
end

function testStudy6ExplicitBindingNeverFallsBackToHistoricalSource(t)
fixture = t.applyFixture(matlab.unittest.fixtures.TemporaryFolderFixture);
cfg = study6_settings;
verifyEqual(t,study6_source(t.TestData.root,cfg,1),t.TestData.sources.study1);
cfg.sourceDirectories = repmat({fixture.Folder},1,5);
verifyEqual(t,study6_source(t.TestData.root,cfg,1),fixture.Folder);
cfg.sourceDirectories{1} = fullfile(fixture.Folder,'missing');
verifyError(t,@() study6_source(t.TestData.root,cfg,1),'study6:MissingSource');
end

function bytes = read_bytes(filename)
file = fopen(filename,'rb');
assert(file ~= -1,'ejc:TestRecord','Cannot read the required reference.');
cleanup = onCleanup(@() fclose(file));
bytes = fread(file,Inf,'*uint8');
end
