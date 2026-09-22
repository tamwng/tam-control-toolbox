function audit = study5_run_audit(r,cfg)
%STUDY5_RUN_AUDIT Saved-input replay and local refinements; no control rerun.
finePlant = physical_model(cfg.Ts,cfg.refinedPlantSubsteps);
finePredictor = physical_model(cfg.Ts,cfg.refinedPredictorSubsteps);
physical = ismember(r.id,{'I','K'}); n = r.nSteps;
audit = struct('plantLocalDifference',nan(1,n),'plantReplay',nan(1,n+1), ...
    'predictorLocalDifference',nan(1,n),'predictorJacobianDifference',nan(2,n), ...
    'zeroInputDifference',nan(1,n));
audit.plantReplay(1) = r.x(1);
model = study5_model(r.id,cfg);
for j = 1:n
    audit.plantLocalDifference(j) = r.x(j+1)-forward_map(finePlant,r.x(j),r.u(j),cfg.trueParameters);
    audit.plantReplay(j+1) = forward_map(finePlant,audit.plantReplay(j),r.u(j),cfg.trueParameters);
    if physical
        theta = r.mappedTheta(:,j);
        [value,A,B] = forward_map(finePredictor,r.y(j),r.u(j),theta);
        audit.predictorLocalDifference(j) = r.prediction(j)-value;
        audit.predictorJacobianDifference(:,j) = [r.A(j)-A;r.B(j)-B];
        exact = r.y(j)/sqrt(1+2*theta(2)*cfg.Ts*r.y(j)^2/theta(1));
        audit.zeroInputDifference(j) = forward_map(model,r.y(j),0,theta)-exact;
    end
end
audit.plantReplayDifference = r.x(1:n+1)-audit.plantReplay;
end
