function tests=test_p07_csv_applicability
tests=functiontests(localfunctions);
end
function setupOnce(t)
t.TestData.path=path;root=fileparts(fileparts(mfilename('fullpath')));addpath(fullfile(root,'studies/p07'));
end
function teardownOnce(t)
path(t.TestData.path);
end
function test_fixed_target_selection(t)
T=table(["A";"S";"R";"P2";"W";"K"],'VariableNames',{'model'});
v=ejc_csv_applicability("study1","tables/initialization_scores.csv","parameterScaledPercent",T);
verifyEqual(t,v,[false;true;true;true;false;false]);
v=ejc_csv_applicability("study3","tables/initialization_scores.csv","parameterScaledPercent",T);
verifyEqual(t,v,[false;true;false;false;false;false]);
end
function test_nan_cannot_define_its_own_applicability(t)
T=table([0;1],[NaN;NaN],'VariableNames',{'finiteScores','median'});
v=ejc_csv_applicability("study1","tables/noisy_summaries.csv","median",T);
verifyEqual(t,v,[false;true]);
r=ejc_acceptance_numeric(T.median,T.median,1e-8,1e-7,v);verifyFalse(t,r.passed);
T.median(2)=1;r=ejc_acceptance_numeric(T.median,T.median,1e-8,1e-7,v);verifyTrue(t,r.passed);
end
function test_original_forgetting_semantics(t)
T=table(["A_none";"S_vrf";"S_pretrained"],[1199;1199;0], ...
    'VariableNames',{'caseId','identificationAttempted'});
v=ejc_csv_applicability("study3","tables/run_diagnostics.csv","residualEnergyMax",T);
verifyEqual(t,v,[false;true;false]);
v=ejc_csv_applicability("study3","tables/run_diagnostics.csv","lambdaMin",T);
verifyEqual(t,v,[true;true;false]);
end
function test_unknown_scope_is_finite_or_blocks(t)
T=table(NaN,'VariableNames',{'unknown'});
v=ejc_csv_applicability("unknown","unknown.csv","unknown",T);verifyTrue(t,v);
verifyError(t,@()ejc_csv_applicability("study4","unknown.csv","parameterScaledPercent",T),'ejc:Applicability');
verifyError(t,@()ejc_csv_applicability("study3","unknown.csv","gramConditionMax",T),'ejc:Applicability');
end
function test_study4_exact_target_rules(t)
T=table(["Known";"Estimated";"Estimated"],[0;3;3],[0;3;2],[3;3;3], ...
    'VariableNames',{'model','coefficientCount','parameterExactSamples','scoredSamples'});
verifyEqual(t,ejc_csv_applicability("study4","tables/metrics.csv","parameterScaledRMSPercent",T),[false;true;false]);
T.exactSamples=T.parameterExactSamples;
verifyEqual(t,ejc_csv_applicability("study4","tables/parameters.csv","componentErrorRMS",T),[false;true;false]);
verifyError(t,@()ejc_csv_applicability("study4","tables/parameters.csv","lastTarget",T),'ejc:Applicability');
source=struct('lastExactTargetAvailable',[false;true;false]);
verifyEqual(t,ejc_csv_applicability("study4","tables/parameters.csv","lastTarget",T,source),[false;true;false]);
end
function test_physical_diagnostic_and_archive_applicability(t)
T=table(["I";"K";"D";"A";"P3"],'VariableNames',{'modelId'});
verifyEqual(t,ejc_csv_applicability("study5","tables/initialization.csv","predictorRefinementRMS",T),[true;true;false;false;false]);
verifyFalse(t,any(ejc_csv_applicability("study6","tables/online.csv","archiveComparisonMax",T)));
verifyTrue(t,all(ejc_csv_applicability("study6","tables/primary.csv","archiveComparisonMax",T)));
verifyError(t,@()ejc_csv_applicability("study6","unknown.csv","archiveComparisonMax",T),'ejc:Applicability');
end
function test_study45_full_valid_gram_count(t)
T=table([5;5;0],[0;5;0],'VariableNames',{'gramFullWindows','gramInvalidFullWindows'});
verifyEqual(t,ejc_csv_applicability("study4","tables/diagnostics.csv","gramConditionMax",T),[true;false;false]);
T.gramInvalidFullWindows(1)=6;
verifyError(t,@()ejc_csv_applicability("study4","tables/diagnostics.csv","gramConditionMax",T),'ejc:Applicability');
end
function test_initialization_lambda_uses_original_attempted_updates(t)
T=table([0;200],[NaN;1],'VariableNames',{'attemptedUpdates','lambdaMin'});
for study=["study2","study3"]
    for field=["lambdaMin","lambdaMax"]
        required=ejc_csv_applicability(study,"tables/initialization_diagnostics.csv",field,T);
        verifyEqual(t,required,[false;true]);
        v=ejc_acceptance_numeric(T.lambdaMin,T.lambdaMin,1e-12,1e-7,required);verifyTrue(t,v.passed);
        v=ejc_acceptance_numeric([NaN;NaN],[NaN;NaN],1e-12,1e-7,required);verifyFalse(t,v.passed);
    end
end
T.attemptedUpdates(1)=-1;
verifyError(t,@()ejc_csv_applicability("study3","tables/initialization_diagnostics.csv","lambdaMin",T),'ejc:Applicability');
end
function test_study6_main_and_complete_verification_scopes(t)
T=table("commonData",200,'VariableNames',{'kind','fittingTransitions'});
verifyTrue(t,ejc_csv_applicability("study6","tables/main.csv","archiveComparisonMax",T));
T.fittingTransitions=50;
verifyError(t,@()ejc_csv_applicability("study6","tables/main.csv","archiveComparisonMax",T),'ejc:Applicability');
T=table(329,'VariableNames',{'filesChecked'});
verifyTrue(t,ejc_csv_applicability("study6","tables/verification.csv","archiveComparisonMax",T));
T.filesChecked=328;
verifyError(t,@()ejc_csv_applicability("study6","tables/verification.csv","archiveComparisonMax",T),'ejc:Applicability');
end
