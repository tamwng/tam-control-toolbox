function study1_run_batch(outputDir,campaign,trials)
%STUDY1_RUN_BATCH Run selected independent trials of one frozen campaign.
% Trial zero is noise-free. This also permits separate MATLAB processes to
% execute disjoint trial ranges without Parallel Computing Toolbox.
saved = load(fullfile(outputDir,'settings.mat'),'cfg');
cfg = saved.cfg;
saved = load(fullfile(outputDir,'data',['records_' campaign '.mat']),'records');
records = saved.records;
assert(all(trials>=0 & trials<=cfg.(campaign).noiseTrials & trials==floor(trials)), ...
    'study1:Trials','Trial indices are outside the frozen campaign.');
for trial = trials
    training = records.initialization;
    noise = zeros(1,cfg.K+1);
    if trial > 0
        training.y = training.x+records.initialNoise(trial,:);
        noise = records.controlNoise(trial,:);
    end
    for m = 1:numel(cfg.modelIds)
        id = cfg.modelIds{m};
        file = fullfile(outputDir,'data',sprintf('%s_%s_%03d.mat',campaign,id,trial));
        assert(~isfile(file),'study1:ExistingRun','Refusing to overwrite %s.',file);
        [estimator,fit] = study1_fit(id,training,cfg);
        result = study1_trajectory(id,fit,estimator,noise,cfg);
        result.campaign = campaign;
        result.trial = trial;
        result.forecasts = study1_forecasts(fit,records.evaluation,cfg);
        save(file,'result','-v7');
        fprintf('%s trial %02d %-2s: %d/%d samples, %d identification rejections, %d control fallbacks.\n', ...
            campaign,trial,id,result.nSteps,cfg.K, ...
            nnz(result.idAttempted & ~result.idAccepted),nnz(~result.controlAccepted(1:result.nSteps)));
    end
end
end
