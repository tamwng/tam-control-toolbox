function rows = study6_online(output,root,cfg)
%STUDY6_ONLINE Common queries after different closed-loop identification paths.
folder = fullfile(root,'results',cfg.sources{3});
saved = load(fullfile(folder,'settings.mat'),'cfg'); source = saved.cfg;
saved = load(fullfile(folder,'records.mat'),'records'); record = saved.records.evaluation;
rows = table;
for scenario = string(source.scenarios)
    q = study6_queries(record,cfg.anchors,'clean');
    gains = study3_gain(cfg.onlineIndices,scenario,cfg.Ts);
    q = study6_truth(q,'A',repmat(gains,29,1));
    q.sourceRecord = 'Study 3 records.mat evaluation; common queries, different training histories';
    for id = string(source.caseIds)
        filename = sprintf('runs/%s_%s_000.mat',scenario,id);
        saved = load(fullfile(folder,filename),'result'); r = saved.result;
        spec = study3_case(id); model = study1_model(spec.modelId);
        assert(r.completed && r.trial == 0 && all(r.processNoise == 0) && all(r.measurementNoise == 0));
        columns = cfg.onlineIndices+1;
        assert(max(abs(r.time(columns)-cfg.onlineTimes)) < 1e-12 && isequal(r.trueGain(columns),gains));
        raw = repmat(reshape(r.theta(:,columns),model.ntheta,1,4),1,29,1);
        meta = study6_meta('onlineCommonQueries',3,'A',spec.modelId,r.name,'dimensionless state', ...
            cfg.sources{3}+"/"+filename,.5);
        meta.scenario = scenario; meta.fitSteps = nan(1,4); meta.snapshotTimes = cfg.onlineTimes;
        meta.snapshotLabels = cellstr("Online at "+string(cfg.onlineTimes)+" s; different training histories");
        out = study6_evaluate(model,raw,raw,q,meta);
        rows = [rows;study6_store(output,'online',scenario+"_"+id,out,q)]; %#ok<AGROW>
    end
end
end
