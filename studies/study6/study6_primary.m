function rows = study6_primary(output,root,cfg)
%STUDY6_PRIMARY Common-data stationary snapshots, before online adaptation.
rows = table;
folder = study6_source(root,cfg,1);
for campaign = ["pilot","confirmation"]
    saved = load(fullfile(folder,'data',"records_"+campaign+".mat"),'records'); record = saved.records.evaluation;
    q = study6_queries(record,cfg.anchors,'clean');
    q = study6_truth(q,'A',.45*ones(29,1)); q.sourceRecord = "data/records_"+campaign+".mat";
    for id = ["A","S","W","R","P2","K"]
        filename = "data/"+campaign+"_"+id+"_000.mat";
        saved = load(fullfile(folder,filename),'result'); r = saved.result;
        [model,name,unit] = study6_model('A',id);
        meta = study6_meta('commonData',1,'A',id,name,unit,cfg.sources{1}+"/"+filename,.5);
        meta.sourceCampaign = campaign; meta = initialization_meta(meta,cfg);
        raw = snapshots(r.fit,cfg); mapped = raw;
        out = study6_evaluate(model,raw,mapped,q,meta);
        out.archiveComparisonMax = study6_archive_check(out,r.forecasts);
        rows = [rows;study6_store(output,'primary',"A_"+campaign+"_"+id,out,q)]; %#ok<AGROW>
    end
end
folder = study6_source(root,cfg,2);
saved = load(fullfile(folder,'records.mat'),'evaluation'); records = saved.evaluation;
assert(isequal([records.L],[.25 .70 1.10]));
for range = 1:3
    q = study6_queries(records(range),cfg.anchors,'clean'); q = study6_truth(q,'B',nan(29,1));
    q.sourceRecord = sprintf('records.mat evaluation(%d)',range);
    for id = ["A","E","O3","O5","P3","K"]
        saved = load(fullfile(folder,'fits',id+".mat"),'fit'); fit = saved.fit;
        saved = load(fullfile(folder,'evaluation',id+".mat"),'evaluations'); old = saved.evaluations(range);
        [model,name,unit] = study6_model('B',id);
        meta = study6_meta('commonData',2,'B',id,name,unit,cfg.sources{2}+"/fits/"+id+".mat",records(range).L);
        meta = initialization_meta(meta,cfg); raw = snapshots(fit,cfg);
        out = study6_evaluate(model,raw,raw,q,meta);
        out.archiveComparisonMax = study6_archive_check(out,old);
        rows = [rows;study6_store(output,'primary',sprintf('B_range%d_%s',range,id),out,q)]; %#ok<AGROW>
    end
end
folder = study6_source(root,cfg,5);
saved = load(fullfile(folder,'settings.mat'),'cfg'); physicalSettings = saved.cfg;
saved = load(fullfile(folder,'records.mat'),'records'); record = saved.records.evaluation;
saved = load(fullfile(folder,'evaluation','common_queries.mat'),'queries'); oldQueries = saved.queries;
q = study6_queries(record,cfg.anchors,'clean');
assert(isequal(q.inputs,oldQueries.inputs) && isequal(q.x,oldQueries.initialStates.') && oldQueries.referenceSubsteps == 40);
q.truthX = oldQueries.truth; q.truthY = q.truthX; q.truthFuture = q.truthX;
q.referenceError = oldQueries.referenceRefinementError;
q.referenceSubsteps = oldQueries.referenceSubsteps; q.predictorSubsteps = physicalSettings.predictorSubsteps;
q.sourceRecord = 'evaluation/common_queries.mat (saved 40-substep truth; no regeneration)';
for id = ["I","D","A","P3","K"]
    saved = load(fullfile(folder,'fits',"fit_"+id+".mat"),'fit'); fit = saved.fit;
    saved = load(fullfile(folder,'evaluation',id+".mat"),'forecasts'); old = saved.forecasts;
    [model,name,unit] = study6_model('C',id,physicalSettings);
    meta = study6_meta('commonData',5,'C',id,name,unit,cfg.sources{5}+"/fits/fit_"+id+".mat",.6);
    meta = initialization_meta(meta,cfg); raw = snapshots(fit,cfg);
    mapped = reshape(study5_map(id,reshape(raw,size(raw,1),[])),size(raw));
    assert(isequal(mapped(:,1,:),reshape(fit.checkpointMappedTheta,size(raw,1),1,4)));
    out = study6_evaluate(model,raw,mapped,q,meta,struct('snapshot',4,'states',old.states));
    out.archiveComparisonMax = study6_archive_check(out,old,4);
    rows = [rows;study6_store(output,'primary',"C_"+id,out,q)]; %#ok<AGROW>
end
end
function raw = snapshots(fit,cfg)
assert(isequal(fit.checkpointTheta,fit.theta(:,cfg.fitSteps+1)), ...
    'study6:FitSnapshot','Use the initialized snapshot, not the later control estimate.');
raw = repmat(reshape(fit.checkpointTheta,size(fit.theta,1),1,4),1,29,1);
end
function meta = initialization_meta(meta,cfg)
meta.fitSteps = cfg.fitSteps; meta.snapshotTimes = nan(1,4);
meta.snapshotLabels = cellstr("After "+string(cfg.fitSteps)+" initialization transitions");
end
