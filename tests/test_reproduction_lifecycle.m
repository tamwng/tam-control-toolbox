function tests=test_reproduction_lifecycle
%TEST_REPRODUCTION_LIFECYCLE Missing inputs never become successful reproduction.
tests=functiontests(localfunctions);
end
function setupOnce(t)
t.TestData.path=path;root=fileparts(fileparts(mfilename('fullpath')));addpath(root);
end
function teardownOnce(t),path(t.TestData.path);end
function testMissingParentsRejected(t)
verifyError(t,@()validate_generated_sources(struct),'study:ParentSources');
end
function testFalseCompletionWithoutFilesRejected(t)
f=t.applyFixture(matlab.unittest.fixtures.TemporaryFolderFixture);parents=struct;
for j=1:5,parents.("study"+j)=f.Folder;end
verifyError(t,@()validate_generated_sources(parents),'study:MissingParent');
end
function testMissingCanonicalNeverPasses(t)
context=study_context; %#ok<NASGU>
verifyError(t,@()resolve_reference_inputs(struct,"study2"),'study:ReferenceUnavailable');
end
function testMissingStudy2PlotReferenceRejected(t)
f=t.applyFixture(matlab.unittest.fixtures.TemporaryFolderFixture);
verifyError(t,@()plot_results('study2',f.Folder),'study:ReferenceUnavailable');
end
function testSourceDefinitionsCannotBeInvented(t)
context=study_context; %#ok<NASGU>
fake=struct('path','src/solve_mpc.m','sha256',repmat('0',1,64));
verifyError(t,@()study_claim_source_guard(fake),'study:DefinitionRelationship');
end
function testPureSensitivityDesignAndAliases(t)
context=study_context; %#ok<NASGU>
[p,m]=p06_design(study1_settings,'','','');
verifyEqual(t,height(m),1558);verifyEqual(t,nnz(m.baselineGate),12);
verifyEqual(t,nnz(~m.noisy),38);verifyEqual(t,p.analysisSeed,7401);
verifyEqual(t,p.bootstrapCount,2000);
verifyEqual(t,p.knownAliases.knownReferenceConfiguration, ...
    ["baseline";"R_half";"R_double";"baseline";"baseline";"baseline";"baseline"]);
end
function testRecordStreamsAndPrefixTiming(t)
context=study_context; %#ok<NASGU>
cfg=study1_settings;records=study1_records(cfg,'confirmation');
verifyEqual(t,size(records.initialNoise),[40 201]);verifyEqual(t,size(records.controlNoise),[40 1201]);
stream=RandStream('mt19937ar','Seed',2201);
verifyEqual(t,records.initialNoise(1,:),cfg.noiseSigma*randn(stream,1,201));
stream=RandStream('mt19937ar','Seed',2301);
verifyEqual(t,records.controlNoise(1,:),cfg.noiseSigma*randn(stream,1,1201));
[~,manifest]=p06_design(cfg,'','','');row=manifest(manifest.runId=="fit_50_S_001",:);
[training,noise,selected]=p06_trial(records,1,row,cfg);
verifyEqual(t,training.x,records.initialization.x(1:51));
verifyEqual(t,training.u,records.initialization.u(1:50));
verifyEqual(t,training.y,records.initialization.x(1:51)+records.initialNoise(1,1:51));
verifyEqual(t,noise,records.controlNoise(1,:));verifyEqual(t,selected.fitSteps,50);
end
