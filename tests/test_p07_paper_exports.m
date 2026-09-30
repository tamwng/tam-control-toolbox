function tests=test_p07_paper_exports
tests=functiontests(localfunctions);
end
function setupOnce(t)
root=fileparts(fileparts(mfilename('fullpath')));
if ~isfile(fullfile(root,'generate_results.m')),root=fileparts(root);end
t.TestData.path=path;addpath(root,fullfile(root,'studies/p07'));
t.TestData.sources=ejc_reference_sources;
f=t.applyFixture(matlab.unittest.fixtures.TemporaryFolderFixture);
t.TestData.base=fullfile(f.Folder,'paper_exports');
ejc_paper_report(t.TestData.sources,t.TestData.sources,t.TestData.base);
end
function teardownOnce(t)
path(t.TestData.path);
end
function test_all_exports_link_to_explicit_saved_sources(t)
s=t.TestData.sources;base=t.TestData.base;z=load(fullfile(base,'paper_report.mat'),'report');
r=ejc_paper_export_checks(s,s,base,z.report);
verifyTrue(t,r.passed);verifyEqual(t,r.csvFamilies,13);verifyEqual(t,r.fieldComparisons,21016);
verifyTrue(t,all([r.links.passed]));
end
function test_changed_export_is_not_accepted_as_a_source_copy(t)
f=t.applyFixture(matlab.unittest.fixtures.TemporaryFolderFixture);base=t.TestData.base;
files=[dir(fullfile(base,'*.csv'));dir(fullfile(base,'paper_report.mat'))];
for file=files.',copyfile(fullfile(file.folder,file.name),fullfile(f.Folder,file.name));end
name="paper_A17_study1_control.csv";file=fullfile(f.Folder,name);
T=ejc_csv_read(file,"paper",name);T.medianDifference(1)=T.medianDifference(1)+1e-3;writetable(T,file);
z=load(fullfile(f.Folder,'paper_report.mat'),'report');s=t.TestData.sources;
r=ejc_paper_export_checks(s,s,f.Folder,z.report);verifyFalse(t,r.passed);
ix=string({r.links.file})==name;verifyFalse(t,r.links(ix).passed);
end
