function outputDir = run_study3(outputName)
%RUN_STUDY3 Parameter-variation pilot and 40 paired mixed-noise gain steps.
% Requires MATLAB and Optimization Toolbox; tested R2026a Update 5.
% Run from the repository root in a clean session. Results always go to a new
% local directory. Settings, windows and seeds are fixed before execution.
% No confirmation campaign, tuning, structural change, or later study is run.
root = fileparts(mfilename('fullpath'));
if nargin < 1, outputName = ['study3_pilot_',char(datetime('now','Format','yyyyMMdd_HHmmss'))]; end
assert(ischar(outputName) && ~isempty(regexp(outputName,'^[A-Za-z0-9_-]+$','once')), ...
    'study3:OutputName','Provide a simple new results-directory name.');
oldPath = path;
cleanup = onCleanup(@() path(oldPath));
restoredefaultpath;
addpath(root,fullfile(root,'src'),fullfile(root,'studies','study1'), ...
    fullfile(root,'studies','study2'),fullfile(root,'studies','study3'));
run_verification;
cfg = study3_settings;
outputDir = fullfile(root,'results',outputName);
study3_prepare(outputDir,cfg);
study3_run_batch(outputDir,0:cfg.noiseTrials);
study3_verify_results(outputDir,cfg);
summary = study3_summarize(outputDir,cfg);
study3_figures(outputDir,cfg,summary);
run_verification;
fprintf('Study 3 pilot package complete: %s\n',outputDir);
end
