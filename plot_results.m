function [output,report] = plot_results(study,source,options)
%PLOT_RESULTS Export saved complete-study figures without running a controller.
% Study 2 requires ReferenceInputs.study2 and ReferenceInputs.rankFile. Other
% exporters read the selected saved package. Use inspect_results for a trace.
arguments
    study (1,1) string
    source
    options.OutputDirectory = ''
    options.ReferenceInputs (1,1) struct = struct
end
[context,root]=study_context; %#ok<ASGLU>
verify_source_relationship;
assert(any(study=="study"+(1:6)),'study:Selection','Select study1 through study6.');
source=char(java.io.File(char(source)).getCanonicalPath());
assert(isfolder(source),'study:MissingSource','Saved study unavailable.');
before=study_output_identity(source);random=rng;restore=onCleanup(@()rng(random));
output=ejc_output_path('study_figures',options.OutputDirectory);
study_separate_output(output,struct('source',source));
study_separate_output(output,options.ReferenceInputs);
if study=='study2'
    refs=options.ReferenceInputs;
    assert(isfield(refs,'rankFile') && isfile(refs.rankFile),'study:ReferenceUnavailable', ...
        'Study 2 publication export requires the canonical numerical-rank CSV.');
    resolve_reference_inputs(refs,"study2");
    refs.study2=char(java.io.File(char(refs.study2)).getCanonicalPath());
    refs.rankFile=char(java.io.File(char(refs.rankFile)).getCanonicalPath());
    study_separate_output([output '_binding'],struct('source',source));
    study_separate_output([output '_binding'],refs);
    binding=ejc_study2_gram_binding(source,refs.study2,refs.rankFile,[output '_binding'],refs);
    [output,verification]=plot_study2_journal(source,output,refs.rankFile,binding.compare); %#ok<NASGU>
    report=binding.finish();
else
    exporter=str2func('plot_'+study+'_journal');output=exporter(source,output);
    report=struct('passed',true,'scope','Saved-data figure export');
end
assert(isequaln(before,study_output_identity(source)),'study:InputChanged','Saved plot inputs changed.');
report.inputsUnchanged=true;report.source=source;
study_json(fullfile(output,'plot_provenance.json'),report);
end
