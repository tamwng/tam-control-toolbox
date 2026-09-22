function values = study6_figure_data(resultsDir)
%STUDY6_FIGURE_DATA Read exact primary-table scores; audit saved paths only.
% No models, estimators, numerical integrators or controllers are executed.
source = readtable(fullfile(resultsDir,'tables','primary.csv'),'TextType','string');
source = source(source.kind == "commonData" & source.sourceCampaign == "pilot" & ...
    source.trial == 0 & source.fittingTransitions == 200 & ...
    source.inputMode == "rateLimited" & source.initialization == "clean",:);
horizons = [1;2;5;10;20];
plants = ["B","C"]; studies = [2 5]; ranges = [1.1 .6];
ids = ["E","I"]; names = ["Exact sine","Integrated physical"];
files = ["B_range3_E","C_I";"B_range3_A","C_A"];
units = ["dimensionless state","rad/s"];
components = ["Nonlinear-model error","Freezing error","Total prediction error","Affine baseline"];
columns = ["modelRMSE","freezingRMSE","totalRMSE"];
fields = ["modelError","freezingError","totalError"];
values = table;
for panel = 1:2
    reference = [];
    for modelIndex = 1:2
        id = ids(panel); name = names(panel);
        if modelIndex == 2, id = "A"; name = "Affine"; end
        block = sortrows(source(source.sourceStudy == studies(panel) & ...
            source.plant == plants(panel) & source.evaluationRange == ranges(panel) & ...
            source.modelId == id,:),'horizon');
        assert(height(block) == 5 && isequal(block.horizon,horizons) && ...
            isequal(block.horizonSeconds,horizons*.1) && all(block.model == name) && ...
            all(block.unit == units(panel)) && ...
            all(block.attemptedQueries == 29 & block.finiteQueries == 29 & block.failedQueries == 0), ...
            'study6:FigureSelection','Require exactly five prescribed scores and all 29 finite queries.');
        saved = load(fullfile(resultsDir,'primary',files(modelIndex,panel)+".mat"),'out','q');
        o = saved.out; q = saved.q;
        snapshot = find(o.meta.fitSteps == 200); mode = find(strcmp(q.inputModes,'rateLimited'));
        assert(isscalar(snapshot) && isscalar(mode) && o.meta.kind == "commonData" && ...
            o.meta.sourceCampaign == "pilot" && o.meta.trial == 0 && ...
            o.meta.sourceStudy == studies(panel) && o.meta.plant == plants(panel) && ...
            o.meta.modelId == id && o.meta.evaluationRange == ranges(panel) && ...
            strcmp(q.initialization,'clean') && isequal(q.indices,20:20:580) && ...
            isequal(q.matlabColumns,q.indices+1) && isequal(q.horizons,horizons.') && ...
            isequal(q.x,q.y) && numel(q.x) == 29 && all(o.valid(:,:,mode,snapshot),'all'), ...
            'study6:FigureSnapshot','Saved paths must use the specified clean initialized snapshot.');
        if isempty(reference), reference = q;
        else
            for field = {'indices','matlabColumns','inputs','x','y','truthX','truthY','referenceError'}
                assert(isequal(q.(field{1}),reference.(field{1})), ...
                    'study6:FigureQueries','The selected model and affine baseline must share every query.');
            end
        end
        if panel == 2
            assert(q.referenceSubsteps == 40 && q.predictorSubsteps == 5);
            if modelIndex == 1
                assert(isequal(o.mappedTheta,min(max(o.rawTheta,[.2;0]),[3;2])));
            end
        end
        assert(isequal(o.rawTheta(:, :, snapshot),repmat(o.rawTheta(:,1,snapshot),1,29)));
        truth = q.truthY(:,horizons+1,mode,min(snapshot,size(q.truthY,4)));
        nonlinear = o.nonlinear(:,horizons+1,mode,snapshot);
        affine = o.affine(:,horizons+1,mode,snapshot);
        errors = {nonlinear-truth,affine-nonlinear,affine-truth};
        for component = 1:3
            assert(isequal(errors{component},o.(fields(component))(:,horizons+1,mode,snapshot)));
            csv_matches(block.(columns(component)),sqrt(mean(errors{component}.^2,1)).');
        end
        assert(block.freezingRMSE(1) <= 1e-11,'study6:FirstStepContact', ...
            'First-step freezing must vanish to the established numerical tolerance.');
        selected = 1:3;
        if modelIndex == 2, selected = 4; end
        for component = selected
            column = columns(min(component,3));
            plotted = ones(5,1);
            if component == 2, plotted(1) = 0; end
            rows = table(repmat(string(char('a'+panel-1)),5,1), ...
                repmat(plants(panel),5,1),repmat(name,5,1),repmat(id,5,1), ...
                repmat(components(component),5,1),horizons,block.horizonSeconds,block.(column), ...
                repmat(units(panel),5,1),repmat(column,5,1),plotted, ...
                block.attemptedQueries,block.finiteQueries,'VariableNames', ...
                {'panel','plant','model','modelId','errorComponent','horizon','horizonSeconds', ...
                'value','unit','sourceColumn','plotted','attemptedQueries','finiteQueries'});
            values = [values;rows]; %#ok<AGROW>
        end
    end
end
assert(height(values) == 40 && nnz(values.plotted) == 38 && ...
    all(isfinite(values.value) & values.value >= 0) && all(values.value(values.plotted == 1) > 0));
end
function csv_matches(actual,expected)
assert(isequal(size(actual),size(expected)) && ...
    all(abs(actual-expected) <= 8e-15*max(abs(expected),realmin),'all'), ...
    'study6:FigureCrosscheck','CSV scores must agree with the saved paths at CSV precision.');
end
