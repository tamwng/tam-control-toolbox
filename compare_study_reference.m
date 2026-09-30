function report = compare_study_reference(sources,references,output,options)
%COMPARE_STUDY_REFERENCE Compare completed saved studies under the frozen rules.
% REFERENCES contains explicitly supplied canonical directories. Study 6 also
% requires both parent sets; sensitivity requires canonical Study 1 records.
% No simulation, reference download, or modification of a generated run occurs.
% Source identity, generated-package identity and numerical agreement are
% checked separately for the supplied datasets.
arguments
    sources (1,1) struct
    references (1,1) struct
    output
    options.ParentSources (1,1) struct = struct
    options.ReferenceParents (1,1) struct = struct
    options.DevelopmentComparison (1,1) logical = false
end
[context,root]=study_context; %#ok<ASGLU>
proof=verify_source_relationship;
sources=study_reference_keys(sources);references=study_reference_keys(references);
options.ParentSources=study_reference_keys(options.ParentSources);
options.ReferenceParents=study_reference_keys(options.ReferenceParents);
keys=string(fieldnames(sources));assert(~isempty(keys),'study:Selection','No generated studies selected.');
parents=options.ParentSources;
for key=keys.'
    if ~isfield(parents,key),parents.(key)=sources.(key);end
    assert(strcmp(canonical(parents.(key)),canonical(sources.(key))), ...
        'study:ParentIdentity','Selected source and own parent differ.');
end
referenceParents=references;
for key=string(fieldnames(options.ReferenceParents)).'
    if isfield(referenceParents,key)
        assert(strcmp(canonical(referenceParents.(key)),canonical(options.ReferenceParents.(key))), ...
            'study:ReferenceIdentity','Conflicting reference parent.');
    end
    referenceParents.(key)=options.ReferenceParents.(key);
end
required=keys;
if any(keys=='study6'),required=union(required,"study"+(1:5).');validate_generated_sources(select(parents,"study"+(1:5)));end
if any(keys=='p06'),required=union(required,"study1");end
referenceIdentity=resolve_reference_inputs(referenceParents,required);
producers=struct;
for key=keys.'
    assert(isfolder(sources.(key)) && ~strcmp(canonical(sources.(key)),referenceIdentity.(key).directory), ...
        'study:SelfReference','A generated package cannot be its own canonical reference.');
    producers.(key)=verify_generated_package(key,sources.(key));
end
assert(~strcmp(proof.sourceReview,'HQ_REVIEW_PENDING') || options.DevelopmentComparison, ...
    'study:SourceReviewPending','The source relationship is not enabled for reference comparison.');
output=new_output_path('reference_comparison',output);
study_separate_output(output,parents);study_separate_output(output,referenceParents);
mkdir(output);
before=verification_input_snapshot(parents,referenceParents);
policyHash=proof.policySHA256;
save(fullfile(output,'input_identity_before.mat'),'before','policyHash');
currentInputs=struct;referenceInputs=struct;
if any(keys=='p06')
    currentInputs=study_sensitivity_inputs(sources.p06,referenceParents.study1);
    referenceInputs=study_sensitivity_inputs(references.p06,referenceParents.study1);
end
bindingsA=verification_csv_source_tables(sources,fullfile(output,'current_sources'),currentInputs);
bindingsB=verification_csv_source_tables(select(references,keys),fullfile(output,'reference_sources'),referenceInputs);
gateFile='';
if any(keys=='p06') && ~isfile(fullfile(sources.p06,'tables','baseline_gate.csv'))
    ix=find(string({bindingsA.study})=='p06' & string({bindingsA.file})=='tables/baseline_gate.csv');
    assert(isscalar(ix),'study:SensitivityGate','Missing exact saved-case baseline binding.');
    gates=bindingsA(ix).values;
    assert(height(gates)==204 && all(gates.passed),'study:SensitivityGate','Required saved baseline checks failed.');
    gateFile=fullfile(output,'baseline_gate.csv');writetable(gates,gateFile);
end
cache=containers.Map('KeyType','char','ValueType','any');
cache('P07_MATRIX_EVIDENCE_DIRECTORY')=fullfile(output,'matrix_details');mkdir(cache('P07_MATRIX_EVIDENCE_DIRECTORY'));
cache('P07_INPUT_IDENTITY_SHA256')=verification_file_sha256(fullfile(output,'input_identity_before.mat'));
adapter=struct('contextForFile',@bind,'additionalFiles',@extra,'sourceFile',@source_file, ...
    'prepareValues',@verification_sensitivity_manifest_order);
report=verification_compare_results(sources,references,fullfile(output,'comparison'),adapter);
assert(isequaln(before,verification_input_snapshot(parents,referenceParents)), ...
    'study:InputChanged','Generated or canonical inputs changed.');
after=verify_source_relationship;
assert(strcmp(after.relationshipSHA256,proof.relationshipSHA256),'study:SourceChanged','Source authority changed.');
report.sourceRelationship=proof;report.inputsUnchanged=true;
for key=keys.',report.producingSources.(key)=producers.(key).sourceIdentity;end
if any(keys=='p06'),report.sensitivityInputIdentity=currentInputs.recordIdentity;end
report.numericalChecksPassed=report.passed;
if strcmp(proof.sourceReview,'HQ_REVIEW_PENDING')
    report.passed=false;report.status='PROVISIONAL_SOURCE_REVIEW_PENDING';
else
    report.status='FAIL';if report.passed,report.status='PASS';end
end
study_json(fullfile(output,'reference_comparison.json'),report);
save(fullfile(output,'reference_comparison.mat'),'report');
    function c=bind(info,a,b)
        c=verification_portable_context(info,a,b,parents,referenceParents,bindingsA,bindingsB,cache);
        c.sourceGuard=@study_claim_source_guard;
        c.canonicalReferencePath=string(referenceIdentity.(info.study).originalPrefix)+info.file;
        if info.study=="p06"
            c.sensitivityRecords=currentInputs.recordIdentity;
            c.allowLegacySensitivityOrder=~strcmp(producers.p06.sourceIdentity,proof.sourceIdentity);
        end
    end
    function names=extra(group)
        names=strings(0,1);
        if group=='p06' && ~isempty(gateFile),names="tables/baseline_gate.csv";end
    end
    function file=source_file(group,name,file)
        if group=='p06' && name=='tables/baseline_gate.csv' && ~isempty(gateFile)
            assert(~isfile(file),'study:SensitivityGate','Do not replace an existing scientific input.');
            file=gateFile;
        end
    end
end
function path=canonical(path)
path=char(java.io.File(char(path)).getCanonicalPath());
end
function subset=select(value,keys)
subset=struct;
for key=reshape(string(keys),1,[])
    assert(isfield(value,key),'study:MissingParent','Required parent %s unavailable.',key);
    subset.(key)=value.(key);
end
end
