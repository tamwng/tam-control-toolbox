function solution = solve_mpc(qp)
%SOLVE_MPC Solve Eq. (39), accepting only a finite, KKT-checked solution.
% Requires Optimization Toolbox. quadprog uses interior-point-convex with
% optimality/constraint tolerances 1e-8. Acceptance requires exitflag > 0
% and normalized primal, stationarity, dual and complementarity <= 1e-7.
% Residuals are normalized by the magnitudes of their defining terms.
% Every rejection holds uNext equal to the committed input (Appendix A).

emptyResiduals = struct('primal',inf,'stationarity',inf,'dual',inf, ...
    'complementarity',inf);
solution = struct('accepted',false,'uNext',qp.uCommitted, ...
    'U',[],'Y',[],'slack',[],'exitflag',NaN,'message','', ...
    'residuals',emptyResiduals,'objective',NaN);
try
    validateattributes(qp.H,{'double'},{'2d','real','finite','square','nonempty'});
    validateattributes(qp.f,{'double'},{'real','finite','size',[size(qp.H,1),1]});
    options = optimoptions('quadprog','Algorithm','interior-point-convex', ...
        'Display','off','ConstraintTolerance',1e-8,'OptimalityTolerance',1e-8);
    [z,~,exitflag,output,multipliers] = quadprog(qp.H,qp.f, ...
        qp.Aineq,qp.bineq,[],[],qp.lb,qp.ub,[],options);
    solution.exitflag = exitflag;
    solution.message = output.message;
    if exitflag <= 0 || numel(z) ~= numel(qp.f) || any(~isfinite(z))
        return
    end
    residuals = kkt_residuals(qp,z,multipliers);
    solution.residuals = residuals;
    if any(structfun(@(value) ~isfinite(value) || value > 1e-7,residuals))
        solution.message = 'QP rejected: the normalized KKT residual exceeds 1e-7.';
        return
    end
    U = reshape(z(1:qp.nU),qp.m,qp.N-1);
    Y = reshape(qp.Y0+qp.Yu*z(1:qp.nU),qp.p,qp.N);
    slack = reshape(z(qp.nU+1:end),qp.nc,qp.N);
    objective = 0.5*z'*qp.H*z+qp.f'*z+qp.constant;
    if any(~isfinite(Y(:))) || ~isfinite(objective)
        solution.message = 'QP rejected: nonfinite prediction or objective.';
        return
    end
    solution.accepted = true;
    solution.uNext = U(:,1);
    solution.U = U;
    solution.Y = Y;
    solution.slack = slack;
    solution.objective = objective;
catch exception
    solution.message = sprintf('QP rejected (%s): %s',exception.identifier,exception.message);
end
end

function residuals = kkt_residuals(qp,z,multipliers)
% Treat finite lower/upper bounds as additional inequalities for auditing.
n = numel(z);
lower = find(isfinite(qp.lb));
upper = find(isfinite(qp.ub));
I = eye(n);
G = [qp.Aineq; -I(lower,:); I(upper,:)];
h = [qp.bineq; -qp.lb(lower); qp.ub(upper)];
mu = [multipliers.ineqlin; multipliers.lower(lower); multipliers.upper(upper)];
mu = mu(:);
g = G*z-h;
if isempty(g)
    primal = 0;
    dual = 0;
    complementarity = 0;
else
    primal = max([0;g./(1+abs(h)+abs(G)*abs(z))]);
    dual = max([0;-mu./(1+abs(mu))]);
    complementarity = max(abs(mu.*g)./(1+abs(mu).*max(1,abs(h))));
end
Hz = qp.H*z;
Gmu = G'*mu;
stationarity = norm(Hz+qp.f+Gmu,inf)/(1+norm(Hz,inf)+norm(qp.f,inf)+norm(Gmu,inf));
residuals = struct('primal',primal,'stationarity',stationarity, ...
    'dual',dual,'complementarity',complementarity);
end
