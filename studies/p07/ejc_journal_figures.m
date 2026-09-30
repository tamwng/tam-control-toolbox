function report=ejc_journal_figures(output,sources,portable)
%EJC_JOURNAL_FIGURES Export six study figures from saved data.
% Portable mode binds the Study 2 rank report to its canonical parents.
% Default calls use the strict plotters. No control trajectories are run.
if nargin<3,portable=false;end
assert(islogical(portable) && isscalar(portable),'ejc:FigureMode','Expected explicit logical mode.');
report=struct('passed',false,'figureCount',0,'portableStudy2',portable);
for s=1:6
    key=sprintf('study%d',s);target=fullfile(output,'figures',key);
    if portable && s==2
        reference=ejc_reference_sources;
        report.study2=ejc_study2_portable_report(sources.study2,reference.study2,target);
        assert(report.study2.passed,'ejc:Study2FigureSource','Required B2 reporting checks failed.');
    else
        runner=str2func(sprintf('plot_study%d_journal',s));
        runner(sources.(key),target);
    end
    report.figureCount=report.figureCount+1;
end
report.passed=true;
end
