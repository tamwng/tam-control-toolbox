function [output,summary] = run_example(outputName)
%RUN_EXAMPLE Generate the fixed Study 1 Shared-model noise-free example.
% [OUTPUT,SUMMARY] = RUN_EXAMPLE creates a new results/example_* directory.
% RUN_EXAMPLE('my_example') uses a new results/my_example directory instead.
% MATLAB and licensed Optimization Toolbox are required. No historical data
% or certification directory is read. The fixed seeds, 200-transition fit,
% separate 600-transition evaluation and 120 s control record are unchanged.
% Internal validity and existing per-run metrics are saved with result/cfg.
% Failures retain the generated record and a failure summary, then raise.
% View without rerunning: inspect_results(1,'confirmation_S_000',OUTPUT).

if nargin < 1, outputName = ''; end
% Resolve explicit relative paths before the source-local path context.
if ~isempty(regexp(char(outputName),'[/\\]','once'))
    outputName = char(java.io.File(char(outputName)).getCanonicalPath());
end
[context,root,resolution] = public_context; %#ok<ASGLU>
assert(exist('quadprog','file')==2 && license('test','Optimization_Toolbox'), ...
    'ejc:MissingSolver','Optimization Toolbox with a licensed quadprog is required.');
if isempty(outputName)
    outputName = ['example_' char(datetime('now','Format','yyyyMMdd_HHmmss_SSS'))];
end
output = ejc_output_path('example',outputName);
mkdir(output); mkdir(fullfile(output,'data'));
randomState = rng; restoreRandom = onCleanup(@() rng(randomState));
summary = struct('schema','FIXED_EXAMPLE_V1','status','RUNNING', ...
    'scope','Study 1 Shared confirmation trial 0','referenceComparison','NOT_RUN');
timer = tic;
try
    cfg = study1_settings;
    records.initialization = study1_record(200,.5,cfg.confirmation.inputSeed,cfg);
    records.evaluation = study1_record(600,.5,cfg.confirmation.evaluationSeed,cfg);

    [estimator,fit] = study1_fit('S',records.initialization,cfg);
    result = study1_trajectory('S',fit,estimator,zeros(1,cfg.K+1),cfg);
    result.campaign = 'confirmation'; result.trial = 0;
    result.forecasts = study1_forecasts(fit,records.evaluation,cfg);
    resultFile = fullfile(output,'data','confirmation_S_000.mat');
    save(resultFile,'result','cfg','records');

    summary.internalChecks = study1_check_case(result,records,cfg);
    helpers = study1_summarize('p06_helpers');
    base = struct('campaign',"confirmation",'model',"S",'trial',0,'noise',false);
    metrics = struct2table(helpers.scoreRun(result,base,cfg));
    writetable(metrics,fullfile(output,'metrics.csv'));
    summary.status = 'PASS'; summary.metrics = table2struct(metrics);
    summary.resultFile = resultFile; summary.resultSHA256 = ejc_file_sha256(resultFile);
    summary.elapsedSeconds = toc(timer);
    summary.environment = struct('MATLAB',version,'architecture',computer, ...
        'optimizationToolbox',ver('optim'));
    summary.source = public_source_identity(root);
    writetable(resolution,fullfile(output,'function_resolution.csv'));
    public_json(fullfile(output,'summary.json'),summary);
catch exception
    summary.status = 'FAILED'; summary.elapsedSeconds = toc(timer);
    summary.error = struct('identifier',exception.identifier,'message',exception.message);
    public_json(fullfile(output,'failure.json'),summary);
    rethrow(exception);
end
fprintf('Example complete: %d control steps; internal checks PASS.\n',result.nSteps);
fprintf('Reference comparison: not run. Output: %s\n',output);
disp(metrics(:,{'window','trackingRMS','inputRMS','peakTrackingError'}));
end
