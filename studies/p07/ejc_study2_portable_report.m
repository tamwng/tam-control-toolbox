function report=ejc_study2_portable_report(current,reference,output)
%EJC_STUDY2_PORTABLE_REPORT Export source-bound rank diagnostics without running trajectories.
assert(~isfolder(output) && ~isfile(output),'ejc:ExistingEvidence','New report evidence required.');
root=fileparts(fileparts(fileparts(mfilename('fullpath'))));
previous=path;restore=onCleanup(@()path(previous));
addpath(root,fullfile(root,'studies/study2'));
csv=fullfile(root,'results/study2_journal/gram_numerical_rank_check.csv');
before=ejc_input_snapshot(struct('study2',current),struct('study2',reference));
z=load(fullfile(current,'settings.mat'),'cfg');study2_verify_results(current,z.cfg);
mkdir(output);
expectedValues=study2_figure_data(current);expectedRanks=study2_gram_report(current);
binding=ejc_study2_gram_binding(current,reference,csv,fullfile(output,'gram_binding'));
[figureDirectory,verification]=plot_study2_journal(current,fullfile(output,'figure'),csv,binding.compare);
parents=binding.finish();
valueFile=fullfile(figureDirectory,'study2_main_values.csv');
tokens=ejc_csv_tokens(valueFile,string(expectedValues.Properties.VariableNames));
assert(size(tokens,1)==33 && height(expectedValues)==33 && ...
    isequal(sort(unique(expectedValues.panel)),["a";"b"]), ...
    'ejc:Study2FigureSource','Incomplete figure points/panels.');
for k=1:width(expectedValues)
    v=expectedValues.(expectedValues.Properties.VariableNames{k});
    if isnumeric(v)
        actual=cellfun(@ejc_csv_number,tokens(:,k));
        assert(isequaln(actual,v),'ejc:Study2FigureSource','17-digit figure values differ from their own exact source.');
    else
        assert(isequal(string(tokens(:,k)),string(v)),'ejc:Study2FigureSource','Figure metadata differs.');
    end
end
rankEncoding=ejc_csv_mat_link(fullfile(figureDirectory,'study2_conditioning_corrected.csv'),expectedRanks);
assert(rankEncoding.passed && height(expectedRanks)==18 && nnz(~expectedRanks.applicable)==3, ...
    'ejc:Study2FigureSource','Original rank report export changed.');
after=ejc_input_snapshot(struct('study2',current),struct('study2',reference));
assert(isequaln(before,after),'ejc:InputChanged','Saved report inputs changed.');
report=struct('passed',true,'mode',"SAVED_DATA_B2_REPORT_NOT_CERTIFICATION", ...
    'adaptiveRows',15,'totalRows',18,'knownModelNARows',3,'panels',2,'exactPlottedPoints',33, ...
    'originalValidityPassed',true,'sourceValuesExact',true,'inputsUnchanged',true, ...
    'rankEncoding',rankEncoding,'gram',parents,'figureDirectory',string(figureDirectory));
save(fullfile(output,'report.mat'),'report','expectedValues','expectedRanks','verification','before','after','-v7');
fid=fopen(fullfile(output,'report.json'),'w');c=onCleanup(@()fclose(fid));fprintf(fid,'%s\n',jsonencode(report,PrettyPrint=true));
end
