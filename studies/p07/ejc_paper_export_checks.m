function report=ejc_paper_export_checks(sources,references,output,paper)
%EJC_PAPER_EXPORT_CHECKS Bind all 13 paper CSV exports to their own sources.
% The seven selected result exports also retain their fixed scalar/claim
% comparisons as well. Underlying complete study comparisons remain mandatory.
root=fileparts(fileparts(fileparts(mfilename('fullpath'))));
previous=path;restorePath=onCleanup(@()path(previous));
addpath(root,fullfile(root,'src'),fullfile(root,'studies/study1'));
exports={ ...
    'study1','paired_contrasts.csv','paper_A17_study1_control.csv'; ...
    'study1','initialization_paired_contrasts.csv','paper_A17_study1_initialization.csv'; ...
    'study1','forecast_paired_contrasts.csv','paper_A17_study1_common_forecasts.csv'; ...
    'study1','measured_initialization_paired_contrasts.csv','paper_A17_study1_retrospective.csv'; ...
    'study3','paired_contrasts.csv','paper_A17_study3.csv'; ...
    'p06','noisy_summaries.csv','paper_A18_noisy_summaries.csv'; ...
    'p06','paired_contrasts.csv','paper_A18_paired_contrasts.csv'};
links=struct([]);ledger={};
% Re-execute the unchanged saved reducers for exact source-row inheritance.
claimBindingsA=ejc_csv_source_tables(struct('study1',sources.study1),fullfile(output,'claim_source_current'));
claimBindingsB=ejc_csv_source_tables(struct('study1',references.study1),fullfile(output,'claim_source_reference'));
claimCache=containers.Map('KeyType','char','ValueType','any');
for k=1:size(exports,1)
    study=string(exports{k,1});relative="tables/"+exports{k,2};name=string(exports{k,3});
    source=string(fullfile(sources.(study),relative));reference=string(fullfile(references.(study),relative));
    [sa,ia]=select(source,study,relative);[sb,ib]=select(reference,study,relative);
    file=string(fullfile(output,name));link=ejc_csv_mat_link(file,sa);
    links=[links;link_row(name,file,source,link)]; %#ok<AGROW>
    a=ejc_csv_read(file,"paper",name);b=sb;
    assert(isequal(a.Properties.VariableNames,b.Properties.VariableNames) && isequal(size(a),size(b)), ...
        'ejc:PaperExportSchema','Paper export schema/shape differs: %s.',name);
    c=struct('study',"paper",'file',name,'source',file,'reference',reference,'rootA',a,'rootB',b, ...
        'sources',sources,'references',references,'sourceSHA256',string(ejc_file_sha256(file)), ...
        'referenceSHA256',string(ejc_file_sha256(reference)),'isCSV',true,'rowIndex',NaN, ...
        'csvHeaders',string(sa.Properties.VariableNames));
    % These are selections of previously serialized support rows, not
    % invented unrounded historical aggregates. Full study/MAT source checks
    % remain a separate mandatory prerequisite for campaign acceptance.
    c.claimBindingsA=claimBindingsA;c.claimBindingsB=claimBindingsB;c.parentCache=claimCache;
    c.bindingA=struct('values',sa,'sourceKind',"EXACT_SERIALIZED_SOURCE_SELECTION");
    c.bindingB=struct('values',sb,'sourceKind',"EXACT_SERIALIZED_SOURCE_SELECTION");
    c.csvTokensA=ejc_csv_tokens(file,c.csvHeaders);
    tokens=ejc_csv_tokens(reference,c.csvHeaders);c.csvTokensB=tokens(ib,:);
    for field=c.csvHeaders
        for j=1:height(a)
            c.rowIndex=j;v=ejc_portable_leaf(a.(field)(j,:),b.(field)(j,:),"value."+field,a(j,:),b(j,:),c);
            v.file=name;v.field=field;v.row=j;v.currentSourceRow=ia(j);v.referenceSourceRow=ib(j);
            ledger{end+1,1}=v; %#ok<AGROW>
        end
    end
end
pairs={ ...
    'paper_A14_conditioning.csv',paper.conditioning; ...
    'paper_primary_run_counts.csv',paper.primaryRunCounts; ...
    'paper_source_bindings.csv',paper.sourceBindings; ...
    'paper_result_sources.csv',paper.resultSources};
for k=1:size(pairs,1)
    name=string(pairs{k,1});file=string(fullfile(output,name));
    link=ejc_csv_mat_link(file,pairs{k,2});
    links=[links;link_row(name,file,string(fullfile(output,'paper_report.mat')),link)]; %#ok<AGROW>
end
for side=["current","reference"]
    base=sources.study6;name="paper_table12.csv";
    if side=="reference",base=references.study6;name="paper_table12_reference.csv";end
    file=string(fullfile(output,name));source=string(fullfile(base,'tables/measurement.csv'));
    T=ejc_csv_read(source,"study6","tables/measurement.csv");
    T=T(T.kind=="measurementInitialization" & T.sourceStudy==1 & T.sourceCampaign=="confirmation" & ...
        T.trial==0 & T.inputMode=="recordedRateLimited" & T.initialization=="measured",:);
    T=sortrows(T,{'modelId','horizon'});
    assert(height(T)==30 && numel(unique(T.modelId))==6 && all(T.attemptedQueries==29) && ...
        isequal(sort(unique(T.horizon)),[1;2;5;10;20]),'ejc:PaperSelection','Table 12 source selection differs.');
    link=ejc_csv_mat_link(file,T);links=[links;link_row(name,file,source,link)]; %#ok<AGROW>
end
report=struct('passed',numel(links)==13 && all([links.passed]) && all(cellfun(@(v)v.passed,ledger)), ...
    'csvFamilies',numel(links),'fieldComparisons',numel(ledger),'links',links,'ledger',{ledger}, ...
    'fullStudyComparisonsRequired',true,'historicalUnroundedExportScalarsInvented',false);
report.claimApplicabilityInstances=nnz(cellfun(@(v)isfield(v.claim,'directionalClaimApplicability'),ledger));
report.rawClaimDifferences=nnz(cellfun(@(v)isfield(v.claim,'directionalClaimApplicability') && ~v.claim.originalStrictVerdict.passed,ledger));
end
function [T,indices]=select(file,study,relative)
T=ejc_csv_read(file,study,relative);indices=(1:height(T)).';
if study=="study1",mask=T.campaign=="confirmation";T=T(mask,:);indices=indices(mask);end
assert(~isempty(T),'ejc:EmptyPaperTable','Paper source selection is empty.');
end
function row=link_row(name,file,source,link)
row=struct('file',name,'path',file,'sha256',string(ejc_file_sha256(file)), ...
    'source',source,'sourceSHA256',string(ejc_file_sha256(source)),'passed',link.passed,'link',link);
end
