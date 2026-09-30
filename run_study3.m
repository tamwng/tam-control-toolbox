function outputDir = run_study3(outputName,options)
%RUN_STUDY3 Parameter-variation pilot and 40 paired mixed-noise gain steps.
% Requires MATLAB and Optimization Toolbox; tested R2026a Update 5.
% Run from the repository root in a clean session. Results always go to a new
% local directory. Settings, windows and seeds are fixed before execution.
% No confirmation campaign, tuning, structural change, or later study is run.
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
outputDir = new_output_path('study3',outputName);
if isempty(options.VerificationAdapter)
    options.VerificationAdapter = study_validity_callback('study3', ...
        [outputDir '_validity']);
end
oldPath = path;
cleanup = onCleanup(@() path(oldPath));
restoredefaultpath;
addpath(root,fullfile(root,'src'),fullfile(root,'studies','study1'), ...
    fullfile(root,'studies','study2'),fullfile(root,'studies','study3'));
study_prerequisites('study3');

cfg = study3_settings;
study3_prepare(outputDir,cfg);
check_input_records(outputDir,options.ReferenceDirectory,3);

study3_run_batch(outputDir,0:cfg.noiseTrials);
if isempty(options.VerificationAdapter)
    study3_verify_results(outputDir,cfg);
else
    assert(isa(options.VerificationAdapter,'function_handle'),'ejc:VerificationAdapter','Expected a verification function.');
    options.VerificationAdapter(outputDir,cfg);
end

summary = study3_summarize(outputDir,cfg);
if options.Figures, study3_figures(outputDir,cfg,summary); end
study_prerequisites('study3');
fprintf('Study 3 pilot package complete: %s\n',outputDir);
end
