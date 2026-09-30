function report=verification_csv_mat_link(file,source)
%VERIFICATION_CSV_MAT_LINK Direct saved table -> actual serialized columns, no inference.
assert(istable(source),'ejc:CSVSource','The declared unrounded source must be a table.');
tokens=verification_csv_tokens(file,string(source.Properties.VariableNames));
assert(size(tokens,1)==height(source),'ejc:CSVRows','CSV row count differs from its declared source.');
report=struct('passed',true,'rows',height(source),'columns',width(source), ...
    'numericValues',0,'exactValues',0,'maximumEncodingDifference',0,'failures',struct([]));
for k=1:width(source)
    name=source.Properties.VariableNames{k};v=source.(name);
    assert(size(v,2)==1 || isempty(v),'ejc:CSVSource','Unsupported multicolumn table variable.');
    for j=1:height(source)
        raw=tokens{j,k};ok=false;delta=NaN;limit=NaN;
        if isa(v,'double')
            a=verification_csv_number(raw);b=v(j);report.numericValues=report.numericValues+1;
            if isfinite(b)
                limit=verification_csv_encoding_budget(b);delta=abs(a-b);ok=isfinite(a) && delta<=limit;
                if b==0,ok=ok && a==0;end
                report.maximumEncodingDifference=max(report.maximumEncodingDifference,delta);
            else,ok=isequaln(a,b);end
        elseif islogical(v)
            ok=any(strcmp(raw,{'0','1'})) && str2double(raw)==double(v(j));report.exactValues=report.exactValues+1;
        elseif isstring(v) || iscellstr(v)
            expected=string(v(j));if ismissing(expected),expected="";end
            ok=string(raw)==expected;report.exactValues=report.exactValues+1;
        else,error('ejc:CSVSource','Unsupported source column class %s.',class(v));end
        if ~ok
            report.passed=false;
            report.failures=[report.failures;struct('column',string(name),'row',j, ...
                'rawToken',string(raw),'encodingDelta',delta,'encodingBudget',limit)]; %#ok<AGROW>
        end
    end
end
end
