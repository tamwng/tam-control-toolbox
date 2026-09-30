function outputDir = run_study4(outputName,options)
%RUN_STUDY4 Deterministic fixed-dictionary structural-change pilot only.
% From the repository root: run_study4
% Requires MATLAB and Optimization Toolbox. Every invocation uses a new
% results directory; no tuning, noisy repetitions, or confirmation runs.
% The complete test suite requires retained archives/fixtures; this is
% not a reference-free single-case driver. Figures=false suppresses figures
% only; it does not reduce the computation or its scientific checks.

arguments
    outputName = ''
    options.Figures (1,1) logical = true
    options.ReferenceDirectory = ''
    options.VerificationAdapter = []
end
root = fileparts(mfilename('fullpath'));
outputDir = ejc_output_path('study4',outputName);
oldPath = path;
cleanup = onCleanup(@() path(oldPath));
restoredefaultpath;
addpath(root,fullfile(root,'src'),fullfile(root,'studies','study1'), ...
    fullfile(root,'studies','study2'),fullfile(root,'studies','study3'), ...
    fullfile(root,'studies','study4'));
before = run_verification;
cfg = study4_settings;
mkdir(outputDir);
for folder = {'fits','runs','evaluation','tables','figures'}
    mkdir(fullfile(outputDir,folder{1}));
end
optimization = ver('optim');
environment = struct('matlab',version,'optimizationToolbox',optimization.Version, ...
    'execution','Sequential deterministic Study 4 pilot; no confirmation or tuning.');
save(fullfile(outputDir,'settings.mat'),'cfg','environment');
records.initialization = study4_record(200,.5,cfg.inputSeed,cfg);
records.evaluation = study4_record(600,.5,cfg.evaluationSeed,cfg);
save(fullfile(outputDir,'records.mat'),'records');
ejc_check_records(outputDir,options.ReferenceDirectory,4);
fits = struct;
for id = string(cfg.modelIds)
    if id == "K", continue; end
    fit = study4_fit(id,records.initialization,cfg);
    fits.(id) = fit;
    save(fullfile(outputDir,'fits',sprintf('fit_%s.mat',id)),'fit');
end
for scenario = string(cfg.scenarios)
    for id = string(cfg.modelIds)
        fit = []; if id ~= "K", fit = fits.(id); end
        result = study4_trajectory(id,fit,scenario,cfg);
        save(fullfile(outputDir,'runs',sprintf('%s_%s.mat',scenario,id)),'result');
        fprintf('Study 4: %s / %s, %d/%d transitions, completed=%d.\n', ...
            result.scenarioName,result.name,result.nSteps,cfg.K,result.completed);
    end
end
% Evaluator-only queries run AFTER all control trajectories have been saved.
for scenario = string(cfg.scenarios)
    for id = string(cfg.modelIds)
        saved = load(fullfile(outputDir,'runs',sprintf('%s_%s.mat',scenario,id)),'result');
        evaluation = study4_evaluate(saved.result,cfg);
        save(fullfile(outputDir,'evaluation',sprintf('%s_%s.mat',scenario,id)),'evaluation');
    end
end
if isempty(options.VerificationAdapter)
    study4_verify_results(outputDir,cfg);
else
    assert(isa(options.VerificationAdapter,'function_handle'),'ejc:VerificationAdapter','Expected a verification function.');
    options.VerificationAdapter(outputDir,cfg);
end
summary = study4_summarize(outputDir,cfg);
save(fullfile(outputDir,'summary.mat'),'summary');
if options.Figures, study4_figures(outputDir,cfg); end
after = run_verification;
verification = struct('beforeNames',{ {before.Name} },'beforePassed',[before.Passed], ...
    'afterNames',{ {after.Name} },'afterPassed',[after.Passed], ...
    'savedDataChecksPassed',true);
save(fullfile(outputDir,'verification.mat'),'verification');
fprintf('Study 4 pilot package complete: %s\n',outputDir);
end
