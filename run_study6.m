function outputDir = run_study6(outputName,options)
%RUN_STUDY6 Prediction/control diagnostics from the saved Studies 1--5.
% From the repository root: run_study6
% No fitting, new noise, QP solves or closed-loop study runs are performed by
% this evaluator. The complete verification suite includes its own fixtures.
arguments
    outputName = ''
    options.Figures (1,1) logical = true
    options.Sources (1,1) struct = struct
end
root = fileparts(mfilename('fullpath'));
outputDir = ejc_output_path('study6',outputName);
oldPath = path; cleanup = onCleanup(@() path(oldPath));
restoredefaultpath; addpath(root,fullfile(root,'src'));
for s = 1:6, addpath(fullfile(root,'studies',sprintf('study%d',s))); end
before = run_verification;
cfg = study6_settings;
cfg.sourceMode = 'historical';
if ~isempty(fieldnames(options.Sources))
    ejc_validate_sources(options.Sources);
    cfg.sourceMode = 'fresh';
    for s = 1:5
        key = sprintf('study%d',s);
        assert(isfield(options.Sources,key),'ejc:Study6Sources','Study 6 requires all five source directories.');
        cfg.sourceDirectories{s} = char(options.Sources.(key));
        [~,cfg.sources{s}] = fileparts(cfg.sourceDirectories{s});
    end
end
sources = cell(1,5);
for s = 1:5
    sources{s} = load(fullfile(study6_source(root,cfg,s),'settings.mat'));
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
if options.Figures, study6_figures(outputDir,summary); end
verification = study6_verify_results(outputDir);
after = run_verification;
verification.beforeNames = {before.Name}; verification.beforePassed = [before.Passed];
verification.afterNames = {after.Name}; verification.afterPassed = [after.Passed];
save(fullfile(outputDir,'verification.mat'),'verification');
fprintf('Study 6 derived pilot complete: %s\n',outputDir);
end
