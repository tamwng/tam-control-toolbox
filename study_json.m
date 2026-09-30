function study_json(file,value)
%STUDY_JSON Write a complete metadata record to the selected output directory.
fid=fopen(file,'w');assert(fid>=0,'study:Write','Cannot write %s.',file);
cleanup=onCleanup(@()fclose(fid));fprintf(fid,'%s\n',jsonencode(value,PrettyPrint=true));
end
