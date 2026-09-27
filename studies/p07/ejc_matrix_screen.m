function report = ejc_matrix_screen(M,kind,options)
%EJC_MATRIX_SCREEN Frozen P4-P7 verification on saved, original coordinates.
% Engineering screening envelopes are not certified singular-value bounds.
% No estimator, optimizer or trajectory is run and M is never modified.
arguments
    M
    kind (1,1) string {mustBeMember(kind,["covariance","gram","hessian"])}
    options.Regressors = []
    options.StoredCondition = []
    options.RequireRank (1,1) logical = false
    options.ExpectedRegressorCount (1,1) double = NaN
end
report = struct('kind',kind,'status',"FAILED_MATRIX_VALIDITY", ...
    'valid',false,'decompositionPassed',false,'formationPassed',false, ...
    'resolved',false,'rankResolved',false,'thresholdRank',NaN, ...
    'pointThresholdRank',NaN,'rankLower',NaN,'rankUpper',NaN, ...
    'robustlyThresholdDeficient',false,'dimension',NaN, ...
    'defaultRank',NaN,'conditionInsideEnvelope',false,'zeroMatrix',false, ...
    'structuralZero',false,'zeroParentsExact',false, ...
    'reason',"Invalid required matrix",'matrix',M);
if ~isa(M,'double') || ~isreal(M) || isempty(M) || ~ismatrix(M) || ...
        size(M,1)~=size(M,2) || any(~isfinite(M),'all'), return; end
n=size(M,1); report.dimension=n;
rho=100*n*eps; singular=svd(M); [U,S,V]=svd(M);
s1=singular(1); eta=rho*max(s1,realmin);
report.rho=rho; report.eta=eta; report.singularValues=singular;
report.singularValuesWithVectors=diag(S); report.norm2=s1;
report.svdReconstruction=norm(M-U*S*V',2);
report.svdOrthogonalityU=norm(U'*U-eye(n),2);
report.svdOrthogonalityV=norm(V'*V-eye(n),2);
% Exactly the eigenvalue diagnostic symmetrization used by the producers.
B=(M+M')/2; eigenvalues=eig(B); [Q,L]=eig(B);
report.eigenvalues=eigenvalues; report.eigenvaluesWithVectors=diag(L);
report.eigenReconstruction=norm(B-Q*L*Q',2);
report.eigenEquation=norm(B*Q-Q*L,2);
report.eigenOrthogonality=norm(Q'*Q-eye(n),2);
report.symmetryResidual=norm(M-M','fro');
report.symmetryLimit=100*eps*max(norm(M,'fro'),realmin);
report.defaultRank=rank(M); report.recomputedCondition=cond(M);
report.storedCondition=options.StoredCondition;
report.zeroMatrix=all(M==0,'all');
report.decompositionPassed=all(isfinite(singular)) && all(singular>=0) && ...
    all(diff(singular)<=0) && report.svdReconstruction<=eta && ...
    report.svdOrthogonalityU<=rho && report.svdOrthogonalityV<=rho && ...
    all(isfinite(eigenvalues)) && report.eigenReconstruction<=eta && ...
    report.eigenEquation<=eta && report.eigenOrthogonality<=rho;
if ~report.decompositionPassed
    report.reason="Required decomposition screen failed"; return
end
if kind=="covariance" || kind=="hessian"
    [~,flag]=chol(M); report.cholFlag=flag;
    if report.symmetryResidual>report.symmetryLimit || flag~=0
        report.reason="Required symmetry or positive definiteness failed"; return
    end
end
if kind=="gram"
    R=options.Regressors; m=size(R,1);
    if ~isa(R,'double') || ~isreal(R) || ~ismatrix(R) || m<1 || ...
            size(R,2)~=n || any(~isfinite(R),'all')
        report.reason="Missing or invalid own-run normalized regressors"; return
    end
    u=2^-53; denominator=1-(m+1)*u;
    if denominator<=0, report.reason="Invalid formation operation count"; return; end
    gamma=(m+1)*u/denominator;
    report.regressorCount=m;
    if ~isnan(options.ExpectedRegressorCount) && m~=options.ExpectedRegressorCount
        report.reason="Completed regressor row count differs";return
    end
    report.zeroParentsExact=all(R==0,'all');
    if report.zeroMatrix && ~report.zeroParentsExact
        report.reason="Zero Gram with nonzero own-parent rows, including underflow";return
    end
    report.formationResidual=norm(M-(R'*R)/m,2);
    report.formationLimit=2*gamma*norm((abs(R)'*abs(R))/m,2)+eta;
    report.formationPassed=report.formationResidual<=report.formationLimit;
    if ~report.formationPassed, report.reason="Gram formation screen failed"; return; end
else
    report.formationPassed=true; % Formation is not a P/H requirement.
end
report.valid=true;
tau=1e-10;
report.rankAbove=(singular-eta)>tau*(s1+eta);
report.rankBelow=(singular+eta)<tau*max(0,s1-eta);
report.rankBoundary=~(report.rankAbove | report.rankBelow);
report.pointThresholdRank=nnz(singular>tau*s1);
report.rankLower=nnz(report.rankAbove);
report.rankUpper=n-nnz(report.rankBelow);
report.rankResolved=report.rankLower==report.rankUpper;
report.robustlyThresholdDeficient=report.rankUpper<n;
report.rankThreshold=tau*s1;
report.rankAboveMargin=singular-eta-tau*(s1+eta);
report.rankBelowMargin=tau*max(0,s1-eta)-(singular+eta);
if report.rankResolved,report.thresholdRank=report.rankLower;end
report.algebraicRank="NOT_ESTABLISHED_BY_FLOATING_POINT_SCREEN";
report.envelope=[NaN NaN]; report.envelopeRelativeWidth=Inf;
if singular(end)>eta && ~report.zeroMatrix
    lo=max(0,s1-eta)/(singular(end)+eta);
    hi=(s1+eta)/(singular(end)-eta);
    % Enclose both rounded endpoint evaluations by outward binary64 steps.
    lo=max(0,lo-eps(lo)); hi=hi+eps(hi);
    report.envelope=[lo hi];
    report.envelopeRelativeWidth=(hi-lo)/max(1,(lo+hi)/2);
    report.resolved=all(isfinite(report.envelope)) && ...
        report.envelopeRelativeWidth<=1e-6;
    raw=[options.StoredCondition(:);report.recomputedCondition];
    report.conditionInsideEnvelope=all(isfinite(raw)) && all(raw>=lo & raw<=hi);
end
if report.zeroMatrix
    raw=[options.StoredCondition(:);report.recomputedCondition];
    if kind=="gram" && report.zeroParentsExact && all(isinf(raw) & raw>0)
        report.structuralZero=true;report.rankResolved=true;report.thresholdRank=0;
        report.pointThresholdRank=0;report.rankLower=0;report.rankUpper=0;
        report.robustlyThresholdDeficient=true;
        report.algebraicRank="EXACT_ZERO_MATRIX_RANK_ZERO";
        report.status="STRUCTURAL_ZERO_GRAM";
        report.reason="Exact zero matrix and nonempty exact zero own-parent rows; raw +Inf retained";
    else
        report.status="UNRESOLVED_ZERO_MATRIX";report.reason="Invalid structural-zero convention or parent";
    end
elseif options.RequireRank && ~report.rankResolved
    if kind=="gram" && report.robustlyThresholdDeficient && ~report.resolved
        report.status="ELIGIBLE_P7_UNRESOLVED_INTERMEDIATE_RANK";
        report.reason="Single-matrix prerequisite only; scope, counterpart and all original checks still required";
    elseif kind=="gram" && ~report.resolved && report.rankLower==n-1 && ...
            report.rankUpper==n && singular(end)>eta && ...
            all(isfinite(report.envelope)) && report.conditionInsideEnvelope
        report.status="ELIGIBLE_P7_FULL_RANK_BOUNDARY";
        report.reason="Only supplemental smallest-rank margin unresolved; paired point/original outcomes still required";
    else
        report.status="UNRESOLVED_RANK_BOUNDARY";
        report.reason="Rank interval leaves full rank possible or is outside the Gram amendment";
    end
elseif report.resolved && report.conditionInsideEnvelope
    report.status="RESOLVED"; report.reason="";
elseif report.resolved
    report.status="FAILED_CONDITION_ENVELOPE"; report.reason="Stored or recomputed condition outside own envelope";
else
    report.status="UNRESOLVED_CONDITION";
    report.reason="Required condition is not resolved by the frozen screen";
end
% This primitive never qualifies a run. Qualification also needs exact scope,
% pair/parent agreement, robust matching ranks and unchanged discrete checks.
end
