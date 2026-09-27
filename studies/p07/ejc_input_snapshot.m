function rows=ejc_input_snapshot(sources,references)
%EJC_INPUT_SNAPSHOT Exact per-invocation input identity, not cross-host equality.
rows=struct('role',{},'study',{},'relativePath',{},'absolutePath',{},'bytes',{},'sha256',{});
seen=containers.Map('KeyType','char','ValueType','any');
for role=["current","reference"]
    package=sources;if role=="reference",package=references;end
    for study=sort(string(fieldnames(package))).'
        folder=string(char(java.io.File(char(package.(study))).getCanonicalPath()));
        assert(isfolder(folder),'ejc:MissingSource','Missing source directory: %s.',folder);
        files=[dir(fullfile(folder,'**','*.mat'));dir(fullfile(folder,'**','*.csv'))];
        names=string(fullfile({files.folder},{files.name}));[~,order]=sort(names);files=files(order);
        for file=files.'
            path=string(fullfile(file.folder,file.name));
            if isKey(seen,path),hash=seen(path);else,hash=ejc_file_sha256(path);seen(path)=hash;end
            rows(end+1)=struct('role',role,'study',study, ...
                'relativePath',replace(extractAfter(path,strlength(folder)+1),filesep,'/'), ...
                'absolutePath',path,'bytes',file.bytes,'sha256',string(hash)); %#ok<AGROW>
        end
    end
end
assert(~isempty(rows),'ejc:MissingSource','Empty source package.');
end
