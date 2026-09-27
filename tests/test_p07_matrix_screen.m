function tests=test_p07_matrix_screen
tests=functiontests(localfunctions);
end
function setupOnce(t)
root=fileparts(fileparts(mfilename('fullpath'))); t.TestData.path=path;
addpath(fullfile(root,'studies','p07'));
end
function teardownOnce(t)
path(t.TestData.path);
end
function test_resolved_covariance(t)
M=diag([1 2 3]); r=ejc_matrix_screen(M,"covariance",StoredCondition=3);
verifyTrue(t,r.valid && r.decompositionPassed && r.resolved);
verifyEqual(t,r.status,"RESOLVED"); verifyEqual(t,M,diag([1 2 3]));
verifyLessThanOrEqual(t,r.envelope(1),3); verifyGreaterThanOrEqual(t,r.envelope(2),3);
end
function test_invalid_covariance_and_hessian(t)
for kind=["covariance","hessian"]
    r=ejc_matrix_screen([1 .1;0 1],kind); verifyFalse(t,r.valid);
    r=ejc_matrix_screen(diag([1 -1]),kind); verifyFalse(t,r.valid);
    r=ejc_matrix_screen(diag([1 0]),kind); verifyFalse(t,r.valid);
    r=ejc_matrix_screen(diag([1 1e-14]),kind);
    verifyTrue(t,r.valid); verifyFalse(t,r.resolved);
    verifyEqual(t,r.status,"UNRESOLVED_CONDITION");
end
end
function test_formation_and_mutation(t)
R=[1 2;3 4;5 6]; G=R'*R/3; original=G;
r=ejc_matrix_screen(G,"gram",Regressors=R,RequireRank=true);
verifyTrue(t,r.valid && r.formationPassed && r.rankResolved);
verifyEqual(t,G,original);
r=ejc_matrix_screen(G+1e-6*eye(2),"gram",Regressors=R);
verifyFalse(t,r.valid); verifyFalse(t,r.formationPassed);
r=ejc_matrix_screen(G,"gram"); verifyFalse(t,r.valid);
r=ejc_matrix_screen(G,"gram",Regressors=R(:,1)); verifyFalse(t,r.valid);
end
function test_tiny_singular_and_rank_boundary(t)
for z=[1e-20 1e-10 2e-10]
    G=diag([1 z]);R=sqrt(2)*diag([1 sqrt(z)]);
    r=ejc_matrix_screen(G,"gram",Regressors=R,RequireRank=true);
    verifyTrue(t,r.valid);
    if z==1e-10
        verifyEqual(t,r.status,"ELIGIBLE_P7_FULL_RANK_BOUNDARY");
        verifyFalse(t,r.rankResolved);
    else
        verifyTrue(t,r.rankResolved);
        verifyEqual(t,r.thresholdRank,1+double(z>1e-10));
        verifyEqual(t,r.status,"UNRESOLVED_CONDITION");
    end
end
end
function test_zero_and_nonfinite(t)
r=ejc_matrix_screen(zeros(2),"gram",Regressors=zeros(2));
verifyTrue(t,r.zeroMatrix); verifyEqual(t,r.status,"STRUCTURAL_ZERO_GRAM");
for M={NaN,Inf,complex(1,1),single(1),[],[1 2]}
    r=ejc_matrix_screen(M{1},"covariance");verifyFalse(t,r.valid);
end
end
function test_condition_envelope_is_mandatory(t)
for bad=[2,NaN,Inf]
    r=ejc_matrix_screen(eye(2),"hessian",StoredCondition=bad);
    verifyTrue(t,r.resolved);verifyFalse(t,r.conditionInsideEnvelope);
    verifyEqual(t,r.status,"FAILED_CONDITION_ENVELOPE");
end
end
