function figureDir = plot_study5_journal(resultsDir,figureDir)
%PLOT_STUDY5_JOURNAL Two panels from the saved deterministic pilot only.
% From the repository root: plot_study5_journal
% Requires MATLAB only. Exports a 137.07-by-85 mm vector PDF, 300 dpi PNG,
% exact plotted-value CSV and supplied caption. No models are evaluated.
root = fileparts(mfilename('fullpath'));
if nargin < 1, resultsDir = fullfile(root,'results','study5_pilot_20260922'); end
if nargin < 2, figureDir = fullfile(root,'results','study5_journal'); end
oldPath = path; restorePath = onCleanup(@() path(oldPath));
addpath(fullfile(root,'studies','study5'));
source = char(java.io.File(resultsDir).getCanonicalPath());
destination = char(java.io.File(figureDir).getCanonicalPath());
assert(~strcmpi(source,destination) && ...
    ~startsWith(lower(destination),[lower(source),filesep]), ...
    'study5:ArchiveWrite','Derived exports must stay outside the pilot archive.');
values = study5_figure_data(resultsDir);
names = {{'RMS','Maximum'}, ...
    {'Integrated physical','Euler-informed direct','Affine','Complete cubic'}};
colors = {[.12 .38 .64;.77 .43 .08], ...
    [0 .47 .36;.47 .31 .65;.12 .38 .64;.73 .20 .22]};
styles = {{'-','--'},{'-','--','-.',':'}};
markers = {{'o','s'},{'o','d','s','v'}};
positions = {[.125 .36 .36 .54],[.635 .36 .34 .54]};
fig = figure('Visible','off','Color','white','Units','centimeters', ...
    'Position',[2 2 13.707 8.5],'PaperUnits','centimeters', ...
    'PaperPosition',[0 0 13.707 8.5],'PaperSize',[13.707 8.5]);
cleanup = onCleanup(@() close(fig));
if isprop(fig,'Scrollable'), fig.Scrollable = 'off'; end
axesList = gobjects(1,2);
for panel = 1:2
    ax = axes(fig,'Position',positions{panel}); axesList(panel) = ax;
    set(ax,'FontName','Times New Roman','FontSize',9.5,'LineWidth',.7, ...
        'Box','off','TickDir','out','TickLength',[.016 .016],'YScale','log', ...
        'XGrid','off','YGrid','off','XMinorGrid','off','YMinorGrid','off', ...
        'XMinorTick','off','YMinorTick','off','Layer','top', ...
        'XColor',[.15 .15 .15],'YColor',[.15 .15 .15]);
    hold(ax,'on'); lines = gobjects(1,numel(names{panel}));
    panelCode = string(char('a'+panel-1));
    for j = 1:numel(lines)
        block = values(values.panel == panelCode & values.series == names{panel}{j},:);
        lines(j) = plot(ax,block.horizontalValue,block.value,'Color',colors{panel}(j,:), ...
            'LineStyle',styles{panel}{j},'LineWidth',.85,'Marker',markers{panel}{j}, ...
            'MarkerSize',4,'MarkerFaceColor','white','DisplayName',names{panel}{j});
        assert(isequal(lines(j).XData,block.horizontalValue.') && ...
            isequal(lines(j).YData,block.value.'),'study5:PlotValues', ...
            'Displayed points must retain the exact source CSV values, without resampling.');
    end
    if panel == 1
        set(ax,'XScale','log','XLim',[.022 .114],'XTick',[.025 .05 .1], ...
            'XTickLabel',{'0.025','0.05','0.10'},'YLim',[6e-5 8e-3],'YTick',10.^(-4:-2));
        xlabel(ax,'Sampling interval, T_s (s)'); ylabel(ax,'Normalized residual (N m)');
        title(ax,'(a) Endpoint quadrature','FontSize',10,'FontWeight','normal');
    else
        set(ax,'XLim',[0 2.1],'XTick',[.1 .5 1 2],'XTickLabel',{'0.1','0.5','1.0','2.0'}, ...
            'YLim',[1e-5 .13],'YTick',10.^(-5:-1));
        xlabel(ax,'Forecast horizon, H T_s (s)'); ylabel(ax,'Prediction RMSE (rad/s)');
        title(ax,'(b) Nonlinear prediction','FontSize',10,'FontWeight','normal');
    end
    data = values(values.panel == panelCode,:);
    assert(all(data.horizontalValue > ax.XLim(1) & data.horizontalValue < ax.XLim(2)) && ...
        all(data.value > ax.YLim(1) & data.value < ax.YLim(2)), ...
        'study5:PlotClipping','All recorded values must remain inside the displayed limits.');
    key = legend(ax,lines,names{panel},'Box','off','FontName','Times New Roman', ...
        'FontSize',9.5,'Interpreter','none','NumColumns',1);
    key.ItemTokenSize = [18 9]; key.Units = 'normalized'; drawnow;
    key.Position(1:2) = [positions{panel}(1)+(positions{panel}(3)-key.Position(3))/2, ...
        .23-key.Position(4)];
    ax.Position = positions{panel};
    assert(key.Position(1) >= 0 && key.Position(2) >= 0 && ...
        key.Position(1)+key.Position(3) <= 1,'study5:LegendLayout', ...
        'Each panel legend must fit below its axes at manuscript size.');
end
assert(numel(findall(fig,'Type','axes')) == 2,'study5:PanelCount','Exactly two panels are required.');
if ~isfolder(figureDir), mkdir(figureDir); end
csvFile = fullfile(figureDir,'study5_main_values.csv'); write_values(csvFile,values);
assert(isequal(readtable(csvFile,'TextType','string'),values), ...
    'study5:CsvValues','CSV must preserve every plotted double exactly.');
write_caption(fullfile(figureDir,'study5_main_caption.tex'));
drawnow;
print(fig,fullfile(figureDir,'study5_main.pdf'),'-dpdf','-vector');
print(fig,fullfile(figureDir,'study5_main.png'),'-dpng','-r300');
fprintf('Study 5 journal figure: two panels at 137.07 mm width, 9.5 pt axes.\n');
fprintf('26 exact source-table points checked against saved arrays; 29 common forecast queries.\n');
fprintf('Known-model errors checked and omitted; no model evaluations or simulations run.\n');
end
function write_values(filename,values)
file = fopen(filename,'w'); assert(file ~= -1,'study5:FigureWrite','Cannot write plotted values.');
cleanup = onCleanup(@() fclose(file));
fprintf(file,'%s\n',strjoin(values.Properties.VariableNames,','));
for j = 1:height(values)
    r = values(j,:);
    fprintf(file,'%s,%s,%s,%.17g,%s,%s,%.17g,%s,%s,%d,%s,%d\n', ...
        r.panel,r.series,r.horizontalVariable,r.horizontalValue,r.horizontalUnit, ...
        r.quantity,r.value,r.unit,r.sourceColumn,r.fittingTransitions,r.inputMode,r.queryCount);
end
end
function write_caption(filename)
% Verbatim short caption supplied in study5_results_draft.tex.
file = fopen(filename,'w'); assert(file ~= -1,'study5:FigureWrite','Cannot write supplied caption.');
cleanup = onCleanup(@() fclose(file));
fprintf(file,['\\caption{Study 5. (a) RMS and maximum endpoint-quadrature residual,\n' ...
    'divided by $T_s$, over 441 queries. (b) Nonlinear forecast RMSE after\n' ...
    '200 initialization transitions, using 29 common initial states and\n' ...
    'rate-limited inputs. Refined-integral and known-model numerical errors\n' ...
    'are omitted from (a) and (b), respectively.}\n']);
end
