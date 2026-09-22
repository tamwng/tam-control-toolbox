function outputDir = run_study4(outputName)
%RUN_STUDY4 Deterministic fixed-dictionary structural-change pilot only.
% From the repository root: run_study4
% Requires MATLAB and Optimization Toolbox. Every invocation uses a new
% results directory; no tuning, noisy repetitions, or confirmation runs.
root = fileparts(mfilename('fullpath'));
if nargin < 1, outputName = ['study4_pilot_',char(datetime('now','Format','yyyyMMdd_HHmmss'))]; end
assert(ischar(outputName) && ~isempty(regexp(outputName,'^[A-Za-z0-9_-]+$','once')), ...
    'study4:OutputName','Provide a simple new results-directory name.');
oldPath = path;
cleanup = onCleanup(@() path(oldPath));
restoredefaultpath;
addpath(root,fullfile(root,'src'),fullfile(root,'studies','study1'), ...
    fullfile(root,'studies','study2'),fullfile(root,'studies','study3'), ...
    fullfile(root,'studies','study4'));
outputDir = fullfile(root,'results',outputName);
assert(~isfolder(outputDir) && ~isfile(outputDir),'study4:ExistingOutput','Use a new results directory.');
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
study4_verify_results(outputDir,cfg);
summary = study4_summarize(outputDir,cfg);
save(fullfile(outputDir,'summary.mat'),'summary');
study4_figures(outputDir,cfg);
after = run_verification;
verification = struct('beforeNames',{ {before.Name} },'beforePassed',[before.Passed], ...
    'afterNames',{ {after.Name} },'afterPassed',[after.Passed], ...
    'savedDataChecksPassed',true);
save(fullfile(outputDir,'verification.mat'),'verification');
fprintf('Study 4 pilot package complete: %s\n',outputDir);
end
