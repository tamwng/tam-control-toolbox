function figureDir = plot_study3(resultsDir,figureDir)
%PLOT_STUDY3 Six-panel figure from the saved noise-free pilot only.
% Run from the repository root; requires MATLAB only (tested R2026a).
% Exports a 137.07-by-135 mm vector PDF, 300 dpi PNG, exact plotted values,
% and the supplied short caption. Width matches the attached manuscript's
% text block; 9.5 pt fonts are retained at that width. No simulations run.
% CSV rows contain one time sample and all 13 traces, with descriptive
% column names. Frozen/known forgetting factors are deliberately absent.
root = fileparts(mfilename('fullpath'));
if nargin < 1, resultsDir = fullfile(root,'references','study3'); end
if nargin < 2, figureDir = []; end
figureDir = new_output_path('study3_figures',figureDir);
assert_output_writable(figureDir);
oldPath = path;
restorePath = onCleanup(@() path(oldPath));
addpath(fullfile(root,'studies','study3'));
source = char(java.io.File(resultsDir).getCanonicalPath());
destination = char(java.io.File(figureDir).getCanonicalPath());
assert(~strcmpi(source,destination) && ...
    ~startsWith(lower(destination),[lower(source),filesep]), ...
    'study3:ArchiveWrite','Derived exports must stay outside the pilot archive.');
values = study3_figure_data(resultsDir);

names = {'No forgetting','Fixed forgetting','Variable-rate forgetting', ...
    'Pretrained-frozen','Known model','True gain'};
colors = [.12 .38 .64;.77 .43 .08;0 .47 .36;.47 .31 .65;.15 .15 .15;.15 .15 .15];
styles = {'-','--','-.',':','-','--'};
widths = [1.15 1.25 1.25 1.25 .95 1.1];
scenarios = ["abrupt","drift"];
xLimits = [45 65;45 100];
preview = {[59 60],[59 60;79 80;99 100]};
positions = cell(3,2);
for row = 1:3
    positions{row,1} = [.145 .665-(row-1)*.28 .355 .225];
    positions{row,2} = [.61 .665-(row-1)*.28 .345 .225];
end
fig = figure('Visible','off','Color','white','Units','centimeters', ...
    'Position',[2 2 13.707 13.5],'PaperUnits','centimeters', ...
    'PaperPosition',[0 0 13.707 13.5],'PaperSize',[13.707 13.5]);
cleanup = onCleanup(@() close(fig));
if isprop(fig,'Scrollable'), fig.Scrollable = 'off'; end
axesList = gobjects(3,2); keyLines = gobjects(1,6);
for col = 1:2
    block = values(values.scenario == scenarios(col),:);
    for row = 1:3
        ax = axes(fig,'Position',positions{row,col}); axesList(row,col) = ax;
        style_axes(ax); hold(ax,'on');
        if row == 1
            data = block{:,3:7}; indices = 1:5;
        elseif row == 2
            data = block{:,8:12}; indices = [1:4 6];
        else
            data = block{:,13:15}; indices = 1:3;
        end
        limits = padded_limits(data);
        if row == 3, limits = [min(limits(1),.98),1.002]; end
        xlim(ax,xLimits(col,:)); ylim(ax,limits);
        for interval = preview{col}.'
            patch(ax,interval([1 2 2 1]),limits([1 1 2 2]),[.92 .92 .92], ...
                'EdgeColor','none','HandleVisibility','off');
        end
        xline(ax,50,':','Color',[.65 .65 .65],'LineWidth',.6,'HandleVisibility','off');
        if col == 2
            xline(ax,90,':','Color',[.65 .65 .65],'LineWidth',.6,'HandleVisibility','off');
        end
        if row == 1
            for tolerance = [-.04 .04]
                yline(ax,tolerance,':','Color',[.55 .55 .55],'LineWidth',.6, ...
                    'HandleVisibility','off');
            end
        end
        for j = 1:numel(indices)
            id = indices(j);
            args = {'Color',colors(id,:),'LineStyle',styles{id},'LineWidth',widths(id), ...
                'DisplayName',names{id}};
            if row == 3 || id == 6
                line = stairs(ax,block.timeSeconds,data(:,j),args{:});
            else
                line = plot(ax,block.timeSeconds,data(:,j),args{:});
            end
            assert(isequal(line.XData,block.timeSeconds.') && ...
                isequal(line.YData,data(:,j).'),'study3:PlotValues', ...
                'Every displayed trace must retain the exact recorded values and times.');
            assert(all(data(:,j) >= limits(1) & data(:,j) <= limits(2)), ...
                'study3:PlotClipping','No recorded excursion may be clipped.');
            if col == 1 && (row == 1 || id == 6), keyLines(id) = line; end
        end
        if col == 1
            ax.XTick = 45:5:65;
            labels = {'Tracking error, x_k - r_k','Input gain','Forgetting factor, \lambda_k'};
            ylabel(ax,labels{row});
        else
            ax.XTick = [45 60 80 100];
        end
        if row < 3, ax.XTickLabel = []; else, xlabel(ax,'Time (s)'); end
        if row == 1
            headings = {'(a) Abrupt gain change','(b) Gain drift'};
            title(ax,headings{col},'FontSize',10,'FontWeight','normal');
        end
    end
end
key = legend(axesList(1,1),keyLines,names,'Orientation','horizontal','NumColumns',3, ...
    'Box','off','FontName','Times New Roman','FontSize',9.5,'Interpreter','none');
key.ItemTokenSize = [17 9]; key.Units = 'normalized';
drawnow;
key.Position(1:2) = [(1-key.Position(3))/2,.933];
for row = 1:3
    for col = 1:2, axesList(row,col).Position = positions{row,col}; end
end
assert(numel(findall(fig,'Type','axes')) == 6,'study3:PanelCount','Exactly six panels are required.');
assert(key.Position(1) >= 0 && key.Position(2)+key.Position(4) <= 1, ...
    'study3:LegendLayout','Legend must fit at the final figure size.');
if ~isfolder(figureDir), mkdir(figureDir); end
csvFile = fullfile(figureDir,'study3_main_values.csv');
write_values(csvFile,values);
roundTrip = readtable(csvFile,'TextType','string');
assert(isequal(roundTrip,values),'study3:CsvValues','CSV must retain all plotted doubles exactly.');
write_caption(fullfile(figureDir,'study3_main_caption.tex'));
drawnow;
print(fig,fullfile(figureDir,'study3_main.pdf'),'-dpdf','-vector');
print(fig,fullfile(figureDir,'study3_main.png'),'-dpng','-r300');
fprintf('Study 3 journal figure: six panels at 137.07 mm width, 9.5 pt axes.\n');
fprintf('752 recorded times, 13 traces, 9,776 unchanged plotted values; trial 000 only.\n');
fprintf('Vector PDF, 300 dpi PNG, exact CSV, and supplied caption exported.\n');
end

function style_axes(ax)
set(ax,'FontName','Times New Roman','FontSize',9.5,'LineWidth',.7, ...
    'Box','off','TickDir','out','TickLength',[.016 .016], ...
    'XGrid','off','YGrid','off','XColor',[.15 .15 .15],'YColor',[.15 .15 .15], ...
    'XMinorTick','off','YMinorTick','off','Layer','top');
end

function limits = padded_limits(data)
low = min(data,[],'all'); high = max(data,[],'all');
padding = .08*max(high-low,1e-3);
limits = [low-padding,high+padding];
end

function write_values(filename,values)
file = fopen(filename,'w');
assert(file ~= -1,'study3:FigureWrite','Cannot write plotted values.');
cleanup = onCleanup(@() fclose(file));
fprintf(file,'%s\n',strjoin(values.Properties.VariableNames,','));
for j = 1:height(values)
    fprintf(file,'%s',values.scenario(j));
    fprintf(file,',%.17g',values{j,2:end});
    fprintf(file,'\n');
end
end

function write_caption(filename)
file = fopen(filename,'w');
assert(file ~= -1,'study3:FigureWrite','Cannot write supplied caption.');
cleanup = onCleanup(@() fclose(file));
fprintf(file,['\\caption{Study 3: noise-free shared-model responses to an abrupt gain\n' ...
    'change (left) and drift (right). Rows show tracking error, gain estimate,\n' ...
    'and forgetting factor. The known-model tracking reference and true gain\n' ...
    'are included. Shading marks reference-preview intervals.}\n']);
end
