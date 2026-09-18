function cfg = study2_settings
%STUDY2_SETTINGS Fixed pilot protocol for approximation order and region.
% Reference amplitudes and independent evaluation input ranges are separate
% variables. These seeds are pilot-only; no confirmation campaign is run.

cfg.Ts = 0.1;
cfg.N = 10;
cfg.duration = 80;
cfg.K = 800;
cfg.amplitudes = [0.2 0.6 1.0];
cfg.evaluationRanges = [0.25 0.70 1.10];
cfg.fitSteps = [25 50 100 200];
cfg.horizons = [1 2 5 10 20];
cfg.anchors = 20:20:580;
cfg.modelIds = {'A','E','O3','O5','P3','K'};
cfg.auditIds = {'A','O3','E','K'};
cfg.inputSeed = 3101;
cfg.evaluationSeeds = [3102 3103 3104];
cfg.initializationCount = 200;
cfg.initializationRange = 1.10;
cfg.evaluationCount = 600;
cfg.initialState = 0;
cfg.initialInput = 0;
cfg.kind = 'amplitude';
cfg.constantReference = NaN;
cfg.control = struct('Q',reshape([ones(1,9),10],1,1,10), ...
    'R',0.05,'Hu',[1;-1],'hu',[1.2;1.2], ...
    'Hdu',[1;-1],'hdu',[0.25;0.25], ...
    'Hy',[1;-1],'hy',[1.2;1.2],'Seps',1e4*eye(2));
end
