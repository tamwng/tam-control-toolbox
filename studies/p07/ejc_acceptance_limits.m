function [absolute,relative] = ejc_acceptance_limits(family,subrule,unitScale,parentNorm)
%EJC_ACCEPTANCE_LIMITS Author-approved constants; no observed-delta input.
% Dispatch/applicability/units must be established before this primitive.
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
