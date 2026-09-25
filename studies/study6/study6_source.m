function folder = study6_source(root,cfg,index)
%STUDY6_SOURCE Resolve an explicitly bound Study 1--5 input directory.
% Historical configurations retain their original repository-relative paths.
% A missing explicit source is an error; historical data are never substituted.
if isfield(cfg,'sourceDirectories')
    assert(iscell(cfg.sourceDirectories) && numel(cfg.sourceDirectories) >= index, ...
        'study6:SourceBinding','An explicit directory is required for every source study.');
    folder = cfg.sourceDirectories{index};
else
    folder = fullfile(root,'results',cfg.sources{index});
end
assert((ischar(folder) || (isstring(folder) && isscalar(folder))) && isfolder(folder), ...
    'study6:MissingSource','Required Study %d source directory is missing.',index);
end
