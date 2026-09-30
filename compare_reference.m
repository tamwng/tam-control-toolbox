function report = compare_reference(resultFile,referenceFile,outputName)
%COMPARE_REFERENCE Compare an existing fixed example with its canonical record.
% REPORT = COMPARE_REFERENCE(resultFile,referenceFile) never reruns the science.
% Both MAT files must be explicit. The canonical reference SHA-256 and frozen
% policy/inventory identities are checked before the unchanged representative
% comparator is called. Scope: Shared S, confirmation, trial 0 only.
% Missing/wrong references raise errors (never PASS). A numerical failure is
% retained as report.passed=false; qualified Gram outcomes retain their scope.
% An optional third argument selects a new report directory under results/ or
% an absolute path. It saves scalar/field/Gram summaries, not copied trajectories.
% This is not a source-integrity or full-paper certificate.
assert(nargin>=2 && ~isempty(referenceFile),'reference:MissingReference', ...
    'Supply the canonical reference MAT file; comparison was not run.');
if nargin<3, outputName = ''; end
resultFile = char(java.io.File(char(resultFile)).getCanonicalPath());
referenceFile = char(java.io.File(char(referenceFile)).getCanonicalPath());
if ~isempty(regexp(char(outputName),'[/\\]','once'))
    outputName = char(java.io.File(char(outputName)).getCanonicalPath());
end
[context,root] = public_context; %#ok<ASGLU>
assert(isfile(referenceFile),'reference:MissingReference', ...
    'Canonical reference unavailable; comparison was not run: %s',referenceFile);
assert(isfile(resultFile),'example:MissingResult','Saved result is missing: %s',resultFile);
assert(~strcmpi(resultFile,referenceFile),'reference:SelfComparison', ...
    'The generated result and canonical reference must be separate records.');
contract = jsondecode(fileread(fullfile(root,'private','representative_reference_inputs.json')));
referenceHash = ejc_file_sha256(referenceFile);
assert(strcmp(referenceHash,contract.canonical_sha256),'reference:Identity', ...
    'The supplied file is not the declared canonical reference.');
assert(strcmp(ejc_file_sha256(fullfile(root,contract.policy_path)),contract.policy_sha256) && ...
    strcmp(ejc_file_sha256(fullfile(root,contract.field_inventory_path)),contract.field_inventory_sha256), ...
    'reference:PolicyIdentity','The released policy or field inventory differs.');
current = load(resultFile,'result','cfg','records');
assert(all(isfield(current,{'result','cfg','records'})),'example:Record','The generated result is incomplete.');
checks = study1_check_case(current.result,current.records,current.cfg);
canonical = load(referenceFile,'result');
assert(isfield(canonical,'result'),'reference:Record','The reference result is missing.');

report = ejc_compare_representative(current.result,canonical.result,current.cfg);
report.scope = contract.scope; report.internalChecks = checks;
report.sourceFile = resultFile; report.referenceFile = referenceFile;
report.sourceSHA256 = ejc_file_sha256(resultFile); report.referenceSHA256 = referenceHash;
report.policySHA256 = contract.policy_sha256;
report.fieldInventorySHA256 = contract.field_inventory_sha256;
if ~isempty(outputName)
    output = ejc_output_path('comparison',outputName); mkdir(output);
    compact = rmfield(report,intersect(fieldnames(report),{'rows','conditions','matrixDetails'}));
    compact.fieldRows = numel(report.rows);
    public_json(fullfile(output,'comparison.json'),compact);
    if ~isempty(report.rows)
        writetable(struct2table(rmfield(report.rows,'numeric')),fullfile(output,'fields.csv'));
    end
    if isfield(report.conditions,'gramRows') && ~isempty(report.conditions.gramRows)
        writetable(struct2table(report.conditions.gramRows),fullfile(output,'gram.csv'));
    end
end
fprintf('Reference comparison (%s): %s; passed=%d; qualified Gram rows=%d.\n', ...
    report.scope,report.status,report.passed,report.qualifiedCount);
if ~report.passed, fprintf('Reason: %s\n',report.reason); end
end
