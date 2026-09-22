function rows = study6_summary(out,q)
%STUDY6_SUMMARY Same complete query set for every MSE/RMSE and signed cross term.
% Invalid rows retain attempted counts and NaN scores; no finite-only ranking.
rows = table; H = q.horizons; meta = out.meta;
for s = 1:size(out.mappedTheta,3)
    for mode = 1:2
        for h = H
            j = h+1; row = meta;
            row.snapshot = string(meta.snapshotLabels{s});
            row.fittingTransitions = meta.fitSteps(s); row.snapshotTime = meta.snapshotTimes(s);
            row = rmfield(row,{'snapshotLabels','fitSteps','snapshotTimes'});
            row.inputMode = string(q.inputModes{mode}); row.initialization = string(q.initialization);
            row.squaredUnit = "("+meta.unit+")^2";
            row.currentTrueGain = NaN;
            if isfield(q,'currentGain') && all(q.currentGain(:,min(s,size(q.currentGain,2))) == q.currentGain(1,min(s,size(q.currentGain,2))))
                row.currentTrueGain = q.currentGain(1,min(s,size(q.currentGain,2)));
            end
            row.horizon = h; row.horizonSeconds = .1*h;
            valid = out.valid(:,j,mode,s); row.attemptedQueries = numel(valid);
            row.finiteQueries = nnz(valid); row.failedQueries = nnz(~valid);
            for quantity = ["model","freezing","total","initialization","change","combined"]
                errors = out.(quantity+"Error")(:,j,mode,s);
                mse = mean(errors.^2); center = mean(errors);
                if ~all(valid), mse = NaN; center = NaN; end
                row.(quantity+"MeanError") = center;
                row.(quantity+"MSE") = mse; row.(quantity+"RMSE") = sqrt(mse);
            end
            row.meanCrossTerm = mean(out.crossTerm(:,j,mode,s));
            row.meanCombinedCrossTerm = mean(out.combinedCrossTerm(:,j,mode,s));
            if ~all(valid), row.meanCrossTerm = NaN; row.meanCombinedCrossTerm = NaN; end
            row.aggregateSquaredResidual = row.totalMSE-row.modelMSE-row.freezingMSE-row.meanCrossTerm;
            row.aggregateCombinedSquaredResidual = row.combinedMSE-row.modelMSE-row.freezingMSE- ...
                row.initializationMSE-row.changeMSE-row.meanCombinedCrossTerm;
            for field = ["identityResidual","squaredIdentityResidual","combinedIdentityResidual","combinedSquaredIdentityResidual"]
                row.(field+"Max") = max(abs(out.(field)(:,j,mode,s)),[],'omitnan');
            end
            row.referenceRefinementRMSE = sqrt(mean(q.referenceError(:,j,mode,min(s,size(q.referenceError,4))).^2));
            row.archiveComparisonMax = out.archiveComparisonMax;
            rows = [rows;struct2table(row)]; %#ok<AGROW>
        end
    end
end
end
