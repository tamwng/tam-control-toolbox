function tests = test_p07_entrypoints
%TEST_P07_ENTRYPOINTS Guard changed output and fresh-source interfaces only.
tests = functiontests(localfunctions);
end

function testOutputCollisionAndProtectedPaths(t)
fixture = t.applyFixture(matlab.unittest.fixtures.TemporaryFolderFixture);
before = rng;
verifyError(t,@() ejc_output_path('test',fixture.Folder),'ejc:ExistingOutput');
target = fullfile(fixture.Folder,'new');
verifyEqual(t,ejc_output_path('test',target),target);
verifyFalse(t,isfolder(target)); verifyEqual(t,rng,before);
sources = ejc_reference_sources;
verifyError(t,@() ejc_assert_writable(sources.study1),'ejc:ProtectedOutput');
verifyError(t,@() ejc_assert_writable(fullfile(sources.study1,'data','new.mat')),'ejc:ProtectedOutput');
verifyError(t,@() ejc_assert_writable(fileparts(sources.study1)),'ejc:ProtectedOutput');
end

function testInvalidModeCannotCreateOutput(t)
fixture = t.applyFixture(matlab.unittest.fixtures.TemporaryFolderFixture);
target = fullfile(fixture.Folder,'unused');
verifyError(t,@() run_ejc('unknown',OutputDirectory=target),'ejc:Mode');
verifyFalse(t,isfolder(target));
end

function testFreshStudy6RejectsUnqualifiedHistoricalSources(t)
before = rng; revision = ejc_source_revision; expected = 'ejc:ProtectedOutput';
if ~revision.clean, expected = 'ejc:DirtySource'; end
verifyError(t,@() ejc_validate_sources(ejc_reference_sources),expected);
verifyEqual(t,rng,before);
end
