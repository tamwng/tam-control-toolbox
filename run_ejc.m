function [output,sources] = run_ejc(mode,options)
%RUN_EJC Student entry point for the frozen EJC implementation.
%   run_ejc('quick')     bounded existing checks and one fixed clean example
%   run_ejc('study1')    fresh complete study (similarly study2..study5, p06)
%   run_ejc('full')      all Studies 1--6 and P06, then archive comparisons
%   run_ejc('archive')   regenerate summaries/figures from historical records
%   run_ejc('study6',Sources=s) binds to s.study1..s.study5 fresh output paths.
% OutputDirectory optionally selects a NEW directory. Default locations are
% collision-safe under results/p07_*. No existing output is overwritten.
% Full execution is sequential and requires a clean committed candidate. It
% has no automatic retry/resume. P06 alone previously took 3865.945 seconds;
% no measured full-paper runtime is available before the P07 verification.
arguments
    mode (1,:) char = 'quick'
    options.OutputDirectory = ''
    options.Sources (1,1) struct = struct
end
valid = {'quick','archive','full','study1','study2','study3','study4','study5','study6','p06'};
assert(ismember(mode,valid),'ejc:Mode','Unknown mode. See help run_ejc.');
root = fileparts(mfilename('fullpath')); oldPath = path;
restore = onCleanup(@() path(oldPath));
addpath(root,fullfile(root,'src'),fullfile(root,'studies','p06'),fullfile(root,'studies','p07'));
for s = 1:6, addpath(fullfile(root,'studies',sprintf('study%d',s))); end
reference = ejc_reference_sources; revision = ejc_source_revision;
isFresh = ~ismember(mode,{'quick','archive'});
if isFresh
    assert(revision.clean,'ejc:DirtySource','Commit the candidate and obtain a clean source tree before fresh reproduction.');
end
if strcmp(mode,'study6'), ejc_validate_sources(options.Sources); end
assert(exist('quadprog','file')==2 && license('test','Optimization_Toolbox'), ...
    'ejc:MissingSolver','Licensed Optimization Toolbox is required.');
output = ejc_output_path(mode,options.OutputDirectory);
% Historic whole tree is 1.36 GB. Allow three such trees for new data/logs;
% this is a conservative storage allowance, not a predicted output size.
if strcmp(mode,'full')
    diskPath = fileparts(output);
    while ~isfolder(diskPath), diskPath = fileparts(diskPath); end
    disk = java.io.File(diskPath);
    assert(disk.getUsableSpace() > 3*1357579926,'ejc:Storage','Full reproduction needs at least 4.08 GB free working space.');
end
fprintf('EJC %s: %s\nSource: %s\n',mode,output,revision.sourceSHA);
if strcmp(mode,'full')
    fprintf('Sequential complete studies, including 1558 P06 cases. P06 historical time: 64 min 26 s; full time not yet measured.\n');
end
mkdir(output); diary(fullfile(output,'matlab_diary.txt'));
finish = onCleanup(@() diary('off')); started = tic;
manifest = revision; manifest.mode = mode; manifest.status = 'RUNNING';
manifest.computationMode = 'fresh';
if strcmp(mode,'archive'), manifest.computationMode = 'archive regeneration'; end
if strcmp(mode,'quick'), manifest.computationMode = 'bounded verification and one fresh representative'; end
manifest.startedUTC = char(datetime('now','TimeZone','UTC'));
manifest.output = output; manifest.references = reference;
manifest.environment = struct('MATLAB',version,'computer',computer,'toolboxes',ver, ...
    'OS',char(java.lang.System.getProperty('os.name')), ...
    'OSVersion',char(java.lang.System.getProperty('os.version')), ...
    'CPU',getenv('PROCESSOR_IDENTIFIER'),'architecture',computer('arch'));
solver = optimoptions('quadprog','Algorithm','interior-point-convex','Display','off', ...
    'ConstraintTolerance',1e-8,'OptimalityTolerance',1e-8);
manifest.solverOptions = struct;
for name = string(properties(solver)).', manifest.solverOptions.(name) = solver.(name); end
manifest.normalizedKKTRejectionThreshold = 1e-7;
manifest.comparisonRule = 'Exact scientific values and discrete definitions; wall-clock and explicit provenance excluded. Existing numerical identity/KKT thresholds unchanged.';
manifest.legacySchemaRule = ['Only study1 data/pilot_{A,K,P2,R,S,W}_{000,001}.mat may lack historical ' ...
    'identityChecksEvaluated and firstStepCheckEvaluated fields. Both fresh flags are required and validated ' ...
    'against isfinite of their corresponding residual maxima; every other comparison remains exact.'];
manifest.coverage = struct('study1',258,'study2',22,'study3',218,'study4',12, ...
    'study5',5,'study6DiagnosticBatches',329,'study6ControlRuns',0,'p06',1558);
write_json(fullfile(output,'run_manifest.json'),manifest);
sources = struct;
try
    if isFresh, write_expected_inventory(output,mode,reference); end
    if ~strcmp(mode,'quick')
        manifest.integrityBefore = ejc_archive_integrity(fullfile(output,'integrity_before'));
    end
    switch mode
        case 'quick'
            quick_example(output,reference);
        case 'archive'
            archive_reports(output,reference);
        otherwise
            stages = {mode};
            if strcmp(mode,'full'), stages = {'study1','study2','study3','study4','study5','study6','p06'}; end
            for k = 1:numel(stages)
                study = stages{k}; stageTimer = tic;
                target = fullfile(output,study);
                if strcmp(study,'p06')
                    run_p06_tests(fullfile(output,'p06_tests'));
                    run_p06(target,'execute','P06_PRODUCTION_AUTHORIZED');
                elseif strcmp(study,'study6')
                    bound = sources;
                    if ~strcmp(mode,'full'), bound = options.Sources; end
                    identities = ejc_validate_sources(bound);
                    run_study6(target,Figures=false,Sources=bound);
                    write_json(fullfile(target,'source_relationships.json'),identities);
                else
                    runner = str2func(['run_' study]);
                    runner(target,Figures=false,ReferenceDirectory=reference.(study));
                end
                sources.(study) = target;
                one = struct; one.(study) = target;
                comparison = ejc_compare_results(one,reference,fullfile(output,['comparison_' study]));
                assert(comparison.passed,'ejc:ReproductionMismatch','Study comparison failed. Review recorded differences.');
                current = ejc_source_revision;
                assert(current.clean && strcmp(current.sourceSHA,revision.sourceSHA),'ejc:SourceChanged','Candidate changed during execution.');
                identity = struct('sourceSHA',revision.sourceSHA,'study',study, ...
                    'computationMode','fresh','status','PASSED','output',target, ...
                    'elapsedSeconds',toc(stageTimer),'completedUTC',char(datetime('now','TimeZone','UTC')));
                write_json(fullfile(target,'execution_manifest.json'),identity);
                manifest.completedSources = sources;
                write_json(fullfile(output,'run_manifest.json'),manifest);
            end
            if strcmp(mode,'full')
                report = ejc_paper_report(sources,reference,fullfile(output,'paper_report'));
                assert(report.passed,'ejc:PaperReportMismatch','Paper diagnostics differ. Stop for review.');
                journal_figures(output,sources);
            end
    end
    if ~strcmp(mode,'quick')
        manifest.integrityAfter = ejc_archive_integrity(fullfile(output,'integrity_after'));
    end
    manifest.status = 'PASSED';
catch exception
    manifest.status = 'FAILED_OR_BLOCKED'; manifest.identifier = exception.identifier;
    manifest.message = exception.message;
    manifest.exception = getReport(exception,'extended','hyperlinks','off');
    manifest.elapsedSeconds = toc(started);
    manifest.completedUTC = char(datetime('now','TimeZone','UTC'));
    write_json(fullfile(output,'run_manifest.json'),manifest);
    rethrow(exception)
end
manifest.elapsedSeconds = toc(started); manifest.completedUTC = char(datetime('now','TimeZone','UTC'));
write_json(fullfile(output,'run_manifest.json'),manifest);
fprintf('EJC %s complete in %.3f s: %s\n',mode,manifest.elapsedSeconds,output);
end

function quick_example(output,reference)
results = run_tests('quick'); save(fullfile(output,'unit_checks.mat'),'results');
cfg = study1_settings;
saved = load(fullfile(reference.study1,'data','records_confirmation.mat'),'records');
initialization = study1_record(200,.5,cfg.confirmation.inputSeed,cfg);
evaluation = study1_record(600,.5,cfg.confirmation.evaluationSeed,cfg);
assert(isequaln(initialization,saved.records.initialization) && ...
    isequaln(evaluation,saved.records.evaluation),'ejc:RecordMismatch','Fixed example records differ.');
[estimator,fit] = study1_fit('S',initialization,cfg);
result = study1_trajectory('S',fit,estimator,zeros(1,cfg.K+1),cfg);
result.campaign = 'confirmation'; result.trial = 0;
result.forecasts = study1_forecasts(fit,evaluation,cfg);
original = load(fullfile(reference.study1,'data','confirmation_S_000.mat'),'result');
exact = isequaln(rmfield(result,'controlTime'),rmfield(original.result,'controlTime'));
save(fullfile(output,'representative_study1_S_000.mat'),'result','cfg','exact');
assert(exact,'ejc:ExampleMismatch','Representative scientific arrays differ.');
fprintf('Fixed Study 1 Shared trial 0: exact scientific agreement; wall-clock timing excluded.\n');
end

function archive_reports(output,reference)
for s = 1:5
    key = sprintf('study%d',s); target = fullfile(output,key);
    saved = load(fullfile(reference.(key),'settings.mat'),'cfg');
    summarize = str2func(sprintf('study%d_summarize',s));
    summary = summarize(reference.(key),saved.cfg,target); %#ok<NASGU>
    save(fullfile(target,'summary.mat'),'summary');
end
mkdir(fullfile(output,'study6'));
saved = load(fullfile(reference.study6,'summary.mat'),'summary');
mkdir(fullfile(output,'study6','tables'));
for name = string(fieldnames(saved.summary)).'
    writetable(saved.summary.(name),fullfile(output,'study6','tables',name+'.csv'));
end
study6_verify_results(reference.study6,fullfile(output,'study6'));
[plan,~] = p06_plan;
% The CSV supplies only the recorded row order. MAT items retain logical
% flags and full-precision scores used by the original paired bootstrap.
listing = readtable(fullfile(reference.p06,'tables','runs.csv'),'TextType','string');
items = cell(height(listing),1);
for j = 1:height(listing)
    saved = load(fullfile(reference.p06,'runs',listing.runId(j)+'.mat'),'item');
    assert(strcmp(saved.item.runId,listing.runId(j)),'ejc:P06RecordIdentity','P06 run identity differs.');
    items{j} = saved.item;
end
runs = struct2table(vertcat(items{:}));
[summaries,contrasts,analysis] = p06_summarize(runs,plan); %#ok<ASGLU>
mkdir(fullfile(output,'p06','tables'));
writetable(summaries,fullfile(output,'p06','tables','noisy_summaries.csv'));
writetable(contrasts,fullfile(output,'p06','tables','paired_contrasts.csv'));
save(fullfile(output,'p06','analysis_randomness.mat'),'analysis');
historical = load(fullfile(reference.p06,'analysis_randomness.mat'),'analysis');
assert(isequaln(analysis,historical.analysis),'ejc:P06AnalysisMismatch','P06 bootstrap records differ.');
for name = ["noisy_summaries.csv","paired_contrasts.csv"]
    current = readtable(fullfile(output,'p06','tables',name),'TextType','string');
    historical = readtable(fullfile(reference.p06,'tables',name),'TextType','string');
    assert(isequaln(current,historical),'ejc:P06SummaryMismatch','P06 archived summary differs: %s',name);
end
report = ejc_paper_report(reference,reference,fullfile(output,'paper_report'));
assert(report.passed,'ejc:PaperReportMismatch','Historical report consistency failed.');
journal_figures(output,reference);
end

function journal_figures(output,sources)
% Exactly six paper figures, never thousands of per-trial inspection plots.
for s = 1:6
    runner = str2func(sprintf('plot_study%d_journal',s));
    runner(sources.(sprintf('study%d',s)),fullfile(output,'figures',sprintf('study%d',s)));
end
end

function write_json(file,value)
fid = fopen(file,'w'); assert(fid>=0,'ejc:Output','Cannot write %s.',file);
cleanup = onCleanup(@() fclose(fid)); fprintf(fid,'%s\n',jsonencode(value,PrettyPrint=true));
end

function write_expected_inventory(output,mode,reference)
% Freeze required result identities before the first expensive computation.
% This is a file/case inventory, not a different simulation execution order.
groups = {mode};
if strcmp(mode,'full'), groups = {'study1','study2','study3','study4','study5','study6','p06'}; end
rows = cell(0,4);
for k = 1:numel(groups)
    group = groups{k}; source = reference.(group);
    entries = [dir(fullfile(source,'**','*.mat'));dir(fullfile(source,'**','*.csv'))];
    for j = 1:numel(entries)
        file = fullfile(entries(j).folder,entries(j).name);
        relative = strrep(file(numel(source)+2:end),filesep,'/');
        if ismember(relative,{'verification.mat','execution_provenance.mat'}) || ...
                startsWith(relative,{'review/','source_snapshot/'}), continue; end
        rows(end+1,:) = {group,relative,file,fullfile(output,group,relative)}; %#ok<AGROW>
    end
end
inventory = cell2table(rows,'VariableNames',{'study','relativePath','reference','plannedOutput'});
inventory = sortrows(inventory,{'study','relativePath'});
if strcmp(mode,'full')
    assert(height(inventory)==2877,'ejc:ExpectedCoverage','Required scientific inventory differs from the approved coverage.');
end
writetable(inventory,fullfile(output,'expected_scientific_files.csv'));
end
