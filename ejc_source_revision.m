function info = ejc_source_revision
%EJC_SOURCE_REVISION Identify the actual checkout; do not infer historical producers.
root = fileparts(mfilename('fullpath'));
[status,sha] = system(sprintf('git --no-optional-locks -C "%s" rev-parse HEAD',root));
assert(status==0,'ejc:Git','Cannot identify the source revision.');
[status,changes] = system(sprintf('git --no-optional-locks -C "%s" status --porcelain=v1',root));
assert(status==0,'ejc:Git','Cannot identify the source working tree.');
info = struct('sourceSHA',strtrim(sha),'sourceChanges',changes,'clean',isempty(strtrim(changes)));
end
