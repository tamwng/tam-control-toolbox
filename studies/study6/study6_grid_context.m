function grid = study6_grid_context(root,cfg)
%STUDY6_GRID_CONTEXT Reuse Study 4 grid scores without a new snapshot campaign.
folder = fullfile(root,'results',cfg.sources{4});
grid = readtable(fullfile(folder,'tables','grid.csv'),'TextType','string');
for scenario = ["no_change","represented","unrepresented"]
    for id = ["A","Aplus","P2","K"]
        saved = load(fullfile(folder,'evaluation',scenario+"_"+id+".mat"),'evaluation'); e = saved.evaluation;
        block = sortrows(grid(grid.scenarioId == scenario & grid.modelId == id,:),'sampleIndex');
        assert(height(block) == 120 && isequal(block.timeSeconds,e.time.') && all(block.queryCount == 441));
        assert(max(abs(e.rms-sqrt(mean(e.error.^2,1)))) <= cfg.tolerance);
        assert(all(abs(block.predictionRMS-e.rms.') <= 8e-15*max(abs(e.rms.'),realmin)));
    end
end
grid.sourceStudy = repmat(4,height(grid),1);
grid.interpretation = repmat("Reused nonlinear grid error; not a frozen-affine or tracking score",height(grid),1);
end
