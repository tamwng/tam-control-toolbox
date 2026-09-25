function report = ejc_compare_results(sources,references,output)
%EJC_COMPARE_RESULTS Compare fresh EJC results with immutable reference files.
% Sources/references have absolute study1,...,study6,p06 directory fields.
% Output is a new or existing writable evidence directory. Each MAT is loaded
% separately. Scientific values, array order, classes and nonfinite masks
% must agree exactly for this same-machine candidate. This rule was fixed
% after the unchanged-source Gate B comparisons, before the candidate run.
% Existing P06 gate tolerances remain separately visible; they are not a
% blanket allowance for other quantities. CSV values are compared at their
% stored precision, with underlying MAT arrays compared independently.
% Wall-clock measurements and explicit source/environment metadata are
% recorded as exclusions. No covariance/Hessian conditioning is excluded.
ejc_assert_writable(output);
assert(~isfile(output),'ejc:OutputFile','The evidence destination is a file.');
if ~isfolder(output), mkdir(output); end
targets = {'comparison_files.csv','comparison_failures.csv','comparison_exclusions.csv', ...
    'comparison_inventory.csv','p06_baseline_gate.csv','comparison.mat'};
for k = 1:numel(targets)
    assert(~isfile(fullfile(output,targets{k})),'ejc:ExistingComparison','Never overwrite comparison evidence.');
end
allowed = ["study1","study2","study3","study4","study5","study6","p06"];
supplied = string(fieldnames(sources));
assert(~isempty(supplied) && all(ismember(supplied,allowed)), ...
    'ejc:SourceFields','Supply one or more study1,...,study6,p06 directory fields.');
groups = allowed(ismember(allowed,supplied));
files = struct([]); failures = struct([]); exclusions = struct([]); inventory = struct([]);
for group = groups
    assert(isfield(sources,group) && isfield(references,group),'ejc:MissingSource','Missing %s directory.',group);
    actualRoot = sources.(group); referenceRoot = references.(group);
    assert(isfolder(actualRoot) && isfolder(referenceRoot),'ejc:MissingSource','Missing %s directory.',group);
    mode = "fresh-versus-retained";
    if strcmp(char(java.io.File(char(actualRoot)).getCanonicalPath()), ...
            char(java.io.File(char(referenceRoot)).getCanonicalPath()))
        mode = "archive self-check; no fresh computation";
    end
    [expected,ignoredReference] = scientific_files(referenceRoot);
    [actual,ignoredCurrent] = scientific_files(actualRoot);
    assert(~isempty(expected),'ejc:MissingReference','No scientific reference files found for %s.',group);
    names = union(expected,actual);
    for name = reshape(names,1,[])
        present = any(actual == name); retained = any(expected == name);
        inventoryRow = struct('study',group,'relativePath',name, ...
            'referencePresent',retained,'currentPresent',present,'passed',present && retained);
        inventory = [inventory;inventoryRow]; %#ok<AGROW>
        context = struct('study',group,'file',name,'source',string(fullfile(actualRoot,name)), ...
            'reference',string(fullfile(referenceRoot,name)));
        state = empty_state;
        if ~present || ~retained
            state = failed(state,"<file>","Required file set differs",NaN,NaN);
        else
            try
                if endsWith(name,'.mat')
                    a = load(context.source); b = load(context.reference);
                else
                    a = read_csv(context.source); b = read_csv(context.reference);
                end
                if group == "p06" && name == "tables/baseline_gate.csv"
                    % The gate maxima describe new-versus-archive comparisons;
                    % their historical zero values are not new tolerances.
                    assert(all(a.passed) && height(a) == height(b), ...
                        'ejc:P06GateFailed','The retained P06 gate did not pass completely.');
                    writetable(a,fullfile(output,'p06_baseline_gate.csv'));
                    state.excluded = [state.excluded;excluded("maxAbsoluteDifference", ...
                        "Reported separately under the original P06 quantity-specific gate",a.maxAbsoluteDifference,b.maxAbsoluteDifference)];
                    a.maxAbsoluteDifference = []; b.maxAbsoluteDifference = [];
                end
                state = compare_value(a,b,"value",state);
                if isstruct(a) && isfield(a,'result') && isstruct(a.result) && isscalar(a.result) && isfield(a.result,'completed')
                    state.attemptedRuns = 1; state.completedRuns = double(a.result.completed);
                end
            catch exception
                state = failed(state,"<read-or-compare>",string(exception.identifier)+": "+string(exception.message),NaN,NaN);
            end
        end
        fileRow = struct('study',group,'relativePath',name,'source',context.source, ...
            'reference',context.reference,'mode',mode,'rule',"exact scientific values", ...
            'absoluteTolerance',0,'relativeTolerance',0,'leafChecks',state.leafChecks, ...
            'numericValues',state.numericValues,'nonfiniteMaskMismatches',state.maskMismatches, ...
            'maximumAbsoluteDifference',state.maximum,'maximumField',state.maximumField, ...
            'maximumLinearIndex',state.maximumIndex,'attemptedRuns',state.attemptedRuns, ...
            'completedRuns',state.completedRuns,'failedChecks',numel(state.failures), ...
            'passed',isempty(state.failures));
        files = [files;fileRow]; %#ok<AGROW>
        for k = 1:numel(state.failures)
            row = state.failures(k); row.study = group; row.relativePath = name;
            failures = [failures;row]; %#ok<AGROW>
        end
        for k = 1:numel(state.excluded)
            row = state.excluded(k); row.study = group; row.relativePath = name;
            exclusions = [exclusions;row]; %#ok<AGROW>
        end
    end
    % Preserve the distinction between execution provenance and scientific
    % equality. These files are retained in each source package, not loaded
    % as historical scientific answers or compared as source identities.
    for name = reshape(union(ignoredReference,ignoredCurrent),1,[])
        reason = "Run-specific provenance/test metadata; numerical verification CSV is compared when present";
        if startsWith(name,"review/") || startsWith(name,"source_snapshot/")
            reason = "Historical review/source-snapshot export; producing run MAT values and scientific tables are compared separately";
        end
        row = excluded("<execution-evidence>",reason, ...
            string(fullfile(actualRoot,name)),string(fullfile(referenceRoot,name)));
        row.study = group; row.relativePath = name; exclusions = [exclusions;row]; %#ok<AGROW>
    end
end
report.files = as_table(files,struct('study',"",'passed',false));
report.failures = as_table(failures,struct('quantity',"",'reason',"", ...
    'maximumAbsoluteDifference',NaN,'linearIndex',NaN,'study',"",'relativePath',""));
report.exclusions = as_table(exclusions,struct('quantity',"",'reason',"", ...
    'currentMetadata',"",'referenceMetadata',"",'study',"",'relativePath',""));
report.inventory = as_table(inventory,struct('study',"",'relativePath',"", ...
    'referencePresent',false,'currentPresent',false,'passed',false));
report.passed = ~isempty(files) && all(report.files.passed) && all(report.inventory.passed);
report.rule = 'Exact scientific MAT values and discrete definitions; exact values at stored CSV precision. No ranking assertions.';
report.sourceDirectories = sources; report.referenceDirectories = references;
writetable(report.files,fullfile(output,'comparison_files.csv'));
writetable(report.failures,fullfile(output,'comparison_failures.csv'));
writetable(report.exclusions,fullfile(output,'comparison_exclusions.csv'));
writetable(report.inventory,fullfile(output,'comparison_inventory.csv'));
save(fullfile(output,'comparison.mat'),'report','-v7');
end

function [names,ignored] = scientific_files(root)
entries = [dir(fullfile(root,'**','*.mat'));dir(fullfile(root,'**','*.csv'))];
names = strings(0,1); ignored = strings(0,1);
for k = 1:numel(entries)
    file = fullfile(entries(k).folder,entries(k).name);
    relative = replace(string(file(numel(char(root))+2:end)),filesep,'/');
    if any(relative == ["verification.mat","execution_provenance.mat"]) || ...
            startsWith(relative,"review/") || startsWith(relative,"source_snapshot/")
        ignored(end+1,1) = relative; %#ok<AGROW>
        continue
    end
    names(end+1,1) = relative; %#ok<AGROW>
end
names = sort(names); ignored = sort(ignored);
end

function value = read_csv(file)
% Empty event tables are valid retained outputs, not missing observations.
info = dir(file);
if info.bytes == 0, value = table; return; end
value = readtable(file,'TextType','string','VariableNamingRule','preserve');
end

function state = empty_state
state = struct('leafChecks',0,'numericValues',0,'maskMismatches',0, ...
    'maximum',0,'maximumField',"",'maximumIndex',NaN,'attemptedRuns',0,'completedRuns',0, ...
    'failures',struct([]),'excluded',struct([]));
end

function state = compare_value(a,b,quantity,state)
if isstruct(a) && isstruct(b)
    if ~isequal(size(a),size(b)), state = failed(state,quantity,"Struct shape differs",NaN,NaN); return; end
    names = union(string(fieldnames(a)),string(fieldnames(b)));
    for name = reshape(names,1,[])
        if strlength(exclusion_reason(name,quantity)) == 0 && (~isfield(a,name) || ~isfield(b,name))
            state = failed(state,quantity+"."+name,"Scientific field set differs",NaN,NaN);
        end
    end
    for k = 1:numel(a)
        for name = reshape(names,1,[])
            field = quantity+"("+k+")."+name;
            reason = exclusion_reason(name,quantity);
            if strlength(reason) > 0
                left = []; right = [];
                if isfield(a,name), left = a(k).(name); end
                if isfield(b,name), right = b(k).(name); end
                state.excluded = [state.excluded;excluded(field,reason,left,right)];
            elseif ~isfield(a,name) || ~isfield(b,name)
                continue % The schema discrepancy was recorded above, including empty structs.
            else
                state = compare_value(a(k).(name),b(k).(name),field,state);
            end
        end
    end
elseif istable(a) && istable(b)
    if height(a) ~= height(b), state = failed(state,quantity,"Table row count differs",NaN,NaN); return; end
    leftNames = string(a.Properties.VariableNames); rightNames = string(b.Properties.VariableNames);
    keptLeft = leftNames(arrayfun(@(x) strlength(exclusion_reason(x,quantity)) == 0,leftNames));
    keptRight = rightNames(arrayfun(@(x) strlength(exclusion_reason(x,quantity)) == 0,rightNames));
    if ~isequal(keptLeft,keptRight), state = failed(state,quantity,"Scientific table columns/order differ",NaN,NaN); return; end
    for name = reshape(union(leftNames,rightNames,'stable'),1,[])
        field = quantity+"."+name; reason = exclusion_reason(name,quantity);
        if strlength(reason) > 0
            left = []; right = [];
            if any(leftNames == name), left = a.(name); end
            if any(rightNames == name), right = b.(name); end
            state.excluded = [state.excluded;excluded(field,reason,left,right)];
        else
            state = compare_value(a.(name),b.(name),field,state);
        end
    end
elseif iscell(a) && iscell(b)
    if ~isequal(size(a),size(b)), state = failed(state,quantity,"Cell shape differs",NaN,NaN); return; end
    for k = 1:numel(a), state = compare_value(a{k},b{k},quantity+"{"+k+"}",state); end
else
    state.leafChecks = state.leafChecks+1;
    maximum = NaN; index = NaN;
    if (isnumeric(a) || islogical(a)) && (isnumeric(b) || islogical(b)) && isequal(size(a),size(b))
        state.numericValues = state.numericValues+numel(b);
        maskDifference = (isfinite(a) ~= isfinite(b)) | (isnan(a) ~= isnan(b)) | (isinf(a) & isinf(b) & a ~= b);
        state.maskMismatches = state.maskMismatches+nnz(maskDifference);
        finite = isfinite(a) & isfinite(b); indices = find(finite);
        delta = abs(double(a(finite))-double(b(finite))); maximum = 0;
        if ~isempty(delta), [maximum,k] = max(delta); index = indices(k); end
        if maximum > state.maximum
            state.maximum = maximum; state.maximumField = quantity; state.maximumIndex = index;
        end
    end
    if ~isequaln(a,b), state = failed(state,quantity,"Exact value/class/shape agreement failed",maximum,index); end
end
end

function reason = exclusion_reason(name,parent)
reason = "";
if any(name == ["controlTime","controlTimeMedianSeconds","controlTimeMaximumSeconds","controlTimeMaxSeconds"])
    reason = "Wall-clock execution time; no scientific time/index is excluded";
elseif name == "environment"
    reason = "Execution environment is retained separately for each run";
elseif any(name == ["sourceFile","sourceRecord","recordFile","baselineFile"])
    reason = "Source-location metadata; scientific record identities/arrays are compared separately";
elseif endsWith(parent,".cfg") && any(name == ["execution","sources","sourceDirectories","sourceMode"])
    reason = "Execution/source-binding metadata; binding is reported separately";
end
end

function state = failed(state,quantity,reason,maximum,index)
row = struct('quantity',quantity,'reason',reason, ...
    'maximumAbsoluteDifference',maximum,'linearIndex',index);
state.failures = [state.failures;row];
end

function row = excluded(quantity,reason,a,b)
row = struct('quantity',quantity,'reason',reason, ...
    'currentMetadata',description(a),'referenceMetadata',description(b));
end

function text = description(value)
% Avoid duplicating full timing arrays in compact comparison evidence.
if (ischar(value) || isstring(value) || iscellstr(value)) && numel(value) < 4096
    text = string(jsonencode(value));
elseif isstruct(value) && isscalar(value)
    text = string(jsonencode(value));
else
    text = string(class(value))+" "+string(mat2str(size(value)));
end
end

function value = as_table(rows,prototype)
% Each struct element is one evidence record, including scalar/empty cases.
if isempty(rows)
    value = struct2table(prototype,'AsArray',true); value(1,:) = [];
else
    value = struct2table(rows,'AsArray',true);
end
end
