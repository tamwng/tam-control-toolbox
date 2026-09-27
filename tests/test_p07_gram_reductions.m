function tests=test_p07_gram_reductions
tests=functiontests(localfunctions);
end
function setupOnce(t)
root=fileparts(fileparts(mfilename('fullpath')));t.TestData.path=path;
addpath(root,fullfile(root,'src'),fullfile(root,'studies/study1'),fullfile(root,'studies/p07'));
s=ejc_reference_sources;file="tables/run_diagnostics.csv";sourcePath=string(fullfile(s.study1,file));
T=ejc_csv_read(sourcePath,"study1",file);
c=struct('study',"study1",'file',file,'source',sourcePath,'reference',sourcePath, ...
    'sourceSHA256',string(ejc_file_sha256(sourcePath)),'referenceSHA256',string(ejc_file_sha256(sourcePath)), ...
    'rootA',T,'rootB',T,'sources',s,'references',s,'isCSV',true, ...
    'parentCache',containers.Map('KeyType','char','ValueType','any'),'rowIndex',1);
t.TestData.c=c;t.TestData.row=T(1,:);
end
function teardownOnce(t)
path(t.TestData.path);
end
function test_historical_reduction_retains_raw_value_and_qualification(t)
d=t.TestData;x=d.row.gramConditionMax;
v=ejc_portable_leaf(x,x,"value.gramConditionMax",d.row,d.row,d.c);
verifyTrue(t,v.passed,v.reason);verifyEqual(t,v.status,"QUALIFIED_UNRESOLVED_GRAM_REDUCTION");
verifyEqual(t,v.rawCurrent,x);verifyEqual(t,v.rawReference,x);verifyGreaterThan(t,v.qualifiedCount,0);
verifyTrue(t,v.parents.ownCurrentDefinition && v.parents.ownReferenceDefinition);
end
function test_missing_historical_identity_and_nan_do_not_qualify(t)
d=t.TestData;x=d.row.gramConditionMax;c=d.c;c.referenceSHA256="missing identity";
v=ejc_portable_leaf(x,x,"value.gramConditionMax",d.row,d.row,c);verifyFalse(t,v.passed);
v=ejc_portable_leaf(NaN,NaN,"value.gramConditionMax",d.row,d.row,d.c);verifyFalse(t,v.passed);
end
function test_unrounded_p06_historical_scope_has_same_parent_requirement(t)
d=t.TestData;s=d.c.sources;file=string(fullfile(s.p06,'runs/baseline_A_000.mat'));z=load(file);
c=d.c;c.study="p06";c.file="runs/baseline_A_000.mat";c.source=file;c.reference=file;c.rootA=z;c.rootB=z;c.isCSV=false;
c.sourceSHA256=string(ejc_file_sha256(file));c.referenceSHA256=c.sourceSHA256;
row=z.scores.diagnostics;x=row.gramConditionMax;
v=ejc_portable_leaf(x,x,"value(1).scores(1).diagnostics(1).gramConditionMax",row,row,c);
verifyTrue(t,v.passed,v.reason);verifyEqual(t,v.status,"QUALIFIED_UNRESOLVED_GRAM_REDUCTION");
c.referenceSHA256="missing identity";
v=ejc_portable_leaf(x,x,"value(1).scores(1).diagnostics(1).gramConditionMax",row,row,c);verifyFalse(t,v.passed);
end
