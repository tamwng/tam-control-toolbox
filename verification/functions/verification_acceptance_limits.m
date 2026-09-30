function [absolute,relative] = verification_acceptance_limits(family,subrule,unitScale,parentNorm)
% VERIFICATION_ACCEPTANCE_LIMITS Frozen additive absolute/relative comparison limits.
%  This primitive returns constants only. Establish field applicability,
%  units and parent identities before calling it. The elementwise rule is
%  abs(current-reference) <= absolute + relative*abs(reference).
%  unitScale is one declared unit per original coordinate; it is never
%  estimated from observed differences. Matrix eigenvalue rules additionally
%  require the reference parent norm. Unknown families/subrules raise errors.
%  These comparison limits are distinct from solver acceptance thresholds.
arguments
    family (1,1) string
    subrule (1,1) string = ""
    unitScale double = 1
    parentNorm (1,1) double = NaN
end
assert(isreal(unitScale) && ~isempty(unitScale) && all(unitScale==1,'all'), ...
    'ejc:UnsupportedUnits','Current approved coordinates use one declared unit per component.');
switch family
    case {"A1","A4"}, absolute=1e-10;relative=1e-10;
    case "A2", absolute=1e-7;relative=1e-7;
    case {"A3","A5","P1","P2","P10","P11"}
        absolute=1e-8*unitScale;relative=1e-7;
    case "P3"
        switch subrule
            case "calibration",absolute=1e-12*unitScale;relative=1e-10;
            case "lambda_energy",absolute=1e-10;relative=1e-7;
            case "regression",absolute=1e-8*unitScale;relative=1e-7;
            otherwise,error('ejc:UnknownRule','P3 requires an explicit subrule.');
        end
    case {"P4","P5"}
        relative=1e-7;
        switch subrule
            case "entries",absolute=1e-10;
            case "eigenvalues"
                assert(isfinite(parentNorm) && parentNorm>=0,'ejc:MissingParent','Eigenvalue limits need the reference parent norm.');
                absolute=1e-10*max(1,parentNorm);
            otherwise,error('ejc:UnknownRule','Matrix rules require entries or eigenvalues.');
        end
    case "P6", absolute=1e-8;relative=1e-7;
    case "P8"
        relative=1e-7;
        switch subrule
            case "kkt",absolute=1e-9;
            case "identity",absolute=1e-12*unitScale;
            otherwise,error('ejc:UnknownRule','P8 requires the residual type.');
        end
    case "P9"
        relative=1e-7;
        switch subrule
            case "state",absolute=1e-8*unitScale;
            case "diagnostic",absolute=1e-10*unitScale;
            otherwise,error('ejc:UnknownRule','P9 requires the physical quantity type.');
        end
    case "P12",absolute=1e-12;relative=1e-7;
    otherwise,error('ejc:UnknownRule','No numeric fallback for %s.',family);
end
end
