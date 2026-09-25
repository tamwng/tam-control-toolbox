function output = ejc_output_path(prefix,requested)
%EJC_OUTPUT_PATH Choose a new destination without touching the filesystem/RNG.
% Omit REQUESTED for a collision-safe directory under results. A simple name
% is also placed under results; explicit relative paths are repository-relative.
% Existing requested destinations fail. Direct callers create the directory.
if nargin < 2, requested = ''; end
root = fileparts(mfilename('fullpath')); requested = char(requested);
if isempty(requested)
    base = fullfile(root,'results',['p07_' char(prefix) '_' ...
        char(datetime('now','Format','yyyyMMdd_HHmmss_SSS'))]);
    output = base; suffix = 0;
    while isfolder(output) || isfile(output)
        suffix = suffix+1; output = sprintf('%s_%03d',base,suffix);
    end
elseif java.io.File(requested).isAbsolute()
    output = requested;
elseif isempty(regexp(requested,'[/\\]','once'))
    output = fullfile(root,'results',requested);
else
    output = fullfile(root,requested);
end
output = char(java.io.File(output).getCanonicalPath());
rootPath = strrep(root,'\','/'); targetPath = strrep(output,'\','/');
if ispc, rootPath = lower(rootPath); targetPath = lower(targetPath); end
assert(~startsWith(targetPath,[rootPath '/']) || startsWith(targetPath,[rootPath '/results/']), ...
    'ejc:OutputPath','Repository-local generated outputs must stay under results/.');
ejc_assert_writable(output);
assert(~isfolder(output) && ~isfile(output),'ejc:ExistingOutput', ...
    'Output already exists. Choose a new directory: %s',output);
end
