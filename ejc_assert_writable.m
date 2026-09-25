function ejc_assert_writable(destination)
%EJC_ASSERT_WRITABLE Reject outputs that overlap immutable historical inputs.
% Canonical paths also catch '..' and existing symbolic-link aliases. Parents
% of a protected directory are rejected because recursive operations there
% could include the archive. This is a guard, not a filesystem permission.
root = fileparts(mfilename('fullpath'));
references = ejc_reference_sources; protected = struct2cell(references);
for s = 1:6
    protected{end+1} = fullfile(root,'results',sprintf('study%d_journal',s)); %#ok<AGROW>
end
protected{end+1} = fullfile(root,'studies','p06','tests','fixtures','pre_interface.mat');
protected{end+1} = fullfile(root,'results','p07_gate_b_20260925');
target = canonical(destination);
for j = 1:numel(protected)
    archive = canonical(protected{j});
    assert(~(strcmp(target,archive) || startsWith(target,[archive '/']) || ...
        startsWith(archive,[target '/'])),'ejc:ProtectedOutput', ...
        'Output overlaps protected historical evidence: %s',destination);
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
