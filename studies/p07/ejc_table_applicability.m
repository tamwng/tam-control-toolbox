function [required,reason]=ejc_table_applicability(study,file,key,field,T,sources)
%EJC_TABLE_APPLICABILITY Bind table masks to original source selections.
% Summary MAT tables and their CSV exports share the same original masks.
if string(file)=="summary.mat"
    token=regexp(char(key),'\.summary\[\]\.([^.]+)\.','tokens','once');
    assert(~isempty(token),'ejc:Applicability','Missing original summary table name.');
    file="tables/"+string(token{1})+".csv";
end
source=struct;
if string(study)=="study4" && string(field)=="lastTarget"
    assert(height(T)==1 && string(file)=="tables/parameters.csv", ...
        'ejc:Applicability','Only the original Study 4 parameter row is supported.');
    runFile=ejc_table_run_source(study,T,sources);
    [~,name]=fileparts(runFile);base=sources.(study);
    a=load(runFile,'result');r=a.result;
    a=load(fullfile(base,'evaluation',name+".mat"),'evaluation');e=a.evaluation;
    a=load(fullfile(base,'settings.mat'),'cfg');cfg=a.cfg;
    iw=find(string(cfg.windowNames)==T.window);
    assert(isscalar(iw) && r.nEstimated==T.coefficientCount && ...
        nnz(string(r.labels)==T.component)==1,'ejc:Applicability','Parameter source keys differ.');
    ix=find(r.time(1:end-1)>=cfg.windows(iw,1) & r.time(1:end-1)<cfg.windows(iw,2) & ...
        (1:cfg.K)<=r.nSteps);
    assert(numel(ix)==T.scoredSamples && nnz(e.exactTargetAvailable(ix))==T.exactSamples, ...
        'ejc:Applicability','Parameter source selection/count differs.');
    source.lastExactTargetAvailable=~isempty(ix) && e.exactTargetAvailable(ix(end));
end
[required,reason]=ejc_csv_applicability(study,file,field,T,source);
end
