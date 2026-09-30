function [output,summary] = run_sensitivity(mode,options)
%RUN_SENSITIVITY Declare the fixed design, run one named case, or run all cases.
% 'plan' performs no fitting or simulation. 'case' requires the exact runId.
% 'all' requires ConfirmFull=true. Historical-reference checks run separately.
arguments
    mode (1,1) string
    options.Case (1,1) string = ""
    options.OutputDirectory = ''
    options.ConfirmFull (1,1) logical = false
end
assert(any(mode==["plan","case","all"]),'study:SensitivityMode','Select plan, case or all.');
assert(mode~='all' || options.ConfirmFull,'study:ExpensiveSelection','ConfirmFull=true is required.');
[context,root,resolution]=study_context; %#ok<ASGLU>
identity=verify_source_relationship;
cfg=study1_settings;
[plan,manifest]=sensitivity_design(cfg,'','','');
if mode=='case'
    index=find(manifest.runId==options.Case);
    assert(isscalar(index),'study:SensitivityCase','Supply one exact fixed runId.');
elseif mode=='all'
    index=[find(manifest.baselineGate);find(~manifest.baselineGate)];
else
    index=[];
end
if isempty(options.OutputDirectory)
    options.OutputDirectory=char("sensitivity_"+mode+"_"+string(datetime('now','Format','yyyyMMdd_HHmmss_SSS')));
end
output=new_output_path('sensitivity',options.OutputDirectory);mkdir(output);
summary=struct('schema','GENERATED_SENSITIVITY_V1','mode',char(mode),'status','PLANNED', ...
    'sourceIdentity',identity.sourceIdentity,'referenceComparison','NOT_REQUESTED', ...
    'internalValidity',struct('passed',false,'scope','No execution requested'));
if mode=='plan'
    writetable(manifest,fullfile(output,'P06_RUN_MANIFEST.csv'));
    study_json(fullfile(output,'sensitivity_manifest.json'),summary);return
end
mkdir(fullfile(output,'runs'));mkdir(fullfile(output,'tables'));
inputs=fullfile(output,'review','generation_inputs');mkdir(inputs);
records=study1_records(cfg,'confirmation');
sensitivity_check_records(cfg,records);
recordFile=fullfile(inputs,'records_confirmation.mat');save(recordFile,'records');
environment=struct('matlab',version,'optimizationToolbox',ver('optim'));
settingsFile=fullfile(inputs,'settings.mat');save(settingsFile,'cfg','environment');
[plan,manifest]=sensitivity_design(cfg,recordFile,sensitivity_hash(recordFile),'');
plan.settingsFile=settingsFile;plan.settingsSHA256=sensitivity_hash(settingsFile);
manifest=manifest(index,:);
save(fullfile(output,'execution_provenance.mat'),'plan','manifest');
writetable(manifest,fullfile(output,'P06_RUN_MANIFEST.csv'));
rows=struct([]);
for j=1:height(manifest)
    item=sensitivity_generate_case(output,manifest(j,:),plan,records);
    rows=[rows;item]; %#ok<AGROW>
    assert(item.completed && item.predictionCompleted,'study:SensitivityFailed', ...
        'Sensitivity case %s failed; saved failure evidence retained.',item.runId);
end
runs=struct2table(rows);
writetable(runs,fullfile(output,'tables','runs.csv'));
writetable(runs(~runs.noisy,:),fullfile(output,'tables','deterministic.csv'));
writetable(plan.knownAliases,fullfile(output,'tables','known_reference_aliases.csv'));
if mode=='all'
    [summaries,contrasts,analysis]=sensitivity_summarize(runs,plan);
    writetable(summaries,fullfile(output,'tables','noisy_summaries.csv'));
    writetable(contrasts,fullfile(output,'tables','paired_contrasts.csv'));
    save(fullfile(output,'analysis_randomness.mat'),'analysis','-v7');
end
summary.internalValidity=check_study_results('p06',output,OutputDirectory=[output '_checks']);
writetable(resolution,fullfile(output,'review','function_resolution.csv'));
summary.status='COMPLETED';summary.files=reshape(study_output_identity(output),[],1);
study_json(fullfile(output,'sensitivity_manifest.json'),summary);
end
