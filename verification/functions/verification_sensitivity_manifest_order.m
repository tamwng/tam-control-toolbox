function [a,b,c] = verification_sensitivity_manifest_order(a,b,c)
%VERIFICATION_SENSITIVITY_MANIFEST_ORDER Read the declared legacy execution order.
% Only an explicitly compatible producer may store the exact baseline-first
% permutation. Files stay unchanged; tokens move with their rows for validation.
if string(c.study)~="p06" || string(c.file)~="P06_RUN_MANIFEST.csv",return;end
expected=c.bindingA.values;reference=c.bindingB.values;
assert(isequal(expected.runId,reference.runId) && isequal(b.runId,reference.runId), ...
    'study:SensitivityManifestOrder','Canonical fixed design order differs.');
assert(height(a)==height(expected) && numel(unique(a.runId))==height(a), ...
    'study:SensitivityManifestOrder','Missing or duplicate sensitivity run identity.');
if isequal(a.runId,expected.runId),return;end
order=[find(expected.baselineGate);find(~expected.baselineGate)];
assert(isfield(c,'allowLegacySensitivityOrder') && c.allowLegacySensitivityOrder && ...
    isequal(a.runId,expected.runId(order)), ...
    'study:SensitivityManifestOrder','Unrecognized sensitivity manifest order.');
[~,inverse]=sort(order);
a=a(inverse,:);c.csvTokensA=c.csvTokensA(inverse,:);c.rootA=a;
c.manifestOrderProof=struct('status','EXACT_LEGACY_BASELINE_FIRST_PERMUTATION', ...
    'passed',true,'sourceRowForDesignRow',inverse,'originalFileSHA256',c.sourceSHA256);
end
