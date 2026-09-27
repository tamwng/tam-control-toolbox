function scope=ejc_claim_scope(rule,row)
%EJC_CLAIM_SCOPE Closed post-failure semantic map, independent of magnitude.
scope=struct('applicable',false,'kind',"STRICT",'identityClass',"",'sourceStudy',string(rule.study), ...
    'sourceFile',string(rule.family),'sourceField',string(rule.fieldPath));
root=fileparts(fileparts(fileparts(mfilename('fullpath'))));
persistent map
if isempty(map),map=readtable(fullfile(root,'evidence/p07_acceptance/freezing_identity/CLAIM_APPLICABILITY.csv'),'TextType','string');end
ix=map.coverage_id==string(rule.coverage_id);
if ~any(ix),return;end
assert(all(map.study(ix)==string(rule.study) & map.family(ix)==string(rule.family) & ...
    map.fieldPath(ix)==string(rule.fieldPath)),'ejc:ClaimScope','Claim inventory binding differs.');
if string(rule.original_group)=="N_CROSS"
    scope.applicable=true;scope.kind="DESCRIPTIVE_ALGEBRAIC_CROSS_TERM";
elseif string(rule.policy_family)=="P11" && ismember('metric',row.Properties.VariableNames)
    if any(row.metric==["meanCrossTerm","meanCombinedCrossTerm"])
        scope.applicable=true;scope.kind="DESCRIPTIVE_ALGEBRAIC_CROSS_TERM";
    elseif any(string(rule.coverage_id)==["F0301","F0302","F0303","F4022","F4023","F4024"])
        scope.identityClass=ejc_freezing_identity(row);
        scope.applicable=scope.identityClass~="";
        if scope.applicable,scope.kind="STRUCTURAL_NULL_CONTRAST";end
    end
end
if ~scope.applicable,return;end
% Exact aliases only. They inherit the source rule after exact row linkage.
if scope.sourceStudy=="paper"
    switch scope.sourceFile
        case "paper_A17_study1_common_forecasts.csv"
            scope.sourceStudy="study1";scope.sourceFile="tables/forecast_paired_contrasts.csv";
        case "paper_A17_study1_retrospective.csv"
            scope.sourceStudy="study1";scope.sourceFile="tables/measured_initialization_paired_contrasts.csv";
        case {"paper_table12.csv","paper_table12_reference.csv"}
            scope.sourceStudy="study6";scope.sourceFile="tables/measurement.csv";
        otherwise,error('ejc:ClaimScope','No approved claim source for this paper export.');
    end
end
end
