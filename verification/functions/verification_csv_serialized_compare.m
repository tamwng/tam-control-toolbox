function report=verification_csv_serialized_compare(a,b,absolute,relative,required,contract)
%VERIFICATION_CSV_SERIALIZED_COMPARE P13 for an explicitly absent historical scalar.
% A caller must validate the exact emitter and both saved-MAT source recipes.
needed=["knownDouble15DigitEmitter","currentSourceValidated", ...
    "referenceSourceValidated","historicalUnroundedAbsent"];
for name=needed
    assert(isfield(contract,name) && islogical(contract.(name)) && ...
        isscalar(contract.(name)) && contract.(name), ...
        'ejc:CSVContract','Missing explicit source/precision/absence contract: %s.',name);
end
% Let the shared numeric primitive reject shapes, types and required masks.
ea=zeros(size(a));eb=zeros(size(b));
if isa(a,'double') && isreal(a),ea(isfinite(a))=verification_csv_encoding_budget(a(isfinite(a)));end
if isa(b,'double') && isreal(b),eb(isfinite(b))=verification_csv_encoding_budget(b(isfinite(b)));end
if ~isequal(size(a),size(b))
    report=verification_acceptance_numeric(a,b,absolute,relative,required);
else
    budget=absolute+ea+(1+relative)*eb;
    report=verification_acceptance_numeric(a,b,budget,relative,required);
end
report.mode="SERIALIZED_SCALAR_COMPARISON_WITH_MAT_SOURCE_SUPPORT";
report.unroundedHistoricalAgreementEstablished=false;
end
