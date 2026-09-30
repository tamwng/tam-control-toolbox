function proof = verify_source_relationship
%VERIFY_SOURCE_RELATIONSHIP Check source files against a fixed offline identity.
% Recording observed hashes for a generated run does not make that run
% its own reference authority.
root=fileparts(mfilename('fullpath'));
file=fullfile(root,'verification','source_relationship.json');
expected=source_relationship_anchor;
assert(strcmp(verification_file_sha256(file),expected),'study:RelationshipChanged', ...
    'Source relationship differs from its fixed identity.');
mapping=jsondecode(fileread(file));
assert(strcmp(mapping.policySHA256, ...
    'ca9101ea01a6eb093664d383a3d6bd1734598ba84aed2ee35b28cfa7412aec58'), ...
    'study:PolicyChanged','Numerical policy identity changed.');
for row=reshape(mapping.files,1,[])
    target=fullfile(root,row.path);
    assert(isfile(target) && strcmp(verification_file_sha256(target),row.newSHA256), ...
        'study:SourceChanged','Source file differs from its recorded identity: %s.',row.path);
end
% Generated outputs and separately inventoried reference data are not source files.
entries=dir(fullfile(root,'**','*')); actual=strings(0,1);
for j=1:numel(entries)
    if entries(j).isdir,continue;end
    name=replace(string(fullfile(entries(j).folder,entries(j).name)),string(root)+filesep,'');
    name=replace(name,filesep,'/');
    if startsWith(name,{'results/','references/','.git/'}),continue;end
    actual(end+1,1)=name; %#ok<AGROW>
end
declared=[string({mapping.files.path}).';"verification/source_relationship.json"; ...
    "source_relationship_anchor.m"];
assert(isequal(sort(actual),sort(declared)),'study:UnlistedSource', ...
    'The source inventory includes missing or unlisted files.');
proof=struct('passed',true,'relationshipSHA256',expected, ...
    'sourceReview',mapping.reviewStatus,'policySHA256',mapping.policySHA256, ...
    'sourceIdentity',mapping.sourceIdentity,'fileCount',numel(mapping.files));
end
