function assert_output_writable(destination)
%ASSERT_OUTPUT_WRITABLE Reject outputs that overlap canonical inputs.
% Canonical paths also catch '..' and existing symbolic-link aliases. Parents
% of a protected directory are rejected because recursive operations there
% could include the archive. This is a guard, not a filesystem permission.
root = fileparts(mfilename('fullpath'));
references = reference_directories; protected = struct2cell(references);
protected{end+1} = fullfile(root,'references','study2_rank.csv');

target = canonical(destination);
for j = 1:numel(protected)
    archive = canonical(protected{j});
    assert(~(strcmp(target,archive) || startsWith(target,[archive '/']) || ...
        startsWith(archive,[target '/'])),'ejc:ProtectedOutput', ...
        'Output overlaps protected reference data: %s',destination);
end
end

function value = canonical(value)
assert((ischar(value) || isstring(value)) && strlength(string(value)) > 0, ...
    'ejc:OutputPath','An explicit nonempty output path is required.');
value = char(java.io.File(char(value)).getCanonicalPath());
value = strrep(value,'\','/');
if ispc, value = lower(value); end
while numel(value)>1 && value(end)=='/', value(end)=[]; end
end
