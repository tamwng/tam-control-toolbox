function record = study2_record(count,L,seed,cfg)
%STUDY2_RECORD Independent clean initialization or evaluation transitions.
% Sample targets at k=0,5,... . Set u(0)=0, then approach the current target
% within the increment bound. A local stream preserves the global RNG state.

validateattributes(count,{'double'},{'scalar','integer','positive','finite'});
validateattributes(L,{'double'},{'scalar','positive','finite','<=',1.2});
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
    record.x(j+1) = study2_plant(record.x(j),record.u(j));
end
record.y = record.x;
end
