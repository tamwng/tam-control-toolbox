function recovery = study3_recovery(result)
%STUDY3_RECOVERY Sampled abrupt-change recovery with explicit censoring.
% A candidate t>=50 is accepted when all 20 samples on [t,t+2) satisfy
% |x-r|<=0.04. The interval may end at 60 s. Delay is measured from 50 s.
% No numeric recovery delay is assigned to censoring, termination, or drift.
recovery = struct('applicable',strcmp(result.scenario,'abrupt'), ...
    'status',"notApplicable",'recovered',false,'recoveryTime',NaN, ...
    'recoveryDelay',NaN,'dwellEnd',NaN,'rightCensored',false, ...
    'censorTime',NaN,'terminationBeforeCensor',false,'terminationTime',NaN, ...
    'threshold',.04,'dwellSamples',20,'dwellSeconds',2);
if ~recovery.applicable, return; end
assert(result.Ts == .1,'study3:RecoverySampling','The prescribed recovery uses Ts=0.1 s.');
n = min(result.nSteps+1,numel(result.time));
assert(n >= 1 && n <= numel(result.x) && n <= numel(result.r), ...
    'study3:RecoveryData','State and reference must cover the recorded prefix.');
if ~result.completed
    recovery.terminationTime = result.time(n);
    recovery.terminationBeforeCensor = recovery.terminationTime < 60;
end
% Integer sample indices avoid floating-point ambiguity at 50 and 60 s.
for k = 500:580
    indices = k+(1:20);
    if indices(end) > n, break; end
    error = result.x(indices)-result.r(indices);
    if all(isfinite(error)) && all(abs(error) <= .04)
        recovery.status = "recovered"; recovery.recovered = true;
        recovery.recoveryTime = k*result.Ts;
        recovery.recoveryDelay = (k-500)*result.Ts;
        recovery.dwellEnd = (k+20)*result.Ts;
        return
    end
end
if recovery.terminationBeforeCensor
    recovery.status = "terminatedBeforeCensor";
else
    assert(result.time(n) >= 59.9,'study3:RecoveryData', ...
        'A nonterminated recovery record must cover the censoring window.');
    recovery.status = "rightCensored";
    recovery.rightCensored = true;
    recovery.censorTime = 60;
end
end
