function study_separate_output(output,inputs)
%STUDY_SEPARATE_OUTPUT Keep derived evidence outside every supplied input tree.
% Explicit reference locations can be outside this checkout, so the local
% historical-path guard alone cannot protect them.
target=canonical(output);
for name=string(fieldnames(inputs)).'
    input=canonical(inputs.(name));
    assert(~strcmp(target,input) && ~startsWith(target,[input '/']) && ...
        ~startsWith(input,[target '/']), ...
        'study:InputOutputOverlap','Output overlaps supplied input %s.',name);
end
end
function value=canonical(value)
value=char(java.io.File(char(value)).getCanonicalPath());value=strrep(value,'\','/');
if ispc,value=lower(value);end
end
