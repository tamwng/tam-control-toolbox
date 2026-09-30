function results = study_prerequisites(study)
%STUDY_PREREQUISITES Explicit small scientific prerequisites, without archives.
[context,root]=study_context; %#ok<ASGLU>
results=run_component_tests;
switch string(study)
    case 'study1', files={};
    case 'study2', files={'test_study2.m'};
    case 'study3', files={'test_study3_definitions.m','test_study3_timing.m','test_study3_recovery.m'};
    case 'study4', files={'test_study4.m','test_study4_timing.m'};
    case 'study5', files={'test_study5.m'};
    case 'study6', files={'test_study6.m'};
    otherwise, error('study:Selection','Unknown study.');
end
for j=1:numel(files)
    suite=matlab.unittest.TestSuite.fromFile(fullfile(root,'tests',files{j}));
    if string(study)=='study6'
        % Archive-dependent tests remain in the separate reference test group.
        name=string({suite.Name});
        suite=suite(~endsWith(name,{'/testIndicesAndCommonInputs', ...
            '/testSnapshotSelectionAndPhysicalMapping','/testConstraintBenchmarkFromArchive'}));
    end
    assert(~isempty(suite),'study:NoTests','Required component selection is empty.');
    extra=run(suite); results=[results extra]; %#ok<AGROW>
end
assert(all([results.Passed]) && ~any([results.Incomplete]), ...
    'study:Prerequisites','Applicable component checks failed or did not run.');
end
