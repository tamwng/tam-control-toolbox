function report = check_study_results(study,source,options)
%CHECK_STUDY_RESULTS Recheck saved own-record validity without simulation.
% This command neither compares with a historical dataset nor edits the run.
arguments
    study (1,1) string
    source
    options.ParentSources (1,1) struct = struct
    options.OutputDirectory = ''
end
[context,root]=study_context; %#ok<ASGLU>
identity=verify_source_relationship;
if study=="sensitivity",study="p06";end
assert(any(study==["study"+(1:6),"p06"]),'study:Selection','Unsupported saved study.');
source=char(java.io.File(char(source)).getCanonicalPath());
assert(isfolder(source),'study:MissingSource','Saved source is unavailable.');
before=study_output_identity(source);
output=new_output_path('validity',options.OutputDirectory);
study_separate_output(output,struct('source',source));
study_separate_output(output,options.ParentSources);
mkdir(output);
if study=='p06'
    z=load(fullfile(source,'execution_provenance.mat'),'plan','manifest');
    files=dir(fullfile(source,'runs','*.mat'));
    assert(numel(files)==height(z.manifest),'study:Incomplete','Sensitivity case inventory differs.');
    for j=1:numel(files)
        file=fullfile(files(j).folder,files(j).name);saved=load(file);
        assert(isempty(fieldnames(saved.failure)) && saved.item.completed && saved.item.predictionCompleted, ...
            'study:SensitivityValidity','Sensitivity calculation incomplete.');
        verification_own_source_copies(saved,'p06',file,struct('p06',source));
        score=sensitivity_score(saved.result,case_config(z.plan.cfg,saved.item));
        assert(isequaln(score,saved.scores),'study:ScoreChanged','Saved scores differ from their own result.');
    end
elseif any(study==["study3","study4"])
    z=load(fullfile(source,'settings.mat'),'cfg');
    report34=verification_study34_verify(study,source,z.cfg,fullfile(output,'source_checks')); %#ok<NASGU>
elseif study=='study6'
    validate_generated_sources(options.ParentSources);
    study6_verify_results(source,fullfile(output,'study6_validity'));
    verification_study6_source_checks(source,options.ParentSources,fullfile(output,'parent_copies'));
else
    z=load(fullfile(source,'settings.mat'),'cfg');
    verifier=str2func(study+"_verify_results");verifier(source,z.cfg);
end
assert(isequaln(before,study_output_identity(source)),'study:InputChanged','Saved scientific input changed.');
report=struct('passed',true,'study',char(study),'scope','Saved own-record validity', ...
    'referenceComparison','NOT_REQUESTED','inputsUnchanged',true, ...
    'sourceIdentity',identity.sourceIdentity,'evidenceDirectory',output);
study_json(fullfile(output,'validity.json'),report);
end
function cfg=case_config(cfg,item)
cfg.control.R=item.R;
n=item.fittingTransitions;if ~item.identificationApplicable,n=200;end
cfg.fitSteps=n;
end
