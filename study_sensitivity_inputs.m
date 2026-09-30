function inputs = study_sensitivity_inputs(source,referenceStudy1)
%STUDY_SENSITIVITY_INPUTS Explicit saved record/design and baseline references.
% Reference gate checks are evaluated from saved cases by the original reducer.
saved=load(fullfile(source,'execution_provenance.mat'),'plan');
assert(isfield(saved,'plan'),'study:SensitivityPlan','Saved sensitivity plan is required.');
cfg=study1_settings;
if isfile(fullfile(source,'sensitivity_manifest.json'))
    recordFile=fullfile(source,'review','generation_inputs','records_confirmation.mat');
    settingsFile=fullfile(source,'review','generation_inputs','settings.mat');
    archive='';
else
    recordFile=fullfile(referenceStudy1,'data','records_confirmation.mat');
    settingsFile=fullfile(referenceStudy1,'settings.mat');
    archive=char(referenceStudy1);
end
assert(isfile(recordFile) && isfile(settingsFile),'study:ReferenceUnavailable','Sensitivity record/settings missing.');
z=load(settingsFile,'cfg');assert(isequaln(z.cfg,cfg),'study:SensitivitySettings','Fixed settings differ.');
z=load(recordFile,'records');sensitivity_check_records(cfg,z.records);
[plan,manifest]=sensitivity_design(cfg,recordFile,sensitivity_hash(recordFile),archive);
plan.settingsFile=settingsFile;
assert(height(manifest)==1558,'study:SensitivityInventory','Complete sensitivity design required.');
inputs=struct('sensitivityPlan',plan,'sensitivityManifest',manifest, ...
    'sensitivityReference',char(referenceStudy1));
end
