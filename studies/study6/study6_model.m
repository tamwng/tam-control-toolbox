function [model,name,unit] = study6_model(plant,id,physicalSettings)
%STUDY6_MODEL Reuse the complete study maps and descriptive model names.
unit = 'dimensionless state';
switch char(plant)
    case 'A'
        model = study1_model(id);
        ids = {'A','S','W','R','P2','K'};
        names = {'Affine','Shared','Incorrectly shared','Relaxed','Complete quadratic','Known-model reference'};
        name = names{strcmp(ids,id)};
    case 'B'
        [model,~,~,name] = study2_model(id);
    case 'C'
        [model,~,~,name] = study5_model(id,physicalSettings); unit = 'rad/s';
end
if strcmp(id,'K'), name = 'Known-model reference'; end
end
