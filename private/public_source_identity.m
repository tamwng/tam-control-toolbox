function identity = public_source_identity(root)
%PUBLIC_SOURCE_IDENTITY Identify source bytes; this is not a certificate.
folders = {'','private','src','studies/study1','studies/p07'};
files = struct('path',{},'sha256',{});
for k = 1:numel(folders)
    entries = dir(fullfile(root,folders{k},'*.m'));
    for j = 1:numel(entries)
        name = strrep(fullfile(folders{k},entries(j).name),'\','/');
        files(end+1) = struct('path',name,'sha256',ejc_file_sha256(fullfile(root,name))); %#ok<AGROW>
    end
end
identity = struct('schema','SOURCE_BYTES_V1','sourceRoot',root, ...
    'meaning','Source identity only; no historical certification','files',files);
end
