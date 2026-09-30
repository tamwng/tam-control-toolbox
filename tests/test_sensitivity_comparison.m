function tests = test_sensitivity_comparison
%TEST_SENSITIVITY_COMPARISON Exact input binding and fixed manifest ordering.
% Small saved fixtures only; no controller or sensitivity campaign runs.
tests=functiontests(localfunctions);
end
function setupOnce(t)
t.TestData.context=study_context;
end
function teardownOnce(t)
t.TestData.context=[];
end
function testHeaderOnlyDifference(t)
[a,b]=records_fixture(t);
fid=fopen(a,'r+');assert(fid>=0);fwrite(fid,'MATLAB 5.0 MAT-file, synthetic timestamp difference','char');fclose(fid);
proof=sensitivity_record_identity(a,b);
verifyTrue(t,proof.passed);
verifyNotEqual(t,proof.currentSHA256,proof.referenceSHA256);
end
function testChangedValueRejected(t)
[a,b]=records_fixture(t);z=load(a);records=z.records;records.u(1)=records.u(1)+eps;
save(a,'records','-v7');
verifyError(t,@()sensitivity_record_identity(a,b),'study:SensitivityRecordIdentity');
end
function testChangedClassRejected(t)
[a,b]=records_fixture(t);z=load(a);records=z.records;records.u=single(records.u);
save(a,'records','-v7');
verifyError(t,@()sensitivity_record_identity(a,b),'study:SensitivityRecordIdentity');
end
function testShapeAndVariablesRejected(t)
[a,b]=records_fixture(t);z=load(a);records=z.records;records.u=records.u.';
save(a,'records','-v7');
verifyError(t,@()sensitivity_record_identity(a,b),'study:SensitivityRecordIdentity');
records=z.records;extra=0;save(a,'records','extra','-v7');
verifyError(t,@()sensitivity_record_identity(a,b),'study:SensitivityRecordIdentity');
end
function testMissingInputRejected(t)
[a,b]=records_fixture(t);
verifyError(t,@()sensitivity_record_identity(a,[b '.absent']),'study:ReferenceUnavailable');
end
function testOwnHashBinding(t)
c=hash_context;
a=string(c.sensitivityRecords.currentSHA256);b=string(c.sensitivityRecords.referenceSHA256);
v=verification_portable_leaf(a,b,"value.recordSHA256",c.bindingA.values,c.bindingB.values,c);
verifyTrue(t,v.passed,v.reason);verifyEqual(t,v.status,"EXACT_BOUND_INPUT_RECORDS");
v=verification_portable_leaf(string(repmat('0',1,64)),b,"value.recordSHA256",c.bindingA.values,c.bindingB.values,c);
verifyFalse(t,v.passed);
c.sensitivityRecords.passed=false;
v=verification_portable_leaf(a,b,"value.recordSHA256",c.bindingA.values,c.bindingB.values,c);
verifyFalse(t,v.passed);
end
function testHashScopeIsNarrow(t)
c=hash_context;a=string(c.sensitivityRecords.currentSHA256);b=string(c.sensitivityRecords.referenceSHA256);
[applied,~]=verification_sensitivity_record_hash(a,b,"value.seed",c);verifyFalse(t,applied);
c.file="other.csv";
[applied,~]=verification_sensitivity_record_hash(a,b,"value.recordSHA256",c);verifyFalse(t,applied);
c.file="runs/example.mat";
for key=["value[].item[].recordSHA256","value[].result[].p06[].recordSHA256"]
    [applied,p]=verification_sensitivity_record_hash(a,b,key,c);verifyTrue(t,applied);verifyTrue(t,p.passed);
end
c.study="study1";
[applied,~]=verification_sensitivity_record_hash(a,b,"value[].item[].recordSHA256",c);verifyFalse(t,applied);
end
function testCanonicalAndDeclaredLegacyOrder(t)
[canonical,legacy,c]=order_fixture;
[a,b,d]=verification_sensitivity_manifest_order(legacy,canonical,c);
verifyEqual(t,a,canonical);verifyEqual(t,b,canonical);
verifyEqual(t,string(d.csvTokensA),canonical.runId);
verifyTrue(t,d.manifestOrderProof.passed);
[a,~,d]=verification_sensitivity_manifest_order(canonical,canonical,c);
verifyEqual(t,a,canonical);verifyFalse(t,isfield(d,'manifestOrderProof'));
end
function testUnexpectedOrderRejected(t)
[canonical,legacy,c]=order_fixture;
bad=canonical;bad([1 2],:)=bad([2 1],:);
verifyError(t,@()verification_sensitivity_manifest_order(bad,canonical,c),'study:SensitivityManifestOrder');
c.allowLegacySensitivityOrder=false;
verifyError(t,@()verification_sensitivity_manifest_order(legacy,canonical,c),'study:SensitivityManifestOrder');
end
function testMembershipAndReferenceOrderRejected(t)
[canonical,legacy,c]=order_fixture;
bad=legacy;bad.runId(2)=bad.runId(1);
verifyError(t,@()verification_sensitivity_manifest_order(bad,canonical,c),'study:SensitivityManifestOrder');
verifyError(t,@()verification_sensitivity_manifest_order(legacy(2:end,:),canonical,c),'study:SensitivityManifestOrder');
verifyError(t,@()verification_sensitivity_manifest_order(legacy,legacy,c),'study:SensitivityManifestOrder');
end
function testOrderDoesNotReplaceScientificValues(t)
[canonical,legacy,c]=order_fixture;
legacy.R(1)=legacy.R(1)+1;
[a,~,~]=verification_sensitivity_manifest_order(legacy,canonical,c);
verifyEqual(t,nnz(a.R~=canonical.R),1);
verifyEqual(t,a.R(a.runId==legacy.runId(1)),legacy.R(1));
end
function testCompatibleProducerAndFileIntegrity(t)
f=t.applyFixture(matlab.unittest.fixtures.TemporaryFolderFixture);source=f.Folder;
writetable(table(1,'VariableNames',{'value'}),fullfile(source,'fixture.csv'));
manifest=struct('status','COMPLETED','mode','all','internalValidity',struct('passed',true), ...
    'sourceIdentity','d0ec9db6d2c7375c990e8214a27d8c315afd653b0219fa14356c4ec079818d54', ...
    'files',reshape(study_output_identity(source),[],1));
file=fullfile(source,'sensitivity_manifest.json');study_json(file,manifest);
actual=verify_generated_package('sensitivity',source);verifyEqual(t,actual.sourceIdentity,manifest.sourceIdentity);
unknown=manifest;unknown.sourceIdentity=repmat('0',1,64);study_json(file,unknown);
verifyError(t,@()verify_generated_package('sensitivity',source),'study:GenerationIdentity');
study_json(file,manifest);writetable(table(2,'VariableNames',{'value'}),fullfile(source,'fixture.csv'));
verifyError(t,@()verify_generated_package('sensitivity',source),'study:GeneratedInputChanged');
end
function [a,b]=records_fixture(t)
f=t.applyFixture(matlab.unittest.fixtures.TemporaryFolderFixture);
a=fullfile(f.Folder,'current.mat');b=fullfile(f.Folder,'reference.mat');
records=struct('u',[.25 .5],'seed',2101,'mask',[true false],'nested',struct('n',NaN));
save(a,'records','-v7');copyfile(a,b);
end
function c=hash_context
proof=struct('passed',true,'currentSHA256',repmat('a',1,64), ...
    'referenceSHA256',repmat('b',1,64),'requirement','Exact fixture inputs');
c=struct('study',"p06",'file',"P06_RUN_MANIFEST.csv",'isCSV',true,'rowIndex',1, ...
    'csvHeaders',"recordSHA256",'sensitivityRecords',proof);
c.bindingA=struct('values',table(string(proof.currentSHA256),'VariableNames',{'recordSHA256'}));
c.bindingB=struct('values',table(string(proof.referenceSHA256),'VariableNames',{'recordSHA256'}));
c.csvTokensA={proof.currentSHA256};c.csvTokensB={proof.referenceSHA256};
end
function [canonical,legacy,c]=order_fixture
[~,canonical]=sensitivity_design(study1_settings,'input.mat',repmat('a',1,64),'');
order=[find(canonical.baselineGate);find(~canonical.baselineGate)];legacy=canonical(order,:);
c=struct('study',"p06",'file',"P06_RUN_MANIFEST.csv",'allowLegacySensitivityOrder',true, ...
    'bindingA',struct('values',canonical),'bindingB',struct('values',canonical), ...
    'sourceSHA256',"fixture-identity");
c.csvTokensA=cellstr(legacy.runId);
end
