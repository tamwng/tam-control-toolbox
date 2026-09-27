function tests=test_p07_reporting_adapter
tests=functiontests(localfunctions);
end
function setupOnce(t)
root=fileparts(fileparts(mfilename('fullpath')));t.TestData.path=path;
addpath(root,fullfile(root,'src'),fullfile(root,'studies/p07'), ...
    fullfile(root,'studies/study1'),fullfile(root,'studies/p06/tests'));
f=t.applyFixture(matlab.unittest.fixtures.TemporaryFolderFixture);
source=fullfile(f.Folder,'source');cfg=p06_legacy_fixture(source);
t.TestData.a=study1_summarize(source,cfg,fullfile(f.Folder,'summary'));
z=load(fullfile(root,'studies/p06/tests/fixtures/pre_interface.mat'),'oracle');t.TestData.b=z.oracle.summary;
runs=cell(2,1);campaigns={'pilot','confirmation'};
for k=1:2,z=load(fullfile(source,'data',[campaigns{k},'_S_000.mat']),'result');runs{k}=z.result;end
t.TestData.runs=runs;t.TestData.cfg=cfg;
end
function teardownOnce(t)
path(t.TestData.path);
end
function test_approved_fieldwise_positive(t)
d=t.TestData;r=ejc_covariance_report_compare(d.a,d.b,d.runs,d.runs,d.cfg);
verifyTrue(t,r.passed,r.reason);verifyGreaterThan(t,r.qualifiedCount,0);
verifyTrue(t,all([r.rows.passed]));verifyFalse(t,any([r.gramRows.rawExtremumReproduced]));
end
function test_beyond_budget_and_masks(t)
d=t.TestData;
for v=[d.b.diagnostics.covarianceConditionMax(1)+1e-3,NaN,Inf]
    a=d.a;a.diagnostics.covarianceConditionMax(1)=v;
    r=ejc_covariance_report_compare(a,d.b,d.runs,d.runs,d.cfg);verifyFalse(t,r.passed);
end
end
function test_exact_schema_count_source(t)
d=t.TestData;
a=d.a;a.diagnostics.extra=zeros(height(a.diagnostics),1);
r=ejc_covariance_report_compare(a,d.b,d.runs,d.runs,d.cfg);verifyFalse(t,r.passed);
a=d.a;a.diagnostics.attemptedSteps(1)=a.diagnostics.attemptedSteps(1)+1;
r=ejc_covariance_report_compare(a,d.b,d.runs,d.runs,d.cfg);verifyFalse(t,r.passed);
a=d.a;a.diagnostics.trial(1)=9;b=d.b;b.diagnostics.trial(1)=9;
r=ejc_covariance_report_compare(a,b,d.runs,d.runs,d.cfg);verifyFalse(t,r.passed);
runs=d.runs;runs{1}.id='A';
r=ejc_covariance_report_compare(d.a,d.b,runs,d.runs,d.cfg);verifyFalse(t,r.passed);
end
function test_invalid_parent_and_no_blanket_tolerance(t)
d=t.TestData;runs=d.runs;runs{1}.covariance(:,:,1)=-eye(size(runs{1}.covariance,1));
r=ejc_covariance_report_compare(d.a,d.b,runs,d.runs,d.cfg);verifyFalse(t,r.passed);
a=d.a;a.diagnostics.identificationAttempted(1)=a.diagnostics.identificationAttempted(1)+1;
r=ejc_covariance_report_compare(a,d.b,d.runs,d.runs,d.cfg);verifyFalse(t,r.passed);
end
