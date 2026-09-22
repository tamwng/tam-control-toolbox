function outputDir = run_study6(outputName)
%RUN_STUDY6 Prediction/control diagnostics from the saved Studies 1--5.
% From the repository root: run_study6
% No fitting, new noise, QP solves or closed-loop study runs are performed by
% this evaluator. The complete verification suite includes its own fixtures.
root = fileparts(mfilename('fullpath'));
if nargin < 1, outputName = ['study6_pilot_',char(datetime('now','Format','yyyyMMdd_HHmmss'))]; end
assert(ischar(outputName) && ~isempty(regexp(outputName,'^[A-Za-z0-9_-]+$','once')));
oldPath = path; cleanup = onCleanup(@() path(oldPath));
restoredefaultpath; addpath(root,fullfile(root,'src'));
for s = 1:6, addpath(fullfile(root,'studies',sprintf('study%d',s))); end
outputDir = fullfile(root,'results',outputName);
assert(~isfolder(outputDir) && ~isfile(outputDir),'study6:ExistingOutput','Use a new results directory.');
before = run_verification;
cfg = study6_settings;
sources = cell(1,5);
for s = 1:5
    sources{s} = load(fullfile(root,'results',cfg.sources{s},'settings.mat'));
end
mkdir(outputDir);
for folder = {'primary','online','measurement','change','tables','figures'}, mkdir(fullfile(outputDir,folder{1})); end
environment = struct('matlab',version,'execution', ...
    'Sequential derived pilot; original archive campaign labels retained, no new confirmation or controller runs.');
save(fullfile(outputDir,'settings.mat'),'cfg','sources','environment');
summary.primary = study6_primary(outputDir,root,cfg);
fprintf('Study 6: stationary paths recovered and checked against archived terminal forecasts.\n');
summary.online = study6_online(outputDir,root,cfg);
fprintf('Study 6: prescribed Study 3 online snapshots evaluated on common clean queries.\n');
[summary.measurement,summary.change] = study6_secondary(outputDir,root,cfg);
fprintf('Study 6: existing Study 1 initialization selections and nine clean change cases evaluated.\n');
[summary.constraintHistory,summary.constraintSummary] = study6_constraints(outputDir,root,cfg);
summary.study4Grid = study6_grid_context(root,cfg);
summary.main = summary.primary(summary.primary.fittingTransitions == 200,:);
save(fullfile(outputDir,'summary.mat'),'summary');
names = fieldnames(summary);
for j = 1:numel(names), writetable(summary.(names{j}),fullfile(outputDir,'tables',[names{j},'.csv'])); end
study6_figures(outputDir,summary);
verification = study6_verify_results(outputDir);
after = run_verification;
verification.beforeNames = {before.Name}; verification.beforePassed = [before.Passed];
verification.afterNames = {after.Name}; verification.afterPassed = [after.Passed];
save(fullfile(outputDir,'verification.mat'),'verification');
fprintf('Study 6 derived pilot complete: %s\n',outputDir);
end
