function records = study1_records(cfg,campaign)
%STUDY1_RECORDS Fixed clean input records and independent paired noise streams.
% Noise column j belongs to state sample j, including the initial sample.
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
end
