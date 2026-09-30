function proof = study_claim_source_guard(rows)
%STUDY_CLAIM_SOURCE_GUARD Bind original definitions to the explicit descendant.
proof=verify_source_relationship;
root=fileparts(mfilename('fullpath'));
mapping=jsondecode(fileread(fullfile(root,'verification','cleaned_source_relationship.json')));
if nargin==0
    rows=jsondecode(fileread(fullfile(root, ...
        'evidence/p07_acceptance/freezing_identity/C0_SCIENTIFIC_DEPENDENCIES.json')));
end
for row=reshape(rows,1,[])
    ix=find(string({mapping.definitionRelationships.path})==string(row.path) & ...
        string({mapping.definitionRelationships.oldSHA256})==string(row.sha256));
    assert(isscalar(ix),'study:DefinitionRelationship', ...
        'Unmapped original scientific definition: %s.',row.path);
    relation=mapping.definitionRelationships(ix);
    assert(strcmp(ejc_file_sha256(fullfile(root,relation.newPath)),relation.newSHA256), ...
        'study:DefinitionChanged','Mapped scientific definition changed.');
end
proof.dependencyCount=numel(rows);
end
