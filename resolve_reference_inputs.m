function identity = resolve_reference_inputs(references,keys)
%RESOLVE_REFERENCE_INPUTS Verify explicitly supplied local canonical packages.
% No network acquisition or private default directory is used.
root=fileparts(mfilename('fullpath'));
manifest=readtable(fullfile(root,'evidence/p07_gate_b/P07_SOURCE_SHA256.csv'),'TextType','string');
names=["study1","study2","study3","study4","study5","study6","p06"];
roots=["study1_candidate_20260917","study2_pilot_20260918","study3_pilot_20260918", ...
    "study4_pilot_20260922","study5_pilot_20260922","study6_pilot_20260922","p06_sensitivity_20260924_225708"];
identity=struct;
for key=reshape(string(keys),1,[])
    ix=find(names==key);
    assert(isscalar(ix),'study:ReferenceKey','Unsupported reference key.');
    assert(isfield(references,key) && isfolder(references.(key)), ...
        'study:ReferenceUnavailable','Canonical reference %s is unavailable.',key);
    directory=char(java.io.File(char(references.(key))).getCanonicalPath());
    prefix="results/"+roots(ix)+"/";
    selected=startsWith(manifest.relative_path,prefix) & endsWith(manifest.relative_path,{'.mat','.csv'});
    rows=manifest(selected,:);
    assert(~isempty(rows),'study:ReferenceInventory','Canonical inventory is unavailable.');
    for j=1:height(rows)
        relative=extractAfter(rows.relative_path(j),strlength(prefix));
        file=fullfile(directory,relative);
        assert(isfile(file),'study:ReferenceUnavailable','Required canonical file is unavailable: %s.',relative);
        assert(strcmp(ejc_file_sha256(file),rows.sha256(j)), ...
            'study:ReferenceChanged','Canonical file identity differs: %s.',relative);
    end
    identity.(key)=struct('directory',directory,'originalPrefix',char(prefix), ...
        'files',height(rows),'inventorySHA256',ejc_file_sha256(fullfile(root,'evidence/p07_gate_b/P07_SOURCE_SHA256.csv')));
end
end
