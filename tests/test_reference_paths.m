function tests = test_reference_paths
%TEST_REFERENCE_PATHS Canonical locations, compatibility names and source guards.
tests=functiontests(localfunctions);
end
function setupOnce(t)
t.TestData.context=study_context;
t.TestData.root=fileparts(fileparts(mfilename('fullpath')));
end
function teardownOnce(t)
t.TestData.context=[];
end
function testIncludedDirectories(t)
references=reference_directories;
verifyEqual(t,fieldnames(references),[cellstr("study"+(1:6).');{'sensitivity'}]);
for key=string(fieldnames(references)).'
    verifyTrue(t,isfolder(references.(key)));
    verifyTrue(t,startsWith(string(references.(key)),string(fullfile(t.TestData.root,'references'))+filesep));
end
end
function testSensitivityAlias(t)
references=reference_directories;
actual=study_reference_keys(struct('sensitivity',references.sensitivity));
verifyEqual(t,actual,struct('p06',references.sensitivity));
actual=study_reference_keys(struct('sensitivity',references.sensitivity,'p06',references.sensitivity));
verifyEqual(t,actual,struct('p06',references.sensitivity));
verifyError(t,@()study_reference_keys(struct('sensitivity',references.sensitivity,'p06',references.study1)), ...
    'study:ReferenceIdentity');
end
function testProtectedDestinations(t)
references=reference_directories;
for key=string(fieldnames(references)).'
    verifyError(t,@()assert_output_writable(references.(key)),'ejc:ProtectedOutput');
    verifyError(t,@()assert_output_writable(fullfile(references.(key),'new.mat')),'ejc:ProtectedOutput');
end
verifyError(t,@()assert_output_writable(fullfile(t.TestData.root,'references')),'ejc:ProtectedOutput');
verifyError(t,@()assert_output_writable(fullfile(t.TestData.root,'references','study2_rank.csv')),'ejc:ProtectedOutput');
end
function testFrozenSpecificationLocations(t)
file=fullfile(t.TestData.root,'verification','specification','numerical_policy.json');
verifyEqual(t,verification_file_sha256(file),'ca9101ea01a6eb093664d383a3d6bd1734598ba84aed2ee35b28cfa7412aec58');
p=jsondecode(fileread(file));a=p.maximum_locator_amendment;
verifyEqual(t,verification_file_sha256(verification_specification_path(a.scope_map)),a.scope_map_sha256);
verifyTrue(t,isfile(verification_specification_path(a.source_definitions)));
verifyError(t,@()verification_specification_path('unlisted.json'),'study:SpecificationIdentity');
end
function testDefinitionIdentity(t)
proof=study_claim_source_guard;verifyTrue(t,proof.passed);
verifyError(t,@()study_claim_source_guard(struct('path','unlisted.m','sha256',repmat('0',1,64))), ...
    'study:DefinitionRelationship');
end
function testCanonicalStudy6Locations(t)
cfg=study6_settings;references=reference_directories;
for j=1:5,verifyEqual(t,study6_source(t.TestData.root,cfg,j),references.("study"+j));end
cfg.sources{1}='unlisted_source';
verifyError(t,@()study6_source(t.TestData.root,cfg,1),'study6:SourceBinding');
end
function testExplicitStudy6Sources(t)
cfg=study6_settings;references=reference_directories;
cfg.sourceDirectories={references.study1,references.study2,references.study3,references.study4,references.study5};
verifyEqual(t,study6_source(t.TestData.root,cfg,2),references.study2);
cfg.sourceDirectories{2}=fullfile(t.TestData.root,'absent_source');
verifyError(t,@()study6_source(t.TestData.root,cfg,2),'study6:MissingSource');
end
