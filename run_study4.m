function outputDir = run_study4(outputName,options)
%RUN_STUDY4 Deterministic fixed-dictionary structural-change pilot only.
% From the repository root: run_study4
% Requires MATLAB and Optimization Toolbox. Every invocation uses a new
% results directory; no tuning, noisy repetitions, or confirmation runs.
% Generates the complete fixed study with applicable component and saved-data
% validity checks. Figures=false changes plotting only. Reference comparison
% is a separate operation; use generate_results for recorded source identity.

arguments
    outputName = ''
    options.Figures (1,1) logical = true
    options.ReferenceDirectory = ''
    options.VerificationAdapter = []
end
root = fileparts(mfilename('fullpath'));
outputDir = new_output_path('study4',outputName);
if isempty(options.VerificationAdapter)
    options.VerificationAdapter = study_validity_callback('study4', ...
        [outputDir '_validity']);
end
oldPath = path;
cleanup = onCleanup(@() path(oldPath));
restoredefaultpath;
addpath(root,fullfile(root,'src'),fullfile(root,'studies','study1'), ...
    fullfile(root,'studies','study2'),fullfile(root,'studies','study3'), ...
    fullfile(root,'studies','study4'));
before = study_prerequisites('study4');

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
check_input_records(outputDir,options.ReferenceDirectory,4);

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
after = study_prerequisites('study4');
verification = struct('beforeNames',{ {before.Name} },'beforePassed',[before.Passed], ...
    'afterNames',{ {after.Name} },'afterPassed',[after.Passed], ...
    'savedDataChecksPassed',true);
save(fullfile(outputDir,'verification.mat'),'verification');
fprintf('Study 4 pilot package complete: %s\n',outputDir);
end
