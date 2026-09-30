function report=ejc_covariance_report_compare(a,b,currentRuns,referenceRuns,cfg)
%EJC_COVARIANCE_REPORT_COMPARE Narrow P6 adapter for Study 1 diagnostics only.
% Each scalar is checked against its own saved matrix history and exact maximum
% index. No enclosing-struct tolerance, producer edit, or covariance waiver.
if nargin<5,cfg=study1_settings;end
report=struct('passed',false,'reason',"",'rows',struct([]),'parameterRows',struct([]), ...
    'gramRows',struct([]),'qualifiedCount',0);
if ~isstruct(a) || ~isstruct(b) || ~isscalar(a) || ~isscalar(b) || ...
        ~isfield(a,'diagnostics') || ~isfield(b,'diagnostics') || ...
        ~istable(a.diagnostics) || ~istable(b.diagnostics)
    report.reason="Reporting schema differs";return
end
if ~isequal(a.diagnostics.Properties.VariableNames,b.diagnostics.Properties.VariableNames) || ...
        height(a.diagnostics)~=height(b.diagnostics) || ...
        numel(currentRuns)~=height(a.diagnostics) || numel(referenceRuns)~=height(b.diagnostics)
    report.reason="Reporting schema/count differs";return
end
x=a.diagnostics.covarianceConditionMax;y=b.diagnostics.covarianceConditionMax;
left=a;right=b;left.diagnostics.covarianceConditionMax=[];right.diagnostics.covarianceConditionMax=[];
% These named fields have individual comparison rules. All remaining
% fields of the summary structure retain exact comparison.
for name=["parameterScaledRMSPercent","parameterFinalScaledPercent"]
    if ~istable(a.metrics) || ~isequal(a.metrics.Properties.VariableNames,b.metrics.Properties.VariableNames)
        report.reason="Metric schema differs";return
    end
    v=ejc_acceptance_numeric(a.metrics.(name),b.metrics.(name),1e-8,1e-7,true(size(a.metrics.(name))));
    if ~v.passed,report.reason="Approved P10 legacy coordinate score failed: "+name;return;end
    report.parameterRows=[report.parameterRows;struct('field',name,'family',"P10",'numeric',v)];
    left.metrics.(name)=[];right.metrics.(name)=[];
end
gx=a.diagnostics.gramConditionMax;gy=b.diagnostics.gramConditionMax;
left.diagnostics.gramConditionMax=[];right.diagnostics.gramConditionMax=[];
if ~isequaln(left,right),report.reason="Another strict scientific field differs";return;end
for k=1:numel(x)
    try
        ca=parent(currentRuns{k},a.diagnostics(k,:),x(k),true);
        cb=parent(referenceRuns{k},b.diagnostics(k,:),y(k),false);
        v=ejc_acceptance_numeric(x(k),y(k),1e-8,1e-7,true);
        ok=ca.passed && cb.passed && ca.count==cb.count && ca.maximumIndex==cb.maximumIndex && v.passed;
        row=struct('row',k,'passed',ok,'current',ca,'reference',cb,'numeric',v);
        report.rows=[report.rows;row]; %#ok<AGROW>
        if ~ok,report.reason="P6 parent/reduction/selection/numerical requirement failed";return;end
        g=gram_reduction(currentRuns{k},referenceRuns{k},gx(k),gy(k),cfg);
        report.gramRows=[report.gramRows;g];report.qualifiedCount=report.qualifiedCount+g.qualifiedCount;
    catch e
        report.reason=string(e.identifier)+": "+e.message;return
    end
end
report.passed=all([report.rows.passed]) && all([report.gramRows.passed]);
if ~report.passed,report.reason="P6 parent, selection, source, mask or numerical requirement failed";end
end
function out=parent(r,row,value,isCurrent)
assert(isequal(string(r.campaign),row.campaign) && isequal(string(r.id),row.model) && ...
    isequal(r.trial,row.trial) && isequal(r.nSteps,row.attemptedSteps) && ...
    isequal(r.completed,row.completed),'ejc:ReportSource','Source identity/count mismatch.');
assert(r.fit.nEstimated>0 && size(r.covariance,3)>=r.nSteps,'ejc:ReportSource','Missing required covariance.');
values=zeros(1,r.nSteps);stored=r.covarianceCondition(1:r.nSteps);valid=true;
envelopes=zeros(r.nSteps,2);
for j=1:r.nSteps
    s=ejc_matrix_screen(r.covariance(:,:,j),"covariance",StoredCondition=stored(j));
    valid=valid && s.valid && s.resolved && s.conditionInsideEnvelope;
    values(j)=s.recomputedCondition;envelopes(j,:)=s.envelope;
end
[rawMaximum,rawIndex]=max(stored);[computedMaximum,computedIndex]=max(values);
% The historical assertion's unrounded oracle must be supported by the saved
% production history. A present-day recomputation is not a historical oracle.
if isCurrent,ownMaximum=computedMaximum;else,ownMaximum=rawMaximum;end
own=ejc_acceptance_numeric(value,ownMaximum,1e-8,1e-7,true);
out=struct('passed',valid && own.passed && ...
    rawIndex==computedIndex && value>=envelopes(computedIndex,1) && value<=envelopes(computedIndex,2), ...
    'count',r.nSteps,'maximumIndex',computedIndex,'rawMaximum',rawMaximum, ...
    'computedMaximum',computedMaximum,'value',value,'allParentsPassed',valid);
end
function out=gram_reduction(a,b,x,y,cfg)
out=struct('passed',false,'qualifiedCount',0,'rawCurrent',x,'rawReference',y, ...
    'currentComputedMaximum',NaN,'referenceRecomputedMaximum',NaN, ...
    'rawExtremumReproduced',false,'parentInstances',0,'status',"BLOCKED");
ia=find(a.gramCount(1:a.nSteps)>=50);ib=find(b.gramCount(1:b.nSteps)>=50);
if ~isequal(ia,ib) || isempty(ia) || ~isequal(a.fit.D,b.fit.D),return;end
% Reuse executed paired guards; no preinitialized success flags authorize a
% qualification. Full publication comparisons remain a separate caller gate.
pair=ejc_pair_run_screen(a,b,"study1",cfg,a.fit,b.fit,"F0069");
if ~pair.passed,return;end
values=zeros(numel(ia),2);
for k=1:numel(ia)
    j=ia(k);values(k,:)=[cond(a.gram(:,:,j)),cond(b.gram(:,:,j))];
end
selected=ismember([pair.gramRows.index],ia);
parents=pair.gramRows(selected);
out.parentInstances=numel(ia);out.currentComputedMaximum=max(values(:,1));out.referenceRecomputedMaximum=max(values(:,2));
% The historical scalar is retained. Recomputing it now cannot reconstruct
% an unknown historical backend's unstable argmax or condition estimates.
if ~isequaln(x,out.currentComputedMaximum) || ~isequal(isnan(x),isnan(y)) || ...
        ~isequal(isinf(x),isinf(y)) || (isinf(x) && ~isequal(x,y)),return;end
v=ejc_p7_reduce_verdict(x,y,ia,ib,parents,true);
out.passed=v.eligibleToAdvance;out.qualifiedCount=v.qualifiedCount;
out.rawExtremumReproduced=v.rawExtremumReproduced;out.status=v.status;
end
