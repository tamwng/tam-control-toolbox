function report = ejc_paper_report(sources,references,output)
%EJC_PAPER_REPORT Compact paper-result views from explicitly identified runs.
% This is reporting, not a simulation. Sources/references use study1,...,
% study6,p06 absolute directory fields. Output must not be a historical
% archive. Stored values are never rounded here.
% Table A.14 uses the 503 primary runs, excluding the 12 earlier Study 1
% diagnostic dependencies. Table 12 is the controller-specific retrospective
% measurement diagnostic, not the common-query forecast comparison.
ejc_assert_writable(output);
assert(~isfile(output),'ejc:OutputFile','The evidence destination is a file.');
if ~isfolder(output), mkdir(output); end
assert(~isfile(fullfile(output,'paper_report.mat')),'ejc:ExistingReport','Never overwrite a paper report.');
binding = source_bindings(sources,references);
[current,currentRuns] = conditioning(sources,"current");
[reference,referenceRuns] = conditioning(references,"reference");
left = current; right = reference; left.source = []; right.source = [];
conditioningPassed = isequaln(left,right);
conditions = [current;reference];
current12 = measurement_rows(sources.study6); reference12 = measurement_rows(references.study6);
left12 = current12; right12 = reference12;
left12.sourceFile = []; right12.sourceFile = [];
table12Passed = isequaln(left12,right12);

% These exports retain all reported-group support rows and their identifiers.
% Their exact paper row selections are documented in the paper/result map.
exports = {
    'study1','paired_contrasts.csv','paper_A17_study1_control.csv';
    'study1','initialization_paired_contrasts.csv','paper_A17_study1_initialization.csv';
    'study1','forecast_paired_contrasts.csv','paper_A17_study1_common_forecasts.csv';
    'study1','measured_initialization_paired_contrasts.csv','paper_A17_study1_retrospective.csv';
    'study3','paired_contrasts.csv','paper_A17_study3.csv';
    'p06','noisy_summaries.csv','paper_A18_noisy_summaries.csv';
    'p06','paired_contrasts.csv','paper_A18_paired_contrasts.csv'};
resultRows = struct([]);
for k = 1:size(exports,1)
    study = exports{k,1}; filename = exports{k,2}; target = exports{k,3};
    input = fullfile(sources.(study),'tables',filename);
    assert(isfile(input),'ejc:MissingPaperTable','Required table is missing: %s.',input);
    values = readtable(input,'TextType','string','VariableNamingRule','preserve');
    if strcmp(study,'study1'), values = values(values.campaign == "confirmation",:); end
    assert(~isempty(values),'ejc:EmptyPaperTable','Required table has no rows: %s.',input);
    write_table(values,fullfile(output,target));
    resultRow = struct('resultGroup',string(target),'study',string(study), ...
        'source',string(input),'reference',string(fullfile(references.(study),'tables',filename)), ...
        'computationMode',"derived summary of the explicitly supplied runs",'rows',height(values));
    resultRows = [resultRows;resultRow]; %#ok<AGROW>
end
report.conditioning = conditions;
report.conditioningPassed = conditioningPassed;
report.primaryRunCounts = currentRuns;
report.referenceRunCounts = referenceRuns;
report.table12Passed = table12Passed;
report.table12Rows = height(current12);
report.sourceBindings = binding;
report.resultSources = struct2table(resultRows,'AsArray',true);
report.passed = conditioningPassed && table12Passed;
report.mode = 'Derived reporting only; execution manifests identify fresh versus historical sources.';
report.conditioningDefinition = ['Recorded covarianceCondition for adaptive runs and qpCondition for all runs, ' ...
    'at steps 1:nSteps. These are separate from recent-regressor numerical rank/condition. ' ...
    'NaN/Inf counts are retained; summary statistics omit NaN only.'];
report.table12Definition = ['Study 6 measurementInitialization, sourceStudy=1, confirmation trial=0, ' ...
    'measured initialization, recordedRateLimited inputs; all six models and five horizons. ' ...
    'These are retrospective controller-specific paths, not common-query forecasts.'];
write_table(conditions,fullfile(output,'paper_A14_conditioning.csv'));
write_table(currentRuns,fullfile(output,'paper_primary_run_counts.csv'));
write_table(current12,fullfile(output,'paper_table12.csv'));
write_table(reference12,fullfile(output,'paper_table12_reference.csv'));
write_table(binding,fullfile(output,'paper_source_bindings.csv'));
write_table(report.resultSources,fullfile(output,'paper_result_sources.csv'));
save(fullfile(output,'paper_report.mat'),'report','-v7');
end

function binding = source_bindings(sources,references)
saved = load(fullfile(sources.study6,'settings.mat'),'cfg'); cfg = saved.cfg;
historical = load(fullfile(references.study6,'settings.mat'),'cfg');
freshLocation = ~same_path(sources.study6,references.study6);
if freshLocation
    assert(isfield(cfg,'sourceDirectories') && numel(cfg.sourceDirectories) == 5, ...
        'ejc:Study6Binding','A new Study 6 package must declare five explicit source directories.');
end
rows = struct([]);
for k = 1:5
    field = sprintf('study%d',k);
    used = references.(field); mode = "historical derived records";
    if isfield(cfg,'sourceDirectories')
        used = cfg.sourceDirectories{k};
        assert(same_path(used,sources.(field)),'ejc:Study6Binding', ...
            'Study 6 source %d does not match the supplied Study %d package.',k,k);
        mode = string(cfg.sourceMode);
    end
    row = struct('sourceStudy',k,'currentSource',string(used), ...
        'historicalSource',string(references.(field)),'sourceMode',mode, ...
        'currentSourceLabel',string(cfg.sources{k}), ...
        'historicalSourceLabel',string(historical.cfg.sources{k}));
    rows = [rows;row]; %#ok<AGROW>
end
binding = struct2table(rows,'AsArray',true);
end

function [rows,counts] = conditioning(sources,label)
expected = [246 22 218 12 5]; blocks = cell(5,2); cases = cell(5,2); indices = cell(5,2);
countRows = struct([]);
for s = 1:5
    root = sources.(sprintf('study%d',s));
    if s == 1, files = dir(fullfile(root,'data','confirmation_*.mat')); else, files = dir(fullfile(root,'runs','*.mat')); end
    [~,order] = sort(string({files.name})); files = files(order);
    assert(numel(files) == expected(s),'ejc:PrimaryCoverage', ...
        'Study %d needs exactly %d primary trajectories; found %d.',s,expected(s),numel(files));
    completed = 0; steps = 0;
    for file = files.'
        saved = load(fullfile(file.folder,file.name),'result'); r = saved.result;
        assert(isfield(r,'completed') && isfield(r,'nSteps'),'ejc:InvalidRun','Missing run completion fields.');
        completed = completed+double(r.completed); steps = steps+r.nSteps;
        names = ["covarianceCondition","qpCondition"];
        for q = 1:2
            if s == 1, coefficientCount = r.fit.nEstimated; else, coefficientCount = r.nEstimated; end
            if q == 1 && coefficientCount == 0, continue; end
            values = r.(names(q));
            assert(numel(values) >= r.nSteps,'ejc:IncompleteHistory','Missing %s history: %s.',names(q),file.name);
            values = values(1:r.nSteps).';
            blocks{s,q} = [blocks{s,q};values]; %#ok<AGROW>
            cases{s,q} = [cases{s,q};repmat(string(file.name),numel(values),1)]; %#ok<AGROW>
            indices{s,q} = [indices{s,q};(1:numel(values)).']; %#ok<AGROW>
        end
    end
    countRow = struct('study',"study"+s,'attemptedRuns',numel(files), ...
        'completedRuns',completed,'incompleteRuns',numel(files)-completed,'recordedSteps',steps);
    countRows = [countRows;countRow]; %#ok<AGROW>
end
rows = struct([]);
for s = 1:6
    for q = 1:2
        if s <= 5
            values = blocks{s,q}; ids = cases{s,q}; sample = indices{s,q}; group = "study"+s;
        else
            values = vertcat(blocks{:,q}); ids = strings(0,1); sample = vertcat(indices{:,q}); group = "all_primary";
            for j = 1:5, ids = [ids;"study"+j+"/"+cases{j,q}]; end %#ok<AGROW>
        end
        valid = find(~isnan(values)); maximum = NaN; minimum = NaN; middle = NaN; id = ""; index = NaN;
        if ~isempty(valid)
            [maximum,k] = max(values(valid)); minimum = min(values(valid)); middle = median(values(valid));
            location = valid(k); id = ids(location); index = sample(location);
        end
        names = ["RLS_covariance","QP_Hessian"];
        row = struct('source',label,'study',group,'quantity',names(q), ...
            'samples',numel(values),'finiteSamples',nnz(isfinite(values)), ...
            'nanSamples',nnz(isnan(values)),'infiniteSamples',nnz(isinf(values)), ...
            'minimum',minimum,'median',middle,'maximum',maximum,'maximumCase',id, ...
            'maximumMatlabIndex',index);
        rows = [rows;row]; %#ok<AGROW>
    end
end
rows = struct2table(rows,'AsArray',true); counts = struct2table(countRows,'AsArray',true);
aggregate = rows(rows.study == "all_primary",:);
assert(isequal(aggregate.samples,[483500;590000]),'ejc:ConditionCoverage', ...
    'A.14 requires 483500 adaptive covariance and 590000 all-run QP condition samples.');
end

function values = measurement_rows(root)
file = fullfile(root,'tables','measurement.csv');
assert(isfile(file),'ejc:MissingPaperTable','Required Table 12 source is missing.');
values = readtable(file,'TextType','string','VariableNamingRule','preserve');
values = values(values.kind == "measurementInitialization" & values.sourceStudy == 1 & ...
    values.sourceCampaign == "confirmation" & values.trial == 0 & ...
    values.inputMode == "recordedRateLimited" & values.initialization == "measured",:);
values = sortrows(values,{'modelId','horizon'});
assert(height(values) == 30 && numel(unique(values.modelId)) == 6 && ...
    isequal(sort(unique(values.horizon)),[1;2;5;10;20]),'ejc:Table12Coverage','Incomplete Table 12 support rows.');
assert(all(values.attemptedQueries == 29),'ejc:Table12Queries','The retained selection has 29 queries per row.');
end

function yes = same_path(a,b)
a = char(java.io.File(char(a)).getCanonicalPath());
b = char(java.io.File(char(b)).getCanonicalPath());
if ispc, yes = strcmpi(a,b); else, yes = strcmp(a,b); end
end

function write_table(value,file)
assert(~isfile(file),'ejc:ExistingReport','Never overwrite report evidence: %s.',file);
writetable(value,file);
end
