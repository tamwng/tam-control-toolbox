function r = study2_reference(t,amplitude)
%STUDY2_REFERENCE One prescribed amplitude of Eq. (49); t is in seconds.
validateattributes(t,{'double'},{'real','finite','nonnegative'});
validateattributes(amplitude,{'double'},{'scalar','real','finite','positive'});
r = 0.08+amplitude*sin(2*pi*0.05*t);
end
