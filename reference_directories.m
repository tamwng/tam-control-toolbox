function sources = reference_directories
%REFERENCE_DIRECTORIES Locations of supplied canonical comparison inputs.
% resolve_reference_inputs verifies their original membership and byte hashes.
root=fileparts(mfilename('fullpath'));
sources=struct;
for j=1:6
    key=sprintf('study%d',j);
    sources.(key)=fullfile(root,'references',key);
end
sources.sensitivity=fullfile(root,'references','sensitivity');
end
