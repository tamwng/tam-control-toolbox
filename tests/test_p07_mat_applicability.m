function tests=test_p07_mat_applicability
tests=functiontests(localfunctions);
end
function setupOnce(t)
t.TestData.path=path;root=fileparts(fileparts(mfilename('fullpath')));addpath(fullfile(root,'studies/p07'));
end
function teardownOnce(t)
path(t.TestData.path);
end
function test_required_plan_nonfinite_fails(t)
r=struct('nSteps',2,'controlAccepted',[true false false],'nEstimated',2);
v=nan(4,3);v(:,1)=1;
mask=ejc_mat_applicability("study1","data/test.mat","value[].result[].plannedInput",v,r,struct);
verifyEqual(t,mask,repmat([true false false],4,1));
verifyTrue(t,ejc_acceptance_numeric(v,v,1e-8,1e-7,mask).passed);
v(2,1)=NaN;verifyFalse(t,ejc_acceptance_numeric(v,v,1e-8,1e-7,mask).passed);
end
function test_gram_initial_and_known_masks(t)
r=struct('nSteps',3,'controlAccepted',true(1,3),'nEstimated',2);
v=zeros(2,2,3);mask=ejc_mat_applicability("study3","runs/test.mat","value[].result[].gram",v,r,struct);
verifyFalse(t,any(mask(:,:,1),'all'));verifyTrue(t,all(mask(:,:,2:3),'all'));
r.nEstimated=0;mask=ejc_mat_applicability("study3","runs/test.mat","value[].result[].gram",v,r,struct);
verifyFalse(t,any(mask,'all'));
end
function test_known_beta_uses_producer_semantics(t)
r=struct('nSteps',2,'controlAccepted',true(1,2),'nEstimated',0);
v=zeros(3,2);
verifyFalse(t,any(ejc_mat_applicability("study1","data/test.mat","value[].result[].beta",v,r,struct),'all'));
verifyTrue(t,all(ejc_mat_applicability("study3","runs/test.mat","value[].result[].beta",v,r,struct),'all'));
end
function test_nonfinite_value_never_selects_mask(t)
verifyTrue(t,ejc_mat_applicability("study6","online/test.mat","value[].out[].errors[].total",NaN,struct,struct));
r=struct('exactTargetAvailable',[false true]);v=[NaN NaN];
mask=ejc_mat_applicability("study4","evaluation/test.mat","value[].parameterError",v,r,struct);
verifyEqual(t,mask,[false true]);verifyFalse(t,ejc_acceptance_numeric(v,v,1e-8,1e-7,mask).passed);
end
function test_archive_bookkeeping_scope(t)
for file=["primary/a.mat","measurement/a.mat","online/a.mat","change/a.mat"]
    mask=ejc_mat_applicability("study6",file,"value[].out[].archiveComparisonMax",NaN,struct,struct);
    verifyEqual(t,mask,startsWith(file,["primary/","measurement/"]));
end
end
