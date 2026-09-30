function proof = validate_generated_sources(sources)
%VALIDATE_GENERATED_SOURCES Require complete, explicit Studies 1--5 parents.
% Completion status is checked together with saved settings and file hashes;
% a status label alone is not a source identity or validity proof.
[context,root]=study_context; %#ok<ASGLU>
identity=verify_source_relationship;
assert(isequal(sort(string(fieldnames(sources))),"study"+(1:5).'), ...
    'study:ParentSources','Supply exactly Studies 1 through 5.');
rows=struct([]);
for j=1:5
    key="study"+j;source=char(java.io.File(char(sources.(key))).getCanonicalPath());
    file=fullfile(source,'generation_manifest.json');
    assert(isfile(file),'study:MissingParent','Missing generated parent manifest: %s.',key);
    manifest=jsondecode(fileread(file));
    assert(strcmp(manifest.schema,'GENERATED_STUDY_V1') && strcmp(manifest.study,key) && ...
        strcmp(manifest.status,'COMPLETED') && manifest.internalValidity.passed && ...
        strcmp(manifest.sourceIdentity,identity.sourceIdentity), ...
        'study:ParentIdentity','Parent is incomplete or from a different source: %s.',key);
    assert(isequaln(manifest.files,reshape(study_output_identity(source),[],1)), ...
        'study:ParentChanged','Parent scientific files changed: %s.',key);
    verify_study_inventory(key,source);
    z=load(fullfile(source,'settings.mat'),'cfg');settings=str2func(key+"_settings");
    assert(isequaln(z.cfg,settings()),'study:ParentSettings','Parent study settings differ.');
    rows=[rows;struct('study',key,'source',string(source), ...
        'manifestSHA256',ejc_file_sha256(file),'passed',true)]; %#ok<AGROW>
end
proof=struct('passed',true,'parents',rows,'sourceIdentity',identity.sourceIdentity);
end
