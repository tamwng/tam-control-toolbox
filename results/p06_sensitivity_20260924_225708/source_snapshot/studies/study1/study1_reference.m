function reference = study1_reference(t)
%STUDY1_REFERENCE Six prescribed twenty-second plateaus, Eq. (46).
validateattributes(t,{'double'},{'real','finite','nonnegative'});
levels = [0.6,-0.5,0.75,-0.4,0.6,0];
indices = min(5,floor(t/20))+1;
reference = reshape(levels(indices(:)),size(t));
end
