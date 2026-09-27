function tests=test_p07_source_copies
tests=functiontests(localfunctions);
end
function setupOnce(t)
t.TestData.path=path;root=fileparts(fileparts(mfilename('fullpath')));addpath(root,fullfile(root,'studies/p07'));
end
function test_p06_plan_status_is_transformed_not_copied(t)
ref=ejc_reference_sources;file=fullfile(ref.p06,'runs/baseline_S_000.mat');z=load(file);
ejc_own_source_copies(z,"p06",file,ref);
a=z;a.item.executionStatus="PROPOSED_NOT_RUN";
verifyError(t,@()ejc_own_source_copies(a,"p06",file,ref),'ejc:OwnSource');
a=z;a.result.p06.executionStatus="COMPLETED";
verifyError(t,@()ejc_own_source_copies(a,"p06",file,ref),'ejc:OwnSource');
a=z;a.item.predictionRMS=a.item.predictionRMS+eps(a.item.predictionRMS);
verifyError(t,@()ejc_own_source_copies(a,"p06",file,ref),'ejc:OwnSource');
end
function teardownOnce(t)
path(t.TestData.path);
end
function test_checkpoint_is_exact_even_inside_numeric_allowance(t)
f=struct('theta',[1 2 3 4],'checkpointTheta',[2 4], ...
    'covariance',reshape(1:4,1,1,4),'checkpointCovariance',reshape([2 4],1,1,2));
z=struct('result',struct('fit',f,'forecasts',struct('fitSteps',[1 3])));
ejc_own_source_copies(z,"study1","synthetic",struct);
z.result.fit.checkpointTheta(1)=2+eps(2);
verifyError(t,@()ejc_own_source_copies(z,"study1","synthetic",struct),'ejc:OwnSource');
z.result.fit=f;z.result.fit.checkpointCovariance(1)=2+eps(2);
verifyError(t,@()ejc_own_source_copies(z,"study1","synthetic",struct),'ejc:OwnSource');
end
function test_study6_main_is_an_exact_selected_copy(t)
T=table([50;200],[1;2],'VariableNames',{'fittingTransitions','value'});
z=struct('summary',struct('primary',T,'main',T(2,:)));
v=ejc_own_source_copies(z,"study6","summary.mat",struct);verifyEqual(t,v.checks,1);
z.summary.main.value=2+eps(2);
verifyError(t,@()ejc_own_source_copies(z,"study6","summary.mat",struct),'ejc:OwnSource');
v=ejc_own_source_copies(struct('summary',T),"study6","constraint_audit.mat",struct);
verifyEqual(t,v.status,"NOT_APPLICABLE");
end
