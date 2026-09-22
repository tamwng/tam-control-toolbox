function record = study4_record(count,L,seed,cfg)
%STUDY4_RECORD Fresh linear-regime record with Appendix A input generation.
stream = RandStream('mt19937ar','Seed',seed);
levels = L*[-1,-.5,0,.5,1];
record = struct('x',zeros(1,count+1),'y',zeros(1,count+1), ...
    'u',zeros(1,count),'target',zeros(1,count), ...
    'time',(0:count)*cfg.Ts,'seed',seed,'L',L);
for j = 1:count
    if mod(j-1,5) == 0, target = levels(randi(stream,5)); end
    record.target(j) = target;
    if j > 1
        change = min(max(target-record.u(j-1),-cfg.control.hdu(1)),cfg.control.hdu(1));
        record.u(j) = record.u(j-1)+change;
    end
    record.x(j+1) = study4_plant(record.x(j),record.u(j),0,0);
end
record.y = record.x;
end
