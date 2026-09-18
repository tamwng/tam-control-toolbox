function study3_prepare(output,cfg)
%STUDY3_PREPARE Freeze common inputs and independent pilot noise streams.
% The same initialization inputs are used for every trial. Saved process
% disturbances are propagated later; each trial's measurements add its own
% independent noise. No fitted model or closed-loop trajectory is made here.
assert(~isfolder(output) && ~isfile(output),'study3:ExistingOutput', ...
    'Use a new results directory.');
optimization = ver('optim');
assert(~isempty(optimization),'study3:MissingOptimizationToolbox', ...
    'Study 3 requires MATLAB and Optimization Toolbox.');
mkdir(output);
for folder = {'fits','evaluation','runs'}
    mkdir(fullfile(output,folder{1}));
end
environment.matlab = version;
environment.optimizationToolbox = optimization.Version;
environment.execution = 'Sequential Study 3 pilot; fixed inputs and independent noise streams.';
if isfield(cfg,'execution')
    environment.execution = cfg.execution;
end
save(fullfile(output,'settings.mat'),'cfg','environment');
records.initialization = study1_record(200,0.5,cfg.inputSeed,cfg);
records.evaluation = study1_record(600,0.5,cfg.evaluationSeed,cfg);
records.initialMeasurementNoise = zeros(cfg.noiseTrials,201);
records.initialProcessNoise = zeros(cfg.noiseTrials,200);
records.controlMeasurementNoise = zeros(cfg.noiseTrials,cfg.K+1);
records.controlProcessNoise = zeros(cfg.noiseTrials,cfg.K);
for trial = 1:cfg.noiseTrials
    stream = RandStream('mt19937ar','Seed',cfg.initialMeasurementBase+trial);
    records.initialMeasurementNoise(trial,:) = cfg.measurementSigma*randn(stream,1,201);
    stream = RandStream('mt19937ar','Seed',cfg.initialProcessBase+trial);
    records.initialProcessNoise(trial,:) = cfg.processSigma*randn(stream,1,200);
    stream = RandStream('mt19937ar','Seed',cfg.controlMeasurementBase+trial);
    records.controlMeasurementNoise(trial,:) = cfg.measurementSigma*randn(stream,1,cfg.K+1);
    stream = RandStream('mt19937ar','Seed',cfg.controlProcessBase+trial);
    records.controlProcessNoise(trial,:) = cfg.processSigma*randn(stream,1,cfg.K);
end
records.campaign = 'pilot';
save(fullfile(output,'records.mat'),'records','-v7');
end
