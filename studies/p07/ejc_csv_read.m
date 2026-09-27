function value=ejc_csv_read(file,study,relative)
%EJC_CSV_READ Header, ordering and types come from the approved schema.
root=fileparts(fileparts(fileparts(mfilename('fullpath'))));
persistent inventory
if isempty(inventory)
    inventory=readtable(fullfile(root,'evidence/p07_acceptance/full_field_coverage.csv'), ...
        'Delimiter',',','TextType','string','VariableNamingRule','preserve');
end
rows=inventory(inventory.study==string(study) & inventory.family==string(relative),:);
container=rows(rows.fieldPath=="value" & rows.class=="table",:);
assert(height(container)==1,'ejc:CSVSchema','Unknown/ambiguous table schema.');
if ismissing(container.schemaFields) || strlength(container.schemaFields)==0,headers=strings(1,0);
else,headers=split(container.schemaFields,',').';end
tokens=ejc_csv_tokens(file,headers);value=table;
for k=1:numel(headers)
    types=unique(rows.class(rows.fieldPath=="value."+headers(k)));
    assert(numel(types)==1,'ejc:CSVType','Ambiguous/unknown CSV column class.');
    col=tokens(:,k);
    switch types
        case 'double'
            v=zeros(size(col));for j=1:numel(col),v(j)=ejc_csv_number(col{j});end
        case 'logical'
            assert(all(ismember(string(col),["0","1"])),'ejc:CSVType','Invalid logical token.');v=string(col)=="1";
        case 'string',v=string(col);v(v=="")=missing;
        otherwise,error('ejc:CSVType','Unsupported frozen CSV type %s.',types);
    end
    value.(headers(k))=v;
end
end
