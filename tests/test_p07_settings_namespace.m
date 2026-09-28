function tests=test_p07_settings_namespace
tests=functiontests(localfunctions);
end
function setupOnce(t)
t.TestData.path=path;root=fileparts(fileparts(mfilename('fullpath')));
addpath(root,fullfile(root,'src'),fullfile(root,'studies/p07'));
t.TestData.refs=ejc_reference_sources;t.TestData.base=load(fullfile(t.TestData.refs.study6,'settings.mat'));
end
function teardownOnce(t),path(t.TestData.path);end
function test_outer_order_passes_and_descendants_execute(t)
b=t.TestData.base;a=orderfields(b,flipud(fieldnames(b)));
r=compare(t,a,b,t.TestData.refs,true);verifyTrue(t,r.passed);
verifyGreaterThan(t,r.files.leafChecks,0);verifyEqual(t,r.files.maximumAbsoluteDifference,0);
r=compare(t,a,b,t.TestData.refs,false);verifyTrue(t,r.passed); % Actual old nonportable behavior.
end
function test_scope_is_only_exact_outer_F2710(t)
b=t.TestData.base;a=orderfields(b,flipud(fieldnames(b)));c=context(t.TestData.refs);rule=struct('coverage_id',"F2710");
v=ejc_settings_namespace(a,b,rule,c,"value",["sources";"cfg"],["cfg";"sources"]);
verifyTrue(t,v.applied);verifyTrue(t,v.descendantChecksStillRequired);verifyEqual(t,v.currentSources.checks,5);
for k=1:4
 x=c;rr=rule;q="value";
 if k==1,x.study="study5";elseif k==2,x.file="other/settings.mat";elseif k==3,rr.coverage_id="F2711";else,q="value(1).cfg";end
 v=ejc_settings_namespace(a,b,rr,x,q,["sources";"cfg"],["cfg";"sources"]);verifyFalse(t,v.applied);
end
end
function test_missing_extra_renamed_class_shape(t)
b=t.TestData.base;
cases={rmfield(b,'cfg'),rmfield(b,'sources'),setfield(b,'extra',1), ...
    struct('configuration',b.cfg,'sources',{b.sources}),struct('cfg',1,'sources',{b.sources})}; %#ok<SFLD>
for k=1:numel(cases),r=compare(t,cases{k},b,t.TestData.refs,true);verifyFalse(t,r.passed);end
c=context(t.TestData.refs);rule=struct('coverage_id',"F2710");
verifyError(t,@()ejc_settings_namespace(1,b,rule,c,"value",["cfg";"sources"],["cfg";"sources"]),'ejc:SettingsNamespace');
verifyError(t,@()ejc_settings_namespace([b b],b,rule,c,"value",["cfg";"sources"],["cfg";"sources"]),'ejc:SettingsNamespace');
end
function test_nested_order_remains_exact(t)
b=t.TestData.base;a=b;a.cfg=orderfields(a.cfg,flipud(fieldnames(a.cfg)));
r=compare(t,a,b,t.TestData.refs,true);verifyFalse(t,r.passed);
verifyTrue(t,any(contains(r.failures.reason,'field order')));
a=b;a.sources{1}=orderfields(a.sources{1},flipud(fieldnames(a.sources{1})));
r=compare(t,a,b,t.TestData.refs,true);verifyFalse(t,r.passed);
a=b;a.sources([1 2])=a.sources([2 1]);r=compare(t,a,b,t.TestData.refs,true);verifyFalse(t,r.passed);
end
function test_scientific_descendants_fail_after_namespace_pass(t)
b=t.TestData.base;
for field=["tolerance","horizons","fitSteps","anchors","changeSelection","Ts"]
 a=b;
 if ischar(a.cfg.(field)),a.cfg.(field)=[a.cfg.(field),' changed'];else,a.cfg.(field)(1)=a.cfg.(field)(1)+1;end
 r=compare(t,a,b,t.TestData.refs,true);verifyFalse(t,r.passed);
 verifyGreaterThan(t,r.files.leafChecks,0);verifyTrue(t,any(endsWith(r.failures.quantity,"."+field)));
end
a=b;a.cfg.horizons=fliplr(a.cfg.horizons);r=compare(t,a,b,t.TestData.refs,true);verifyFalse(t,r.passed);
a=b;a.cfg.fitSteps=single(a.cfg.fitSteps);r=compare(t,a,b,t.TestData.refs,true);verifyFalse(t,r.passed);
a=b;a.cfg.fitSteps=a.cfg.fitSteps.';r=compare(t,a,b,t.TestData.refs,true);verifyFalse(t,r.passed);
end
function test_mutated_seed_cannot_hide_behind_valid_own_source(t)
b=t.TestData.base;a=b;refs=t.TestData.refs;
f=t.applyFixture(matlab.unittest.fixtures.TemporaryFolderFixture);
parent=fullfile(f.Folder,a.cfg.sources{1});mkdir(parent);refs.study1=parent;
a.sources{1}.cfg.confirmation.inputSeed=a.sources{1}.cfg.confirmation.inputSeed+1;
saved=a.sources{1};save(fullfile(parent,'settings.mat'),'-struct','saved');
r=compare(t,a,b,refs,true);verifyFalse(t,r.passed);verifyGreaterThan(t,r.files.leafChecks,0);
verifyTrue(t,any(contains(r.failures.quantity,'inputSeed')));
end
function test_metadata_does_not_waive_wrong_missing_stale_sources(t)
b=t.TestData.base;refs=t.TestData.refs;
a=b;a.cfg.sources{1}='wrong';verifyError(t,@()ejc_settings_source_binding(a,refs),'ejc:SettingsSource');
verifyError(t,@()ejc_settings_source_binding(b,rmfield(refs,'study1')),'ejc:SettingsSource');
f=t.applyFixture(matlab.unittest.fixtures.TemporaryFolderFixture);
parent=fullfile(f.Folder,b.cfg.sources{1});mkdir(parent);changed=refs;changed.study1=parent;
verifyError(t,@()ejc_settings_source_binding(b,changed),'ejc:SettingsSource');
saved=b.sources{1};saved.cfg.Ts=2*saved.cfg.Ts;save(fullfile(parent,'settings.mat'),'-struct','saved');
verifyError(t,@()ejc_settings_source_binding(b,changed),'ejc:SettingsSource');
a=b;a.cfg.sourceDirectories=cellfun(@(k)refs.(k),cellstr("study"+(1:5)),'UniformOutput',false);
a.cfg.sourceDirectories{1}=parent; % Admissible basename, wrong bound source.
verifyError(t,@()ejc_settings_source_binding(a,refs),'ejc:SettingsSource');
end
function test_original_protected_settings_are_read_only(t)
refs=t.TestData.refs;
verifyEqual(t,ejc_file_sha256(fullfile(refs.study6,'settings.mat')), ...
 '0307bf98df8a23ad9c9fa7ced53cea9eec3a8d8ae33e9a8b9fd6d2e0ba0cef0d');
end
function r=compare(t,a,b,parents,portable)
f=t.applyFixture(matlab.unittest.fixtures.TemporaryFolderFixture);
ca=fullfile(f.Folder,'a');cb=fullfile(f.Folder,'b');mkdir(ca);mkdir(cb);
save(fullfile(ca,'settings.mat'),'-struct','a');save(fullfile(cb,'settings.mat'),'-struct','b');
adapter=[];if portable,adapter=struct('contextForFile',@ctx);end
r=ejc_compare_results(struct('study6',ca),struct('study6',cb),fullfile(f.Folder,'out'),adapter);
 function c=ctx(info,x,y)
  c=info;c.rootA=x;c.rootB=y;c.sources=parents;c.references=t.TestData.refs;c.isCSV=false;c.rowIndex=NaN;
 end
end
function c=context(refs),c=struct('study',"study6",'file',"settings.mat",'sources',refs,'references',refs);end
