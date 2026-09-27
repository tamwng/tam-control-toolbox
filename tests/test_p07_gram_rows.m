function tests=test_p07_gram_rows
tests=functiontests(localfunctions);
end
function setupOnce(t)
root=fileparts(fileparts(mfilename('fullpath')));t.TestData.path=path;addpath(root,fullfile(root,'src'),fullfile(root,'studies/p07'));
for k=1:5,addpath(fullfile(root,'studies',sprintf('study%d',k)));end
t.TestData.ref=ejc_reference_sources;
end
function teardownOnce(t)
path(t.TestData.path);
end
function test_selected_window_boundaries_match_original_builder(t)
ref=t.TestData.ref;
for study=["study1","study2","study3","study4","study5"]
    base=ref.(study);z=load(fullfile(base,'settings.mat'),'cfg');cfg=z.cfg;
    folder='runs';if study=="study1",folder='data';end
    files=dir(fullfile(base,folder,'*.mat'));seen=strings(0,1);
    for f=files.'
        z=load(fullfile(f.folder,f.name));if ~isfield(z,'result'),continue;end
        r=z.result;
        if isfield(r,'fit'),fit=r.fit;elseif study=="study2",z=load(fullfile(base,'fits',r.id+".mat"),'fit');fit=z.fit;else,fit=struct('D',r.D);end
        if isfield(r,'D'),D=r.D;else,D=fit.D;end
        if isfield(r,'nEstimated'),estimated=r.nEstimated;else,estimated=fit.nEstimated;end
        if estimated==0 || any(seen==string(r.id)),continue;end
        seen(end+1)=string(r.id);R=ejc_gram_rows(r,study,cfg,fit);
        verifySize(t,R,[r.nSteps-1,numel(D)]);
        % Initial, pre-full, full, advancing and last window boundaries.
        for j=unique([2,min(50,r.nSteps),min(51,r.nSteps),min(52,r.nSteps),r.nSteps])
            old=ejc_gram_parent(r,study,cfg,fit,j);
            verifyEqual(t,R(max(1,j-50):j-1,:),old,study+"/"+f.name+" index "+j);
        end
    end
    verifyNotEmpty(t,seen);
end
end
