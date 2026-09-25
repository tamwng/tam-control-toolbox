function [fig,selection] = inspect_ejc(study,caseId,sourceDirectory,varargin)
%INSPECT_EJC Display one saved temporal response without running a model.
% INSPECT_EJC displays the preselected Study 1 Shared noisy trial 1.
% INSPECT_EJC(3,'abrupt_S_vrf_001') selects an existing Study 3 case.
% An optional third argument selects a newly reproduced source directory.
% Name/value options: 'SaveTo', an unused PNG/PDF filename in an existing
% directory; 'Visible', 'on' (default) or 'off'. No file is saved by default.
% States include the final endpoint; applied inputs and parameter snapshots
% cover completed control instants only. The unused terminal input is omitted.
% These are inspection plots, not additional experiments or publication plots.

randomState = rng;
restoreRandom = onCleanup(@() rng(randomState));
if nargin < 1 || isempty(study), study = 1; end
if nargin < 2, caseId = ''; end
if nargin < 3, sourceDirectory = ''; end
if isnumeric(study)
    assert(isscalar(study) && ismember(study,1:5), ...
        'ejc:InspectionStudy','Select Study 1--5 or ''p06''; Study 6 contains derived forecasts.');
    key = sprintf('study%d',study);
else
    key = char(string(study));
    assert(strcmp(key,'p06'),'ejc:InspectionStudy', ...
        'Select Study 1--5 or ''p06''; Study 6 contains derived forecasts.');
end
defaults = struct('study1','confirmation_S_001','study2','amplitude_02_E', ...
    'study3','abrupt_S_vrf_001','study4','represented_Aplus', ...
    'study5','I','p06','baseline_S_001');
if isempty(caseId), caseId = defaults.(key); end
caseId = char(string(caseId));
assert(~isempty(regexp(caseId,'^[A-Za-z0-9_-]+$','once')), ...
    'ejc:InspectionCase','Use an existing case filename without its .mat extension.');
if isempty(sourceDirectory)
    sources = ejc_reference_sources;
    sourceDirectory = sources.(key);
end
parser = inputParser;
addParameter(parser,'SaveTo','',@(value) ischar(value) || (isstring(value) && isscalar(value)));
addParameter(parser,'Visible','on',@(value) any(strcmp(value,{'on','off'})));
parse(parser,varargin{:});
saveFile = char(parser.Results.SaveTo);
if ~isempty(saveFile)
    ejc_assert_writable(saveFile);
    assert(~isfile(saveFile) && ~isfolder(saveFile),'ejc:ExistingOutput', ...
        'Inspection exports must use an unused filename.');
    [parent,~,extension] = fileparts(saveFile);
    if isempty(parent), parent = pwd; end
    assert(isfolder(parent) && any(strcmpi(extension,{'.png','.pdf'})), ...
        'ejc:InspectionExport','Use a PNG/PDF filename in an existing output directory.');
end
folder = 'runs';
if strcmp(key,'study1'), folder = 'data'; end
filename = fullfile(sourceDirectory,folder,[caseId '.mat']);
assert(isfile(filename),'ejc:MissingInspectionCase','Required saved case is missing: %s',filename);
saved = load(filename,'result');
assert(isfield(saved,'result') && isstruct(saved.result) && isscalar(saved.result), ...
    'ejc:InspectionRecord','The selected file must contain one saved result structure.');
r = saved.result;
required = {'time','x','r','u','nSteps','completed'};
assert(all(isfield(r,required)),'ejc:InspectionRecord','The saved temporal response is incomplete.');
n = r.nSteps;
assert(isscalar(n) && isfinite(n) && n >= 1 && n == floor(n) && ...
    all([numel(r.time),numel(r.x),numel(r.r),numel(r.u)] >= n+1), ...
    'ejc:InspectionRecord','The selected record has no valid completed time interval.');
stateUnit = 'dimensionless state'; inputUnit = 'dimensionless input';
if isfield(r,'units')
    stateUnit = r.units.state; inputUnit = r.units.input;
end
hasTheta = isfield(r,'theta') && ~isempty(r.theta) && size(r.theta,2) >= n;
hasLambda = isfield(r,'lambda') && numel(r.lambda) >= n && any(isfinite(r.lambda(1:n)));
fig = figure('Visible',parser.Results.Visible,'Color','white', ...
    'Name',['EJC inspection: ' caseId],'NumberTitle','off');
layout = tiledlayout(fig,3+hasTheta+hasLambda,1,'TileSpacing','compact');
endpoints = 1:n+1; instants = 1:n;
ax = nexttile(layout); hold(ax,'on');
plot(ax,r.time(endpoints),r.r(endpoints),'k--','DisplayName','Reference');
plot(ax,r.time(endpoints),r.x(endpoints),'DisplayName','True output (evaluator)', ...
    'Tag','ejc.output');
if isfield(r,'y') && numel(r.y) >= n+1 && ~isequaln(r.y(endpoints),r.x(endpoints))
    plot(ax,r.time(endpoints),r.y(endpoints),':','DisplayName','Measured output');
end
ylabel(ax,['Output (' stateUnit ')']); legend(ax,'Location','best'); grid(ax,'on');
ax = nexttile(layout);
plot(ax,r.time(instants),r.x(instants)-r.r(instants),'Tag','ejc.trackingError');
ylabel(ax,['x - reference (' stateUnit ')']); grid(ax,'on');
ax = nexttile(layout);
stairs(ax,r.time(instants),r.u(instants),'Tag','ejc.appliedInput');
ylabel(ax,['Applied input (' inputUnit ')']); grid(ax,'on');
if hasTheta
    ax = nexttile(layout); hold(ax,'on');
    labels = arrayfun(@(j) sprintf('theta(%d)',j),1:size(r.theta,1),'UniformOutput',false);
    if isfield(r,'labels') && numel(r.labels) == numel(labels), labels = r.labels;
    elseif isfield(r,'fit') && isfield(r.fit,'labels') && numel(r.fit.labels) == numel(labels)
        labels = r.fit.labels;
    end
    parameterKind = ' raw';
    if (isfield(r,'nEstimated') && r.nEstimated == 0) || ...
            (isfield(r,'id') && strcmp(r.id,'K'))
        parameterKind = ' known reference';
    end
    for j = 1:size(r.theta,1)
        plot(ax,r.time(instants),r.theta(j,instants), ...
            'DisplayName',[char(labels{j}) parameterKind],'Tag','ejc.rawParameter');
        if isfield(r,'mappedTheta') && isequal(size(r.mappedTheta),size(r.theta)) && ...
                ~isequaln(r.mappedTheta(j,instants),r.theta(j,instants))
            plot(ax,r.time(instants),r.mappedTheta(j,instants),'--', ...
                'DisplayName',[char(labels{j}) ' mapped']);
        end
    end
    ylabel(ax,'Parameters (model units)'); legend(ax,'Location','best','Interpreter','none'); grid(ax,'on');
end
if hasLambda
    ax = nexttile(layout);
    plot(ax,r.time(instants),r.lambda(instants),'Tag','ejc.forgetting');
    ylabel(ax,'Forgetting factor'); grid(ax,'on');
end
xlabel(layout,'Time (s)');
status = 'complete'; if ~r.completed, status = 'incomplete retained prefix'; end
title(layout,{['Inspection: ' key ' / ' caseId ' / ' status], ...
    char(sourceDirectory)},'Interpreter','none');
selection = struct('study',key,'caseId',caseId,'sourceFile',filename, ...
    'nSteps',n,'completed',r.completed,'savedTo',saveFile);
if ~isempty(saveFile), exportgraphics(fig,saveFile); end
end
