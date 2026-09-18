function values = study3_figure_data(resultsDir)
%STUDY3_FIGURE_DATA Exact trial-000 histories for the six journal panels.
% Theta and lambda at array index j belong to time(j), after the available
% transition is identified. True gain at j generates the next transition.
% No time shift, resampling, fitting, or recovery calculation is performed.
ids = {'S_none','S_fixed','S_vrf','S_pretrained','K'};
suffixes = {'NoForgetting','FixedForgetting','VariableRateForgetting', ...
    'PretrainedFrozen','KnownModel'};
scenarios = {'abrupt','drift'};
limits = [45 65;45 100];
values = table;
for s = 1:2
    runs = cell(1,5);
    for j = 1:5
        filename = fullfile(resultsDir,'runs',sprintf('%s_%s_000.mat',scenarios{s},ids{j}));
        saved = load(filename,'result'); r = saved.result;
        assert(strcmp(r.id,ids{j}) && strcmp(r.scenario,scenarios{s}) && ...
            r.trial == 0 && r.completed && r.nSteps == numel(r.time)-1, ...
            'study3:FigureSource','Expected complete deterministic trial 000.');
        assert(r.Ts == .1 && all(r.measurementNoise == 0) && all(r.processNoise == 0), ...
            'study3:FigureSource','Only the noise-free pilot is used here.');
        runs{j} = r;
    end
    base = runs{1};
    selected = find(base.time >= limits(s,1) & base.time <= limits(s,2));
    expected = (round(limits(s,1)/base.Ts):round(limits(s,2)/base.Ts))+1;
    assert(isequal(selected,expected),'study3:FigureWindow','Both window endpoints must be retained.');
    block = table(repmat(string(scenarios{s}),numel(selected),1),base.time(selected).', ...
        'VariableNames',{'scenario','timeSeconds'});
    for j = 1:5
        r = runs{j};
        assert(isequal(r.time,base.time) && isequal(r.r,base.r) && ...
            isequal(r.trueGain,base.trueGain),'study3:FigurePairing', ...
            'Time, reference and current true gain must match within each schedule.');
        block.(['trackingError' suffixes{j}]) = (r.x(selected)-r.r(selected)).';
    end
    for j = 1:4
        block.(['gainEstimate' suffixes{j}]) = runs{j}.theta(3,selected).';
    end
    block.currentTrueGain = base.trueGain(selected).';
    for j = 1:3
        block.(['forgettingFactor' suffixes{j}]) = runs{j}.lambda(selected).';
    end
    assert(all(isfinite(block{:,2:end}),'all'),'study3:FigureNonfinite', ...
        'Every requested plotted value must be finite.');
    values = [values;block]; %#ok<AGROW>
end
end
