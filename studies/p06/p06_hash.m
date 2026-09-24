function value = p06_hash(file)
%P06_HASH Identify exact saved bytes, without loading or modifying the file.
fid = fopen(file,'rb');
assert(fid >= 0,'p06:MissingFile','Cannot read %s.',file);
close = onCleanup(@() fclose(fid));
md = java.security.MessageDigest.getInstance('SHA-256');
while ~feof(fid)
    md.update(fread(fid,1048576,'*uint8'));
end
value = lower(reshape(dec2hex(typecast(md.digest(),'uint8'),2).',1,[]));
end
