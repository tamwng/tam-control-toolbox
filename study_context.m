function [cleanup,root,resolution] = study_context
%STUDY_CONTEXT Limit complete-study commands to this tree and MATLAB.
root = fileparts(mfilename('fullpath'));
oldPath = path; oldDirectory = pwd;
cleanup = onCleanup(@() restore(oldDirectory,oldPath));
restoredefaultpath; cd(root);
folders = {root,fullfile(root,'src'),fullfile(root,'studies','p06'), ...
    fullfile(root,'studies','p07')};
for j=1:6, folders{end+1}=fullfile(root,'studies',sprintf('study%d',j)); end
addpath(folders{:});
names = strings(0,1); files = strings(0,1);
for k=1:numel(folders)
    entries=dir(fullfile(folders{k},'*.m'));
    for j=1:numel(entries)
        [~,name]=fileparts(entries(j).name);
        expected=fullfile(entries(j).folder,entries(j).name);
        actual=which(name);
        assert(strcmpi(strrep(actual,'\','/'),strrep(expected,'\','/')), ...
            'study:FunctionResolution','Unexpected function: %s -> %s',name,actual);
        names(end+1,1)=string(name); files(end+1,1)=string(actual); %#ok<AGROW>
    end
end
resolution=table(names,files,'VariableNames',{'functionName','sourceFile'});
end
function restore(directory,originalPath)
cd(directory); path(originalPath);
end
