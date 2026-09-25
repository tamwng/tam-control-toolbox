function figureDir = plot_study6_journal(resultsDir,figureDir)
%PLOT_STUDY6_JOURNAL Two-panel journal figure from archived scores only.
% From the repository root: plot_study6_journal
% Requires MATLAB only. Exports a 137.07-by-85 mm vector PDF, 300 dpi PNG,
% exact selected-value CSV and supplied caption. No forecasts are rerun.
root = fileparts(mfilename('fullpath'));
if nargin < 1, resultsDir = fullfile(root,'results','study6_pilot_20260922'); end
if nargin < 2, figureDir = []; end
figureDir = ejc_output_path('study6_figures',figureDir);
ejc_assert_writable(figureDir);
oldPath = path; restorePath = onCleanup(@() path(oldPath));
addpath(fullfile(root,'studies','study6'));
source = char(java.io.File(resultsDir).getCanonicalPath());
destination = char(java.io.File(figureDir).getCanonicalPath());
assert(~strcmpi(source,destination) && ...
    ~startsWith(lower(destination),[lower(source),filesep]), ...
    'study6:ArchiveWrite','Derived exports must stay outside the pilot archive.');
values = study6_figure_data(resultsDir);
names = {'Nonlinear-model error','Freezing error','Total prediction error','Affine baseline'};
colors = [0 .47 .36;.77 .43 .08;.47 .31 .65;.15 .15 .15];
styles = {'-','--',':','-.'}; markers = {'o','s','d','^'};
markerSizes = [4 6 3.6 4.5];
positions = {[.105 .285 .36 .51],[.62 .285 .355 .51]};
fig = figure('Visible','off','Color','white','Units','centimeters', ...
    'Position',[2 2 13.707 8.5],'PaperUnits','centimeters', ...
    'PaperPosition',[0 0 13.707 8.5],'PaperSize',[13.707 8.5]);
cleanup = onCleanup(@() close(fig));
if isprop(fig,'Scrollable'), fig.Scrollable = 'off'; end
axesList = gobjects(1,2); lines = gobjects(1,4);
for panel = 1:2
    ax = axes(fig,'Position',positions{panel}); axesList(panel) = ax;
    set(ax,'FontName','Times New Roman','FontSize',9.5,'LineWidth',.7, ...
        'Box','off','TickDir','out','TickLength',[.016 .016],'YScale','log', ...
        'XGrid','off','YGrid','on','GridColor',[.6 .6 .6],'GridAlpha',.17, ...
        'XMinorGrid','off','YMinorGrid','off','XMinorTick','off','YMinorTick','off', ...
        'Layer','top','XColor',[.15 .15 .15],'YColor',[.15 .15 .15]);
    hold(ax,'on'); panelCode = string(char('a'+panel-1));
    for component = 1:4
        block = values(values.panel == panelCode & values.errorComponent == names{component} & ...
            values.plotted == 1,:);
        % Nested hollow square/diamond markers keep coincident error curves
        % visible without offsetting either the points or their connecting lines.
        lines(component) = plot(ax,block.horizonSeconds,block.value, ...
            'Color',colors(component,:),'LineStyle',styles{component},'LineWidth',.9, ...
            'Marker',markers{component},'MarkerSize',markerSizes(component), ...
            'MarkerFaceColor','none','DisplayName',names{component});
        assert(isequal(lines(component).XData,block.horizonSeconds.') && ...
            isequal(lines(component).YData,block.value.'),'study6:PlotValues', ...
            'All visible coordinates must retain the exact selected source-table values.');
    end
    set(ax,'XLim',[0 2.1],'XTick',[.1 .5 1 2],'XTickLabel',{'0.1','0.5','1.0','2.0'});
    xlabel(ax,'Forecast horizon, H T_s (s)');
    if panel == 1
        ylim(ax,[1e-5 .25]); yticks(ax,10.^(-5:-1));
        ylabel(ax,'Forecast RMSE');
        title(ax,{'(a) Exact-sine model','(Plant B)'},'FontSize',10,'FontWeight','normal');
    else
        ylim(ax,[1e-5 .13]); yticks(ax,10.^(-5:-1));
        ylabel(ax,'Forecast RMSE (rad/s)');
        title(ax,{'(b) Integrated physical model','(Plant C)'},'FontSize',10,'FontWeight','normal');
    end
    block = values(values.panel == panelCode & values.plotted == 1,:);
    assert(all(block.horizonSeconds > ax.XLim(1) & block.horizonSeconds < ax.XLim(2)) && ...
        all(block.value > ax.YLim(1) & block.value < ax.YLim(2)), ...
        'study6:PlotClipping','Every non-omitted point must remain inside its panel limits.');
end
key = legend(axesList(2),lines,names,'Orientation','horizontal','NumColumns',2, ...
    'Box','off','FontName','Times New Roman','FontSize',9.5,'Interpreter','none');
key.ItemTokenSize = [24 10]; key.Units = 'normalized'; drawnow;
key.Position(1:2) = [(1-key.Position(3))/2,.035];
for panel = 1:2, axesList(panel).Position = positions{panel}; end
assert(numel(findall(fig,'Type','axes')) == 2,'study6:PanelCount','Exactly two panels are required.');
assert(key.Position(1) >= 0 && key.Position(2)+key.Position(4) < .18, ...
    'study6:LegendLayout','Shared legend must fit below the axes at manuscript size.');
if ~isfolder(figureDir), mkdir(figureDir); end
csvFile = fullfile(figureDir,'study6_main_values.csv'); write_values(csvFile,values);
assert(isequal(readtable(csvFile,'TextType','string'),values), ...
    'study6:CsvValues','CSV must preserve all selected doubles, including omitted first-step freezing values.');
write_caption(fullfile(figureDir,'study6_main_caption.tex'));
drawnow;
print(fig,fullfile(figureDir,'study6_main.pdf'),'-dpdf','-vector');
print(fig,fullfile(figureDir,'study6_main.png'),'-dpng','-r300');
fprintf('Study 6 journal figure: two panels at 137.07 mm width, 9.5 pt axes.\n');
fprintf('40 exact table values checked against saved paths; 38 plotted, two H=1 freezing points omitted.\n');
fprintf('29/29 finite common queries per row; no simulations or forecasts run.\n');
end
function write_values(filename,values)
file = fopen(filename,'w'); assert(file ~= -1,'study6:FigureWrite','Cannot write selected values.');
cleanup = onCleanup(@() fclose(file));
fprintf(file,'%s\n',strjoin(values.Properties.VariableNames,','));
for j = 1:height(values)
    r = values(j,:);
    fprintf(file,'%s,%s,%s,%s,%s,%d,%.17g,%.17g,%s,%s,%d,%d,%d\n', ...
        r.panel,r.plant,r.model,r.modelId,r.errorComponent,r.horizon,r.horizonSeconds, ...
        r.value,r.unit,r.sourceColumn,r.plotted,r.attemptedQueries,r.finiteQueries);
end
end
function write_caption(filename)
% Verbatim short caption supplied in study6_results_draft.tex.
file = fopen(filename,'w'); assert(file ~= -1,'study6:FigureWrite','Cannot write supplied caption.');
cleanup = onCleanup(@() fclose(file));
fprintf(file,['\\caption{Study 6: nonlinear-model, freezing, and total forecast errors.\n' ...
    '(a) Exact-sine model on Plant B, $L=1.1$.\n' ...
    '(b) Integrated physical model on Plant C.\n' ...
    'Each panel uses 200-transition estimates and 29 common initial states\n' ...
    'under rate-limited inputs; the affine baseline uses the same queries.\n' ...
    'First-step freezing errors are zero to numerical precision and omitted\n' ...
    'from the logarithmic axes.}\n']);
end
