function cfg = study4_settings
%STUDY4_SETTINGS Manuscript Sections 6.3.2-6.3.3 and Appendix A.
cfg = study1_settings;
cfg = rmfield(cfg,{'modelIds','noiseSigma','pilot','confirmation', ...
    'horizons','anchors','bootstrapCount','representativeTrial'});
cfg.modelIds = {'A','Aplus','P2','K'};
cfg.scenarios = {'no_change','represented','unrepresented'};
cfg.scenarioNames = {'No change','Represented nonlinear change','Unrepresented nonlinear change'};
cfg.forgetting = struct('mode','variable','Nf',10,'sigma',.03,'eta',.02,'gamma',10);
cfg.hStar = .08;
cfg.rhoStar = .08*sqrt((1/5)/(1/2-sin(4)/8));
cfg.eventIndex = 500;
cfg.measurementSigma = 0; cfg.processSigma = 0;
cfg.inputSeed = 5101; cfg.evaluationSeed = 5102;
cfg.campaign = 'pilot';
cfg.seedPolicy = 'Fixed local mt19937ar pilot streams; independent initialization/evaluation; no confirmation.';
cfg.gridX = linspace(-1,1,21); cfg.gridU = linspace(-.7,.7,21);
cfg.snapshotStride = 10; % k=0,10,...,1190: online control snapshots on [0,120).
cfg.windows = [0,120;30,40;50,60;90,100];
cfg.windowNames = {'whole','pre','event','late'};
cfg.gramWindow = 50; cfg.rankRelativeThreshold = 1e-10;
end
