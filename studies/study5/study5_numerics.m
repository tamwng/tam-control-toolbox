function audit = study5_numerics(cfg)
%STUDY5_NUMERICS Offline grid quadrature and independent propagation checks.
% The refined integral is adaptive quadrature of a separate ode45 solution.
% It is NOT inferred from the integrated-equation identity. Refinement and
% analytic state errors are retained separately from equation residuals.
[x,u] = ndgrid(cfg.auditStates,cfg.auditInputs); count = numel(x);
audit = struct('x',x(:),'u',u(:),'sampling',cfg.auditSampling, ...
    'substeps',[5 10 20 40],'endpoints',nan(count,4,3), ...
    'independentEndpoint',nan(count,3),'refinedIntegral',nan(count,3), ...
    'trapezoid',nan(count,3),'trapezoidResidual',nan(count,3), ...
    'refinedResidual',nan(count,3),'zeroInputError',nan(21,4,3), ...
    'zeroInputStates',cfg.auditStates,'relativeTolerance',cfg.auditRelativeTolerance, ...
    'absoluteTolerance',cfg.auditAbsoluteTolerance,'endpointSubstepsForQuadrature',40);
theta = cfg.trueParameters; J = theta(1); d = theta(2);
options = odeset('RelTol',cfg.auditRelativeTolerance,'AbsTol',cfg.auditAbsoluteTolerance);
for s = 1:3
    Ts = cfg.auditSampling(s);
    for resolution = 1:4
        model = physical_model(Ts,audit.substeps(resolution));
        for q = 1:count
            audit.endpoints(q,resolution,s) = forward_map(model,x(q),u(q),theta);
        end
        for q = 1:21
            initial = cfg.auditStates(q);
            exact = initial/sqrt(1+2*d*Ts*initial^2/J);
            audit.zeroInputError(q,resolution,s) = forward_map(model,initial,0,theta)-exact;
        end
    end
    for q = 1:count
        solution = ode45(@(~,state) (u(q)-d*state.^3)/J,[0 Ts],x(q),options);
        audit.independentEndpoint(q,s) = deval(solution,Ts);
        I = integral(@(t) deval(solution,t).^3,0,Ts, ...
            'RelTol',cfg.auditRelativeTolerance,'AbsTol',cfg.auditAbsoluteTolerance);
        endpoint = audit.endpoints(q,4,s);
        trap = Ts*(x(q)^3+endpoint^3)/2;
        audit.refinedIntegral(q,s) = I; audit.trapezoid(q,s) = trap;
        audit.trapezoidResidual(q,s) = (Ts*u(q)-J*(endpoint-x(q))-d*trap)/Ts;
        audit.refinedResidual(q,s) = (Ts*u(q)-J*(endpoint-x(q))-d*I)/Ts;
    end
end
audit.plantRefinement = squeeze(audit.endpoints(:,3,:)-audit.endpoints(:,4,:));
audit.predictorRefinement = squeeze(audit.endpoints(:,1,:)-audit.endpoints(:,2,:));
audit.independentStateError = audit.endpoints-reshape(audit.independentEndpoint,count,1,3);
% Reuse the existing test_physical nonzero-input absolute state tolerance.
% This is an engineering check, not a manuscript performance requirement.
audit.stateCheckTolerance = 1e-8;
audit.stateChecksPassed = all(abs(audit.independentStateError) <= audit.stateCheckTolerance,'all') && ...
    all(abs(audit.zeroInputError) <= audit.stateCheckTolerance,'all');
end
