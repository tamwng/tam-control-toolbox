function outputDir = run_study1(outputName,options)
%RUN_STUDY1 Reproduce Section 6.2.1 and its applicable Appendix A diagnostics.
% Requires MATLAB and Optimization Toolbox (tested R2026a Update 5).
% Runs the verified core tests, a separate pilot, then 40 paired confirmation
% trials plus noiseless comparisons, using the fixed manuscript pilot values.
% No tuning occurs. Each invocation writes a new repository-local package.
% Complete execution may take several minutes. Nothing is overwritten.
arguments
    outputName = ''
    options.Figures (1,1) logical = true
    options.ReferenceDirectory = ''
end
root = fileparts(mfilename('fullpath'));
outputDir = ejc_output_path('study1',outputName);
previousPath = path;
restorePath = onCleanup(@() path(previousPath));
restoredefaultpath;
addpath(root,fullfile(root,'src'),fullfile(root,'studies','study1'));
run_verification;
cfg = study1_settings;
study1_prepare(outputDir,cfg);
ejc_check_records(outputDir,options.ReferenceDirectory,1);
study1_run_batch(outputDir,'pilot',0:cfg.pilot.noiseTrials);
study1_run_batch(outputDir,'confirmation',0:cfg.confirmation.noiseTrials);
study1_measured_audits(outputDir,cfg);
study1_verify_results(outputDir,cfg);
summary = study1_summarize(outputDir,cfg);
if options.Figures, study1_figures(outputDir,cfg,summary); end
fprintf('Study 1 package complete: %s\n',outputDir);
end
