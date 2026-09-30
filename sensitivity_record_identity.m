function proof = sensitivity_record_identity(current,reference)
%SENSITIVITY_RECORD_IDENTITY Exact input content, with separate file-byte identities.
% MAT headers contain creation dates. Content agreement requires identical
% variables, field order, classes, shapes and values, including nonfinite masks.
assert(isfile(current) && isfile(reference),'study:ReferenceUnavailable', ...
    'Both saved input-record files are required.');
a=load(current);b=load(reference);
assert(isequal(fieldnames(a),{'records'}) && isequal(fieldnames(b),{'records'}) && ...
    exact_value(a,b),'study:SensitivityRecordIdentity', ...
    'Saved sensitivity input records differ from the canonical records.');
proof=struct('passed',true,'currentFile',char(current),'referenceFile',char(reference), ...
    'currentSHA256',verification_file_sha256(current), ...
    'referenceSHA256',verification_file_sha256(reference), ...
    'requirement','Exact saved variables, fields, classes, shapes and values; no numerical tolerance');
end
function equal=exact_value(a,b)
equal=strcmp(class(a),class(b)) && isequal(size(a),size(b));
if ~equal,return;end
if isstruct(a)
    equal=isequal(fieldnames(a),fieldnames(b));if ~equal,return;end
    for j=1:numel(a)
        for name=reshape(fieldnames(a),1,[])
            if ~exact_value(a(j).(name{1}),b(j).(name{1})),equal=false;return;end
        end
    end
elseif iscell(a)
    for j=1:numel(a),if ~exact_value(a{j},b{j}),equal=false;return;end,end
else
    equal=isequaln(a,b);
end
end
