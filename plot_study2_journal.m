function figureDir = plot_study2_journal(resultsDir,figureDir,rankCheckFile)
%PLOT_STUDY2_JOURNAL Two-panel figure and corrected saved-data rank report.
% Run at the repository root; requires MATLAB only (tested R2026a).
% Exports an 180-by-90 mm vector PDF, 300 dpi PNG, the exact 33 plotted values,
% and a separate numerical-rank report. No simulations or fitting are run.
% The archived pilot and original scores are read only. The supplied rank
% cross-check CSV is retained separately in results/study2_journal.
root = fileparts(mfilename('fullpath'));
if nargin < 1, resultsDir = fullfile(root,'results','study2_pilot_20260918'); end
if nargin < 2, figureDir = []; end
figureDir = ejc_output_path('study2_figures',figureDir);
ejc_assert_writable(figureDir);
if nargin < 3, rankCheckFile = fullfile(root,'results','study2_journal','gram_numerical_rank_check.csv'); end
oldPath = path;
restorePath = onCleanup(@() path(oldPath));
addpath(fullfile(root,'studies','study2'));
% Prevent derived exports from entering the archived source directory.
sourcePath = char(java.io.File(resultsDir).getCanonicalPath());
outputPath = char(java.io.File(figureDir).getCanonicalPath());
assert(~strcmpi(sourcePath,outputPath) && ...
    ~startsWith(lower(outputPath),[lower(sourcePath),filesep]), ...
    'study2:ArchiveWrite','Choose a separate derived-output directory.');
assert(isfile(rankCheckFile),'study2:MissingRankReference', ...
    'The supplied gram_numerical_rank_check.csv is required for cross-checking.');
values = study2_figure_data(resultsDir);
rankReport = study2_gram_report(resultsDir,rankCheckFile);

ids = ["A","E","O3","O5","P3","K"];
names = {'Affine','Exact sine','Odd cubic','Odd quintic','Complete cubic','Known model'};
colors = [.12 .38 .64;0 .47 .36;.47 .31 .65; ...
    .77 .43 .08;.73 .20 .22;.20 .20 .20];
markers = {'s','o','d','^','v','x'};
styles = {'-','-','--','-.',':','--'};
fig = figure('Visible','off','Color','white','Units','centimeters', ...
    'Position',[2 2 18 9],'PaperUnits','centimeters', ...
    'PaperPosition',[0 0 18 9],'PaperSize',[18 9]);
cleanup = onCleanup(@() close(fig));
if isprop(fig,'Scrollable'), fig.Scrollable = 'off'; end
positions = {[.085 .19 .365 .57],[.595 .19 .385 .57]};
ax = gobjects(1,2); lines = gobjects(1,6);
for panel = 1:2
    ax(panel) = axes(fig,'Position',positions{panel});
    style_axes(ax(panel)); hold(ax(panel),'on');
    panelCode = string(char('a'+panel-1));
    for j = 1:6
        block = sortrows(values(values.panel == panelCode & values.modelId == ids(j),:), ...
            'horizontalValue');
        if isempty(block), continue; end
        line = plot(ax(panel),block.horizontalValue,block.metricValue, ...
            'Color',colors(j,:),'LineStyle',styles{j},'LineWidth',1.2, ...
            'Marker',markers{j},'MarkerSize',4.5,'MarkerFaceColor','white', ...
            'DisplayName',names{j});
        if j == 2, line.MarkerFaceColor = colors(j,:); end
        if panel == 2, lines(j) = line; end
        assert(isequal(line.XData,block.horizontalValue.') && ...
            isequal(line.YData,block.metricValue.'),'study2:PlotValues', ...
            'The figure must use the exact source-table points.');
    end
end
set(ax(1),'XLim',[.19 1.16],'XTick',[.25 .70 1.10], ...
    'XTickLabel',{'0.25','0.70','1.10'},'YLim',[3e-6 3e-2], ...
    'YTick',10.^(-5:-2));
xlabel(ax(1),'Evaluation input bound, L');
ylabel(ax(1),'Held-out one-step RMSE');
title(ax(1),'(a) Held-out prediction','FontWeight','normal','FontSize',10.5);
set(ax(2),'XLim',[.14 1.06],'XTick',[.2 .6 1], ...
    'XTickLabel',{'0.2','0.6','1.0'},'YLim',[1.5e-6 4e-2], ...
    'YTick',10.^(-6:-2));
xlabel(ax(2),'Reference amplitude, A_r');
ylabel(ax(2),'Tracking RMSE, 20 \leq t < 80 s');
title(ax(2),'(b) Post-transient tracking','FontWeight','normal','FontSize',10.5);
key = legend(ax(2),lines,names,'Orientation','horizontal','NumColumns',3, ...
    'Box','off','FontName','Times New Roman','FontSize',9.5,'Interpreter','none');
key.ItemTokenSize = [20 9];
key.Units = 'normalized';
drawnow;
key.Position(1:2) = [(1-key.Position(3))/2,.855];
for j = 1:2, ax(j).Position = positions{j}; end
assert(numel(findall(fig,'Type','axes')) == 2,'study2:PanelCount','Exactly two panels are required.');
if ~isfolder(figureDir), mkdir(figureDir); end
write_values(fullfile(figureDir,'study2_main_values.csv'),values);
writetable(rankReport,fullfile(figureDir,'study2_conditioning_corrected.csv'));
drawnow;
print(fig,fullfile(figureDir,'study2_main.pdf'),'-dpdf','-vector');
print(fig,fullfile(figureDir,'study2_main.png'),'-dpng','-r300');
fprintf('Study 2 journal package: two panels, 33 source-table points, corrected rank report.\n');
fprintf('Principal scores verified against 600 archived samples on 20 <= t < 80 s.\n');
end

function style_axes(ax)
set(ax,'FontName','Times New Roman','FontSize',9.5,'LineWidth',.7, ...
    'Box','off','TickDir','out','TickLength',[.012 .012], ...
    'YScale','log','YMinorTick','off','XGrid','off','YGrid','on', ...
    'GridColor',[.6 .6 .6],'GridAlpha',.17,'XMinorGrid','off','YMinorGrid','off', ...
    'XColor',[.15 .15 .15],'YColor',[.15 .15 .15]);
end

function write_values(filename,values)
% Seventeen significant digits retain the plotted double values exactly.
file = fopen(filename,'w');
assert(file ~= -1,'study2:FigureValuesWrite','Cannot write plotted values.');
cleanup = onCleanup(@() fclose(file));
fprintf(file,['panel,model,modelId,horizontalVariable,horizontalValue,metric,' ...
    'metricValue,fittingTransitions,window,scoredSamples\n']);
for j = 1:height(values)
    r = values(j,:);
    fprintf(file,'%s,%s,%s,%s,%.17g,%s,%.17g,%.17g,%s,%d\n', ...
        r.panel,r.model,r.modelId,r.horizontalVariable,r.horizontalValue, ...
        r.metric,r.metricValue,r.fittingTransitions,r.window,r.scoredSamples);
end
end
