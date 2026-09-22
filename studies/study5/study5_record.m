function record = study5_record(count,seed,cfg)
%STUDY5_RECORD Fresh Plant C endpoints; no intersample information is fitted.
stream = RandStream('mt19937ar','Seed',seed);
levels = cfg.inputLevelScale*[-1,-.5,0,.5,1];
plant = physical_model(cfg.Ts,cfg.plantSubsteps);
record = struct('x',zeros(1,count+1),'y',zeros(1,count+1), ...
    'u',zeros(1,count),'target',zeros(1,count),'time',(0:count)*cfg.Ts, ...
    'seed',seed,'L',cfg.inputLevelScale,'plantSubsteps',cfg.plantSubsteps);
for j = 1:count
    if mod(j-1,5) == 0, target = levels(randi(stream,5)); end
    record.target(j) = target;
    if j > 1
        change = min(max(target-record.u(j-1),-cfg.control.hdu(1)),cfg.control.hdu(1));
        record.u(j) = record.u(j-1)+change;
    end
    record.x(j+1) = forward_map(plant,record.x(j),record.u(j),cfg.trueParameters);
end
record.y = record.x;
end
