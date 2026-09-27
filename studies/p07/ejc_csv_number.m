function value=ejc_csv_number(token)
%EJC_CSV_NUMBER Dot-decimal only, with explicit nonfinite/missing tokens.
if isempty(token) || strcmp(token,'NaN'),value=NaN;return;end
if any(strcmp(token,{'Inf','+Inf','-Inf'})),value=str2double(token);return;end
pattern='^[+-]?(([0-9]+(\.[0-9]*)?)|(\.[0-9]+))([eE][+-]?[0-9]+)?$';
assert(~isempty(regexp(token,pattern,'once')),'ejc:CSVNumericToken','Malformed or locale-dependent numeric token.');
value=str2double(token);
assert(isfinite(value),'ejc:CSVNumericRange','Finite token overflow or invalid parse.');
if value==0
    significand=regexp(token,'^[^eE]*','match','once');
    assert(~any(ismember(significand,'123456789')),'ejc:CSVNumericRange','Nonzero token underflowed to zero.');
end
end
