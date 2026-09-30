function entries = study_output_identity(source)
%STUDY_OUTPUT_IDENTITY Exact saved scientific files, without the manifest itself.
files=[dir(fullfile(source,'**','*.mat'));dir(fullfile(source,'**','*.csv'))];
entries=struct('path',{},'sha256',{});
for j=1:numel(files)
    file=fullfile(files(j).folder,files(j).name);
    relative=replace(string(file),string(source)+filesep,'');
    if startsWith(replace(relative,filesep,'/'),'source_snapshot/'),continue;end
    entries(end+1)=struct('path',char(replace(relative,filesep,'/')), ...
        'sha256',verification_file_sha256(file)); %#ok<AGROW>
end
if ~isempty(entries),[~,order]=sort(string({entries.path}));entries=entries(order);end
end
