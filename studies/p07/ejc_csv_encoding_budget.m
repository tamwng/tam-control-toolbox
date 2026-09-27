function budget=ejc_csv_encoding_budget(values)
%EJC_CSV_ENCODING_BUDGET Approved 15-significant-digit binary64 representation.
assert(isa(values,'double') && isreal(values) && all(isfinite(values),'all'), ...
    'ejc:CSVEncoding','Encoding budget requires finite real double values.');
budget=zeros(size(values));
for j=find(values(:)~=0).'
    % A round-trip decimal exponent avoids log10 rounding across a decade.
    text=sprintf('%.16e',abs(values(j)));e=str2double(extractAfter(string(text),'e'));
    quantum=0.5*10^(e-14);
    b=quantum+eps(abs(values(j)));
    budget(j)=b+eps(b); % Outward rounding, including subnormal quantum.
end
end
