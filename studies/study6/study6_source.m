function folder = study6_source(root,cfg,index)
%STUDY6_SOURCE Resolve an explicitly bound Study 1--5 input directory.
% Saved configurations retain their original source labels.
% A missing explicit source is an error; historical data are never substituted.
if isfield(cfg,'sourceDirectories')
    assert(iscell(cfg.sourceDirectories) && numel(cfg.sourceDirectories) >= index, ...
        'study6:SourceBinding','An explicit directory is required for every source study.');
    folder = cfg.sourceDirectories{index};
else
    labels={'study1_candidate_20260917','study2_pilot_20260918', ...
        'study3_pilot_20260918','study4_pilot_20260922','study5_pilot_20260922'};
    assert(index>=1 && index<=5 && strcmp(cfg.sources{index},labels{index}), ...
        'study6:SourceBinding','Unrecognized canonical source label or order.');
    folder = fullfile(root,'references',sprintf('study%d',index));
end
assert((ischar(folder) || (isstring(folder) && isscalar(folder))) && isfolder(folder), ...
    'study6:MissingSource','Required Study %d source directory is missing.',index);
end
