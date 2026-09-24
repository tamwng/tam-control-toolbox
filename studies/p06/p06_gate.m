function checks = p06_gate(current,saved,cfg)
%P06_GATE Proposed tolerances fixed before production results are available.
% Exact statuses; fit state 1e-10+1e-10*|reference|; trajectory 1e-7+1e-7*|ref|;
% scores 1e-8+1e-7*|ref|. Timing and machine-dependent condition scores excluded.
rows = struct([]);
for name = {'completed','nSteps','idAttempted','idAccepted','controlAccepted'}
    rows = [rows; compare(name{1},current.(name{1}),saved.(name{1}),0,0)]; %#ok<AGROW>
end
for name = {'theta','beta','covariance'}
    rows = [rows; compare(['fit.' name{1}],current.fit.(name{1}),saved.fit.(name{1}),1e-10,1e-10)]; %#ok<AGROW>
end
for name = {'x','y','u','theta','prediction'}
    rows = [rows; compare(name{1},current.(name{1}),saved.(name{1}),1e-7,1e-7)]; %#ok<AGROW>
end
helper = study1_summarize('p06_helpers');
base = struct;
a = helper.scoreRun(current,base,cfg); b = helper.scoreRun(saved,base,cfg);
for name = {'trackingRMS','inputRMS','meanAbsoluteIncrement'}
    rows = [rows; compare(['whole.' name{1}],a(1).(name{1}),b(1).(name{1}),1e-8,1e-7)]; %#ok<AGROW>
end
currentCfg=cfg; currentCfg.fitSteps=200;
a = helper.scoreFit(current,base,currentCfg); b = helper.scoreFit(saved,base,cfg);
b = b([b.fittingTransitions]==200);
rows = [rows;compare('initialization.predictionRMS',a.predictionRMS,b.predictionRMS,1e-10,1e-10)];
checks = struct2table(rows);
end

function row = compare(name,a,b,absolute,relative)
passed = isequal(size(a),size(b)); maximum = NaN;
if passed
    passed = isequal(isfinite(a),isfinite(b)) && isequal(isnan(a),isnan(b)) ...
        && isequal(a(isinf(a)),b(isinf(b)));
    if passed
        finite = isfinite(a);
        difference = abs(double(a(finite))-double(b(finite)));
        maximum = max([0;difference(:)]);
        passed = all(difference <= absolute+relative*abs(double(b(finite))),'all');
    end
end
row = struct('quantity',string(name),'absoluteTolerance',absolute, ...
    'relativeTolerance',relative,'maxAbsoluteDifference',maximum,'passed',passed);
end
