function hash=verification_file_sha256(file)
%VERIFICATION_FILE_SHA256 Exact bytes; no source normalization or timestamp identity.
fid=fopen(file,'rb');assert(fid>=0,'ejc:MissingSource','Cannot read %s.',file);
cleanup=onCleanup(@()fclose(fid));
digest=java.security.MessageDigest.getInstance('SHA-256');
while ~feof(fid)
    bytes=fread(fid,1024*1024,'*uint8');digest.update(bytes);
end
hash=lower(reshape(dec2hex(typecast(digest.digest(),'uint8'),2).',1,[]));
end
