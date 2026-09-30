function row = sensitivity_contrast(left,right,stream,count)
%SENSITIVITY_CONTRAST Paired median bootstrap; original percentile convention.
% Inputs: trial, value, complete. Nonfinite complete pairs make CI undefined.
assert(numel(unique(left.trial))==height(left) && numel(unique(right.trial))==height(right), ...
    'p06:DuplicateTrial','Trial IDs must be unique within a contrast side.');
helper = study1_summarize('analysis_helpers');
[~,il,ir] = intersect(left.trial,right.trial); % Sorted trial order is explicit.
complete = left.complete(il) & right.complete(ir);
values = left.value(il(complete))-right.value(ir(complete));
row = struct('attemptedPairs',numel(il),'completePairs',nnz(complete), ...
    'finitePairs',nnz(isfinite(values)),'medianDifference',NaN, ...
    'lower95',NaN,'upper95',NaN,'bootstrapResamples',count);
if ~isempty(values) && all(isfinite(values))
    row.medianDifference = helper.percentile(values,.5);
    samples = randi(stream,numel(values),numel(values),count);
    bootstrap = median(values(samples),1);
    row.lower95 = helper.percentile(bootstrap,.025);
    row.upper95 = helper.percentile(bootstrap,.975);
end
end
