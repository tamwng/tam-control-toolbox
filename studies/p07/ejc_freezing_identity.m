function identity=ejc_freezing_identity(row)
%EJC_FREEZING_IDENTITY Definition-only selector; no observed value is read.
identity="";
if ~all(ismember(["metric","auditType","contrast","horizon","inputMode"],string(row.Properties.VariableNames)))
    return
end
if row.metric~="freezingRMS",return;end
assert(row.auditType=="within-run measured-initial-state sensitivity",'ejc:ClaimScope','Unknown freezing audit.');
assert(any(row.contrast==["S-A","S-W","S-R","R-P2"]),'ejc:ClaimScope','Unknown contrast.');
assert(any(row.inputMode==["held","recordedRateLimited"]),'ejc:ClaimScope','Unsupported input mode.');
assert(any(row.horizon==[1 2 5 10 20]),'ejc:ClaimScope','Unsupported horizon.');
models=split(row.contrast,'-');
if row.horizon==1,identity="FIRST_STEP_CONTACT";
elseif row.inputMode=="held" && all(ismember(models,["A","S","W","R","K"]))
    identity="HELD_INPUT_AFFINE_IN_STATE";
end
end
