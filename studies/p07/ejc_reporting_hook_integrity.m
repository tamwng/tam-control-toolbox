function proof=ejc_reporting_hook_integrity(root,row,actualHash)
%EJC_REPORTING_HOOK_INTEGRITY Exact B2 interface hashes, not a mutable allowance.
proof=struct('applied',false);
if ~any(string(row.path)==["studies/study2/study2_gram_report.m","plot_study2_journal.m"]),return;end
annexPath='evidence/p07_acceptance/blocker_repairs/REPORTING_HOOK_INTEGRITY_ANNEX.json';
annexHash='a3557128d5b402efdb80ffd83937dd49f32a7d1b949860109868ec00889bc682';
file=fullfile(root,annexPath);
if ~isfile(file) || ~strcmp(ejc_file_sha256(file),annexHash),return;end
annex=jsondecode(fileread(file));
if ~isfile(fullfile(root,annex.authority)) || ...
        ~strcmp(ejc_file_sha256(fullfile(root,annex.authority)),annex.authoritySHA256) || ...
        ~isfile(fullfile(root,annex.originalScientificManifest)) || ...
        ~strcmp(ejc_file_sha256(fullfile(root,annex.originalScientificManifest)),annex.originalScientificManifestSHA256),return;end
entry=annex.entries(string({annex.entries.path})==string(row.path));
if ~isscalar(entry) || ~strcmp(row.sha256,entry.oldSHA256) || ~strcmp(actualHash,entry.newSHA256),return;end
proof=struct('applied',true,'path',string(row.path),'oldSHA256',string(row.sha256), ...
    'newSHA256',string(actualHash),'annexSHA256',string(annexHash), ...
    'authoritySHA256',string(annex.authoritySHA256),'scope',"AUTHORIZED_B2_REPORTING_INTERFACE_ONLY");
end
