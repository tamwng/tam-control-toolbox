function evidence=verification_settings_source_binding(record,parents)
%VERIFICATION_SETTINGS_SOURCE_BINDING Exact own copies behind excluded source metadata.
assert(isfield(record,'cfg') && isstruct(record.cfg) && isscalar(record.cfg) && ...
    isfield(record,'sources') && iscell(record.sources) && isequal(size(record.sources),[1 5]) && ...
    isfield(record.cfg,'sources') && iscell(record.cfg.sources) && numel(record.cfg.sources)==5, ...
    'ejc:SettingsSource','Five ordered source settings and labels required.');
if isfield(record.cfg,'sourceDirectories')
    assert(iscell(record.cfg.sourceDirectories) && numel(record.cfg.sourceDirectories)==5, ...
        'ejc:SettingsSource','Five explicit source directories required.');
end
rows=struct([]);
for j=1:5
    key="study"+j;assert(isfield(parents,key),'ejc:SettingsSource','Missing bound source %s.',key);
    directory=char(parents.(key));[~,label]=fileparts(directory);
    if ~strcmp(string(record.cfg.sources{j}),label)
        % Relocated canonical inputs must pass their complete original inventory.
        verified=resolve_reference_inputs(parents,key);
        parts=split(strip(string(verified.(key).originalPrefix),'right','/'),'/');
        label=parts(end);
    end
    assert(strcmp(string(record.cfg.sources{j}),label),'ejc:SettingsSource','Source label/order differs.');
    if isfield(record.cfg,'sourceDirectories')
        declared=char(java.io.File(char(record.cfg.sourceDirectories{j})).getCanonicalPath());
        bound=char(java.io.File(directory).getCanonicalPath());
        assert(strcmp(declared,bound),'ejc:SettingsSource','Excluded directory metadata points at the wrong source.');
    end
    file=fullfile(directory,'settings.mat');assert(isfile(file),'ejc:SettingsSource','Missing source settings.');
    before=verification_file_sha256(file);value=load(file);
    assert(exact_ordered_copy(record.sources{j},value),'ejc:SettingsSource','Stored source settings differ from their own parent.');
    assert(strcmp(before,verification_file_sha256(file)),'ejc:InputChanged','Source changed during settings binding.');
    rows=[rows;struct('study',key,'path',string(file),'sha256',string(before),'passed',true)]; %#ok<AGROW>
end
evidence=struct('passed',true,'checks',numel(rows),'rows',rows);
end
function yes=exact_ordered_copy(a,b)
yes=strcmp(class(a),class(b)) && isequal(size(a),size(b));if ~yes,return;end
if isstruct(b)
    yes=isequal(fieldnames(a),fieldnames(b));if ~yes,return;end
    for j=1:numel(b)
        for f=string(fieldnames(b)).'
            if ~exact_ordered_copy(a(j).(f),b(j).(f)),yes=false;return;end
        end
    end
elseif iscell(b)
    for j=1:numel(b),if ~exact_ordered_copy(a{j},b{j}),yes=false;return;end,end
else,yes=isequaln(a,b);end
end
