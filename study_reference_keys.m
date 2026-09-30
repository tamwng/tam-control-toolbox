function value = study_reference_keys(value)
%STUDY_REFERENCE_KEYS Translate the public sensitivity name to the saved schema.
% Reject conflicting aliases instead of silently choosing one directory.
if isfield(value,'sensitivity')
    if isfield(value,'p06')
        a=char(java.io.File(char(value.sensitivity)).getCanonicalPath());
        b=char(java.io.File(char(value.p06)).getCanonicalPath());
        assert(strcmp(a,b),'study:ReferenceIdentity','Conflicting sensitivity directories.');
    end
    value.p06=value.sensitivity;
    value=rmfield(value,'sensitivity');
end
end
