function recovery = study4_recovery(result)
%STUDY4_RECOVERY Reuse the verified half-open dwell and censoring convention.
source = result;
source.scenario = 'abrupt';
if strcmp(result.scenario,'no_change'), source.scenario = 'notApplicable'; end
recovery = study3_recovery(source);
recovery.recordCompleted = result.completed;
recovery.recordStatus = "complete";
if ~result.completed, recovery.recordStatus = "incomplete"; end
end
