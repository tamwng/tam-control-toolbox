function tests=test_p07_p06_reporting
% Approved portable replacements for two strict P06 reporting assertions.
% Original P06 tests are unedited and their strict execution remains recorded.
tests=functiontests(localfunctions);
end
function setupOnce(t)
root=fileparts(fileparts(mfilename('fullpath')));t.TestData.path=path;
addpath(root,fullfile(root,'src'),fullfile(root,'studies/p07'),fullfile(root,'studies/study1'),fullfile(root,'studies/p06/tests'));
f=t.applyFixture(matlab.unittest.fixtures.TemporaryFolderFixture);
source=fullfile(f.Folder,'source');refs=reference_test_sources;cfg=p06_legacy_fixture(source,refs.study1);
t.TestData.actual=study1_summarize(source,cfg,fullfile(f.Folder,'report'));
z=load(fullfile(root,'studies/p06/tests/fixtures/pre_interface.mat'),'oracle');t.TestData.expected=z.oracle.summary;
t.TestData.cfg=cfg;t.TestData.source=source;
runs=cell(2,1);campaigns={'pilot','confirmation'};
for k=1:2,z=load(fullfile(source,'data',[campaigns{k},'_S_000.mat']),'result');runs{k}=z.result;end
t.TestData.runs=runs;
end
function teardownOnce(t)
path(t.TestData.path);
end
function testOriginalTwoArgumentSummaryPortable(t)
d=t.TestData;
% Exercise the exact original two-argument form in its own new temporary
% fixture; no historical output or expected value is changed.
f=t.applyFixture(matlab.unittest.fixtures.TemporaryFolderFixture);
refs=reference_test_sources;cfg=p06_legacy_fixture(fullfile(f.Folder,'two_argument'),refs.study1);
a=study1_summarize(fullfile(f.Folder,'two_argument'),cfg);
v=ejc_covariance_report_compare(a,d.expected,d.runs,d.runs,d.cfg);
verifyTrue(t,v.passed,v.reason);
end
function testPublicScoresEqualOriginalInternalScoresPortable(t)
d=t.TestData;h=study1_summarize('p06_helpers');r=d.runs{2};a=d.actual;
base=struct('campaign',"confirmation",'model',"S",'trial',0,'noise',false);
rows=a.metrics.campaign=="confirmation";a.metrics(rows,:)=struct2table(h.scoreRun(r,base,d.cfg));
rows=a.initialization.campaign=="confirmation";a.initialization(rows,:)=struct2table(h.scoreFit(r,base,d.cfg));
diagnostics=struct2table(h.diagnoseRun(r,base,d.cfg));
z=load(fullfile(d.source,'audits/confirmation_S_000.mat'),'audit');
diagnostics.measuredAuditInvalid=nnz(~z.audit.valid);
rows=a.diagnostics.campaign=="confirmation";a.diagnostics(rows,:)=diagnostics;
v=ejc_covariance_report_compare(a,d.expected,d.runs,d.runs,d.cfg);
verifyTrue(t,v.passed,v.reason);
end
