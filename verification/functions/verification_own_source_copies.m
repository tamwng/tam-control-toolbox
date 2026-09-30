function info=verification_own_source_copies(record,study,source,sources)
%VERIFICATION_OWN_SOURCE_COPIES Exact selected copies, separate from numerical bounds.
info=struct('checks',0,'status',"NOT_APPLICABLE");
if ~isstruct(record) || ~isscalar(record),return;end
[~,sourceName,sourceExtension]=fileparts(source);
if string(study)=="study6" && string(sourceName)+string(sourceExtension)=="summary.mat"
    assert(isfield(record,'summary') && isstruct(record.summary), ...
        'ejc:OwnSource','Missing original Study 6 summary structure.');
    s=record.summary;
    assert(isfield(s,'main') && isfield(s,'primary') && ...
        istable(s.main) && istable(s.primary) && ...
        ismember('fittingTransitions',s.primary.Properties.VariableNames), ...
        'ejc:OwnSource','Missing original Study 6 primary/main source relationship.');
    assert(isequaln(s.main,s.primary(s.primary.fittingTransitions==200,:)), ...
        'ejc:OwnSource','Study 6 main differs from its exact own 200-transition primary selection.');
    info.checks=info.checks+1;
end
fit=[];steps=[];
if isfield(record,'result') && isstruct(record.result) && isscalar(record.result) && isfield(record.result,'fit')
    r=record.result;fit=r.fit;steps=r.forecasts.fitSteps;
elseif isfield(record,'fit') && isstruct(record.fit)
    fit=record.fit;
    z=load(fullfile(sources.(study),'settings.mat'),'cfg');steps=z.cfg.fitSteps;
end
if ~isempty(fit)
    for pair={"checkpointTheta","theta";"checkpointMappedTheta","mappedTheta";"checkpointCovariance","covariance"}'
        target=pair{1};parent=pair{2};
        if ~isfield(fit,target),continue;end
        assert(isfield(fit,parent) && ~isempty(steps),'ejc:OwnSource','Missing own checkpoint source.');
        if parent=="covariance",expected=fit.(parent)(:,:,steps+1);else,expected=fit.(parent)(:,steps+1);end
        assert(isequaln(fit.(target),expected),'ejc:OwnSource','Checkpoint differs from its exact own history: %s.',source);
        info.checks=info.checks+1;
    end
end
if info.checks>0,info.status="PASSED";end
if string(study)~="p06" || ~isfield(record,'item'),return;end
r=record.result;s=record.scores;item=record.item;[~,name]=fileparts(source);
assert(string(item.runId)==string(name),'ejc:OwnSource','Sensitivity source filename/run identity differs.');
for field=string(fieldnames(r.p06)).'
    if field=="executionStatus",continue;end % Saved execution state differs from the planned state.
    if isfield(item,field)
        assert(isequaln(item.(field),r.p06.(field)),'ejc:OwnSource','Sensitivity item metadata copy differs: %s.',field);
        info.checks=info.checks+1;
    end
end
expectedStatus="TERMINATED";if r.completed,expectedStatus="COMPLETED";end
assert(string(r.p06.executionStatus)=="PROPOSED_NOT_RUN" && string(item.executionStatus)==expectedStatus, ...
    'ejc:OwnSource','Sensitivity plan-to-execution status transformation differs.');
info.checks=info.checks+1;
assert(isequal(item.completed,r.completed) && isequal(item.nSteps,r.nSteps) && ...
    isequal(item.predictionCompleted,s.initialization.evaluationQueries==600 && s.initialization.finiteQueries==600) && ...
    isequaln(item.predictionRMS,s.initialization.predictionRMS) && ...
    isequal(item.failureMessage,string(r.terminationReason)), 'ejc:OwnSource','Sensitivity result/item copy differs.');
info.checks=info.checks+5;
for field=["trackingRMS","inputRMS","meanAbsoluteIncrement"]
    expected=NaN;if r.completed,expected=s.metrics(1).(field);end
    assert(isequaln(item.(field),expected),'ejc:OwnSource','Sensitivity complete-score copy differs: %s.',field);
    info.checks=info.checks+1;
end
for field=["identificationRejected","initializationRejected","controlRejected"]
    assert(isequaln(item.(field),s.diagnostics.(field)),'ejc:OwnSource','Sensitivity diagnostic count copy differs: %s.',field);
    info.checks=info.checks+1;
end
for field=["outputViolationPeak","inputViolationPeak","incrementViolationPeak"]
    assert(isequaln(item.(field),s.metrics(1).(field)),'ejc:OwnSource','Sensitivity metric copy differs: %s.',field);
    info.checks=info.checks+1;
end
info.status="PASSED";
end
