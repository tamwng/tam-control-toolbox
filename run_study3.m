function outputDir = run_study3(outputName,options)
%RUN_STUDY3 Parameter-variation pilot and 40 paired mixed-noise gain steps.
% Requires MATLAB and Optimization Toolbox; tested R2026a Update 5.
% Run from the repository root in a clean session. Results always go to a new
% local directory. Settings, windows and seeds are fixed before execution.
% No confirmation campaign, tuning, structural change, or later study is run.
arguments
    outputName = ''
    options.Figures (1,1) logical = true
    options.ReferenceDirectory = ''
end
root = fileparts(mfilename('fullpath'));
outputDir = ejc_output_path('study3',outputName);
oldPath = path;
cleanup = onCleanup(@() path(oldPath));
restoredefaultpath;
addpath(root,fullfile(root,'src'),fullfile(root,'studies','study1'), ...
    fullfile(root,'studies','study2'),fullfile(root,'studies','study3'));
run_verification;
cfg = study3_settings;
study3_prepare(outputDir,cfg);
ejc_check_records(outputDir,options.ReferenceDirectory,3);
study3_run_batch(outputDir,0:cfg.noiseTrials);
study3_verify_results(outputDir,cfg);
summary = study3_summarize(outputDir,cfg);
if options.Figures, study3_figures(outputDir,cfg,summary); end
run_verification;
fprintf('Study 3 pilot package complete: %s\n',outputDir);
end
