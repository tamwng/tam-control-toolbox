function checks = check_result(resultFile)
%CHECK_RESULT Recheck a saved fixed example without rerunning its controller.
% CHECKS = CHECK_RESULT(fullfile(output,'data','confirmation_S_000.mat')).
% Uses the saved input records and unchanged Study 1 independent checks.
% Raises on missing data, altered settings or an invalid calculation.
% A PASS here means internal validity, not historical-reference agreement.
assert(nargin==1,'example:ResultRequired','Supply the saved example MAT file.');
resultFile = char(java.io.File(char(resultFile)).getCanonicalPath());
context = public_context; %#ok<NASGU>
assert(isfile(resultFile),'example:MissingResult','Saved result is missing: %s',resultFile);
saved = load(resultFile,'result','cfg','records');
assert(all(isfield(saved,{'result','cfg','records'})), ...
    'example:Record','The example requires result, cfg and input records.');
checks = study1_check_case(saved.result,saved.records,saved.cfg);
fprintf('Saved-result internal validity: PASS. Reference comparison: not run.\n');
end
