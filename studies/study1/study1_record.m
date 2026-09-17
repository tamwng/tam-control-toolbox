function record = study1_record(count,L,seed,cfg)
%STUDY1_RECORD Independent clean initialization or evaluation transitions.
% Targets are sampled at k=0,5,... . The initial applied input u(0)=0;
% subsequent samples approach the current target within the rate bound.
% This local stream does not consume or replace MATLAB's global RNG state.

validateattributes(count,{'double'},{'scalar','integer','positive','finite'});
validateattributes(L,{'double'},{'scalar','positive','finite','<=',1});
validateattributes(seed,{'double'},{'scalar','integer','nonnegative','finite'});
stream = RandStream('mt19937ar','Seed',seed);
levels = L*[-1,-0.5,0,0.5,1];
incrementLimit = cfg.control.hdu(1);
record = struct('x',zeros(1,count+1),'y',zeros(1,count+1), ...
    'u',zeros(1,count),'target',zeros(1,count), ...
    'time',(0:count)*cfg.Ts,'seed',seed,'L',L);
target = 0;
for j = 1:count
    if mod(j-1,5) == 0
        target = levels(randi(stream,numel(levels)));
    end
    record.target(j) = target;
    if j > 1
        change = min(max(target-record.u(j-1),-incrementLimit),incrementLimit);
        record.u(j) = record.u(j-1)+change;
    end
    record.x(j+1) = study1_plant(record.x(j),record.u(j));
end
record.y = record.x;
end
