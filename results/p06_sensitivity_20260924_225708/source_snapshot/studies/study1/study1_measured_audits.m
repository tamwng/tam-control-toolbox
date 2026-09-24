function study1_measured_audits(outputDir,cfg)
%STUDY1_MEASURED_AUDITS Within-run sensitivity to measured initialization.
% Section 6.5: true forecasts start at x(k), while learned and frozen-affine
% forecasts start at y(k). A second learned forecast starts at x(k) to isolate
% initialization sensitivity. Parameters and affine coefficients stay fixed.
% Each controller generated its own trajectory: these audits are not a
% common-query comparison between models. Raw results are never modified.

campaigns = {'pilot','confirmation'};
auditDir = fullfile(outputDir,'audits');
tableDir = fullfile(outputDir,'tables');
tableFile = fullfile(tableDir,'measured_initialization_audit.csv');
assert(~isfile(tableFile),'study1:ExistingAudit','Refusing to overwrite %s.',tableFile);
% Check the complete requested file set before creating any audit output.
for c = 1:numel(campaigns)
    campaign = campaigns{c};
    for m = 1:numel(cfg.modelIds)
        for trial = 0:cfg.(campaign).noiseTrials
            name = sprintf('%s_%s_%03d.mat',campaign,cfg.modelIds{m},trial);
            assert(isfile(fullfile(outputDir,'data',name)), ...
                'study1:MissingRun','Required raw result is missing: %s.',name);
            assert(~isfile(fullfile(auditDir,name)), ...
                'study1:ExistingAudit','Refusing to overwrite audit %s.',name);
        end
    end
end
if ~isfolder(auditDir), mkdir(auditDir); end
if ~isfolder(tableDir), mkdir(tableDir); end
rows = struct([]);
count = 0;
invalid = 0;
for c = 1:numel(campaigns)
    campaign = campaigns{c};
    for m = 1:numel(cfg.modelIds)
        id = cfg.modelIds{m};
        for trial = 0:cfg.(campaign).noiseTrials
            name = sprintf('%s_%s_%03d.mat',campaign,id,trial);
            saved = load(fullfile(outputDir,'data',name),'result');
            audit = audit_run(saved.result,cfg);
            save(fullfile(auditDir,name),'audit','-v7');
            rows = [rows;summary_rows(audit)]; %#ok<AGROW>
            count = count+1;
            invalid = invalid+nnz(~audit.valid);
        end
    end
end
writetable(struct2table(rows),tableFile);
fprintf('Measured-initialization audits: %d runs; %d invalid queries retained explicitly.\n', ...
    count,invalid);
end

function audit = audit_run(result,cfg)
model = study1_model(result.id);
shape = [numel(cfg.anchors),numel(cfg.horizons),2];
audit = struct('campaign',result.campaign,'id',result.id,'trial',result.trial, ...
    'description','Within-run sensitivity audit; different models use different trajectories.', ...
    'snapshotIndices',cfg.anchors,'horizons',cfg.horizons, ...
    'inputModes',{{'held','recordedRateLimited'}}, ...
    'trueInitialState',nan(1,shape(1)),'measuredInitialState',nan(1,shape(1)), ...
    'snapshotTheta',nan(model.ntheta,shape(1)), ...
    'measuredModelError',nan(shape),'freezingError',nan(shape), ...
    'totalError',nan(shape),'crossTerm',nan(shape), ...
    'cleanModelError',nan(shape),'initializationEffect',nan(shape), ...
    'valid',false(shape),'identityResidual',nan(shape), ...
    'squaredIdentityResidual',nan(shape),'initializationIdentityResidual',nan(shape), ...
    'failures',struct('snapshotIndex',{},'mode',{},'horizon',{},'message',{}));
for a = 1:numel(cfg.anchors)
    j = cfg.anchors(a)+1;
    if j <= result.nSteps
        audit.trueInitialState(a) = result.x(j);
        audit.measuredInitialState(a) = result.y(j);
        audit.snapshotTheta(:,a) = result.theta(:,j);
    end
    for mode = 1:2
        h = 0;
        try
            assert(j <= result.nSteps,'study1:UnavailableSnapshot', ...
                'No controller snapshot exists at this index in the completed prefix.');
            theta = audit.snapshotTheta(:,a);
            zTrue = audit.trueInitialState(a);
            zMeasured = audit.measuredInitialState(a);
            zClean = zTrue;
            zAffine = zMeasured;
            assert(all(isfinite([zTrue;zMeasured;theta;result.u(j)])), ...
                'study1:InvalidSnapshot','The required snapshot is nonfinite.');
            [A,B,c] = freeze_predictor(model,zMeasured,result.u(j),theta);
            for h = 1:max(cfg.horizons)
                input = result.u(j);
                if mode == 2
                    assert(j+h-1 <= result.nSteps,'study1:UnavailableInput', ...
                        'A future applied input is outside the completed trajectory.');
                    input = result.u(j+h-1);
                end
                zTrue = study1_plant(zTrue,input);
                zMeasured = forward_map(model,zMeasured,input,theta);
                zClean = forward_map(model,zClean,input,theta);
                zAffine = c+A*zAffine+B*input;
                assert(all(isfinite([zTrue,zMeasured,zClean,zAffine])), ...
                    'study1:InvalidForecast','A forecast became nonfinite.');
                ih = find(cfg.horizons == h,1);
                if isempty(ih), continue; end
                em = zMeasured-zTrue;
                ef = zAffine-zMeasured;
                et = zAffine-zTrue;
                ec = zClean-zTrue;
                ei = zMeasured-zClean;
                cross = 2*em*ef;
                assert(all(isfinite([em,ef,et,ec,ei,cross,em^2,ef^2,et^2])), ...
                    'study1:InvalidForecastError','Forecast error arithmetic became nonfinite.');
                audit.measuredModelError(a,ih,mode) = em;
                audit.freezingError(a,ih,mode) = ef;
                audit.totalError(a,ih,mode) = et;
                audit.cleanModelError(a,ih,mode) = ec;
                audit.initializationEffect(a,ih,mode) = ei;
                audit.crossTerm(a,ih,mode) = cross;
                audit.identityResidual(a,ih,mode) = abs(et-em-ef);
                audit.squaredIdentityResidual(a,ih,mode) = abs(et^2-em^2-ef^2-cross);
                audit.initializationIdentityResidual(a,ih,mode) = abs(em-ec-ei);
                audit.valid(a,ih,mode) = true;
            end
        catch err
            item = struct('snapshotIndex',cfg.anchors(a),'mode',audit.inputModes{mode}, ...
                'horizon',h,'message',err.message);
            audit.failures(end+1) = item;
        end
    end
end
audit.checkedQueryCount = nnz(audit.valid);
audit.invalidQueryCount = nnz(~audit.valid);
audit.allQueriesValid = all(audit.valid(:));
audit.maxIdentityResidual = finite_max(audit.identityResidual);
audit.maxSquaredIdentityResidual = finite_max(audit.squaredIdentityResidual);
audit.maxInitializationIdentityResidual = finite_max(audit.initializationIdentityResidual);
first = find(cfg.horizons == 1,1);
audit.maxFirstStepFreezingError = finite_max(abs(audit.freezingError(:,first,:)));
audit.maxAffineFreezingError = NaN;
if audit.checkedQueryCount > 0
    errors = [audit.measuredModelError(audit.valid);audit.freezingError(audit.valid); ...
        audit.totalError(audit.valid);audit.cleanModelError(audit.valid); ...
        audit.initializationEffect(audit.valid)];
    scale = max([1;abs(errors)]);
    assert(audit.maxIdentityResidual <= 1e-11*scale && ...
        audit.maxSquaredIdentityResidual <= 1e-11*scale^2 && ...
        audit.maxInitializationIdentityResidual <= 1e-11*scale, ...
        'study1:MeasuredAuditIdentity','A finite-query error identity failed.');
end
if isfinite(audit.maxFirstStepFreezingError)
    assert(audit.maxFirstStepFreezingError <= 1e-11, ...
        'study1:MeasuredAuditContact','First-step freezing contact failed.');
end
if strcmp(result.id,'A')
    audit.maxAffineFreezingError = finite_max(abs(audit.freezingError));
    if isfinite(audit.maxAffineFreezingError)
        assert(audit.maxAffineFreezingError <= 1e-11, ...
            'study1:MeasuredAuditAffine','Complete affine model freezing error is nonzero.');
    end
end
if result.trial == 0 && audit.checkedQueryCount > 0
    assert(all(audit.initializationEffect(audit.valid) == 0), ...
        'study1:NoiselessInitialization','Noiseless initialization introduced an effect.');
end
end

function rows = summary_rows(audit)
rows = struct([]);
for mode = 1:numel(audit.inputModes)
    for h = 1:numel(audit.horizons)
        valid = audit.valid(:,h,mode);
        row = struct('campaign',string(audit.campaign),'model',string(audit.id), ...
            'trial',audit.trial,'noise',audit.trial>0, ...
            'auditType',"within-run measured-initial-state sensitivity", ...
            'inputMode',string(audit.inputModes{mode}),'horizon',audit.horizons(h), ...
            'attemptedCount',numel(valid),'validCount',nnz(valid), ...
            'invalidCount',nnz(~valid),'allQueriesValid',all(valid));
        % NaNs deliberately propagate: an incomplete query set is not scored
        % as a complete audit, and no divergent query is silently excluded.
        row.measuredModelRMS = sqrt(mean(audit.measuredModelError(:,h,mode).^2));
        row.freezingRMS = sqrt(mean(audit.freezingError(:,h,mode).^2));
        row.totalRMS = sqrt(mean(audit.totalError(:,h,mode).^2));
        row.cleanModelRMS = sqrt(mean(audit.cleanModelError(:,h,mode).^2));
        row.initializationEffectRMS = sqrt(mean(audit.initializationEffect(:,h,mode).^2));
        row.meanCrossTerm = mean(audit.crossTerm(:,h,mode));
        rows = [rows;row]; %#ok<AGROW>
    end
end
end

function value = finite_max(values)
values = values(isfinite(values));
if isempty(values), value = NaN; else, value = max(values); end
end
