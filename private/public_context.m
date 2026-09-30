function [cleanup,root,resolution] = public_context
%PUBLIC_CONTEXT Resolve public commands only in this source tree and MATLAB.
% The current directory precedes MATLAB's path. Move to this source root as
% well as resetting the path, then restore both when the caller exits.
root = fileparts(fileparts(mfilename('fullpath')));
previousPath = path; previousDirectory = pwd;
cleanup = onCleanup(@() restore_context(previousDirectory,previousPath));
restoredefaultpath;
cd(root);
folders = {root,fullfile(root,'src'),fullfile(root,'studies','study1'), ...
    fullfile(root,'studies','p07')};
addpath(folders{:});
names = strings(0,1); locations = strings(0,1);
for k = 1:numel(folders)
    files = dir(fullfile(folders{k},'*.m'));
    for j = 1:numel(files)
        [~,name] = fileparts(files(j).name);
        actual = which(name);
        expected = fullfile(files(j).folder,files(j).name);
        assert(strcmpi(strrep(actual,'\','/'),strrep(expected,'\','/')), ...
            'example:FunctionResolution','Unexpected function resolution: %s -> %s',name,actual);
        names(end+1,1) = string(name); locations(end+1,1) = string(actual); %#ok<AGROW>
    end
end
resolution = table(names,locations,'VariableNames',{'functionName','sourceFile'});
end

function restore_context(directory,originalPath)
cd(directory);
path(originalPath);
end
