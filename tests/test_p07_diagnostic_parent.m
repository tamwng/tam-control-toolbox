function tests=test_p07_diagnostic_parent
tests=functiontests(localfunctions);
end
function setupOnce(t)
t.TestData.path=path;root=fileparts(fileparts(mfilename('fullpath')));addpath(fullfile(root,'studies/p07'));
end
function teardownOnce(t)
path(t.TestData.path);
end
function test_eigenvalue_scale_uses_corresponding_parent(t)
r=struct('id','E','kind','amplitude','amplitude',1,'nSteps',3,'nEstimated',2, ...
    'covariance',cat(3,eye(2),diag([2 8]),diag([3 4])), ...
    'covarianceEigenvalues',[1 2 3;1 8 4]);
row=table("E","amplitude",1,'VariableNames',{'model','kind','amplitude'});
v=ejc_diagnostic_parent("study2","tables/run_diagnostics.csv","covarianceEigenMax",row,r);
verifyEqual(t,v.sourceValue,8);verifyEqual(t,v.selectedExtremum,2);verifyEqual(t,v.parentNorm,8);
v=ejc_diagnostic_parent("study2","tables/run_diagnostics.csv","covarianceEigenMin",row,r);
verifyEqual(t,v.sourceValue,1);verifyEqual(t,v.selectedExtremum,1);verifyEqual(t,v.parentNorm,1);
row.amplitude=2;verifyError(t,@()ejc_diagnostic_parent("study2","tables/run_diagnostics.csv","covarianceEigenMax",row,r),'ejc:DiagnosticSource');
end
function test_full_window_and_known_nonapplicability(t)
r=struct('id','E','kind','amplitude','amplitude',1,'nSteps',3,'nEstimated',2, ...
    'gramCount',[49 50 50],'gramCondition',[1e20 10 Inf]);
row=table("E","amplitude",1,'VariableNames',{'model','kind','amplitude'});
v=ejc_diagnostic_parent("study2","tables/run_diagnostics.csv","gramConditionMax",row,r);
verifyEqual(t,v.selection,[2 3]);verifyEqual(t,v.sourceValue,Inf);verifyEqual(t,v.selectedExtremum,3);
r.nEstimated=0;v=ejc_diagnostic_parent("study2","tables/run_diagnostics.csv","gramConditionMax",row,r);
verifyFalse(t,v.required);verifyTrue(t,isnan(v.sourceValue));verifyEmpty(t,v.selection);
end
function test_study1_reconstruction_is_not_stored_condition_copy(t)
r=struct('id','S','campaign','confirmation','trial',0,'nSteps',2,'fit',struct('nEstimated',2), ...
    'gramCount',[49 50],'gram',cat(3,eye(2),diag([1 2])),'gramCondition',[NaN 9]);
row=table("confirmation","S",0,'VariableNames',{'campaign','model','trial'});
v=ejc_diagnostic_parent("study1","tables/run_diagnostics.csv","gramConditionMax",row,r);
verifyEqual(t,v.sourceValue,2);verifyNotEqual(t,v.sourceValue,r.gramCondition(2));
end
