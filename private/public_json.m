function public_json(filename,value)
%PUBLIC_JSON Write a new UTF-8 metadata file without overwriting evidence.
assert(~isfile(filename),'example:ExistingOutput','Output exists: %s',filename);
fid = fopen(filename,'w','n','UTF-8');
assert(fid>=0,'example:OutputWrite','Cannot open output: %s',filename);
cleanup = onCleanup(@() fclose(fid));
fprintf(fid,'%s\n',jsonencode(value,PrettyPrint=true));
end
