function output = run_p06(output,mode,authorization)
%RUN_P06 Default: write only P06_RUN_MANIFEST.csv, without fitting or control.
% Production requires separate user authorization and the exact third token.
if nargin < 1, error('p06:OutputRequired','Specify a fresh output directory.'); end
if nargin < 2, mode = 'dry-run'; end
if nargin < 3, authorization = ''; end
assert(any(strcmp(mode,{'dry-run','execute'})),'p06:Mode','Unknown mode.');
if strcmp(mode,'execute')
    assert(strcmp(authorization,'P06_PRODUCTION_AUTHORIZED'), ...
        'p06:NotAuthorized','Production requires separate authorization.');
end
assert(~isfolder(output) && ~isfile(output),'p06:ExistingOutput','Never overwrite an output.');
root = fileparts(fileparts(fileparts(mfilename('fullpath'))));
ejc_assert_writable(output);
previous = path; cleanup = onCleanup(@() path(previous));
addpath(fullfile(root,'src'),fullfile(root,'studies','study1'));
[plan,manifest] = p06_plan;
mkdir(output);
writetable(manifest,fullfile(output,'P06_RUN_MANIFEST.csv'));
if strcmp(mode,'dry-run')
    fprintf('P06 dry-run: %d proposed runs. Manifest only; production not launched.\n',height(manifest));
    return
end
p06_execute(output,plan,manifest,authorization);
end
