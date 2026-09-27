function [report,details]=ejc_saved_run_screen(r,study,cfg,fit)
%EJC_SAVED_RUN_SCREEN Independent saved-coordinate checks, without simulation.
% Does not establish cross-run agreement. Every required P/G/H is screened.
report=struct('gram',0,'covariance',0,'hessian',0,'fitCovariance',0, ...
    'eligibleIntermediate',0,'unresolvedGram',0,'blocking',0, ...
    'originalRankChecks',0,'acceptedPlansChecked',0,'failedChecks',struct([]));
details=struct('index',{},'kind',{},'status',{},'screen',{}, ...
    'originalRank',{},'originalValid',{},'originalCount',{});
if isfield(r,'fit'),fit=r.fit;n=fit.nEstimated;D=fit.D;else,n=r.nEstimated;D=fit.D;end
if isfield(r,'D'),D=r.D;end
if study=="study3",model=study1_model(r.modelId);
elseif study=="study4",model=study4_model(r.id);
elseif study=="study5",model=study5_model(r.id,cfg);
elseif study=="study2",model=study2_model(r.id);
else,model=study1_model(r.id);end
if isfield(r,'controlSettings'),settings=r.controlSettings;else,settings=cfg.control;end
if isfield(r,'p06'),settings.R=r.p06.R;end
N=size(r.plannedOutput,1);R=zeros(0,n);rowScale=1;
if isfield(r,'rowScale'),rowScale=r.rowScale;end
if ~isequal(settings.Hy,[1;-1]) || size(r.plannedInput,1)~=N-1 || ...
        size(r.slack,1)~=2 || size(r.slack,2)~=N
    report=fail(report,0,"plan","UNSUPPORTED_SHAPE_OR_UNITS",NaN,NaN);
end
for j=1:r.nSteps
    if r.controlAccepted(j)
        report.acceptedPlansChecked=report.acceptedPlansChecked+1;
        if any(~isfinite(r.plannedInput(:,j))) || any(~isfinite(r.plannedOutput(:,j))) || ...
                any(~isfinite(r.slack(:,:,j)),'all') || ~isequal(r.u(j+1),r.plannedInput(1,j))
            report=fail(report,j,"plan","REQUIRED_FINITE_PLAN_OR_EXACT_SELECTED_INPUT",NaN,NaN);
        end
        residual=r.solverResiduals(:,j);
        if ~(isfinite(r.exitflag(j)) && r.exitflag(j)>0 && all(isfinite(residual)) && all(residual<=1e-7))
            report=fail(report,j,"solver","ORIGINAL_KKT_OR_EXIT_FLAG",max(residual),1e-7);
        end
    elseif ~isequal(r.u(j+1),r.u(j))
        report=fail(report,j,"fallback","ORIGINAL_COMMITTED_INPUT",NaN,NaN);
    end
    if n>0
        p=ejc_matrix_screen(r.covariance(:,:,j),"covariance",StoredCondition=r.covarianceCondition(j));
        report.covariance=report.covariance+1;
        bad=~p.valid || ~p.resolved || ~p.conditionInsideEnvelope;
        if ~bad
            ev=sort(p.eigenvalues);v=ejc_acceptance_numeric(r.covarianceEigenvalues(:,j),ev([1 end]), ...
                1e-10*max(1,p.norm2),1e-7,true(2,1));bad=~v.passed;
        end
        if bad
            report=fail(report,j,"covariance",p.status,NaN,NaN);
            details(end+1)=detail(j,"covariance",p,r); %#ok<AGROW>
        end
        if j>1
            [response,Phi]=model_regression(model,r.y(j-1),r.y(j),r.u(j-1));
            if study=="study5"
                if ~isequaln(response,r.idResponse(j)) || ~isequaln(Phi,r.idRegressor(:,:,j))
                    % This is a separate calculated regression, so P3 applies.
                    a=ejc_acceptance_numeric(response,r.idResponse(j),1e-8,1e-7,true);
                    b=ejc_acceptance_numeric(Phi,r.idRegressor(:,:,j),1e-8,1e-7,true(size(Phi)));
                    if ~a.passed || ~b.passed,report=fail(report,j,"regressor","P3_RECONSTRUCTION",NaN,NaN);end
                end
            end
            R=[R;(rowScale*Phi)./D.'];R=R(max(1,size(R,1)-49):end,:); %#ok<AGROW>
            if size(R,1)~=r.gramCount(j),report=fail(report,j,"gramCount","EXACT_ROW_MEMBERSHIP",r.gramCount(j),size(R,1));end
            g=ejc_matrix_screen(r.gram(:,:,j),"gram",Regressors=R,StoredCondition=r.gramCondition(j),RequireRank=true,ExpectedRegressorCount=r.gramCount(j));
            report.gram=report.gram+1;
            bad=~g.valid || (g.zeroMatrix && ~g.structuralZero) || g.status=="UNRESOLVED_RANK_BOUNDARY" || ...
                g.status=="FAILED_CONDITION_ENVELOPE";
            if g.valid
                ev=sort(g.eigenvalues);v=ejc_acceptance_numeric(r.gramEigenvalues(:,j),ev([1 end]), ...
                    1e-10*max(1,g.norm2),1e-7,true(2,1));
                if ~v.passed,bad=true;report=fail(report,j,"gramEigenvalues","P5_RECOMPUTATION",v.maximumAbsoluteDifference,NaN);end
                if isfield(r,'gramRank')
                    report.originalRankChecks=report.originalRankChecks+1;
                    if ~isequal(r.gramRank(j),g.pointThresholdRank) || ~isequal(r.gramValid(j),true)
                        bad=true;report=fail(report,j,"gramRank","ORIGINAL_RANK_OR_VALIDITY",r.gramRank(j),g.pointThresholdRank);
                    end
                    if g.pointThresholdRank<n && ~isequal(r.gramCondition(j),Inf)
                        bad=true;report=fail(report,j,"gramCondition","ORIGINAL_DEFICIENT_INFINITY_CONVENTION",r.gramCondition(j),Inf);
                    end
                end
            end
            if bad,report=fail(report,j,"gram",g.status,NaN,NaN);end
            if ~g.resolved
                report.unresolvedGram=report.unresolvedGram+1;
                if ~bad && g.status=="ELIGIBLE_P7_UNRESOLVED_INTERMEDIATE_RANK"
                    report.eligibleIntermediate=report.eligibleIntermediate+1;
                end
            end
            if bad || ~g.resolved,details(end+1)=detail(j,"gram",g,r);end %#ok<AGROW>
        end
    end
    % H does not depend on the reference values. Use the original affine
    % assembly and weights with a zero preview; do not solve the QP.
    try
        qp=assemble_qp(r.A(j),r.B(j),r.c(j),1,r.y(j),r.u(j),zeros(1,N),settings);
        h=ejc_matrix_screen(qp.H,"hessian",StoredCondition=r.qpCondition(j));
        report.hessian=report.hessian+1;
        if ~h.valid || ~h.resolved || ~h.conditionInsideEnvelope
            report=fail(report,j,"hessian",h.status,NaN,NaN);
            details(end+1)=detail(j,"hessian",h,r); %#ok<AGROW>
        end
    catch exception
        report=fail(report,j,"hessian",string(exception.identifier)+": "+string(exception.message),NaN,NaN);
    end
end
if n>0 && isfield(fit,'covariance')
    for j=1:size(fit.covariance,3)
        p=ejc_matrix_screen(fit.covariance(:,:,j),"covariance");report.fitCovariance=report.fitCovariance+1;
        if ~p.valid
            report=fail(report,j,"fitCovariance",p.status,NaN,NaN);
            details(end+1)=detail(j,"fitCovariance",p,r); %#ok<AGROW>
        end
    end
end
end
function r=fail(r,j,field,status,actual,expected)
r.blocking=r.blocking+1;
row=struct('matlabIndex',j,'field',field,'status',status,'actual',actual,'expected',expected);
r.failedChecks=[r.failedChecks;row];
end
function d=detail(j,kind,s,r)
d=struct('index',j,'kind',kind,'status',s.status,'screen',s, ...
    'originalRank',NaN,'originalValid',false,'originalCount',NaN);
if kind=="gram"
    d.originalCount=r.gramCount(j);
    if isfield(r,'gramRank'),d.originalRank=r.gramRank(j);d.originalValid=r.gramValid(j);end
end
end
