function tests = test_study3_recovery
%TEST_STUDY3_RECOVERY Half-open dwell timing and separate failure statuses.
tests = functiontests(localfunctions);
end

function setupOnce(testCase)
testCase.TestData.previousPath = path;
root = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(root,'studies','study3'));
end

function teardownOnce(testCase)
path(testCase.TestData.previousPath);
end

function testEarliestRecoveryIsZeroDelay(testCase)
r = fixture;
r.x(501:520) = .04;
out = study3_recovery(r);
verifyEqual(testCase,out.status,"recovered");
verifyEqual(testCase,[out.recoveryTime,out.recoveryDelay,out.dwellEnd],[50,0,52]);
verifyFalse(testCase,out.rightCensored);
end

function testLastTwentySamplesMayEndAtSixty(testCase)
r = fixture;
r.x(581:600) = 0;
r.x(601) = 1; % The sample at 60 s is outside the accepted dwell.
out = study3_recovery(r);
verifyEqual(testCase,[out.recoveryTime,out.recoveryDelay,out.dwellEnd],[58,8,60]);
verifyEqual(testCase,out.dwellSamples,20);
end

function testStrictBreachBreaksCandidateDwell(testCase)
r = fixture;
r.x(501:520) = 0;
r.x(510) = .04+eps(.04);
out = study3_recovery(r);
verifyFalse(testCase,out.recovered);
verifyEqual(testCase,out.status,"rightCensored");
verifyTrue(testCase,isnan(out.recoveryDelay));
end

function testNonRecoveryRemainsRightCensored(testCase)
out = study3_recovery(fixture);
verifyEqual(testCase,out.status,"rightCensored");
verifyTrue(testCase,out.rightCensored);
verifyEqual(testCase,out.censorTime,60);
verifyTrue(testCase,isnan(out.recoveryTime) && isnan(out.recoveryDelay));
end

function testEarlyTerminationIsSeparate(testCase)
r = fixture; r.nSteps = 550; r.completed = false;
r.x(551) = NaN;
out = study3_recovery(r);
verifyEqual(testCase,out.status,"terminatedBeforeCensor");
verifyTrue(testCase,out.terminationBeforeCensor);
verifyEqual(testCase,out.terminationTime,55);
verifyFalse(testCase,out.rightCensored);
verifyTrue(testCase,isnan(out.recoveryDelay));
end

function testLaterTerminationDoesNotEraseCompletedDwell(testCase)
r = fixture; r.nSteps = 550; r.completed = false;
r.x(501:520) = 0;
out = study3_recovery(r);
verifyTrue(testCase,out.recovered && out.terminationBeforeCensor);
verifyEqual(testCase,out.recoveryDelay,0);
end

function testDriftHasNoRecoveryStatistic(testCase)
r = fixture; r.scenario = 'drift'; r.x(:) = 0;
out = study3_recovery(r);
verifyFalse(testCase,out.applicable);
verifyEqual(testCase,out.status,"notApplicable");
verifyTrue(testCase,isnan(out.recoveryDelay));
end

function r = fixture
r = struct('scenario','abrupt','Ts',.1,'nSteps',1200,'completed',true, ...
    'time',(0:1200)*.1,'x',ones(1,1201),'r',zeros(1,1201));
end
