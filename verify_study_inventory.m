function verify_study_inventory(study,source)
%VERIFY_STUDY_INVENTORY Require every declared scientific output of a study.
root=fileparts(mfilename('fullpath'));
inventory=jsondecode(fileread(fullfile(root,'verification','study_output_inventory.json')));
assert(isfield(inventory,study),'study:Inventory','No output contract for this study.');
files=study_output_identity(source);actual=string({files.path}).';
actual=actual(~startsWith(actual,{'review/','source_snapshot/'}) & ...
    ~ismember(actual,["verification.mat","execution_provenance.mat"]));
assert(isequal(sort(actual),sort(string(inventory.(study)))), ...
    'study:IncompleteInventory','The complete scientific output inventory differs for %s.',study);
end
