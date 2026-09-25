function figureDir = plot_study4_journal(resultsDir,figureDir)
%PLOT_STUDY4_JOURNAL Four panels from the saved deterministic pilot only.
% From the repository root: plot_study4_journal
% Requires MATLAB only. Exports a 137.07-by-128 mm vector PDF, 300 dpi PNG,
% exact plotted-value CSV, and the supplied short caption. No simulations,
% fitting, or prediction evaluations are run. Source data remain read only.
root = fileparts(mfilename('fullpath'));
if nargin < 1, resultsDir = fullfile(root,'results','study4_pilot_20260922'); end
if nargin < 2, figureDir = []; end
figureDir = ejc_output_path('study4_figures',figureDir);
ejc_assert_writable(figureDir);
oldPath = path;
restorePath = onCleanup(@() path(oldPath));
addpath(fullfile(root,'studies','study4'));
source = char(java.io.File(resultsDir).getCanonicalPath());
destination = char(java.io.File(figureDir).getCanonicalPath());
assert(~strcmpi(source,destination) && ...
    ~startsWith(lower(destination),[lower(source),filesep]), ...
    'study4:ArchiveWrite','Derived exports must stay outside the pilot archive.');
values = study4_figure_data(resultsDir);
names = {'Affine','Augmented affine','Complete quadratic','True coefficient'};
colors = [.12 .38 .64;0 .47 .36;.77 .43 .08;.15 .15 .15];
styles = {'-','--','-.',':'}; markers = {'s','o','^'};
scenarios = ["represented","unrepresented"];
positions = {[.145 .55 .355 .33],[.61 .55 .345 .33]; ...
             [.145 .11 .355 .33],[.61 .11 .345 .33]};
fig = figure('Visible','off','Color','white','Units','centimeters', ...
    'Position',[2 2 13.707 12.8],'PaperUnits','centimeters', ...
    'PaperPosition',[0 0 13.707 12.8],'PaperSize',[13.707 12.8]);
cleanup = onCleanup(@() close(fig));
if isprop(fig,'Scrollable'), fig.Scrollable = 'off'; end
axesList = gobjects(2,2); keyLines = gobjects(1,4);
for col = 1:2
    for row = 1:2
        ax = axes(fig,'Position',positions{row,col}); axesList(row,col) = ax;
        style_axes(ax); hold(ax,'on');
        xlim(ax,[45 120]); ax.XTick = [45 60 80 100 120];
        limits = [-.005 .205];
        if row == 2, limits = [0 .10]; end
        ylim(ax,limits);
        xline(ax,50,'--','Color',[.4 .4 .4],'LineWidth',.8,'HandleVisibility','off');
        for t = [60 80 100]
            xline(ax,t,':','Color',[.72 .72 .72],'LineWidth',.65,'HandleVisibility','off');
        end
        if row == 1
            ids = 2:3; quantity = "Estimated xi^2 coefficient";
            if col == 1, ids = [ids 4]; end
        else
            ids = 1:3; quantity = "Common-grid prediction RMSE";
        end
        for m = ids
            selectedQuantity = quantity;
            if m == 4, selectedQuantity = "True xi^2 coefficient"; end
            block = values(values.scenario == scenarios(col) & ...
                values.model == names{m} & values.quantity == selectedQuantity,:);
            assert(~isempty(block) && all(block.value >= limits(1) & block.value <= limits(2)), ...
                'study4:PlotClipping','Every archived excursion must fit in the common vertical limits.');
            for segment = unique(block.segment).'
                part = block(block.segment == segment,:);
                args = {'Color',colors(m,:),'LineStyle',styles{m},'DisplayName',names{m}};
                if m == 4
                    line = stairs(ax,part.timeSeconds,part.value,args{:},'LineWidth',1.15);
                elseif row == 1
                    line = plot(ax,part.timeSeconds,part.value,args{:},'LineWidth',1.2);
                else
                    % Separate actual pre/post segments preserve both the
                    % 49 s and 50 s samples without connecting across them.
                    line = plot(ax,part.timeSeconds,part.value,args{:},'LineWidth',.7, ...
                        'Marker',markers{m},'MarkerSize',1.8,'MarkerFaceColor','white');
                end
                assert(isequal(line.XData,part.timeSeconds.') && isequal(line.YData,part.value.'), ...
                    'study4:PlotValues','Displayed points must be exact archived values, without resampling.');
                if col == 1 && (row == 2 || m == 4), keyLines(m) = line; end
            end
        end
        if row == 1
            ax.YTick = 0:.05:.20;
            headings = {'(a) Represented x^2 change','(b) Unrepresented sine change'};
            title(ax,headings{col},'FontSize',10,'FontWeight','normal');
            ax.XTickLabel = [];
            if col == 1, ylabel(ax,'Estimated \xi^2 coefficient'); end
        else
            ax.YTick = 0:.02:.10; ytickformat(ax,'%.2f'); xlabel(ax,'Time (s)');
            if col == 1, ylabel(ax,'Common-grid prediction RMSE'); end
        end
    end
end
key = legend(axesList(2,1),keyLines,names,'Orientation','horizontal','NumColumns',2, ...
    'Box','off','FontName','Times New Roman','FontSize',9.5,'Interpreter','none');
key.ItemTokenSize = [20 9]; key.Units = 'normalized';
drawnow;
key.Position(1:2) = [(1-key.Position(3))/2,.932];
for row = 1:2
    for col = 1:2, axesList(row,col).Position = positions{row,col}; end
end
assert(numel(findall(fig,'Type','axes')) == 4,'study4:PanelCount','Exactly four panels are required.');
assert(key.Position(1) >= 0 && key.Position(2)+key.Position(4) <= 1, ...
    'study4:LegendLayout','The shared legend must fit at the final manuscript size.');
if ~isfolder(figureDir), mkdir(figureDir); end
csvFile = fullfile(figureDir,'study4_main_values.csv');
write_values(csvFile,values);
assert(isequal(readtable(csvFile,'TextType','string'),values), ...
    'study4:CsvValues','CSV must preserve every plotted double exactly.');
write_caption(fullfile(figureDir,'study4_main_caption.tex'));
drawnow;
print(fig,fullfile(figureDir,'study4_main.pdf'),'-dpdf','-vector');
print(fig,fullfile(figureDir,'study4_main.png'),'-dpng','-r300');
fprintf('Study 4 journal figure: four panels at 137.07 mm width, 9.5 pt axes.\n');
fprintf('4,200 exact plotted values; 720 saved grid scores cross-checked against grid.csv.\n');
fprintf('Coefficient endpoint 119.9 s; snapshot endpoint 119 s; no 49-to-50 s grid connection.\n');
end
function style_axes(ax)
set(ax,'FontName','Times New Roman','FontSize',9.5,'LineWidth',.7, ...
    'Box','off','TickDir','out','TickLength',[.016 .016], ...
    'XGrid','off','YGrid','off','XColor',[.15 .15 .15],'YColor',[.15 .15 .15], ...
    'XMinorTick','off','YMinorTick','off','Layer','top');
end
function write_values(filename,values)
file = fopen(filename,'w');
assert(file ~= -1,'study4:FigureWrite','Cannot write plotted values.');
cleanup = onCleanup(@() fclose(file));
fprintf(file,'scenario,model,timeSeconds,quantity,value,segment\n');
for j = 1:height(values)
    r = values(j,:);
    fprintf(file,'%s,%s,%.17g,%s,%.17g,%d\n',r.scenario,r.model,r.timeSeconds,r.quantity,r.value,r.segment);
end
end
function write_caption(filename)
% Verbatim short caption from the supplied study4_results_draft.tex.
file = fopen(filename,'w');
assert(file ~= -1,'study4:FigureWrite','Cannot write supplied caption.');
cleanup = onCleanup(@() fclose(file));
fprintf(file,['\\caption{Study 4: represented $x^2$ change (left) and unrepresented sine\n' ...
    'change (right). Top: estimated $\\xi^2$ coefficient, with its true value\n' ...
    'shown only in the represented case. Bottom: nonlinear prediction RMSE\n' ...
    'on the common grid. The plant changes at 50~s; dotted lines mark later\n' ...
    'reference changes. The known-model grid error is zero and omitted.}\n']);
end
