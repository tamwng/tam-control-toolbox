function p06_execute(output,plan,manifest,authorization)
%P06_EXECUTE Execute the fixed full design through the historical authorization contract.
assert(nargin==4 && strcmp(authorization,'P06_PRODUCTION_AUTHORIZED'), ...
    'p06:NotAuthorized','Separate production authorization is required.');
assert(height(manifest)==1558,'p06:Budget','Only the approved full design is supported.');
assert(strcmp(p06_hash(plan.recordFile),plan.recordSHA256),'p06:ChangedRecord','Record changed.');
provenance = p06_provenance(plan); provenance.productionLaunched = true;
save(fullfile(output,'execution_provenance.mat'),'provenance','plan','-v7');
% Save the actual source snapshot; a commit label alone is insufficient.
allSources=[provenance.sources,provenance.p06Files];
for j=1:numel(allSources)
    relative=erase(allSources(j).file,[plan.root filesep]);
    target=fullfile(output,'source_snapshot',relative);
    if ~isfolder(fileparts(target)), mkdir(fileparts(target)); end
    copyfile(allSources(j).file,target);
end
saved=load(plan.recordFile,'records'); records=saved.records;
mkdir(fullfile(output,'runs')); mkdir(fullfile(output,'tables'));
gate=find(manifest.baselineGate); remaining=find(~manifest.baselineGate);
order=[gate;remaining]; runRows=struct([]); gateRows=table;
for index=order.'
    row=manifest(index,:); item=table2struct(row); item.executionStatus="FAILED_SETUP_OR_EXECUTION";
    item.completed=false; item.predictionCompleted=false; item.nSteps=0;
    item.predictionRMS=NaN; item.trackingRMS=NaN; item.inputRMS=NaN;
    item.meanAbsoluteIncrement=NaN; item.identificationRejected=NaN;
    item.initializationRejected=NaN; item.controlRejected=NaN;
    item.outputViolationPeak=NaN; item.inputViolationPeak=NaN; item.incrementViolationPeak=NaN;
    item.failureMessage=""; failure=struct; result=[]; scores=[];
    try
        [result,scores]=p06_case(row,plan,records);
        whole=scores.metrics(1); initial=scores.initialization;
        item.completed=result.completed; item.nSteps=result.nSteps;
        item.predictionCompleted=initial.evaluationQueries==600 && initial.finiteQueries==600;
        item.predictionRMS=initial.predictionRMS;
        % Retain finite-prefix metrics in the MAT; complete-run table uses NaN.
        if item.completed
            item.trackingRMS=whole.trackingRMS; item.inputRMS=whole.inputRMS;
            item.meanAbsoluteIncrement=whole.meanAbsoluteIncrement;
        end
        for name={'identificationRejected','initializationRejected','controlRejected'}
            item.(name{1})=scores.diagnostics.(name{1});
        end
        for name={'outputViolationPeak','inputViolationPeak','incrementViolationPeak'}
            item.(name{1})=whole.(name{1});
        end
        item.executionStatus="COMPLETED";
        if ~item.completed, item.executionStatus="TERMINATED"; end
        item.failureMessage=string(result.terminationReason);
    catch exception
        failure=struct('identifier',exception.identifier,'message',exception.message,'stack',exception.stack);
        item.failureMessage=string(exception.message);
    end
    target=fullfile(output,'runs',char(row.runId+".mat"));
    assert(~isfile(target),'p06:ExistingRun','Never overwrite a run.');
    save(target,'result','scores','item','failure','-v7');
    if mod(numel(runRows)+1,50)==0 || row.baselineGate
        fprintf('P06 %d/%d: %s, %s.\n',numel(runRows)+1,height(manifest),row.runId,item.executionStatus);
    end
    runRows=[runRows;item]; %#ok<AGROW>
    if row.baselineGate
        assert(~isempty(result),'p06:BaselineFailed','Baseline case failed; remaining campaign stopped.');
        old=load(row.baselineFile,'result'); checks=p06_gate(result,old.result,plan.cfg);
        checks.runId=repmat(row.runId,height(checks),1);
        checks.baselineSHA256=repmat(string(p06_hash(row.baselineFile)),height(checks),1);
        gateRows=[gateRows;checks]; %#ok<AGROW>
        writetable(gateRows,fullfile(output,'tables','baseline_gate.csv'));
        assert(all(checks.passed),'p06:BaselineMismatch','Baseline mismatch; remaining campaign stopped.');
    end
end
runs=struct2table(runRows);
writetable(runs,fullfile(output,'tables','runs.csv'));
writetable(runs(~runs.noisy,:),fullfile(output,'tables','deterministic.csv'));
writetable(plan.knownAliases,fullfile(output,'tables','known_reference_aliases.csv'));
[summaries,contrasts,analysis]=p06_summarize(runs,plan);
writetable(summaries,fullfile(output,'tables','noisy_summaries.csv'));
writetable(contrasts,fullfile(output,'tables','paired_contrasts.csv'));
save(fullfile(output,'analysis_randomness.mat'),'analysis','-v7');
end
