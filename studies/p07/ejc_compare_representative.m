function report=ejc_compare_representative(a,b,cfg)
% EJC_COMPARE_REPRESENTATIVE Compare saved Study 1 Shared trial 0 arrays.
%  A is the current result, B the separately identified historical reference,
%  and CFG the unchanged Study 1 configuration. Both must identify the
%  confirmation campaign, Shared model S and noise-free trial 0.
%  The closed F3879--F3957 field mapping retains schema, source relationships,
%  independent validity and scoped numerical/Gram requirements. controlTime
%  is excluded. Qualified Gram diagnostics do not assert numerical equality.
%  No fit, controller or forecast is run. REPORT retains blocked/failed
%  reasons and field outcomes; passed is false if required checks cannot run.
report=struct('passed',false,'status',"BLOCKED",'reason',"",'rows',struct([]), ...
 'conditions',struct,'qualifiedCount',0,'excludedFields',"result[].controlTime");
try
 assert(isequal(a.id,'S') && isequal(b.id,'S') && isequal(a.campaign,'confirmation') && ...
  isequal(b.campaign,'confirmation') && a.trial==0 && b.trial==0, ...
  'ejc:RepresentativeScope','Only the declared Shared confirmation trial 0 is supported.');
 assert(a.completed && b.completed && a.nSteps==cfg.K && b.nSteps==cfg.K, ...
  'ejc:RepresentativeIncomplete','The representative must complete every configured step.');
 assert(isequal(a.fit.D,b.fit.D),'ejc:CalibrationMismatch','A1 requires identical calibration.');
 for side={a,b}
  r=side{1};
  assert(isequal(r.fit.checkpointTheta,r.fit.theta(:,cfg.fitSteps+1)) && ...
   isequal(r.fit.checkpointCovariance,r.fit.covariance(:,:,cfg.fitSteps+1)), ...
   'ejc:CheckpointSource','Checkpoint differs from its own fit history.');
  assert(all(r.fit.attempted) && all(r.fit.accepted),'ejc:FitValidity','Required Shared fit did not accept every transition.');
  assert(all(r.fit.lambda==1) && all(r.lambda(r.idAttempted)==1), ...
   'ejc:FixedForgetting','The unchanged fixed forgetting rule differs.');
  for j=1:size(r.fit.covariance,3)
   s=ejc_matrix_screen(r.fit.covariance(:,:,j),"covariance");
   assert(s.valid,'ejc:FitCovariance','Fit covariance validity failed at %d.',j);
  end
  forecast_validity(r.forecasts,cfg);
 end
 [report.conditions,report.matrixDetails]=ejc_pair_run_screen(a,b,"study1",cfg,a.fit,b.fit,"F3914");
 assert(report.conditions.passed,'ejc:RepresentativeParents','%s',report.conditions.reason);
 report.qualifiedCount=report.conditions.qualifiedCount;
 report.rows=walk(a,b,"result",a,b,report.conditions,struct([]));
 report.passed=all([report.rows.passed]);
 verdict=ejc_acceptance_verdict(nnz(~[report.rows.passed]),0,report.qualifiedCount);
 report.status=verdict.status;
 if ~report.passed,report.reason="A required representative scientific field failed";end
catch e
 report.reason=string(e.identifier)+": "+string(e.message);
end
end
function rows=walk(a,b,field,ra,rb,conditions,rows)
assert(strcmp(class(a),class(b)) && isequal(size(a),size(b)), ...
 'ejc:RepresentativeSchema','Class/shape differs: %s.',field);
rule=ejc_rule_lookup("study1","representative_study1_S_000.mat",field,class(a));
if isstruct(a)
 assert(isequal(fieldnames(a),fieldnames(b)),'ejc:RepresentativeSchema','Fields/order differ: %s.',field);
 rows=append(rows,rule,true,"EXACT_SCHEMA",[],field);
 for j=1:numel(a)
  for name=string(fieldnames(a)).'
   rows=walk(a(j).(name),b(j).(name),field+"[]."+name,ra,rb,conditions,rows);
  end
 end
elseif iscell(a)
 rows=append(rows,rule,true,"EXACT_SCHEMA",[],field);
 for j=1:numel(a),rows=walk(a{j},b{j},field+"{}",ra,rb,conditions,rows);end
elseif rule.original_group=="X_EXISTING"
 rows=append(rows,rule,true,"EXCLUDED_WALL_CLOCK",[],field);
elseif rule.policy_family=="E0"
 rows=append(rows,rule,isequaln(a,b),"EXACT",[],field);
elseif rule.policy_family=="P7"
 ok=isequaln(a(1),NaN) && isequaln(b(1),NaN) && conditions.passed;
 rows=append(rows,rule,ok,"P7_PARENT_VERDICTS",[],field);
else
 required=applicability(field,a,ra);
 assert(isequal(required,applicability(field,b,rb)), ...
  'ejc:RepresentativeApplicability','Applicability differs: %s.',field);
 if rule.original_group=="N_COV_EIG"
  absolute=repmat(1e-10*max(1,conditions.covarianceNorms),2,1);relative=1e-7;
 elseif rule.original_group=="N_GRAM_EIG"
  norms=conditions.gramNorms;norms(1)=0;
  absolute=repmat(1e-10*max(1,norms),2,1);relative=1e-7;
 else
  [absolute,relative]=ejc_rule_parameters(rule);
 end
 v=ejc_acceptance_numeric(a,b,absolute,relative,required);
 rows=append(rows,rule,v.passed,"NUMERIC_OR_EXPLICIT_NOT_APPLICABLE",v,field);
end
end
function required=applicability(field,a,r)
required=true(size(a));
switch field
 case "result[].gram",required(:,:,1)=false;
 case "result[].gramEigenvalues",required(:,1)=false;
 case "result[].lambda",required=r.idAttempted;
 case {"result[].plannedInput","result[].plannedOutput"}
  required=repmat(r.controlAccepted,size(a,1),1);
 case "result[].slack"
  required=repmat(reshape(r.controlAccepted,1,1,[]),size(a,1),size(a,2),1);
 case "result[].forecasts[].maxAffineFreezingError",required=false;
end
end
function rows=append(rows,rule,passed,status,numeric,field)
rows=[rows;struct('coverageId',rule.coverage_id,'field',field,'family',rule.policy_family, ...
 'units',rule.units_and_scaling,'passed',passed,'status',status,'numeric',numeric)];
end
function forecast_validity(f,cfg)
assert(isequal(f.fitSteps,cfg.fitSteps) && isequal(f.horizons,cfg.horizons) && ...
 isequal(f.anchors,cfg.anchors) && isequal(f.inputModes,{'held','rateLimited'}), ...
 'ejc:ForecastQueries','Declared forecast query selection differs.');
assert(all(f.valid,'all') && all(isfinite(f.oneStepErrors),'all') && ...
 f.allQueriesValid && isempty(f.failures),'ejc:ForecastValidity','Representative forecasts must be valid.');
assert(f.identityChecksEvaluated==isfinite(f.maxIdentityResidual) && ...
 f.firstStepCheckEvaluated==isfinite(f.maxFirstStepFreezingError),'ejc:ForecastFlags','Fresh forecast flags differ from their definitions.');
scale=max([1;abs(f.modelError(:));abs(f.freezingError(:));abs(f.totalError(:))]);
assert(f.maxIdentityResidual<=1e-11*scale && f.maxSquaredIdentityResidual<=1e-11*scale^2 && ...
 f.maxFirstStepFreezingError<=1e-11,'ejc:ForecastIdentities','An original forecast identity failed.');
assert(isequal(f.maxIdentityResidual,max(f.identityResidual,[],'all')) && ...
 isequal(f.maxSquaredIdentityResidual,max(f.squaredIdentityResidual,[],'all')) && ...
 isequal(f.maxFirstStepFreezingError,max(abs(f.freezingError(:,1,:,:)),[],'all')), ...
 'ejc:ForecastReduction','A cached forecast residual maximum differs from its own source.');
end
