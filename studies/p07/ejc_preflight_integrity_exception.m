function ejc_preflight_integrity_exception(exception)
%EJC_PREFLIGHT_INTEGRITY_EXCEPTION Integrity exceptions may never be collected
% as ordinary disagreements, including changes to newly generated inputs.
fatal=["ejc:PreflightIntegrity","ejc:InputChanged","ejc:SourceChanged", ...
    "ejc:PolicyChanged","ejc:ClaimSourceChanged","ejc:LocatorIntegrity", ...
    "ejc:StaleOriginalChecks","ejc:RecordMismatch","p06:ChangedRecord"];
if any(string(exception.identifier)==fatal),rethrow(exception);end
end
