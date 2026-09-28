function report=ejc_study34_bind(extracted,cfg,output,diagnostic)
%EJC_STUDY34_BIND Complete the approved same-record portable assertion pass.
% The original verifier must first finish EVERY non-hook requirement. Its
% evidence is bound to the checker/policy and every original source file.
% This is only the two named assertion sites, not full/paper acceptance.
if nargin<4,diagnostic="";end
assert(any(string(diagnostic)==["","COLLECT_DIAGNOSTIC_FAILURES"]),'ejc:DiagnosticMode','Unknown mode.');
assert(~isfolder(output) && ~isfile(output),'ejc:ExistingEvidence','Output exists.');
mkdir(output);started=tic;
root=fileparts(fileparts(fileparts(mfilename('fullpath'))));
study=extracted.study;
assert(any(study==["study3","study4"]),'ejc:BindingScope','Unlisted study.');
assert(isequal(extracted.originalRequirementsCompleted,true) && ...
    extracted.status=="ORIGINAL_REQUIREMENTS_EXECUTED_PORTABLE_PENDING", ...
    'ejc:MissingOriginalChecks','Original verifier did not complete every non-hook requirement.');
assert(strcmp(extracted.policySHA256,ejc_file_sha256(fullfile(root,'studies/p07/p07_acceptance_policy.json'))) && ...
    strcmp(extracted.verifierSHA256,ejc_file_sha256(fullfile(root,'studies',study,study+"_verify_results.m"))) && ...
    strcmp(extracted.extractorSHA256,ejc_file_sha256(fullfile(root,'studies/p07/ejc_study34_extract.m'))), ...
    'ejc:StaleOriginalChecks','Policy or original checker changed after execution.');
for row=extracted.inputManifest.'
    info=dir(row.path);
    assert(isscalar(info) && info.bytes==row.bytes && strcmp(row.sha256,ejc_file_sha256(row.path)), ...
        'ejc:StaleOriginalChecks','A checked source changed: %s.',row.path);
end
scope="F0894";if study=="study4",scope="F1344";end
rule=ejc_rule_lookup(study,"runs/case.mat","value[].result[].gramCondition","double");
assert(rule.coverage_id==scope && rule.policy_family=="P7",'ejc:BindingScope','Approved passive scope changed.');
% The approved passive-use finding must remain true for all controller code.
scientific=dir(fullfile(root,'src','**','*.m'));
for f=scientific.'
    assert(~contains(fileread(fullfile(f.folder,f.name)),'gramCondition'), ...
        'ejc:ActiveDiagnostic','A controller/estimator dependency needs a new applicability audit.');
end
report=struct('study',study,'scope',scope,'passed',false,'status',"RUNNING", ...
    'instances',0,'strictFailures',0,'numericalAgreement',0,'qualified',0,'structuralZero',0, ...
    'failed',0,'cases',0,'failures',struct([]),'policySHA256',extracted.policySHA256, ...
    'originalRequirementsCompleted',true,'elapsedSeconds',0, ...
    'publicationContext',"Same immutable source record; reconstruction never replaces a reported value. Original ranks, counts, flags and scientific outcomes verified. No new cross-run publication claim.");
report.checkerHashes=struct;
for name=["ejc_study34_bind","ejc_study34_gram_facts","ejc_p7_qualify","ejc_matrix_screen", ...
        "ejc_gram_parent","ejc_acceptance_numeric","ejc_rule_lookup"]
    report.checkerHashes.(name)=ejc_file_sha256(fullfile(root,'studies/p07',name+".m"));
end
for path=extracted.contexts.'
    z=load(path,'context');c=z.context;
    assert(c.study==study && strcmp(c.sourceSHA256,ejc_file_sha256(c.sourceFile)), ...
        'ejc:BindingSource','Reconstruction source identity changed.');
    z=load(c.sourceFile,'result');r=z.result;
    assert(isequal(c.indices,2:r.nSteps) && size(c.rows,1)==r.nSteps-1 && ...
        size(c.matrices,3)==numel(c.indices),'ejc:BindingCoverage','Incomplete extracted contexts.');
    rows=cell(numel(c.indices),1);details=cell(numel(c.indices),1);
    for k=1:numel(c.indices)
        j=c.indices(k);R=c.rows(max(1,j-50):j-1,:);G=c.matrices(:,:,k);
        [a,b,checks,detail]=ejc_study34_gram_facts(r,G,R,j,c.ranks(k),c.conditions(k),study,cfg);
        checks.passiveUse=rule.coverage_id==scope && rule.policy_family=="P7";
        checks.sourceMembership=c.study==study && c.sourceFile==string(fullfile(fileparts(c.sourceFile),c.case+".mat"));
        checks.outcomes=extracted.originalRequirementsCompleted && checks.sourceMembership;
        checks.publicationChecks=checks.outcomes && checks.originalRanks && checks.originalCounts && checks.originalFlags;
        checks.noRequiredUniqueSupplementalRankClaim=checks.passiveUse;
        verdict=ejc_p7_qualify(a,b,scope,checks);
        row=struct('case',c.case,'index',j,'strictPassed',c.strictPassed(k),'status',verdict.status, ...
            'eligibleToAdvance',verdict.eligibleToAdvance,'qualifiedCount',verdict.qualifiedCount, ...
            'rawStored',r.gramCondition(j),'rawReconstructed',c.conditions(k), ...
            'ordinaryP6Passed',detail.ordinaryP6.passed,'ordinaryP6Ratio',detail.ordinaryP6.maximumBoundRatio, ...
            'reason',verdict.reason);
        rows{k}=row;report.instances=report.instances+1;
        report.strictFailures=report.strictFailures+~row.strictPassed;
        report.numericalAgreement=report.numericalAgreement+(row.status=="NUMERICAL_AGREEMENT");
        report.structuralZero=report.structuralZero+(row.status=="EXACT_STRUCTURAL_ZERO_GRAM");
        report.qualified=report.qualified+row.qualifiedCount;
        report.failed=report.failed+~row.eligibleToAdvance;
        if ~verdict.eligibleToAdvance || verdict.qualifiedCount>0
            details{k}=struct('detail',detail,'actual',a,'reference',b,'checks',checks, ...
                'reconstructedRegressors',R,'storedRegressors',ejc_gram_parent(r,study,cfg,struct('D',r.D),j));
        end
        if ~row.eligibleToAdvance,report.failures=[report.failures;row];end %#ok<AGROW>
    end
    ledger=vertcat(rows{:});details=details(~cellfun(@isempty,details));
    save(fullfile(output,"ledger_"+c.case+".mat"),'ledger','details','-v7');
    report.cases=report.cases+1;
    fprintf('%s %s: %d instances, cumulative portable failures=%d\n',study,c.case,numel(ledger),report.failed);
    save(fullfile(output,'progress.mat'),'report');
    % Collect all independent saved instances in the affected run, then stop
    % this study on a genuine failed rule. No policy adjustment or retry.
    if report.failed>0 && string(diagnostic)=="",break;end
end
if report.failed>0,report.status="FAILED_PORTABLE_ASSERTION";
elseif report.instances~=extracted.instances || report.strictFailures~=extracted.strictFailures
    report.status="BLOCKED_INCOMPLETE_COVERAGE";
else
    report.passed=true;report.status="PASSED";
    if report.qualified>0,report.status="PASSED_WITH_GRAM_QUALIFICATIONS";end
end
report.elapsedSeconds=toc(started);
save(fullfile(output,'portable_summary.mat'),'report');
fid=fopen(fullfile(output,'portable_summary.json'),'w');cleanup=onCleanup(@()fclose(fid));
fprintf(fid,'%s\n',jsonencode(report,PrettyPrint=true));
end
