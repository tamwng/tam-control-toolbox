function [report,verification] = study2_gram_report(resultsDir,referenceFile,comparison)
%STUDY2_GRAM_REPORT Re-evaluate archived full-window Gram matrices only.
% No trajectory, covariance, or archived diagnostic is changed. Only windows
% with gramCount=50 at recorded steps up to nSteps are included. Rank uses
% s>1e-10*smax; deficient windows retain Inf in conditionMin/conditionMax.
% Rank/condition ranges and fractionDeficient use validFullWindowCount;
% invalidFullWindowCount explicitly records exclusions. Known models are N/A.
% Optional referenceFile crosschecks the supplied derived CSV. Its
% maxStoredCondition is the original archived gramCondition maximum, not the
% corrected rank-based condition. The old maximum is used internally only;
% returned conditionMin/conditionMax always follow the numerical-rank rule.

validateattributes(resultsDir,{'char','string'},{'nonempty'});
if nargin<3,comparison=[];end
assert(isempty(comparison) || isa(comparison,'function_handle'), ...
    'study2:GramComparisonHook','Optional raw-maximum comparison must be a callback.');
verification=struct('mode',"STRICT_OR_NO_REFERENCE",'rows',{{}});
files = dir(fullfile(resultsDir,'runs','amplitude_*.mat'));
assert(~isempty(files),'study2:MissingAmplitudeRuns', ...
    'No stored amplitude runs were found in the supplied results directory.');
rows = struct([]);
for k = 1:numel(files)
    saved = load(fullfile(files(k).folder,files(k).name),'result');
    assert(isfield(saved,'result'),'study2:InvalidStoredRun', ...
        'A stored amplitude run must contain result.');
    r = saved.result;
    assert(strcmp(r.kind,'amplitude'),'study2:InvalidStoredRun', ...
        'An amplitude filename must contain an amplitude run.');
    validateattributes(r.nSteps,{'double'},{'scalar','integer','nonnegative','finite'});
    validateattributes(r.nEstimated,{'double'},{'scalar','integer','nonnegative','finite'});
    assert(r.nSteps <= numel(r.gramCount),'study2:InvalidStoredRun', ...
        'The recorded step count exceeds the stored Gram-window counts.');
    row = struct('model',string(r.id),'modelName',string(r.name), ...
        'amplitude',r.amplitude,'applicable',~strcmp(r.id,'K'), ...
        'status',"full numerical rank",'runCompleted',logical(r.completed), ...
        'parameterCount',r.nEstimated,'relativeThreshold',1e-10, ...
        'rankMin',NaN,'rankMax',NaN,'deficientWindowCount',0, ...
        'validFullWindowCount',0,'recordedFullWindowCount',0, ...
        'invalidFullWindowCount',0,'fractionDeficient',NaN, ...
        'conditionMin',NaN,'conditionMax',NaN,'maxStoredCondition',NaN);
    if ~row.applicable
        assert(r.nEstimated == 0,'study2:InvalidKnownRun', ...
            'The known-model reference must have zero estimated coefficients.');
        row.status = "N/A";
    else
        assert(r.nEstimated > 0,'study2:InvalidStoredRun', ...
            'An adaptive run must have at least one estimated coefficient.');
        windows = find(r.gramCount(1:r.nSteps) == 50);
        row.recordedFullWindowCount = numel(windows);
        if ~isempty(windows) && isfield(r,'gramCondition') && ...
                max(windows) <= numel(r.gramCondition)
            stored = r.gramCondition(windows);
            if ~any(isnan(stored))
                row.maxStoredCondition = max(stored);
            end
        end
        ranks = nan(size(windows)); conditions = nan(size(windows));
        valid = false(size(windows));
        for j = 1:numel(windows)
            index = windows(j);
            if size(r.gram,1) ~= r.nEstimated || size(r.gram,2) ~= r.nEstimated || ...
                    index > size(r.gram,3)
                continue
            end
            [ranks(j),conditions(j),valid(j)] = study2_gram_diagnostic(r.gram(:,:,index));
        end
        row.validFullWindowCount = nnz(valid);
        row.invalidFullWindowCount = nnz(~valid);
        row.deficientWindowCount = nnz(ranks(valid) < r.nEstimated);
        if any(valid)
            row.rankMin = min(ranks(valid)); row.rankMax = max(ranks(valid));
            row.conditionMin = min(conditions(valid));
            row.conditionMax = max(conditions(valid));
            row.fractionDeficient = row.deficientWindowCount/row.validFullWindowCount;
        end
        if row.deficientWindowCount > 0
            row.status = "numerically rank deficient";
        end
        if isempty(windows)
            row.status = "no full windows";
        elseif row.validFullWindowCount == 0
            row.status = "invalid windows";
        elseif row.invalidFullWindowCount > 0
            row.status = row.status+"; invalid windows";
        end
        if ~r.completed
            row.status = row.status+"; incomplete run";
        end
    end
    rows = [rows;row]; %#ok<AGROW>
end
report = struct2table(rows);
assert(height(unique(report(:,{'model','amplitude'}))) == height(report), ...
    'study2:DuplicateAmplitudeRun','Each model/amplitude pair must occur once.');
report = sortrows(report,{'amplitude','model'});
if nargin > 1 && ~isempty(referenceFile)
    verification=crosscheck(report,referenceFile,comparison,resultsDir);
end
report.maxStoredCondition = [];
end

function verification=crosscheck(report,referenceFile,comparison,resultsDir)
verification=struct('mode',"STRICT",'rows',{{}});
if ~isempty(comparison),verification.mode="PORTABLE_RAW_GRAM_MAXIMUM_ONLY";end
reference = readtable(referenceFile,'TextType','string','VariableNamingRule','preserve');
required = {'model','modelName','amplitude','coefficients','fullWindows', ...
    'rankMin','rankMax','rankDeficientWindows','maxStoredCondition', ...
    'relative_singular_value_threshold'};
assert(all(ismember(required,reference.Properties.VariableNames)), ...
    'study2:GramReferenceColumns','The reference CSV is missing required diagnostic columns.');
adaptive = report(report.applicable,:);
assert(height(reference) == height(adaptive), ...
    'study2:GramReferenceMismatch', ...
    'Reference has %d rows, but the stored runs have %d adaptive model/amplitude pairs.', ...
    height(reference),height(adaptive));
assert(height(unique(reference(:,{'model','amplitude'}))) == height(reference), ...
    'study2:GramReferenceMismatch','The reference CSV contains duplicate model/amplitude pairs.');
columns = {'parameterCount','recordedFullWindowCount','validFullWindowCount', ...
    'rankMin','rankMax','deficientWindowCount','relativeThreshold'};
referenceColumns = {'coefficients','fullWindows','fullWindows', ...
    'rankMin','rankMax','rankDeficientWindows','relative_singular_value_threshold'};
for k = 1:height(adaptive)
    row = adaptive(k,:);
    selected = reference.model == row.model & reference.amplitude == row.amplitude;
    assert(nnz(selected) == 1,'study2:GramReferenceMismatch', ...
        'Reference has no unique match for %s at amplitude %.17g.',row.model,row.amplitude);
    expected = reference(selected,:);
    assert(row.modelName == expected.modelName,'study2:GramReferenceMismatch', ...
        'Model name differs for %s at amplitude %.17g.',row.model,row.amplitude);
    for j = 1:numel(columns)
        actualValue = row.(columns{j}); expectedValue = expected.(referenceColumns{j});
        assert(isequal(actualValue,expectedValue),'study2:GramReferenceMismatch', ...
            '%s at amplitude %.17g: %s is %.17g; reference gives %.17g.', ...
            row.model,row.amplitude,columns{j},actualValue,expectedValue);
    end
    assert(row.invalidFullWindowCount == 0,'study2:GramReferenceMismatch', ...
        '%s at amplitude %.17g has %d invalid full windows.', ...
        row.model,row.amplitude,row.invalidFullWindowCount);
    actualValue = row.maxStoredCondition; expectedValue = expected.maxStoredCondition;
    matching = isequal(actualValue,expectedValue) || ...
        (isfinite(actualValue) && isfinite(expectedValue) && ...
        abs(actualValue-expectedValue) <= 32*eps(max(1,abs(expectedValue))));
    if isempty(comparison)
        assert(matching,'study2:GramReferenceMismatch', ...
            '%s at amplitude %.17g: original maxStoredCondition is %.17g; reference gives %.17g.', ...
            row.model,row.amplitude,actualValue,expectedValue);
    else
        request=struct('field',"maxStoredCondition",'row',row,'referenceRow',expected, ...
            'resultsDirectory',string(resultsDir),'referenceFile',string(referenceFile),'originalStrictPassed',matching);
        verdict=comparison(request);
        assert(isstruct(verdict) && isscalar(verdict) && ...
            all(isfield(verdict,{'binding','passed','status','rawCurrent','rawReference','ownSourcePassed','parentsPassed'})) && ...
            isequal(string(verdict.binding),"P07_STUDY2_GRAM_MAX_V1") && ...
            isequal(verdict.passed,true) && isequal(verdict.ownSourcePassed,true) && isequal(verdict.parentsPassed,true) && ...
            any(string(verdict.status)==["NUMERICAL_AGREEMENT","QUALIFIED_UNRESOLVED_GRAM_REDUCTION","EXACT_STRUCTURAL_ZERO_GRAM_REDUCTION"]) && ...
            isequaln(verdict.rawCurrent,actualValue) && isequaln(verdict.rawReference,expectedValue), ...
            'study2:GramComparisonHook','Missing, failed or malformed portable raw-maximum evidence.');
        verification.rows{end+1,1}=verdict;
    end
end
if isempty(comparison)
    fprintf(['Study 2 Gram crosscheck: %d adaptive model/amplitude pairs match.\n' ...
        'maxStoredCondition was checked against archived gramCondition, not the corrected rank-based condition.\n'], ...
        height(adaptive));
else
    qualified=nnz(cellfun(@(v)v.status=="QUALIFIED_UNRESOLVED_GRAM_REDUCTION",verification.rows));
    fprintf('Study 2 portable raw-Gram report: %d adaptive rows accepted; %d qualified unresolved maxima (not numerical equality).\n',height(adaptive),qualified);
end
end
