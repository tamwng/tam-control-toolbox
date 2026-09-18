function item = study3_case(id)
%STUDY3_CASE Model, update mode, and forgetting rule for one comparison.
% Event times, gain schedules, and true coefficients are not supplied here.
id = char(id);
item = struct('id',id,'name','','modelId','','mode','adaptive', ...
    'forgetting',struct('mode','none'));
switch id
    case 'A_none'
        item.modelId = 'A'; item.name = 'Affine, no forgetting';
    case 'A_fixed'
        item.modelId = 'A'; item.name = 'Affine, fixed forgetting';
        item.forgetting = struct('mode','fixed','lambda',0.99);
    case 'A_vrf'
        item.modelId = 'A'; item.name = 'Affine, variable forgetting';
        item.forgetting = variable_rule;
    case 'S_none'
        item.modelId = 'S'; item.name = 'Shared, no forgetting';
    case 'S_fixed'
        item.modelId = 'S'; item.name = 'Shared, fixed forgetting';
        item.forgetting = struct('mode','fixed','lambda',0.99);
    case 'S_vrf'
        item.modelId = 'S'; item.name = 'Shared, variable forgetting';
        item.forgetting = variable_rule;
    case 'S_pretrained'
        item.modelId = 'S'; item.mode = 'pretrained';
        item.name = 'Shared, pretrained-frozen';
    case 'S_prior'
        item.modelId = 'S'; item.mode = 'prior';
        item.name = 'Shared, prior-frozen';
    case 'K'
        item.modelId = 'K'; item.mode = 'known'; item.name = 'Known model';
    otherwise
        error('study3:UnknownCase','Unknown Study 3 comparison: %s.',id);
end
end

function rule = variable_rule
rule = struct('mode','variable','Nf',10,'sigma',0.03,'eta',0.02,'gamma',10);
end
