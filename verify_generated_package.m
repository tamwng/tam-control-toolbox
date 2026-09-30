function manifest = verify_generated_package(study,source)
%VERIFY_GENERATED_PACKAGE Bind a completed saved package to its producing source.
identity=verify_source_relationship;
if string(study)=="sensitivity",study="p06";end
file=fullfile(source,'generation_manifest.json');
if string(study)=='p06',file=fullfile(source,'sensitivity_manifest.json');end
assert(isfile(file),'study:MissingGenerationManifest','A generated-package manifest is required.');
manifest=jsondecode(fileread(file));
producerAccepted=strcmp(manifest.sourceIdentity,identity.sourceIdentity);
if ~producerAccepted
    root=fileparts(mfilename('fullpath'));
    mapping=jsondecode(fileread(fullfile(root,'verification','source_relationship.json')));
    if isfield(mapping,'compatibleGeneratedSources')
        rows=mapping.compatibleGeneratedSources;
        ix=find(strcmp({rows.sourceIdentity},manifest.sourceIdentity));
        producerAccepted=isscalar(ix) && strcmp(rows(ix).policySHA256,identity.policySHA256);
    end
end
assert(strcmp(manifest.status,'COMPLETED') && manifest.internalValidity.passed && ...
    producerAccepted, ...
    'study:GenerationIdentity','Incomplete package or different generating source.');
if string(study)=='p06'
    assert(strcmp(manifest.mode,'all'),'study:Incomplete','General comparison requires the complete sensitivity set.');
else
    assert(strcmp(manifest.study,study),'study:GenerationIdentity','Study identity differs.');
end
assert(isequaln(manifest.files,reshape(study_output_identity(source),[],1)), ...
    'study:GeneratedInputChanged','Saved generated files differ from their recorded identity.');
if string(study)~='p06',verify_study_inventory(study,source);end
end
