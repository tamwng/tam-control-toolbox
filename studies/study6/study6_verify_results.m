function verification = study6_verify_results(output)
%STUDY6_VERIFY_RESULTS Read-only complete-array audit of the derived package.
verification = struct('filesChecked',0,'attemptedPaths',0,'finitePaths',0,'failureRecords',0, ...
    'identityMax',0,'squaredIdentityMax',0,'combinedIdentityMax',0, ...
    'firstStepFreezingMax',0,'contactMax',0,'archiveComparisonMax',0,'newControlRuns',0);
groupKeys = strings(0,1); commonQueries = cell(0,1);
for folder = ["primary","online","measurement","change"]
    files = dir(fullfile(output,folder,'*.mat'));
    expected = 35; if folder == "online" || folder == "change", expected = 18;
    elseif folder == "measurement", expected = 258; end
    assert(numel(files) == expected,'study6:PackageCount','A prescribed diagnostic batch is missing.');
    for f = files.'
        saved = load(fullfile(f.folder,f.name),'out','q'); o = saved.out; q = saved.q;
        check = study6_check(o,q);
        verification.filesChecked = verification.filesChecked+1;
        for field = ["attemptedPaths","finitePaths","failureRecords"]
            verification.(field) = verification.(field)+check.(field);
        end
        verification.identityMax = max(verification.identityMax,check.identityResidual);
        verification.squaredIdentityMax = max(verification.squaredIdentityMax,check.squaredIdentityResidual);
        verification.combinedIdentityMax = max(verification.combinedIdentityMax,check.combinedIdentityResidual);
        verification.firstStepFreezingMax = max(verification.firstStepFreezingMax,check.firstStepFreezing);
        verification.contactMax = max(verification.contactMax,check.contactResidual);
        if isfinite(o.archiveComparisonMax)
            verification.archiveComparisonMax = max(verification.archiveComparisonMax,o.archiveComparisonMax);
        end
        if folder == "primary" || folder == "online"
            assert(isequal(q.indices,20:20:580) && isequal(q.x,q.y));
            assert(isequal(o.rawTheta,repmat(o.rawTheta(:,1,:),1,29,1)));
            assert(all(o.changeError == 0,'all') && all(o.initializationError == 0,'all'));
            key = folder+"_"+o.meta.plant+"_"+o.meta.sourceCampaign+"_"+o.meta.scenario+"_"+string(o.meta.evaluationRange);
            group = find(groupKeys == key,1);
            if isempty(group)
                groupKeys(end+1) = key; commonQueries{end+1} = q;
            else
                reference = commonQueries{group};
                for field = {'indices','matlabColumns','inputs','x','y','truthX','truthY','truthFuture','referenceError'}
                    assert(isequal(q.(field{1}),reference.(field{1})), ...
                        'study6:CommonQueries','Compared models must share every query and numerical reference.');
                end
            end
        elseif folder == "change"
            assert(ismember(q.indices,[495 499]) && isequal(o.horizons,20) && o.meta.trial == 0);
            assert(all(o.initializationError == 0,'all'));
        else
            assert(o.meta.sourceStudy == 1 && isequal(q.indices,20:20:580));
            assert(all(o.changeError == 0,'all'));
        end
        if o.meta.plant ~= "C", assert(isequal(o.rawTheta,o.mappedTheta));
        elseif o.meta.modelId == "I"
            assert(isequal(o.mappedTheta,min(max(o.rawTheta,[.2;0]),[3;2])));
        end
    end
end
saved = load(fullfile(output,'summary.mat'),'summary'); s = saved.summary;
verification.commonQueryGroups = numel(groupKeys);
assert(verification.commonQueryGroups == 8);
assert(all(s.primary.attemptedQueries == 29) && all(s.online.attemptedQueries == 29));
assert(all(s.measurement.attemptedQueries == 29) && all(s.change.attemptedQueries == 1));
assert(height(s.constraintHistory) == 400 && height(s.constraintSummary) == 4);
assert(all(s.constraintHistory.nextSampleTime-s.constraintHistory.originTime > .1-1e-12));
assert(all(abs(s.constraintSummary.initialViolation-.55) < 1e-11));
assert(all(abs(s.constraintSummary.firstActualFutureViolation-.09) < 1e-11));
counts = struct2table(verification); writetable(counts,fullfile(output,'tables','verification.csv'));
fprintf('Study 6: %d MAT batches, %d/%d finite paths, %d explicit failures; identities verified.\n', ...
    verification.filesChecked,verification.finitePaths,verification.attemptedPaths,verification.failureRecords);
end
