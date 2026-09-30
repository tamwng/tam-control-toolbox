function outputDir = run_study5(outputName,options)
%RUN_STUDY5 Physical identification/reconstruction deterministic pilot only.
% From the repository root: run_study5
% Requires MATLAB and Optimization Toolbox. Writes a new results package;
% no confirmation, tuning, publication graphics, or Study 6 decomposition.
% The complete test suite requires retained archives/fixtures; this is
% not a reference-free single-case driver. Figures=false suppresses figures
% only; it does not reduce the computation or its scientific checks.

arguments
    outputName = ''
    options.Figures (1,1) logical = true
    options.ReferenceDirectory = ''
end
root = fileparts(mfilename('fullpath'));
outputDir = ejc_output_path('study5',outputName);
oldPath = path; cleanup = onCleanup(@() path(oldPath));
restoredefaultpath; addpath(root,fullfile(root,'src'));
for s = [1 2 3 5], addpath(fullfile(root,'studies',sprintf('study%d',s))); end
before = run_verification;
cfg = study5_settings;
mkdir(outputDir);
for folder = {'fits','runs','evaluation','tables','figures'}, mkdir(fullfile(outputDir,folder{1})); end
optimization = ver('optim');
environment = struct('matlab',version,'optimizationToolbox',optimization.Version, ...
    'execution','Sequential deterministic pilot; offline audits do not supply identification data.');
save(fullfile(outputDir,'settings.mat'),'cfg','environment');
audit = study5_numerics(cfg);
save(fullfile(outputDir,'evaluation','numerical_audit.mat'),'audit');
assert(audit.stateChecksPassed,'study5:NumericalAccuracy', ...
    'Nominal propagation failed the existing physical-flow state accuracy check; saved audit requires review.');
records.initialization = study5_record(200,cfg.inputSeed,cfg);
records.evaluation = study5_record(600,cfg.evaluationSeed,cfg);
save(fullfile(outputDir,'records.mat'),'records');
ejc_check_records(outputDir,options.ReferenceDirectory,5);
queries = study5_queries(records.evaluation,cfg);
save(fullfile(outputDir,'evaluation','common_queries.mat'),'queries');
for id = string(cfg.modelIds)
    fit = study5_fit(id,records.initialization,cfg);
    save(fullfile(outputDir,'fits',sprintf('fit_%s.mat',id)),'fit');
    forecasts = study5_forecasts(fit,records.evaluation,queries,cfg);
    save(fullfile(outputDir,'evaluation',sprintf('%s.mat',id)),'forecasts');
    result = study5_trajectory(id,fit,cfg);
    save(fullfile(outputDir,'runs',sprintf('%s.mat',id)),'result');
    runAudit = study5_run_audit(result,cfg);
    save(fullfile(outputDir,'evaluation',sprintf('run_audit_%s.mat',id)),'runAudit');
    fprintf('Study 5: %s, %d/%d transitions, completed=%d.\n',result.name,result.nSteps,cfg.K,result.completed);
end
summary = study5_summarize(outputDir,cfg);
save(fullfile(outputDir,'summary.mat'),'summary');
study5_verify_results(outputDir,cfg);
if options.Figures, study5_figures(outputDir,cfg,summary); end
after = run_verification;
verification = struct('beforeNames',{{before.Name}},'beforePassed',[before.Passed], ...
    'afterNames',{{after.Name}},'afterPassed',[after.Passed],'savedDataChecksPassed',true);
save(fullfile(outputDir,'verification.mat'),'verification');
fprintf('Study 5 deterministic pilot complete: %s\n',outputDir);
end
