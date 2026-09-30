function figureDir = plot_study1_journal(resultsDir,figureDir)
%PLOT_STUDY1_JOURNAL Two-panel publication figure from saved Study 1 summaries.
% Run from the repository root; requires MATLAB only (tested R2026a).
% No simulations, fitting, or metric calculations are repeated. Both panels
% use the 40 paired noisy confirmation trials. Panel (b) uses the original
% whole-run score, as in study1_results_draft.tex, including all transients.
% Exports an 180-by-90 mm vector PDF, 300 dpi PNG, and LaTeX caption.
% Optional arguments select source records and a fresh figure directory.

root = fileparts(mfilename('fullpath'));
if nargin < 1
    resultsDir = fullfile(root,'results','study1_candidate_20260917');
end
if nargin < 2, figureDir = []; end
figureDir = ejc_output_path('study1_figures',figureDir);
ejc_assert_writable(figureDir);
source = char(java.io.File(resultsDir).getCanonicalPath());
destination = char(java.io.File(figureDir).getCanonicalPath());
assert(~strcmpi(source,destination) && ...
    ~startsWith(lower(destination),[lower(source),filesep]), ...
    'study1:ArchiveWrite','Derived exports must stay outside the source archive.');
tableDir = fullfile(resultsDir,'tables');
learning = readtable(fullfile(tableDir,'initialization_noisy_summaries.csv'), ...
    'TextType','string');
tracking = readtable(fullfile(tableDir,'noisy_summaries.csv'),'TextType','string');
learning = learning(learning.campaign == "confirmation" & ...
    learning.metric == "predictionRMS",:);
tracking = tracking(tracking.campaign == "confirmation" & ...
    tracking.window == "whole" & tracking.metric == "trackingRMS",:);

ids = ["A","S","R","P2","W","K"];
names = {'Affine','Shared','Relaxed','Quadratic','Incorrect sharing','Known model'};
steps = [25;50;100;200];
prediction = cell(1,5);
for j = 1:5
    row = sortrows(learning(learning.model == ids(j),:),'fittingTransitions');
    assert(isequal(row.fittingTransitions,steps) && all(row.attempted == 40) && ...
        all(row.finiteScores == 40),'study1:IncompleteFigureData', ...
        'Panel (a) requires four checkpoints and 40 finite scores per model.');
    check_quartiles(row);
    prediction{j} = row;
end
for j = 1:6
    row = tracking(tracking.model == ids(j),:);
    assert(height(row) == 1 && row.attempted == 40 && row.completed == 40 && ...
        row.finiteScores == 40,'study1:IncompleteFigureData', ...
        'Panel (b) requires 40 complete finite whole-run scores per model.');
    check_quartiles(row);
end
known = learning(learning.model == "K",:);
assert(height(known) == 4 && all(isfinite(known.median)));

colors = [0.12 0.38 0.64; 0.00 0.47 0.36; 0.47 0.31 0.65; ...
          0.77 0.43 0.08; 0.73 0.20 0.22; 0.25 0.25 0.25];
markers = {'s','o','d','^','v','o'};
styles = {'-','-','--','-.',':'};
fig = figure('Visible','off','Color','white','Units','centimeters', ...
    'Position',[2,2,18,9],'PaperUnits','centimeters', ...
    'PaperPosition',[0,0,18,9],'PaperSize',[18,9]);
cleanup = onCleanup(@() close(fig));
if isprop(fig,'Scrollable'), fig.Scrollable = 'off'; end

left = axes(fig,'Position',[0.085,0.24,0.33,0.58]);
style_axes(left); hold(left,'on');
lines = gobjects(1,5);
for j = 1:5
    row = prediction{j};
    lines(j) = errorbar(left,steps,row.median,row.median-row.q1, ...
        row.q3-row.median,'Color',colors(j,:),'LineStyle',styles{j}, ...
        'LineWidth',1.2,'Marker',markers{j},'MarkerSize',4.2, ...
        'MarkerFaceColor','white','CapSize',3,'DisplayName',names{j});
end
lines(2).MarkerFaceColor = colors(2,:);
lines(2).LineWidth = 1.6;
set(left,'YScale','log','XLim',[15,212],'XTick',steps, ...
    'YLim',[1e-4,1e-1],'YTick',[1e-4,1e-3,1e-2,1e-1], ...
    'YMinorTick','off');
xlabel(left,'Identification transitions');
ylabel(left,'Held-out one-step RMSE');
title(left,'(a) Held-out prediction','FontWeight','normal','FontSize',10.5);

right = axes(fig,'Position',[0.53,0.24,0.455,0.58]);
style_axes(right); hold(right,'on');
for j = 1:6
    row = tracking(tracking.model == ids(j),:);
    errorbar(right,j,row.median,row.median-row.q1,row.q3-row.median, ...
        'Color',colors(j,:),'LineStyle','none','LineWidth',1.3, ...
        'Marker',markers{j},'MarkerSize',4.2,'MarkerFaceColor',colors(j,:), ...
        'CapSize',6);
end
set(right,'XLim',[0.5,6.5],'XTick',1:6,'XTickLabel',[], ...
    'YLim',[0.045,0.080],'YTick',0.05:0.01:0.08);
ytickformat(right,'%.2f');
ylabel(right,'Whole-run tracking RMSE');
title(right,'(b) Noisy closed-loop tracking','FontWeight','normal','FontSize',10.5);
labels = {{'Affine','(3)'},{'Shared','(3)'},{'Relaxed','(4)'}, ...
    {'Quadratic','(6)'},{'Incorrect','sharing (3)'},{'Known','model'}};
for j = 1:6
    text(right,j,0.0438,labels{j},'HorizontalAlignment','center', ...
        'VerticalAlignment','top','FontName','Times New Roman', ...
        'FontSize',9,'Interpreter','none','Clipping','off');
end

key = legend(left,lines,names(1:5),'Orientation','horizontal', ...
    'NumColumns',5,'Box','off','FontName','Times New Roman','FontSize',9, ...
    'Interpreter','none');
key.ItemTokenSize = [16,9];
key.Units = 'normalized';
drawnow;
key.Position(1:2) = [(1-key.Position(3))/2,0.915];
% A shared legend is outside the data panels; restore the fixed panel sizes.
left.Position = [0.085,0.24,0.33,0.58];
annotation(fig,'textbox',[0.085,0.015,0.895,0.06], ...
    'String','40 paired trials; symbols: median; bars: interquartile range', ...
    'FontName','Times New Roman','FontSize',9,'HorizontalAlignment','center', ...
    'VerticalAlignment','middle','EdgeColor','none','Interpreter','none');

if ~isfolder(figureDir), mkdir(figureDir); end
drawnow;
print(fig,fullfile(figureDir,'study1_main.pdf'),'-dpdf','-vector');
print(fig,fullfile(figureDir,'study1_main.png'),'-dpng','-r300');
write_caption(fullfile(figureDir,'study1_main_caption.tex'),max(known.median));
fprintf('Study 1 journal figure exported: vector PDF, 300 dpi PNG, and caption.\n');
fprintf('Two panels; original confirmation summaries; no numerical results changed.\n');
end

function style_axes(ax)
set(ax,'FontName','Times New Roman','FontSize',9.5,'LineWidth',0.7, ...
    'Box','off','TickDir','out','TickLength',[0.012,0.012], ...
    'XGrid','off','YGrid','on','GridColor',[0.6,0.6,0.6],'GridAlpha',0.17, ...
    'XColor',[0.15,0.15,0.15],'YColor',[0.15,0.15,0.15], ...
    'XMinorGrid','off','YMinorGrid','off');
end

function check_quartiles(row)
values = [row.q1,row.median,row.q3];
assert(all(isfinite(values),'all') && all(values > 0,'all') && ...
    all(row.q1 <= row.median & row.median <= row.q3), ...
    'study1:InvalidFigureData','Expected finite positive ordered quartiles.');
end

function write_caption(filename,knownFloor)
file = fopen(filename,'w');
assert(file ~= -1,'study1:CaptionWrite','Cannot write the figure caption.');
cleanup = onCleanup(@() fclose(file));
fprintf(file,'%% Include study1_main.pdf at width=180mm (two-column figure).\n');
fprintf(file,'\\caption{Study 1: structural information, identification, and closed-loop tracking.\n');
fprintf(file,['(a) One-step prediction RMSE on the same independent, noise-free\n' ...
    '600-transition evaluation record after 25, 50, 100, and 200 identification\n' ...
    'transitions. Symbols and bars summarize the 40 paired noisy fits by their\n' ...
    'median and interquartile range. The logarithmic axis excludes the known-model\n']);
exponent = floor(log10(knownFloor));
fprintf(file,'reference, whose held-out RMSE is $%.2f \\times 10^{%d}$ (numerical roundoff).\n', ...
    knownFloor/10^exponent,exponent);
fprintf(file,['(b) Original whole-run tracking RMSE over $0 \\leq t < 120$ s for\n' ...
    '40 paired noisy closed-loop trials, with all reference transitions retained.\n' ...
    'Symbols denote medians and bars the interquartile ranges; some ranges are\n' ...
    'narrower than the symbols. Parentheses give the number of estimated\n' ...
    'coefficients; the known model performs no identification.\n' ...
    'Shared and Incorrect sharing impose the correct and opposite-sign coupling\n' ...
    'relations, respectively; Relaxed estimates the coupling coefficients\n' ...
    'independently, and Quadratic uses the complete quadratic dictionary.\n' ...
    'The correctly shared model improves prediction at fixed coefficient count\n' ...
    'and improves tracking relative to the affine model. Additional coefficients\n' ...
    'do not improve held-out prediction here and yield little further reduction\n' ...
    'in whole-run tracking RMSE.}\n']);
end
