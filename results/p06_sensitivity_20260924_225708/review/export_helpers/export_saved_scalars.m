% Export stored scalar records only. No fitting, scoring or model propagation.
campaign = 'C:/Users/tamwi/OneDrive - Kyoto University/research/projects/tam-control-toolbox/results/p06_sensitivity_20260924_225708';
exportRoot = fileparts(mfilename('fullpath'));
destination = fullfile(exportRoot,'compact');
assert(~isfolder(destination),'Export already exists; never overwrite.');
assert(isfile(fullfile(campaign,'tables','paired_contrasts.csv')),'Campaign is not finished.');
mkdir(destination);
paths = dir(fullfile(campaign,'runs','*.mat'));
[~,order] = sort({paths.name}); paths = paths(order);
assert(numel(paths)==1558);
scalarRecords = cell(numel(paths),1);
items = struct([]); metricRows = struct([]); initialRows = struct([]);
diagnosticRows = struct([]); failureRows = struct([]);
comparisons = 0;
for j = 1:numel(paths)
    s = load(fullfile(paths(j).folder,paths(j).name),'item','scores','failure');
    assert(isequal(sort(fieldnames(s)),sort({'item';'scores';'failure'})));
    scalarRecords{j}=s;
    items=[items;s.item]; %#ok<AGROW>
    f=struct('runId',s.item.runId,'executionStatus',s.item.executionStatus, ...
        'identifier',"",'message',"",'stackEntries',0);
    if ~isempty(fieldnames(s.failure))
        f.identifier=string(s.failure.identifier); f.message=string(s.failure.message);
        f.stackEntries=numel(s.failure.stack);
    end
    failureRows=[failureRows;f]; %#ok<AGROW>
    if ~isempty(s.scores)
        assert(numel(s.scores.initialization)==1);
        assert(isequaln(s.item.predictionRMS,s.scores.initialization.predictionRMS));
        assert(s.item.predictionCompleted == (s.scores.initialization.evaluationQueries==600 && s.scores.initialization.finiteQueries==600));
        comparisons=comparisons+2;
        if s.item.completed
            for field={'trackingRMS','inputRMS','meanAbsoluteIncrement'}
                assert(isequaln(s.item.(field{1}),s.scores.metrics(1).(field{1})));
                comparisons=comparisons+1;
            end
        end
        for field={'identificationRejected','initializationRejected','controlRejected'}
            assert(isequaln(s.item.(field{1}),s.scores.diagnostics.(field{1})));
            comparisons=comparisons+1;
        end
        metricRows=[metricRows;context(s.scores.metrics,s.item)]; %#ok<AGROW>
        initialRows=[initialRows;context(s.scores.initialization,s.item)]; %#ok<AGROW>
        diagnosticRows=[diagnosticRows;context(s.scores.diagnostics,s.item)]; %#ok<AGROW>
    end
end
caseTable=struct2table(items); scoringWindows=struct2table(metricRows);
initializationScores=struct2table(initialRows); diagnostics=struct2table(diagnosticRows);
failures=struct2table(failureRows);
save(fullfile(destination,'P06_SAVED_SCALARS.mat'),'scalarRecords','caseTable', ...
    'scoringWindows','initializationScores','diagnostics','failures','-v7');
exactcsv(caseTable,fullfile(destination,'P06_CASE_SCALARS.csv'));
exactcsv(scoringWindows,fullfile(destination,'P06_SCORING_WINDOWS.csv'));
exactcsv(initializationScores,fullfile(destination,'P06_INITIALIZATION_SCORES.csv'));
exactcsv(diagnostics,fullfile(destination,'P06_CASE_DIAGNOSTICS.csv'));
exactcsv(failures,fullfile(destination,'P06_CASE_EXCEPTIONS.csv'));
saved=load(fullfile(campaign,'execution_provenance.mat'),'provenance','plan');
planReadable=saved.plan;
planReadable.configurations=table2struct(saved.plan.configurations);
planReadable.knownAliases=table2struct(saved.plan.knownAliases);
writejson(fullfile(destination,'P06_EXECUTED_PROVENANCE.json'),saved.provenance);
writejson(fullfile(destination,'P06_EXECUTED_PLAN.json'),planReadable);
exactcsv(saved.plan.configurations,fullfile(destination,'P06_CONFIGURATIONS.csv'));
metadata=struct('cases',numel(paths),'scoreWindowRows',height(scoringWindows), ...
    'initializationRows',height(initializationScores),'diagnosticRows',height(diagnostics), ...
    'itemVersusSavedScoreExactComparisons',comparisons, ...
    'sourceVariables',{{'item','scores','failure'}},'resultVariableLoaded',false, ...
    'modelsEvaluated',0,'scoringFunctionsCalled',0,'csvNumericFormat','%.17g', ...
    'nonfiniteCSV','NaN, Inf and -Inf retained explicitly', ...
    'jsonNonfinite','MATLAB JSON uses null for nonfinite numeric metadata; consult MAT and CSV', ...
    'gramDefinition','Legacy Study 1 cond(G); not thresholded numerical-rank diagnostic');
writejson(fullfile(destination,'P06_SCALAR_EXPORT_CHECK.json'),metadata);
disp(metadata);

function rows=context(rows,item)
for k=1:numel(rows)
    rows(k).runId=item.runId;
    rows(k).configuration=item.configuration;
    rows(k).descriptiveModel=item.model;
end
end

function exactcsv(t,path)
assert(~isfile(path));
file=fopen(path,'w','n','UTF-8'); assert(file>=0);
cleanup=onCleanup(@() fclose(file));
fprintf(file,'%s\n',strjoin(t.Properties.VariableNames,','));
for row=1:height(t)
    fields=cell(1,width(t));
    for col=1:width(t)
        value=t{row,col};
        if iscell(value), value=value{1}; end
        if isnumeric(value) || islogical(value)
            assert(isscalar(value)); fields{col}=sprintf('%.17g',value);
        else
            assert(ischar(value) || (isstring(value) && isscalar(value)));
            fields{col}=['"',strrep(char(value),'"','""'),'"'];
        end
    end
    fprintf(file,'%s\n',strjoin(fields,','));
end
end

function writejson(path,value)
assert(~isfile(path));
file=fopen(path,'w','n','UTF-8'); assert(file>=0);
cleanup=onCleanup(@() fclose(file));
fprintf(file,'%s\n',jsonencode(value,'PrettyPrint',true));
end
