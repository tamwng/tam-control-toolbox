function tests=test_p07_evidence_identity
tests=functiontests(localfunctions);
end
function setupOnce(t)
t.TestData.oldPath=path;root=fileparts(fileparts(mfilename('fullpath')));
addpath(root,fullfile(root,'src'),fullfile(root,'studies/p07'),fullfile(root,'studies/study1'));
s=ejc_reference_sources;t.TestData.sources=s;
t.TestData.source=fullfile(s.study1,'data/confirmation_S_000.mat');
z=load(t.TestData.source,'result');t.TestData.run=z.result;
z=load(fullfile(s.study1,'settings.mat'),'cfg');t.TestData.cfg=z.cfg;
end
function teardownOnce(t)
path(t.TestData.oldPath);
end
function test_recording_preserves_verdict_and_keeps_matrix_details(t)
d=t.TestData;r=d.run;
plain=ejc_pair_run_screen(r,r,"study1",d.cfg,r.fit,r.fit,"F3914");
[recorded,details]=ejc_pair_run_screen(r,r,"study1",d.cfg,r.fit,r.fit,"F3914");
verifyEqual(t,recorded,plain);verifyTrue(t,recorded.passed);
expected=nnz([recorded.gramRows.qualifiedCount]>0 | [recorded.gramRows.status]=="EXACT_STRUCTURAL_ZERO_GRAM");
verifyEqual(t,numel(details),expected);verifyGreaterThan(t,expected,0);
j=find([details.index]==1067);verifyNumElements(t,j,1);
verifyEqual(t,details(j).actual.matrix,r.gram(:,:,1067));
verifyEqual(t,details(j).actual.singularValues,svd(r.gram(:,:,1067)));
verifyEqual(t,details(j).reference.storedCondition,r.gramCondition(1067));
bad=r;bad.covarianceCondition(1)=2*bad.covarianceCondition(1);
plain=ejc_pair_run_screen(bad,r,"study1",d.cfg,r.fit,r.fit,"F3914");
[recorded,details]=ejc_pair_run_screen(bad,r,"study1",d.cfg,r.fit,r.fit,"F3914");
verifyEqual(t,recorded,plain);verifyFalse(t,recorded.passed);
verifyEqual(t,details.kind,"covariance");verifyEqual(t,details.index,1);
end
function test_dispatch_saves_bound_details_and_reuses_only_same_invocation(t)
d=t.TestData;r=d.run;f=t.applyFixture(matlab.unittest.fixtures.TemporaryFolderFixture);
cache=containers.Map('KeyType','char','ValueType','any');
cache('P07_MATRIX_EVIDENCE_DIRECTORY')=f.Folder;
cache('P07_INPUT_IDENTITY_SHA256')="synthetic-unit-input-identity";
info=struct('study',"study1",'file',"data/confirmation_S_000.mat", ...
    'source',d.source,'reference',d.source);
c=ejc_portable_context(info,struct('result',r),struct('result',r),d.sources,d.sources,[],[],cache);
v=ejc_portable_leaf(r.gramCondition,r.gramCondition,"value(1).result(1).gramCondition",r,r,c);
verifyTrue(t,v.passed,v.reason);verifyTrue(t,isfile(v.parents.matrixEvidenceFile));
verifyEqual(t,string(ejc_file_sha256(v.parents.matrixEvidenceFile)),v.parents.matrixEvidenceSHA256);
z=load(v.parents.matrixEvidenceFile,'metadata','details');
verifyEqual(t,z.metadata.sourceSHA256,string(ejc_file_sha256(d.source)));
verifyEqual(t,z.metadata.inputIdentitySHA256,"synthetic-unit-input-identity");
verifyGreaterThan(t,numel(z.details),0);
again=ejc_portable_leaf(r.gramCondition,r.gramCondition,"value(1).result(1).gramCondition",r,r,c);
verifyEqual(t,again,v);verifyEqual(t,numel(dir(fullfile(f.Folder,'*.mat'))),1);
end
function test_input_snapshot_detects_changed_bytes_and_added_parent(t)
f=t.applyFixture(matlab.unittest.fixtures.TemporaryFolderFixture);
value=1;save(fullfile(f.Folder,'settings.mat'),'value');s=struct('study1',f.Folder);
a=ejc_input_snapshot(s,s);b=ejc_input_snapshot(s,s);verifyEqual(t,a,b);
value=2;save(fullfile(f.Folder,'settings.mat'),'value');b=ejc_input_snapshot(s,s);
verifyFalse(t,isequaln(a,b));verifyEqual(t,string({a.relativePath}),["settings.mat","settings.mat"]);
save(fullfile(f.Folder,'new_parent.mat'),'value');c=ejc_input_snapshot(s,s);
verifyEqual(t,numel(c),4);verifyFalse(t,isequaln(b,c));
verifyError(t,@()ejc_input_snapshot(struct('study1',fullfile(f.Folder,'missing')),s),'ejc:MissingSource');
end
