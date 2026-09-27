function [selected,link]=ejc_paper_table12_source(base,originalSelection)
x=load(fullfile(base,'summary.mat'),'summary');T=x.summary.measurement;
link=ejc_csv_mat_link(fullfile(base,'tables/measurement.csv'),T);
assert(link.passed,'ejc:PaperEncoding','Table 12 CSV differs from its own unrounded saved table.');
selected=T(T.kind=="measurementInitialization" & T.sourceStudy==1 & T.sourceCampaign=="confirmation" & ...
    T.trial==0 & T.inputMode=="recordedRateLimited" & T.initialization=="measured",:);
selected=sortrows(selected,{'modelId','horizon'});selected.sourceFile=[];
assert(height(selected)==30 && numel(unique(selected.modelId))==6 && ...
    isequal(sort(unique(selected.horizon)),[1;2;5;10;20]) && all(selected.attemptedQueries==29), ...
    'ejc:PaperSelection','Table 12 original support differs.');
assert(isequal(selected.Properties.VariableNames,originalSelection.Properties.VariableNames), ...
    'ejc:PaperSelection','Original Table 12 field selection differs.');
% The CSV link uses every literal token; selection keys must also be exact.
keys={'modelId','horizon','attemptedQueries','sourceStudy','sourceCampaign','trial','inputMode','initialization'};
assert(isequaln(selected(:,keys),originalSelection(:,keys)),'ejc:PaperSelection','Table 12 source keys differ.');
end
