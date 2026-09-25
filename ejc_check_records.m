function ejc_check_records(output,reference,study)
%EJC_CHECK_RECORDS Verify fixed experimental inputs before any study fitting.
% Only Study 3's historical execution-description string is metadata. Every
% scientific configuration value and regenerated input/noise element is exact.
if isempty(reference), return; end
a = load(fullfile(output,'settings.mat'),'cfg');
b = load(fullfile(reference,'settings.mat'),'cfg');
if study == 3 && isfield(b.cfg,'execution'), b.cfg = rmfield(b.cfg,'execution'); end
assert(isequaln(a.cfg,b.cfg),'ejc:ConfigurationMismatch', ...
    'Scientific settings differ in Study %d. Stop for review.',study);
files = {'records.mat'};
if study == 1, files = {fullfile('data','records_pilot.mat'),fullfile('data','records_confirmation.mat')}; end
for j = 1:numel(files)
    assert(isfile(fullfile(reference,files{j})),'ejc:MissingRecord','Required record missing: %s',files{j});
    a = load(fullfile(output,files{j})); b = load(fullfile(reference,files{j}));
    assert(isequaln(a,b),'ejc:RecordMismatch','Study %d input/noise records differ: %s',study,files{j});
end
fprintf('Study %d scientific settings and input/noise records match exactly.\n',study);
end
