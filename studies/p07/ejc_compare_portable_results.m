function report=ejc_compare_portable_results(sources,references,output,parentSources,diagnostic)
%EJC_COMPARE_PORTABLE_RESULTS Saved-value comparison under the frozen policy.
% Never produces a trajectory. Original validity checks and lifecycle guards
% execute separately and remain mandatory before any campaign can advance.
if nargin<4,parentSources=sources;end
if nargin<5,diagnostic="";end
assert(any(string(diagnostic)==["","COLLECT_DIAGNOSTIC_FAILURES"]),'ejc:DiagnosticMode','Unknown comparison mode.');
for key=string(fieldnames(sources)).'
    assert(isfield(parentSources,key) && isequal(string(parentSources.(key)),string(sources.(key))), ...
        'ejc:PortableSource','Comparison source differs from its supplied parent package.');
end
ejc_assert_writable(output);
assert(~isfolder(output) && ~isfile(output),'ejc:ExistingEvidence','New comparison directory required.');
mkdir(output);root=fileparts(fileparts(fileparts(mfilename('fullpath'))));
policyFile=fullfile(root,'studies/p07/p07_acceptance_policy.json');
policyHash=ejc_file_sha256(policyFile);
inputsBefore=ejc_input_snapshot(parentSources,references);
save(fullfile(output,'input_identity_before.mat'),'inputsBefore','policyHash','-v7');
try
referenceSubset=struct;
for key=string(fieldnames(sources)).'
    referenceSubset.(key)=references.(key);
end
currentBindings=ejc_csv_source_tables(sources,fullfile(output,'current_sources'));
if isequaln(sources,referenceSubset)
    referenceBindings=currentBindings;
else
    referenceBindings=ejc_csv_source_tables(referenceSubset,fullfile(output,'reference_sources'));
end
cache=containers.Map('KeyType','char','ValueType','any');
cache('P07_MATRIX_EVIDENCE_DIRECTORY')=fullfile(output,'matrix_details');
cache('P07_INPUT_IDENTITY_SHA256')=ejc_file_sha256(fullfile(output,'input_identity_before.mat'));
mkdir(cache('P07_MATRIX_EVIDENCE_DIRECTORY'));
adapter=struct('contextForFile',@(info,a,b)ejc_portable_context(info,a,b,parentSources,references, ...
    currentBindings,referenceBindings,cache));
adapter.diagnosticCollect=string(diagnostic)=="COLLECT_DIAGNOSTIC_FAILURES";
report=ejc_compare_results(sources,references,fullfile(output,'comparisons'),adapter);
catch failure
    inputsAfter=ejc_input_snapshot(parentSources,references);
    save(fullfile(output,'input_identity_after_failure.mat'),'inputsAfter','failure','-v7');
    rethrow(failure)
end
inputsAfter=ejc_input_snapshot(parentSources,references);
inputsUnchanged=isequaln(inputsBefore,inputsAfter);
save(fullfile(output,'input_identity_after.mat'),'inputsAfter','inputsUnchanged','-v7');
assert(inputsUnchanged,'ejc:InputChanged','A comparison input or dependency changed during comparison.');
report.inputsUnchanged=inputsUnchanged;
report.inputIdentitySHA256=ejc_file_sha256(fullfile(output,'input_identity_before.mat'));
report.policySHA256=policyHash;
assert(strcmp(policyHash,ejc_file_sha256(policyFile)),'ejc:PolicyChanged','Policy changed during comparison.');
report.originalValidityAndLifecycleRequired=true;
report.mode="SAVED_SCIENTIFIC_COMPARISON_COMPONENT_NOT_A_FRESH_CAMPAIGN";
if adapter.diagnosticCollect,report.mode="DIAGNOSTIC_FAILURE_COLLECTION_NOT_CERTIFICATION";end
save(fullfile(output,'portable_comparison.mat'),'report','-v7');
end
