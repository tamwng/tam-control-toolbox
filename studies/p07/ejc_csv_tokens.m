function tokens=ejc_csv_tokens(file,headers)
%EJC_CSV_TOKENS Explicit comma/quote parsing; backslashes are ordinary text.
text=fileread(file);
% The numerical archives' ordinary unquoted rows can be split in compiled
% string operations. Retain the same strict widths, empty fields, line endings
% and NUL rejection; the state machine below still handles quoted records.
if ~contains(text,'"') && ~isempty(text)
    assert(~any(text==char(0)),'ejc:CSVQuotes','Invalid NUL character.');
    lines=regexp(text,'\r\n|\r|\n','split');
    if text(end)==char(10) || text(end)==char(13),lines(end)=[];end
    headers=reshape(string(headers),1,[]);
    first=string(strsplit(lines{1},',','CollapseDelimiters',false));
    assert(isequal(first,headers) && numel(unique(headers))==numel(headers), ...
        'ejc:CSVSchema','CSV header/order/duplicates differ from the frozen schema.');
    tokens=cell(numel(lines)-1,numel(headers));
    for j=2:numel(lines)
        values=strsplit(lines{j},',','CollapseDelimiters',false);
        assert(numel(values)==numel(headers),'ejc:CSVSchema','CSV row width differs.');
        tokens(j-1,:)=values;
    end
    return
end
rows={};row={};token='';quoted=false;afterQuote=false;k=1;
while k<=numel(text)
    c=text(k);
    if quoted
        if c=='"'
            if k<numel(text) && text(k+1)=='"',token(end+1)='"';k=k+1; %#ok<AGROW>
            else,quoted=false;afterQuote=true;end
        else,token(end+1)=c;end %#ok<AGROW>
    elseif c==','
        row{end+1}=token;token='';afterQuote=false; %#ok<AGROW>
    elseif c==char(10) || c==char(13)
        if c==char(13) && k<numel(text) && text(k+1)==char(10),k=k+1;end
        row{end+1}=token;rows{end+1}=row;row={};token='';afterQuote=false; %#ok<AGROW>
    elseif c=='"'
        assert(isempty(token) && ~afterQuote,'ejc:CSVQuotes','Malformed CSV quote.');quoted=true;
    else
        assert(~afterQuote && c~=char(0),'ejc:CSVQuotes','Invalid character after closing quote.');
        token(end+1)=c; %#ok<AGROW>
    end
    k=k+1;
end
assert(~quoted,'ejc:CSVQuotes','Unclosed CSV quote.');
if ~isempty(row) || ~isempty(token) || afterQuote
    row{end+1}=token;rows{end+1}=row;
end
headers=reshape(string(headers),1,[]);
if isempty(rows)
    assert(isempty(headers),'ejc:CSVSchema','Zero-byte file requires an explicitly empty schema.');tokens=cell(0,0);return
end
assert(isequal(string(rows{1}),headers) && numel(unique(headers))==numel(headers), ...
    'ejc:CSVSchema','CSV header/order/duplicates differ from the frozen schema.');
tokens=cell(numel(rows)-1,numel(headers));
for j=2:numel(rows)
    assert(numel(rows{j})==numel(headers),'ejc:CSVSchema','CSV row width differs.');tokens(j-1,:)=rows{j};
end
end
