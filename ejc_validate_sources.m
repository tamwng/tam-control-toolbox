function identities = ejc_validate_sources(sources,expectedPolicy)
%EJC_VALIDATE_SOURCES Require completed fresh runs from this exact clean commit.
% This prevents an explicit path to an old archive being called fresh Study 6.
if nargin<2,expectedPolicy="";end
current = ejc_source_revision;
assert(current.clean,'ejc:DirtySource','Fresh Study 6 requires a clean committed source.');
identities = cell(1,5);
for s = 1:5
    key = sprintf('study%d',s);
    assert(isfield(sources,key),'ejc:Study6Sources','Supply newly reproduced Studies 1--5 explicitly.');
    source = char(sources.(key));
    ejc_assert_writable(source); % Historical inputs cannot qualify as fresh.
    file = fullfile(source,'execution_manifest.json');
    assert(isfile(file),'ejc:Study6Sources','Fresh source manifest missing: %s',file);
    item = jsondecode(fileread(file));
    assert(strcmp(item.computationMode,'fresh') && strcmp(item.status,'PASSED') && ...
        strcmp(item.sourceSHA,current.sourceSHA) && strcmp(item.study,key), ...
        'ejc:Study6Sources','Source is incomplete, historical, or from another candidate: %s',source);
    if strlength(string(expectedPolicy))>0
        assert(isfield(item,'policySHA256') && strcmp(item.policySHA256,expectedPolicy), ...
            'ejc:Study6Sources','Source was not verified with the frozen effective policy: %s.',source);
    end
    identities{s} = item;
end
end
