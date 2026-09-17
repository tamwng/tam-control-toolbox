function outputDir = run_study1(outputName)
%RUN_STUDY1 Reproduce Section 6.2.1 and its applicable Appendix A diagnostics.
% Requires MATLAB and Optimization Toolbox (tested R2026a Update 5).
% Runs the verified core tests, a separate pilot, then 40 paired confirmation
% trials plus noiseless comparisons, using the fixed manuscript pilot values.
% No tuning occurs. Each invocation writes a new repository-local package.
% Complete execution may take several minutes. Nothing is overwritten.
root = fileparts(mfilename('fullpath'));
if nargin < 1
    outputName = ['study1_' char(datetime('now','Format','yyyyMMdd_HHmmss'))];
end
assert(ischar(outputName) && ~isempty(regexp(outputName,'^[A-Za-z0-9_-]+$','once')), ...
    'study1:OutputName','Provide a simple new output directory name.');
previousPath = path;
restorePath = onCleanup(@() path(previousPath));
restoredefaultpath;
addpath(root,fullfile(root,'src'),fullfile(root,'studies','study1'));
run_verification;
cfg = study1_settings;
outputDir = fullfile(root,'results',outputName);
study1_prepare(outputDir,cfg);
study1_run_batch(outputDir,'pilot',0:cfg.pilot.noiseTrials);
study1_run_batch(outputDir,'confirmation',0:cfg.confirmation.noiseTrials);
study1_measured_audits(outputDir,cfg);
study1_verify_results(outputDir,cfg);
summary = study1_summarize(outputDir,cfg);
study1_figures(outputDir,cfg,summary);
fprintf('Study 1 package complete: %s\n',outputDir);
end
