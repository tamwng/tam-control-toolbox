function item = p06_generate_case(output,row,plan,records)
%P06_GENERATE_CASE Save one fixed sensitivity case and its original diagnostics.
    item=table2struct(row); item.executionStatus="FAILED_SETUP_OR_EXECUTION";
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
end
