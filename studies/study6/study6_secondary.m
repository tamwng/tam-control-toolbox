function [measurement,change] = study6_secondary(output,root,cfg)
%STUDY6_SECONDARY User-bounded initialization and unforeseen-change audits.
measurement = table; change = table;
folder = fullfile(root,'results',cfg.sources{1});
files = dir(fullfile(folder,'audits','*.mat'));
saved = load(fullfile(folder,'settings.mat'),'cfg'); source = saved.cfg;
expected = numel(source.modelIds)*(2+source.pilot.noiseTrials+source.confirmation.noiseTrials);
assert(numel(files) == expected,'study6:MissingAudits','An existing Study 1 audit selection is missing.');
for file = files.'
    saved = load(fullfile(file.folder,file.name),'audit'); old = saved.audit;
    saved = load(fullfile(folder,'data',file.name),'result'); r = saved.result;
    assert(isequal(old.snapshotIndices,cfg.anchors) && isequal(old.horizons,cfg.horizons) && ...
        isequal(old.inputModes,{'held','recordedRateLimited'}));
    q = study6_queries(r,old.snapshotIndices,'measured'); q.inputModes = old.inputModes;
    assert(isequal(q.x,old.trueInitialState.') && isequal(q.y,old.measuredInitialState.') && ...
        isequal(old.snapshotTheta,r.theta(:,q.matlabColumns)));
    q = study6_truth(q,'A',.45*ones(29,1));
    q.sourceRecord = "Existing Study 1 audit selection: audits/"+file.name;
    q.legacyDefinition = 'Old measuredModelError includes initialization; Study 6 separates true(y)-true(x).';
    [model,name,unit] = study6_model('A',r.id);
    raw = old.snapshotTheta;
    meta = study6_meta('measurementInitialization',1,'A',r.id,name,unit, ...
        cfg.sources{1}+"/data/"+file.name,NaN);
    meta.sourceCampaign = string(r.campaign); meta.trial = r.trial;
    meta.snapshotLabels = {'Saved within-run indices 20:20:580; different training histories'};
    out = study6_evaluate(model,raw,raw,q,meta);
    % Reuse old compatible totals/freezing, but do not relabel its mixed
    % model-plus-initialization term as the newly defined pure model error.
    lhs = out.combinedError(:,cfg.horizons+1,:);
    rhs = out.freezingError(:,cfg.horizons+1,:);
    mixed = out.modelError(:,cfg.horizons+1,:)+out.initializationError(:,cfg.horizons+1,:);
    assert(isequal(isfinite(lhs),old.valid));
    delta = [lhs(:)-old.totalError(:);rhs(:)-old.freezingError(:);mixed(:)-old.measuredModelError(:)];
    out.archiveComparisonMax = max(abs(delta),[],'omitnan');
    assert(out.archiveComparisonMax <= cfg.tolerance);
    measurement = [measurement;study6_store(output,'measurement',erase(file.name,'.mat'),out,q)]; %#ok<AGROW>
end
folder = fullfile(root,'results',cfg.sources{3});
saved = load(fullfile(folder,'settings.mat'),'cfg'); source = saved.cfg;
for id = string(source.caseIds)
    filename = "runs/abrupt_"+id+"_000.mat";
    saved = load(fullfile(folder,filename),'result'); r = saved.result;
    spec = study3_case(id); model = study1_model(spec.modelId);
    assert(r.trial == 0 && all(r.measurementNoise == 0) && all(r.processNoise == 0));
    for k = cfg.changeIndices
        q = study6_queries(r,k,'clean'); q.horizons = 20;
        q.inputModes = {'held','recordedRateLimited'};
        j = k+1; currentGain = r.trueGain(j); futureGain = r.trueGain(j:j+19);
        assert(currentGain == .45 && isequal(futureGain,study3_gain(k:k+19,'abrupt',cfg.Ts)));
        q = study6_truth(q,'A',currentGain,futureGain);
        assert(max(abs(q.truthFuture(:,:,2)-r.x(j:j+20))) <= cfg.tolerance);
        q.sourceRecord = filename; raw = r.theta(:,j);
        meta = study6_meta('futureChange',3,'A',spec.modelId,r.name,'dimensionless state', ...
            cfg.sources{3}+"/"+filename,NaN);
        meta.scenario = "abrupt"; meta.snapshotTimes = k*cfg.Ts;
        meta.snapshotLabels = {sprintf('Online at %.1f s; future switch evaluator-only',k*cfg.Ts)};
        out = study6_evaluate(model,raw,raw,q,meta);
        change = [change;study6_store(output,'change',sprintf('%s_k%d',id,k),out,q)]; %#ok<AGROW>
    end
end
end
