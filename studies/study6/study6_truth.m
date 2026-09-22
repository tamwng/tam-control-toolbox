function q = study6_truth(q,plant,currentGain,futureGain)
%STUDY6_TRUTH Evaluator-only, noise-free trajectories from both observed states.
% currentGain has one row per query and one column per estimator snapshot.
% Only the separate future-truth path sees the optional future schedule.
if nargin < 4, futureGain = []; end
n = numel(q.x); H = size(q.inputs,2); ns = size(currentGain,2);
assert(size(currentGain,1) == n);
q.currentGain = currentGain; q.futureGain = futureGain;
q.truthX = nan(n,H+1,2,ns); q.truthY = q.truthX; q.truthFuture = q.truthX;
q.referenceError = zeros(size(q.truthX)); % Exact sampled recurrences A/B.
for s = 1:ns
    for mode = 1:2
        x = q.x; y = q.y; future = x;
        q.truthX(:,1,mode,s) = x; q.truthY(:,1,mode,s) = y; q.truthFuture(:,1,mode,s) = future;
        for h = 1:H
            u = q.inputs(:,h,mode); gain = currentGain(:,s); later = gain;
            if ~isempty(futureGain), later = futureGain(:,h); end
            if strcmp(plant,'A')
                x = study3_plant(x,u,gain,0); y = study3_plant(y,u,gain,0);
                future = study3_plant(future,u,later,0);
            else
                assert(strcmp(plant,'B'));
                x = study2_plant(x,u); y = study2_plant(y,u); future = study2_plant(future,u);
            end
            q.truthX(:,h+1,mode,s) = x; q.truthY(:,h+1,mode,s) = y;
            q.truthFuture(:,h+1,mode,s) = future;
        end
    end
end
q.futureProcessNoise = 'Suppressed; observed states and recorded inputs are unchanged.';
end
