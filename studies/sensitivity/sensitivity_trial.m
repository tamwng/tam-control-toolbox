function [training,noise,cfg] = sensitivity_trial(records,trial,configuration,baseCfg)
%SENSITIVITY_TRIAL Prefix endpoints and inputs together; never shift control noise.
validateattributes(trial,{'double'},{'scalar','integer','>=',0,'<=',40});
count = configuration.fittingTransitions;
if isnan(count), count = 200; end % K: metadata only, no RLS updates.
assert(ismember(count,[50 100 200]),'p06:Length','Only approved prefixes are supported.');
training = records.initialization;
if trial > 0, training.y = training.x+records.initialNoise(trial,:); end
for name = {'x','y','time'}
    training.(name{1}) = training.(name{1})(1:count+1);
end
for name = {'u','target'}
    training.(name{1}) = training.(name{1})(1:count);
end
noise = zeros(1,baseCfg.K+1);
if trial > 0, noise = records.controlNoise(trial,:); end
cfg = baseCfg; cfg.control.R = configuration.R; cfg.fitSteps = count;
end
