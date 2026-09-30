function [summaries,contrasts,analysis] = sensitivity_summarize(runs,plan)
%SENSITIVITY_SUMMARIZE Conditional summaries, attempted denominators and paired CIs.
% Stable order: configurations, four model pairs, two outcomes; then five
% adaptive models, six changed configurations, two outcomes. Trials sorted.
helper = study1_summarize('analysis_helpers');
noisy = runs(runs.noisy,:);
metrics = ["predictionRMS","trackingRMS","inputRMS","meanAbsoluteIncrement"];
outcomes = metrics(1:2);
summaryRows = struct([]); contrastRows = struct([]);
stream = RandStream('mt19937ar','Seed',plan.analysisSeed);
analysis = struct('generator','mt19937ar','seed',plan.analysisSeed, ...
    'initialState',stream.State,'contrastStates',{{}},'finalState',[]);
for ic = 1:height(plan.configurations)
    id = plan.configurations.configuration(ic);
    for im = 1:6
        block = noisy(noisy.configuration==id & noisy.modelId==plan.modelIds(im),:);
        if isempty(block), continue; end % Non-applicable K rows are aliases.
        for metric = metrics
            if metric == "predictionRMS", complete = block.predictionCompleted;
            else, complete = block.completed; end
            values = block.(metric)(complete);
            row = struct('configuration',id,'modelId',plan.modelIds(im), ...
                'model',plan.modelNames(im),'metric',metric,'attempted',height(block), ...
                'completedControl',nnz(block.completed),'terminatedOrFailed',nnz(~block.completed), ...
                'eligibleScores',nnz(complete),'finiteScores',nnz(isfinite(values)), ...
                'median',helper.percentile(values,.5),'q1',helper.percentile(values,.25), ...
                'q3',helper.percentile(values,.75), ...
                'iqr',helper.percentile(values,.75)-helper.percentile(values,.25), ...
                'conditioning',"completed control runs; prediction separately requires all 600 queries finite");
            summaryRows = [summaryRows;row]; %#ok<AGROW>
        end
    end
    pairs = ["S","A";"S","W";"S","R";"R","P2"];
    for ip = 1:4
        for metric = outcomes
            left = select(noisy,id,pairs(ip,1),metric);
            right = select(noisy,id,pairs(ip,2),metric);
            analysis.contrastStates{end+1} = stream.State;
            stats = sensitivity_contrast(left,right,stream,plan.bootstrapCount);
            row = context("withinConfiguration",id+":"+pairs(ip,1),id+":"+pairs(ip,2),metric,stats);
            contrastRows = [contrastRows;row]; %#ok<AGROW>
        end
    end
end
for im = 1:5
    for ic = 2:7
        id = plan.configurations.configuration(ic);
        for metric = outcomes
            left = select(noisy,id,plan.modelIds(im),metric);
            right = select(noisy,"baseline",plan.modelIds(im),metric);
            analysis.contrastStates{end+1} = stream.State;
            stats = sensitivity_contrast(left,right,stream,plan.bootstrapCount);
            row = context("changedMinusBaseline",id+":"+plan.modelIds(im), ...
                "baseline:"+plan.modelIds(im),metric,stats);
            contrastRows = [contrastRows;row]; %#ok<AGROW>
        end
    end
end
summaries = struct2table(summaryRows); contrasts = struct2table(contrastRows);
analysis.finalState = stream.State;
end

function t = select(runs,configuration,model,metric)
block = runs(runs.configuration==configuration & runs.modelId==model,:);
complete = block.completed;
if metric=="predictionRMS", complete=block.predictionCompleted; end
t = table(block.trial,block.(metric),complete,'VariableNames',{'trial','value','complete'});
end

function row = context(kind,left,right,metric,stats)
row = struct('kind',kind,'left',left,'right',right,'metric',metric, ...
    'signConvention',"left minus right",'units',"dimensionless state", ...
    'intervalScope',"95% contrast-specific percentile interval; not simultaneous");
names = fieldnames(stats);
for j=1:numel(names), row.(names{j})=stats.(names{j}); end
end
