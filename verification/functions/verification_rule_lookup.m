function rule=verification_rule_lookup(study,file,field,type,context)
%VERIFICATION_RULE_LOOKUP Select a rule from the fixed scientific field inventory.
root=fileparts(fileparts(fileparts(mfilename('fullpath'))));
if nargin<5,context=[];end
persistent inventory decisions
if isempty(inventory)
    inventory=readtable(fullfile(root,'verification/specification/field_coverage.csv'), ...
        'Delimiter',',','TextType','string','VariableNamingRule','preserve');
    decisions=containers.Map('KeyType','char','ValueType','any');
end
field=regexprep(string(field),'\(\d+\)','[]');field=regexprep(field,'\{\d+\}','{}');
selector="";
if istable(context) && height(context)==1
    for name=["fittingTransitions","window","quantity"]
        if ismember(name,string(context.Properties.VariableNames))
            selector=selector+"|"+name+"="+string(jsonencode(context.(name),ConvertInfAndNaN=false));
        end
    end
elseif isstruct(context),selector="|schema="+strjoin(string(fieldnames(context)),",");end
cacheKey=strjoin([string(study),string(file),field,string(type)],"|")+selector;
if isKey(decisions,cacheKey),rule=decisions(cacheKey);return;end
rows=inventory(inventory.study==string(study) & inventory.fieldPath==field & inventory.class==string(type),:);
keep=false(height(rows),1);
for k=1:height(rows)
    pattern="^"+replace(regexptranslate('escape',rows.family(k)),"\*","[^/]*")+"$";
    keep(k)=~isempty(regexp(string(file),pattern,'once'));
end
rows=rows(keep,:);
if height(rows)>1 && istable(context) && height(context)==1
    keep=false(height(rows),1);
    for k=1:height(rows)
        predicate=rows.row_selector(k);
        if startsWith(predicate,"fittingTransitions =="),keep(k)=context.fittingTransitions==200;
        elseif predicate=="fittingTransitions != 200",keep(k)=context.fittingTransitions~=200;
        elseif predicate=="window == whole",keep(k)=context.window=="whole";
        elseif predicate=="window == stationary",keep(k)=context.window=="stationary";
        elseif predicate=="quantity == RLS_covariance",keep(k)=context.quantity=="RLS_covariance";
        elseif predicate=="quantity == QP_Hessian",keep(k)=context.quantity=="QP_Hessian";
        end
    end
    rows=rows(keep,:);
elseif height(rows)>1 && isstruct(context)
    signature=strjoin(string(fieldnames(context)),",");
    rows=rows(rows.schemaFields==signature,:);
end
assert(height(rows)==1,'ejc:UnknownField','Unknown/ambiguous approved field: %s/%s:%s (%s).',study,file,field,type);
rule=table2struct(rows);
decisions(cacheKey)=rule;
end
