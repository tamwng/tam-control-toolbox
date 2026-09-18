function study3_run_batch(outputDir,trials)
%STUDY3_RUN_BATCH Disjoint deterministic or paired-noise Study 3 trials.
% Trial zero runs both clean scenarios; trials 1:40 run the five-case noisy
% abrupt comparison only. Separate MATLAB processes can run disjoint trials.
saved = load(fullfile(outputDir,'settings.mat'),'cfg'); cfg = saved.cfg;
saved = load(fullfile(outputDir,'records.mat'),'records'); records = saved.records;
assert(all(trials >= 0 & trials <= cfg.noiseTrials & trials == floor(trials)), ...
    'study3:Trials','Requested trials are outside this pilot.');
for trial = trials
    training = records.initialization;
    noise = struct('measurement',zeros(1,cfg.K+1),'process',zeros(1,cfg.K));
    training.measurementNoise = zeros(1,201); training.processNoise = zeros(1,200);
    models = {'A','S'}; scenarios = cfg.scenarios; cases = cfg.caseIds;
    if trial > 0
        training.measurementNoise = records.initialMeasurementNoise(trial,:);
        training.processNoise = records.initialProcessNoise(trial,:);
        for j = 1:200
            training.x(j+1) = study3_plant(training.x(j),training.u(j),.45,training.processNoise(j));
        end
        training.y = training.x+training.measurementNoise;
        noise.measurement = records.controlMeasurementNoise(trial,:);
        noise.process = records.controlProcessNoise(trial,:);
        models = {'S'}; scenarios = {'abrupt'}; cases = cfg.noisyCases;
    end
    fits = struct;
    for m = 1:numel(models)
        id = models{m};
        file = fullfile(outputDir,'fits',sprintf('fit_%s_%03d.mat',id,trial));
        assert(~isfile(file),'study3:ExistingFit','Refusing to overwrite %s.',file);
        [~,fit] = study1_fit(id,training,cfg);
        fits.(id) = fit;
        save(file,'fit','training','-v7');
        forecasts = study1_forecasts(fit,records.evaluation,cfg);
        save(fullfile(outputDir,'evaluation',sprintf('evaluation_%s_%03d.mat',id,trial)), ...
            'forecasts','-v7');
    end
    for s = 1:numel(scenarios)
        scenario = scenarios{s};
        for m = 1:numel(cases)
            id = cases{m}; spec = study3_case(id);
            modelId = spec.modelId;
            if strcmp(modelId,'K'), modelId = 'S'; end
            file = fullfile(outputDir,'runs',sprintf('%s_%s_%03d.mat',scenario,id,trial));
            assert(~isfile(file),'study3:ExistingRun','Refusing to overwrite %s.',file);
            result = study3_trajectory(id,fits.(modelId),scenario,trial,noise,cfg);
            save(file,'result','-v7');
            fprintf('%s trial %02d %-12s: %d/%d samples, %d ID rejections, %d control fallbacks.\n', ...
                scenario,trial,id,result.nSteps,cfg.K,nnz(result.idAttempted & ~result.idAccepted), ...
                nnz(~result.controlAccepted(1:result.nSteps)));
        end
    end
end
end
