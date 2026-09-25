function report = ejc_archive_integrity(output)
%EJC_ARCHIVE_INTEGRITY Rehash the protected selection against Gate B's manifest.
% Reads every retained scientific record, including the MAT compatibility
% fixture. Evidence is written only to the caller's new output directory.
root = fileparts(mfilename('fullpath'));
ejc_assert_writable(output);
file = fullfile(root,'evidence','p07_gate_b','P07_SOURCE_SHA256.csv');
assert(isfile(file),'ejc:MissingManifest','Protected source manifest is missing.');
expected = readtable(file,'TextType','string');
actual = expected; actual.sha256(:) = ""; actual.bytes(:) = NaN;
for j = 1:height(expected)
    source = fullfile(root,expected.relative_path(j));
    assert(isfile(source),'ejc:MissingRecord','Protected record missing: %s',source);
    info = dir(source); actual.bytes(j) = info.bytes;
    actual.sha256(j) = p06_hash(source);
end
actual.passed = actual.bytes==expected.bytes & actual.sha256==expected.sha256;
if ~isfolder(output), mkdir(output); end
writetable(actual,fullfile(output,'archive_integrity.csv'));
report = struct('fileCount',height(actual),'totalBytes',sum(actual.bytes), ...
    'allPassed',all(actual.passed),'manifestSHA256',p06_hash(file));
assert(report.allPassed,'ejc:ArchiveChanged','Protected archive checksums differ. Stop for review.');
end
