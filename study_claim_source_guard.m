function proof = study_claim_source_guard(rows)
%STUDY_CLAIM_SOURCE_GUARD Bind original definitions to the explicit descendant.
proof=verify_source_relationship;
root=fileparts(mfilename('fullpath'));
mapping=jsondecode(fileread(fullfile(root,'verification','source_relationship.json')));
if nargin==0
    rows=jsondecode(fileread(fullfile(root, ...
        'verification/specification/scientific_definitions.json')));
end
for row=reshape(rows,1,[])
    ix=find(string({mapping.definitionRelationships.path})==string(row.path) & ...
        string({mapping.definitionRelationships.oldSHA256})==string(row.sha256));
    assert(isscalar(ix),'study:DefinitionRelationship', ...
        'Unmapped original scientific definition: %s.',row.path);
    relation=mapping.definitionRelationships(ix);
    assert(strcmp(verification_file_sha256(fullfile(root,relation.newPath)),relation.newSHA256), ...
        'study:DefinitionChanged','Mapped scientific definition changed.');
end
proof.dependencyCount=numel(rows);
end
