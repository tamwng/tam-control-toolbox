function cfg = study1_settings
%STUDY1_SETTINGS Fixed Section 6.2.1 settings and independent random streams.
% The manuscript's pilot settings are retained without outcome-based tuning.
% Confirmation uses different seeds. Trial 1 is the representative run.
% Paired bootstrap intervals use the 2.5 and 97.5 percentiles of 2000
% resampled paired medians. No resampling or control run changes settings.

cfg.Ts = 0.1;
cfg.N = 10;
cfg.duration = 120;
cfg.K = 1200;
cfg.modelIds = {'A','S','W','R','P2','K'};
cfg.fitSteps = [25 50 100 200];
cfg.horizons = [1 2 5 10 20];
cfg.anchors = 20:20:580;
cfg.noiseSigma = 0.01;
cfg.bootstrapCount = 2000;
cfg.representativeTrial = 1;
cfg.control = struct('Q',reshape([ones(1,9),10],1,1,10), ...
    'R',0.05,'Hu',[1;-1],'hu',[1;1], ...
    'Hdu',[1;-1],'hdu',[0.25;0.25], ...
    'Hy',[1;-1],'hy',[1.2;1.2],'Seps',1e4*eye(2));
cfg.pilot = struct('inputSeed',1101,'evaluationSeed',1102, ...
    'initialNoiseBase',1200,'controlNoiseBase',1300, ...
    'bootstrapSeed',1401,'noiseTrials',1);
cfg.confirmation = struct('inputSeed',2101,'evaluationSeed',2102, ...
    'initialNoiseBase',2200,'controlNoiseBase',2300, ...
    'bootstrapSeed',2401,'noiseTrials',40);
end
