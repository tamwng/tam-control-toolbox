function status=ejc_preflight_branch(integrity,originalValidity,comparison,dependencies)
%EJC_PREFLIGHT_BRANCH Diagnostic routing only; never manufactures agreement.
assert(isequal(integrity,true),'ejc:PreflightIntegrity','Stop the entire diagnostic batch on integrity failure.');
if ~all(dependencies),status="BLOCKED_DEPENDENCY";
elseif ~originalValidity,status="FAILED_SCIENTIFIC_VALIDITY";
elseif ~comparison,status="FAILED_COMPARISON_VALID_SCIENTIFIC_INPUTS";
else,status="DIAGNOSTIC_CHECKS_PASSED_NOT_CERTIFICATION";
end
end
