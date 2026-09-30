function study1_prepare(outputDir,cfg)
%STUDY1_PREPARE Freeze all inputs and independent noise streams before runs.
% The manuscript values remain pilot settings; no data-driven tuning occurs.
assert(~isfolder(outputDir),'study1:ExistingOutput','Use a new results directory.');
mkdir(outputDir);
mkdir(fullfile(outputDir,'data'));
environment.matlab = version;
optimization = ver('optim');
environment.optimizationToolbox = optimization.Version;
environment.execution = 'Sequential MATLAB execution from run_study1.';
save(fullfile(outputDir,'settings.mat'),'cfg','environment');
campaigns = {'pilot','confirmation'};
for c = 1:numel(campaigns)
    campaign = campaigns{c};
    records = study1_records(cfg,campaign);
    save(fullfile(outputDir,'data',['records_' campaign '.mat']),'records');
end
end
