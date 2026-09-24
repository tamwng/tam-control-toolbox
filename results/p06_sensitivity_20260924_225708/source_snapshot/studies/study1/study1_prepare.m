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
    settings = cfg.(campaign);
    records.initialization = study1_record(200,0.5,settings.inputSeed,cfg);
    records.evaluation = study1_record(600,0.5,settings.evaluationSeed,cfg);
    records.initialNoise = zeros(settings.noiseTrials,201);
    records.controlNoise = zeros(settings.noiseTrials,cfg.K+1);
    for trial = 1:settings.noiseTrials
        stream = RandStream('mt19937ar','Seed',settings.initialNoiseBase+trial);
        records.initialNoise(trial,:) = cfg.noiseSigma*randn(stream,1,201);
        stream = RandStream('mt19937ar','Seed',settings.controlNoiseBase+trial);
        records.controlNoise(trial,:) = cfg.noiseSigma*randn(stream,1,cfg.K+1);
    end
    records.campaign = campaign;
    save(fullfile(outputDir,'data',['records_' campaign '.mat']),'records');
end
end
