function tests=test_p07_portable_dispatch
tests=functiontests(localfunctions);
end
function setupOnce(t)
t.TestData.path=path;root=fileparts(fileparts(mfilename('fullpath')));addpath(root,fullfile(root,'studies/p07'));
end
function teardownOnce(t)
path(t.TestData.path);
end
function c=context
c=struct('study',"study1",'file',"audits/confirmation_S_000.mat",'rootA',struct,'rootB',struct, ...
    'isCSV',false,'sourceSHA256',"synthetic-unit-witness-A",'referenceSHA256',"synthetic-unit-witness-B");
end
function test_scoped_additive_rule_and_failure(t)
c=context;q="value(1).audit(1).measuredModelError";
v=ejc_portable_leaf([1 2],[1 2],q,struct,struct,c);verifyTrue(t,v.passed,v.reason);
v=ejc_portable_leaf([1 2+1e-8],[1 2],q,struct,struct,c);verifyTrue(t,v.passed,v.reason);
v=ejc_portable_leaf([1 2+1e-3],[1 2],q,struct,struct,c);verifyFalse(t,v.passed);
verifyEqual(t,v.numeric.failedCount,1);
end
function test_exact_unknown_and_required_nonfinite(t)
c=context;q="value(1).audit(1).trial";
v=ejc_portable_leaf(1,2,q,struct,struct,c);verifyFalse(t,v.passed);
v=ejc_portable_leaf(1,1,"value(1).audit(1).newQuantity",struct,struct,c);verifyFalse(t,v.passed);
q="value(1).audit(1).measuredModelError";
for x=[NaN Inf -Inf]
    v=ejc_portable_leaf(x,x,q,struct,struct,c);verifyFalse(t,v.passed);
end
end
function test_csv_requires_own_source_evidence(t)
c=context;c.study="study1";c.file="tables/run_metrics.csv";c.isCSV=true;
T=table("whole",'VariableNames',{'window'});
v=ejc_portable_leaf(1,1,"value.trackingRMS",T,T,c);verifyFalse(t,v.passed);
end
function test_exact_empty_text_encoding_is_not_nan_equivalence(t)
c=context;c.study="study4";c.file="tables/diagnostics.csv";c.isCSV=true;c.rowIndex=1;
c.csvHeaders="terminationReason";c.csvTokensA={''};c.csvTokensB={''};
c.bindingA=struct('values',table("",'VariableNames',{'terminationReason'}));c.bindingB=c.bindingA;
T=table(NaN,'VariableNames',{'terminationReason'});
v=ejc_portable_leaf(NaN,NaN,"value.terminationReason",T,T,c);verifyTrue(t,v.passed,v.reason);
c.csvTokensA={'NaN'};v=ejc_portable_leaf(NaN,NaN,"value.terminationReason",T,T,c);verifyFalse(t,v.passed);
c.csvTokensA={''};c.bindingA.values.terminationReason="failed";
v=ejc_portable_leaf(NaN,NaN,"value.terminationReason",T,T,c);verifyFalse(t,v.passed);
end
function test_reported_contrast_sign_and_interval_are_separate_gates(t)
c=context;c.study="study1";c.file="tables/paired_contrasts.csv";
c.sources=struct;c.references=struct;
a=table(1,-1e-20,-1e-20,1,'VariableNames',{'finitePairs','medianDifference','lower95','upper95'});
b=a;b.medianDifference=1e-20;b.lower95=1e-20;
v=ejc_portable_leaf(a.medianDifference,b.medianDifference,"value.medianDifference",a,b,c);
verifyTrue(t,v.numeric.passed);verifyFalse(t,v.passed);verifyEqual(t,v.status,"FAILED_PUBLICATION_GUARD");
v=ejc_portable_leaf(a.lower95,b.lower95,"value.lower95",a,b,c);
verifyTrue(t,v.numeric.passed);verifyFalse(t,v.passed);
v=ejc_portable_leaf(a.lower95,a.lower95,"value.lower95",a,a,c);verifyTrue(t,v.passed,v.reason);
end
function test_optional_nan_selector_does_not_poison_dispatch_cache(t)
T=table(NaN,'VariableNames',{'fittingTransitions'});
r=ejc_rule_lookup("paper","paper_table12.csv","value.horizon",'double',T);
verifyEqual(t,r.policy_family,"E0");
T.fittingTransitions=200;
r=ejc_rule_lookup("study1","tables/initialization_scores.csv","value.predictionRMS",'double',T);
verifyEqual(t,r.policy_family,"A4");
T.fittingTransitions=50;
r=ejc_rule_lookup("study1","tables/initialization_scores.csv","value.predictionRMS",'double',T);
verifyEqual(t,r.policy_family,"P10");
end
function test_file_report_retains_input_hashes_and_fieldwise_policy(t)
f=t.applyFixture(matlab.unittest.fixtures.TemporaryFolderFixture);
root=fileparts(fileparts(mfilename('fullpath')));s=ejc_reference_sources;
source=fullfile(s.study1,'audits','confirmation_S_000.mat');
current=fullfile(f.Folder,'current');reference=fullfile(f.Folder,'reference');
for folder={current,reference}
    mkdir(fullfile(folder{1},'audits'));
    copyfile(source,fullfile(folder{1},'audits','confirmation_S_000.mat'));
end
cache=containers.Map('KeyType','char','ValueType','any');
adapter=struct('contextForFile',@(info,a,b)ejc_portable_context(info,a,b, ...
    struct,struct,[],[],cache));
r=ejc_compare_results(struct('study1',current),struct('study1',reference), ...
    fullfile(f.Folder,'comparison'),adapter);
verifyTrue(t,r.passed);verifyEqual(t,height(r.files),1);
verifyEqual(t,r.files.sourceSHA256,string(ejc_file_sha256(source)));
verifyEqual(t,r.files.referenceSHA256,r.files.sourceSHA256);
verifyTrue(t,isnan(r.files.absoluteTolerance) && isnan(r.files.relativeTolerance));
verifyEqual(t,root,fileparts(which('run_ejc')));
end
function test_explicitly_claimed_cross_term_means_preserve_sign(t)
c=context;c.study="study6";c.file="tables/main.csv";c.sources=struct;c.references=struct;c.explicitDirectionalClaim=true;
a=table(-1e-20,-1e-20,'VariableNames',{'meanCrossTerm','meanCombinedCrossTerm'});
b=a;b{:,:}=-b{:,:};
for field=["meanCrossTerm","meanCombinedCrossTerm"]
    v=ejc_portable_leaf(a.(field),b.(field),"value."+field,a,b,c);
    verifyTrue(t,v.numeric.passed);verifyFalse(t,v.passed);
    verifyEqual(t,v.status,"FAILED_PUBLICATION_GUARD");
    v=ejc_portable_leaf(a.(field),a.(field),"value."+field,a,a,c);verifyTrue(t,v.passed,v.reason);
end
end
