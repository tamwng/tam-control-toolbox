function tests=test_p07_representative
tests=functiontests(localfunctions);
end
function setupOnce(t)
root=fileparts(fileparts(mfilename('fullpath')));t.TestData.path=path;
addpath(root,fullfile(root,'src'),fullfile(root,'studies/study1'),fullfile(root,'studies/p07'));
sources=ejc_reference_sources;z=load(fullfile(sources.study1,'data/confirmation_S_000.mat'),'result');
c=load(fullfile(sources.study1,'settings.mat'),'cfg');t.TestData.run=z.result;t.TestData.cfg=c.cfg;
end
function teardownOnce(t)
path(t.TestData.path);
end
function test_complete_scope_and_qualified_propagation(t)
d=t.TestData;r=ejc_compare_representative(d.run,d.run,d.cfg);
verifyTrue(t,r.passed,r.reason);verifyEqual(t,numel(unique(string({r.rows.coverageId}))),79);
verifyEqual(t,r.status,"PASSED_WITH_GRAM_QUALIFICATIONS");verifyGreaterThan(t,r.qualifiedCount,0);
verifyEqual(t,r.conditions.covarianceCount,1200);verifyEqual(t,r.conditions.gramCount,1199);
verifyEqual(t,r.conditions.hessianCount,1200);
end
function test_complete_plans_gate_every_horizon(t)
d=t.TestData;
for name=["plannedInput","plannedOutput","slack"]
 a=d.run;a.(name)(end)=a.(name)(end)+1e-3;
 r=ejc_compare_representative(a,d.run,d.cfg);verifyFalse(t,r.passed);
end
end
function test_checkpoint_calibration_schema_and_outcome_are_exact(t)
d=t.TestData;
a=d.run;a.fit.checkpointTheta(1)=a.fit.checkpointTheta(1)+eps(a.fit.checkpointTheta(1));
r=ejc_compare_representative(a,d.run,d.cfg);verifyFalse(t,r.passed);
a=d.run;a.fit.D(1)=a.fit.D(1)+eps(a.fit.D(1));
r=ejc_compare_representative(a,d.run,d.cfg);verifyFalse(t,r.passed);
a=d.run;a.unapproved=1;r=ejc_compare_representative(a,d.run,d.cfg);verifyFalse(t,r.passed);
a=d.run;a.gramCount(2)=2;r=ejc_compare_representative(a,d.run,d.cfg);verifyFalse(t,r.passed);
end
function test_required_nonfinite_and_wrong_nan_sentinel_fail(t)
d=t.TestData;
a=d.run;a.plannedOutput(2,2)=NaN;r=ejc_compare_representative(a,d.run,d.cfg);verifyFalse(t,r.passed);
a=d.run;a.forecasts.maxAffineFreezingError=0;
r=ejc_compare_representative(a,a,d.cfg);verifyFalse(t,r.passed);
a=d.run;a.gramCondition(2)=-Inf;r=ejc_compare_representative(a,a,d.cfg);verifyFalse(t,r.passed);
end
function test_wall_clock_exclusion_is_narrow(t)
d=t.TestData;a=d.run;a.controlTime(:)=a.controlTime+1;
r=ejc_compare_representative(a,d.run,d.cfg);verifyTrue(t,r.passed,r.reason);
a=d.run;a.qpCondition(1)=a.qpCondition(1)+1;
r=ejc_compare_representative(a,d.run,d.cfg);verifyFalse(t,r.passed);
end
function test_forgetting_branch_cannot_hide_inside_numeric_bound(t)
d=t.TestData;a=d.run;b=d.run;a.lambda(2)=1-1e-12;
v=ejc_acceptance_numeric(a.lambda(2),b.lambda(2),1e-10,1e-7,true);verifyTrue(t,v.passed);
r=ejc_pair_run_screen(a,b,"study1",d.cfg,a.fit,b.fit,"F0069");verifyFalse(t,r.passed);
a=d.run;b=d.run;a.energy=[NaN,1-1e-12];b.energy=[NaN,1+1e-12];
r=ejc_pair_run_screen(a,b,"study1",d.cfg,a.fit,b.fit,"F0069");verifyFalse(t,r.passed);
end
