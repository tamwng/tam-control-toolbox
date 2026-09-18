function cfg = study3_settings
%STUDY3_SETTINGS Fixed gain-variation pilot from Section 6.3.1.
% Common Plant A settings are shared with Study 1. All input and noise seeds
% are fixed before execution; no confirmation campaign is configured here.
cfg = study1_settings;
cfg = rmfield(cfg,{'modelIds','noiseSigma','pilot','confirmation'});
cfg.caseIds = {'A_none','A_fixed','A_vrf','S_none','S_fixed','S_vrf', ...
    'S_pretrained','S_prior','K'};
cfg.noisyCases = {'S_none','S_fixed','S_vrf','S_pretrained','K'};
cfg.scenarios = {'abrupt','drift'};
cfg.noiseTrials = 40;
cfg.measurementSigma = 0.01;
cfg.processSigma = 0.005;
cfg.inputSeed = 4101;
cfg.evaluationSeed = 4102;
cfg.initialMeasurementBase = 4200;
cfg.initialProcessBase = 4300;
cfg.controlMeasurementBase = 4400;
cfg.controlProcessBase = 4500;
cfg.bootstrapSeed = 4601;
cfg.representativeTrial = 1;
cfg.campaign = 'pilot';
end
