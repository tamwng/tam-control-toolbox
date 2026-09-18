function [nextInput,prediction,control] = study3_fixed_step(model,theta,measurement,committed,preview,settings)
%STUDY3_FIXED_STEP Frozen/known snapshot through the shared predictor and QP.
% Only the supplied current parameter vector is available. No plant event,
% time index, true state, or future parameter schedule enters this calculation.
nextInput = committed;
prediction = [];
try
    [A,B,c,value] = freeze_predictor(model,measurement,committed,theta);
    prediction = struct('A',A,'B',B,'c',c,'value',value);
    qp = assemble_qp(A,B,c,model.C,measurement,committed,preview,settings);
    control = solve_mpc(qp);
    if control.accepted, nextInput = control.uNext; end
catch exception
    control = struct('accepted',false,'message',exception.message);
end
end
