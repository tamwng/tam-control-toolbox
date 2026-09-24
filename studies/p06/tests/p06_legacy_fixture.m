function cfg = p06_legacy_fixture(output)
%P06_LEGACY_FIXTURE Copy two saved cases for the summarizer regression only.
root = fileparts(fileparts(fileparts(fileparts(mfilename('fullpath')))));
archive = fullfile(root,'results','study1_candidate_20260917');
assert(~isfolder(output),'p06:ExistingOutput','Use a fresh fixture directory.');
mkdir(output); mkdir(fullfile(output,'data')); mkdir(fullfile(output,'audits'));
mkdir(fullfile(output,'tables'));
cfg = study1_settings;
cfg.modelIds = {'S'};
cfg.pilot.noiseTrials = 0; cfg.confirmation.noiseTrials = 0;
for campaign = {'pilot','confirmation'}
    name = [campaign{1} '_S_000.mat'];
    for kind = {'data','audits'}
        copyfile(fullfile(archive,kind{1},name),fullfile(output,kind{1},name));
    end
end
saved = readtable(fullfile(archive,'tables','measured_initialization_audit.csv'), ...
    'TextType','string');
saved = saved(saved.model == "S" & saved.trial == 0,:);
writetable(saved,fullfile(output,'tables','measured_initialization_audit.csv'));
end
