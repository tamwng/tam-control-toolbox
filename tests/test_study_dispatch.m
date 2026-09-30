function tests=test_study_dispatch
%TEST_STUDY_DISPATCH Synthetic orchestration checks; no controller is called.
tests=functiontests(localfunctions);
end
function setupOnce(t)
t.TestData.path=path;root=fileparts(fileparts(mfilename('fullpath')));addpath(root);
t.TestData.root=root;
end
function teardownOnce(t),path(t.TestData.path);end
function testMandatorySelectorAndExpensiveOptIn(t)
verifyError(t,@()generate_results('unknown'),'study:Selection');
verifyError(t,@()generate_results('all'),'study:ExpensiveSelection');
verifyError(t,@()generate_results('sensitivity'),'study:ExpensiveSelection');
verifyError(t,@()run_sensitivity('all'),'study:ExpensiveSelection');
end
function testEachStudyUsesItsOwnDriver(t)
calls=strings(0,1);operations=struct;
for j=1:6,key="study"+j;operations.(key)=@(varargin)record(key,varargin{:});end
options=struct('Figures',false,'Sources',struct,'ConfirmFull',false);
for j=1:6,study_dispatch("study"+j,'unused',options,operations);end
verifyEqual(t,calls,"study"+(1:6).');
    function record(key,varargin)
        calls(end+1,1)=key;
        verifyEqual(t,varargin{1},'unused');
        verifyFalse(t,varargin{3});
    end
end
function testAllOrderAndNewParentsAreExplicit(t)
f=t.applyFixture(matlab.unittest.fixtures.TemporaryFolderFixture);
output=fullfile(f.Folder,'all');calls=strings(0,1);bound=struct;
operations=struct('generate',@generate,'sensitivity',@sensitivity);
options=struct('Figures',false,'Sources',struct,'ConfirmFull',true);
stages=study_dispatch("all",output,options,operations);
verifyEqual(t,calls,["study"+(1:6),"p06"].');
verifyEqual(t,numel(stages),7);
for j=1:5,verifyEqual(t,bound.("study"+j),fullfile(output,"study"+j));end
    function [destination,m]=generate(key,varargin)
        calls(end+1,1)=string(key);destination=varargin{2};
        if string(key)=="study6",bound=varargin{4};end
        m=struct('internalValidity',struct('passed',true));
    end
    function [destination,m]=sensitivity(mode,varargin)
        verifyEqual(t,mode,'all');calls(end+1,1)="p06";destination=varargin{2};
        verifyTrue(t,varargin{4});m=struct('internalValidity',struct('passed',true));
    end
end
function testFailureStopsLaterStages(t)
f=t.applyFixture(matlab.unittest.fixtures.TemporaryFolderFixture);calls=0;
options=struct('Figures',false,'Sources',struct,'ConfirmFull',true);
operations=struct('generate',@failure,'sensitivity',@never);
verifyError(t,@()study_dispatch("all",fullfile(f.Folder,'failed'),options,operations),'fixture:Failure');
verifyEqual(t,calls,1);
    function varargout=failure(varargin) %#ok<STOUT,INUSD>
        calls=calls+1;error('fixture:Failure','Synthetic dispatch failure.');
    end
    function varargout=never(varargin) %#ok<STOUT,INUSD>
        error('fixture:Unexpected','A later stage must not run.');
    end
end
function testOutputCollisionIsNotOverwritten(t)
f=t.applyFixture(matlab.unittest.fixtures.TemporaryFolderFixture);
verifyError(t,@()ejc_output_path('test',f.Folder),'ejc:ExistingOutput');
end
