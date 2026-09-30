function [absolute,relative,subrule]=ejc_rule_parameters(rule,tableContext,parentNorm)
%EJC_RULE_PARAMETERS Exact subgroup and fixed row predicates; no float fallback.
if nargin<2,tableContext=table;end
if nargin<3,parentNorm=NaN;end
family=rule.policy_family;subrule="";field=string(rule.fieldPath);
if family=="P3"
    if rule.original_group=="N_SCALE",subrule="calibration";
    elseif contains(lower(field),"lambda") || contains(lower(field),"energy"),subrule="lambda_energy";
    else,subrule="regression";end
elseif any(family==["P4","P5"])
    if any(rule.original_group==["N_COV_EIG","N_GRAM_EIG"]),subrule="eigenvalues";
    else,subrule="entries";end
elseif family=="P8"
    if rule.original_group=="N_KKT",subrule="kkt";else,subrule="identity";end
elseif family=="P9"
    leaf=extractAfter(field,find(char(field)=='.',1,'last'));
    if any(leaf==["endpoints","independentEndpoint","zeroInputStates","plantReplay"]),subrule="state";
    else,subrule="diagnostic";end
end
[absolute,relative]=ejc_acceptance_limits(family,subrule,1,parentNorm);
if family=="A3"
    assert(istable(tableContext) && ismember('window',tableContext.Properties.VariableNames),'ejc:RuleRows','A3 requires window keys.');
    % P10 handles the non-whole rows; its constants currently coincide, but
    % the distinction remains part of dispatch and provenance.
elseif family=="A4"
    assert(istable(tableContext) && ismember('fittingTransitions',tableContext.Properties.VariableNames),'ejc:RuleRows','A4 requires exact prefix keys.');
    selected=tableContext.fittingTransitions==200;
    [other,~]=ejc_acceptance_limits("P10");absolute=repmat(other,height(tableContext),1);
    absolute(selected)=1e-10;
    % The relative component also varies; this branch is dispatched per row
    % by the caller so that no smaller-prefix scalar receives A4 implicitly.
    assert(height(tableContext)==1,'ejc:RuleRows','A4 must dispatch one prefix row at a time.');
    if ~selected,relative=1e-7;end
end
end
