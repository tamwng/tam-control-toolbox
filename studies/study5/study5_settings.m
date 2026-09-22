function cfg = study5_settings
%STUDY5_SETTINGS Fixed deterministic Plant C pilot, Section 6.4/Appendix A.
cfg = study1_settings;
cfg = rmfield(cfg,{'noiseSigma','pilot','confirmation','bootstrapCount','representativeTrial'});
cfg.modelIds = {'I','D','A','P3','K'};
cfg.duration = 80; cfg.K = 800;
cfg.control.hdu = [.1;.1];
cfg.trueParameters = [1;.6]; % Plant/evaluator and known reference only.
cfg.plantSubsteps = 20; cfg.refinedPlantSubsteps = 40;
cfg.predictorSubsteps = 5; cfg.refinedPredictorSubsteps = 10;
cfg.forgetting = struct('mode','none');
cfg.inputSeed = 6101; cfg.evaluationSeed = 6102;
cfg.initializationCount = 200; cfg.evaluationCount = 600; cfg.inputLevelScale = .6;
cfg.campaign = 'deterministic pilot';
cfg.seedPolicy = 'Fixed independent local mt19937ar pilot streams; no confirmation.';
cfg.measurementSigma = 0; cfg.processSigma = 0;
cfg.windows = [0 80;20 80]; cfg.windowNames = {'whole','postTransient'};
cfg.gramWindow = 50; cfg.rankRelativeThreshold = 1e-10;
cfg.auditSampling = [.1 .05 .025];
cfg.auditStates = linspace(-1,1,21); cfg.auditInputs = linspace(-.6,.6,21);
% Independent evaluator integral: dense ode45 solution plus adaptive quadrature.
cfg.auditRelativeTolerance = 1e-12; cfg.auditAbsoluteTolerance = 1e-13;
cfg.units = struct('state','rad/s','input','N m','J','kg m^2', ...
    'd_C','N m / (rad/s)^3','prediction','rad/s');
end
