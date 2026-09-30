function tests=test_study_path_lifecycle
%TEST_STUDY_PATH_LIFECYCLE Current-directory and path isolation for public code.
tests=functiontests(localfunctions);
end
function setupOnce(t)
t.TestData.path=path;t.TestData.directory=pwd;
t.TestData.root=fileparts(fileparts(mfilename('fullpath')));addpath(t.TestData.root);
end
function teardownOnce(t),cd(t.TestData.directory);path(t.TestData.path);end
function testColdCallerRestored(t)
f=t.applyFixture(matlab.unittest.fixtures.TemporaryFolderFixture);
old=pwd;restore=onCleanup(@()cd(old));cd(f.Folder);previous=path;
[context,root,resolution]=study_context;
verifyEqual(t,root,t.TestData.root);verifyEqual(t,pwd,root);
verifyTrue(t,all(startsWith(resolution.sourceFile,string(root)+filesep)));
clear context
verifyEqual(t,pwd,f.Folder);verifyEqual(t,path,previous);
end
function testCurrentDirectoryShadowCannotSupplyScience(t)
f=t.applyFixture(matlab.unittest.fixtures.TemporaryFolderFixture);
file=fullfile(f.Folder,'forward_map.m');fid=fopen(file,'w');
fprintf(fid,'function varargout=forward_map(varargin)\nerror(''fixture:Shadow'',''Wrong source'');\nend\n');fclose(fid);
old=pwd;restore=onCleanup(@()cd(old));cd(f.Folder);
[context,root]=study_context; %#ok<ASGLU>
verifyEqual(t,which('forward_map'),fullfile(root,'src','forward_map.m'));
end
function testFailureRestoresContext(t)
old=pwd;previous=path;
verifyError(t,@()fail_in_context,'fixture:Failure');
verifyEqual(t,pwd,old);verifyEqual(t,path,previous);
end
function fail_in_context
context=study_context; %#ok<NASGU>
error('fixture:Failure','Synthetic failure after context entry.');
end
function testRelationshipRequiresFixedOfflineAuthority(t)
context=study_context; %#ok<NASGU>
proof=verify_source_relationship;
verifyEqual(t,proof.sourceReview,'HQ_APPROVED');
verifyEqual(t,proof.relationshipSHA256,source_relationship_anchor);
verifyEqual(t,proof.policySHA256,'ca9101ea01a6eb093664d383a3d6bd1734598ba84aed2ee35b28cfa7412aec58');
end
