function [output,manifest] = generate_results(study,options)
%GENERATE_RESULTS Run one complete fixed study, or explicitly select all studies.
% GENERATE_RESULTS('study2',OutputDirectory='study2_run') runs the full Study 2.
% Study 6 requires Sources with the five generated parent directories.
% 'all' and 'sensitivity' require ConfirmFull=true; neither is a small example.
% Internal validity is mandatory. No historical reference is loaded here.
arguments
    study (1,1) string
    options.OutputDirectory = ''
    options.Figures (1,1) logical = false
    options.Sources (1,1) struct = struct
    options.ConfirmFull (1,1) logical = false
end
assert(any(study==["study"+(1:6),"sensitivity","all"]), ...
    'study:Selection','Select study1 through study6, sensitivity, or all.');
assert(~any(study==["all","sensitivity"]) || options.ConfirmFull, ...
    'study:ExpensiveSelection','This complete campaign requires ConfirmFull=true.');
[context,root,resolution]=study_context; %#ok<ASGLU>
identity=verify_source_relationship;
if isempty(options.OutputDirectory)
    options.OutputDirectory=char(study+"_"+string(datetime('now','Format','yyyyMMdd_HHmmss_SSS')));
end
output=new_output_path(char(study),options.OutputDirectory);
study_separate_output(output,options.Sources);
manifest=struct('schema','GENERATED_STUDY_V1','study',char(study), ...
    'status','RUNNING','sourceIdentity',identity.sourceIdentity, ...
    'sourceReview',identity.sourceReview,'referenceComparison','NOT_REQUESTED', ...
    'policySHA256',identity.policySHA256,'MATLAB',version,'computer',computer);
try
    stages=study_dispatch(study,output,options);
    if study=='all'
        manifest.stages=stages;
        manifest.internalValidity=struct('passed',all([stages.internalValidityPassed]), ...
            'scope','Individual complete-study validity; no reference comparison');
    elseif study=='sensitivity'
        manifest.internalValidity=stages.internalValidity;
    else
        manifest.internalValidity=check_study_results(study,output, ...
            ParentSources=options.Sources,OutputDirectory=[output '_checks']);
    end
    assert(manifest.internalValidity.passed,'study:Invalid','Generated study failed validity.');
    mkdir(fullfile(output,'review'));
    writetable(resolution,fullfile(output,'review','function_resolution.csv'));
    manifest.files=reshape(study_output_identity(output),[],1);
    manifest.status='COMPLETED';
    study_json(fullfile(output,'generation_manifest.json'),manifest);
catch exception
    if isfolder(output)
        manifest.status='FAILED';manifest.error=struct('identifier',exception.identifier,'message',exception.message);
        study_json(fullfile(output,'generation_failure.json'),manifest);
    end
    rethrow(exception)
end
fprintf('%s complete; internal validity PASS; reference comparison NOT REQUESTED.\n',study);
end
