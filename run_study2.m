function outputDir = run_study2(outputName)
%RUN_STUDY2 Complete deterministic Section 6.2.2 pilot, not confirmation.
% Requires MATLAB and Optimization Toolbox; tested R2026a Update 5.
% From a clean session at the repository root, run RUN_STUDY2. This runs the
% complete test suite and creates a new local results package without tuning.
% The 18 amplitude runs and Eq.67's four-case constraint audit stay separate.
% Independent held-out input ranges never select a controller or its settings.
root = fileparts(mfilename('fullpath'));
if nargin < 1
    outputName = ['study2_pilot_' char(datetime('now','Format','yyyyMMdd_HHmmss'))];
end
assert(ischar(outputName) && ~isempty(regexp(outputName,'^[A-Za-z0-9_-]+$','once')), ...
    'study2:OutputName','Provide a simple new results-directory name.');
previousPath = path;
cleanup = onCleanup(@() path(previousPath));
restoredefaultpath;
addpath(root,fullfile(root,'src'),fullfile(root,'studies','study2'));
run_verification;
cfg = study2_settings;
outputDir = fullfile(root,'results',outputName);
assert(~isfolder(outputDir),'study2:ExistingOutput','Use a new results directory.');
mkdir(outputDir);
for name = {'fits','evaluation','runs'}
    mkdir(fullfile(outputDir,name{1}));
end
environment.matlab = version;
product = ver('optim'); environment.optimizationToolbox = product.Version;
environment.execution = 'Sequential deterministic pilot; no confirmation or tuning.';
save(fullfile(outputDir,'settings.mat'),'cfg','environment');
initialization = study2_record(200,1.10,cfg.inputSeed,cfg);
for j = 1:numel(cfg.evaluationRanges)
    evaluation(j) = study2_record(600,cfg.evaluationRanges(j),cfg.evaluationSeeds(j),cfg); %#ok<AGROW>
end
save(fullfile(outputDir,'records.mat'),'initialization','evaluation');
for m = 1:numel(cfg.modelIds)
    id = cfg.modelIds{m};
    [~,fit] = study2_fit(id,initialization,cfg);
    save(fullfile(outputDir,'fits',[id '.mat']),'fit','-v7');
    clear evaluations
    for j = 1:numel(evaluation)
        evaluations(j) = study2_forecasts(fit,evaluation(j),cfg); %#ok<AGROW>
    end
    save(fullfile(outputDir,'evaluation',[id '.mat']),'evaluations','-v7');
    for a = 1:numel(cfg.amplitudes)
        result = study2_trajectory(id,fit,cfg.amplitudes(a),cfg);
        save(fullfile(outputDir,'runs',sprintf('amplitude_%02d_%s.mat',a,id)),'result','-v7');
        print_run(result);
    end
    if ismember(id,cfg.auditIds)
        audit = cfg;
        audit.kind = 'constraintAudit'; audit.duration = 10; audit.K = 100;
        audit.initialState = 1.4; audit.constantReference = 0.6;
        audit.control.hy = [0.85;0.85];
        result = study2_trajectory(id,fit,NaN,audit);
        save(fullfile(outputDir,'runs',['constraint_' id '.mat']),'result','-v7');
        print_run(result);
    end
end
study2_verify_results(outputDir,cfg);
summary = study2_summarize(outputDir,cfg);
study2_figures(outputDir,cfg,summary);
fprintf('Study 2 pilot package complete: %s\n',outputDir);
end

function print_run(r)
fprintf('%s %-3s amplitude=%g: %d/%d transitions, %d ID rejections, %d control fallbacks.\n', ...
    r.kind,r.id,r.amplitude,r.nSteps,numel(r.time)-1, ...
    nnz(r.idAttempted & ~r.idAccepted),nnz(~r.controlAccepted(1:r.nSteps)));
end
