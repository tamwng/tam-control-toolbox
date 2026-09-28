function binding=ejc_study2_gram_binding(currentDirectory,referenceDirectory,referenceFile,output)
%EJC_STUDY2_GRAM_BINDING New per-invocation, hash-bound B2 callback; no reuse flag.
assert(~isfolder(output) && ~isfile(output),'ejc:ExistingEvidence','New Gram binding evidence required.');
root=fileparts(fileparts(fileparts(mfilename('fullpath'))));
policyFile=fullfile(root,'studies/p07/p07_acceptance_policy.json');policyHash=ejc_file_sha256(policyFile);
policy=jsondecode(fileread(policyFile));
assert(isfield(policy,'study2_gram_report_binding') && ...
    strcmp(policy.study2_gram_report_binding.parent_coverage_id,'F0533'), ...
    'ejc:GramReportScope','Missing approved B2 reporting-site policy.');
refs=ejc_reference_sources;
assert(strcmp(canonical(referenceDirectory),canonical(refs.study2)) && ...
    strcmp(canonical(referenceFile),canonical(fullfile(root,'results/study2_journal/gram_numerical_rank_check.csv'))), ...
    'ejc:GramReportScope','Unsupported historical source or replacement reference CSV.');
manifest=readtable(fullfile(root,'evidence/p07_gate_b/P07_SOURCE_SHA256.csv'),'TextType','string');
relative="results/study2_journal/gram_numerical_rank_check.csv";r=manifest(manifest.relative_path==relative,:);
assert(height(r)==1 && strcmp(ejc_file_sha256(referenceFile),r.sha256), ...
    'ejc:GramReportIntegrity','Protected historical CSV changed.');
sources=struct('study2',char(currentDirectory));references=struct('study2',char(referenceDirectory));
inputs=ejc_input_snapshot(sources,references);referenceHash=ejc_file_sha256(referenceFile);
for item=inputs(string({inputs.role})=="reference")
    relative="results/study2_pilot_20260918/"+item.relativePath;
    r=manifest(manifest.relative_path==relative,:);
    assert(height(r)==1 && r.bytes==item.bytes && strcmp(r.sha256,item.sha256), ...
        'ejc:GramReportIntegrity','Unpinned or changed historical dependency: %s.',relative);
end
a=load(fullfile(currentDirectory,'settings.mat'),'cfg');b=load(fullfile(referenceDirectory,'settings.mat'),'cfg');
assert(isequaln(a.cfg,b.cfg),'ejc:GramReportIdentity','Study 2 scientific configuration changed.');cfg=a.cfg;
referenceTable=readtable(referenceFile,'TextType','string','VariableNamingRule','preserve');
mkdir(output);save(fullfile(output,'input_identity.mat'),'inputs','policyHash','referenceHash','-v7');
checkers=["ejc_pair_run_screen","ejc_gram_rows","ejc_matrix_screen","ejc_p7_qualify", ...
    "ejc_p7_reduce_verdict","ejc_acceptance_numeric","ejc_study2_gram_reduction", ...
    "ejc_study2_gram_binding","study2_gram_report","study2_gram_diagnostic", ...
    "study2_figure_data","plot_study2_journal"];
checkerHashes=struct;
for name=checkers,checkerHashes.(name)=ejc_file_sha256(which(name));end
rows={};keys=strings(0,1);
binding=struct('compare',@compare,'finish',@finish,'inputIdentitySHA256',ejc_file_sha256(fullfile(output,'input_identity.mat')));
    function verdict=compare(request)
        guard;
        assert(isstruct(request) && isscalar(request) && ...
            all(isfield(request,{'field','row','referenceRow','resultsDirectory','referenceFile','originalStrictPassed'})) && ...
            request.field=="maxStoredCondition" && ...
            strcmp(canonical(request.resultsDirectory),canonical(currentDirectory)) && ...
            strcmp(canonical(request.referenceFile),canonical(referenceFile)), ...
            'ejc:GramReportScope','Wrong reporting field, source or callback request.');
        row=request.row;expected=request.referenceRow;
        assert(istable(row) && height(row)==1 && istable(expected) && height(expected)==1, ...
            'ejc:GramReportIdentity','Exactly one semantic row required.');
        index=find(referenceTable.model==row.model & referenceTable.amplitude==row.amplitude);
        assert(isscalar(index) && isequaln(referenceTable(index,:),expected), ...
            'ejc:GramReportSource','Callback row does not match the immutable reference CSV.');
        key=row.model+"_"+string(sprintf('%.17g',row.amplitude));
        assert(~any(keys==key),'ejc:GramReportCoverage','Duplicate reporting row.');
        [a,sourceA]=source_run(currentDirectory,row.model,row.amplitude);
        [b,sourceB]=source_run(referenceDirectory,row.model,row.amplitude);
        assert(string(a.name)==row.modelName && string(b.name)==expected.modelName, ...
            'ejc:GramReportIdentity','Source model name differs.');
        fa=load(fullfile(currentDirectory,'fits',row.model+".mat"),'fit');
        fb=load(fullfile(referenceDirectory,'fits',row.model+".mat"),'fit');
        scope=ejc_rule_lookup("study2","runs/example.mat","value[].result[].gramCondition","double");
        assert(scope.coverage_id=="F0533" && scope.policy_family=="P7", ...
            'ejc:GramReportScope','F0533 history binding changed.');
        [pair,details]=ejc_pair_run_screen(a,b,"study2",cfg,fa.fit,fb.fit,"F0533");
        parentFile=fullfile(output,"parents_"+key+".mat");
        sourceHashes=struct('current',ejc_file_sha256(sourceA),'reference',ejc_file_sha256(sourceB));
        save(parentFile,'pair','details','sourceHashes','checkerHashes','policyHash','-v7');
        verdict=ejc_study2_gram_reduction(a,b,row,expected,pair);
        verdict.originalStrictPassed=request.originalStrictPassed;
        verdict.sourceCurrent=string(sourceA);verdict.sourceReference=string(sourceB);
        verdict.sourceHashes=sourceHashes;verdict.parentEvidence=string(parentFile);
        verdict.parentEvidenceSHA256=ejc_file_sha256(parentFile);verdict.policySHA256=string(policyHash);
        guard;rows{end+1,1}=verdict;keys(end+1,1)=key;
        save(fullfile(output,'row_progress.mat'),'rows','keys','-v7');
    end
    function report=finish
        guard;
        expectedKeys=referenceTable.model+"_"+arrayfun(@(v)string(sprintf('%.17g',v)),referenceTable.amplitude);
        assert(numel(rows)==height(referenceTable) && numel(unique(keys))==numel(keys) && ...
            all(ismember(expectedKeys,keys)),'ejc:GramReportCoverage','Not every adaptive row executed.');
        report=struct('passed',true,'binding',"P07_STUDY2_GRAM_MAX_V1",'rows',{rows}, ...
            'adaptiveRows',numel(rows),'numericalAgreement',nnz(cellfun(@(v)v.status=="NUMERICAL_AGREEMENT",rows)), ...
            'qualifiedMaxima',nnz(cellfun(@(v)v.status=="QUALIFIED_UNRESOLVED_GRAM_REDUCTION",rows)), ...
            'originalStrictFailures',nnz(cellfun(@(v)~v.originalStrictPassed,rows)), ...
            'selectedParentChecks',sum(cellfun(@(v)v.selectedParentChecks,rows)), ...
            'qualifiedParentChecks',sum(cellfun(@(v)v.qualifiedParentChecks,rows)), ...
            'policySHA256',string(policyHash),'inputsUnchanged',true,'checkerHashes',checkerHashes);
        save(fullfile(output,'binding_report.mat'),'report','-v7');
        fid=fopen(fullfile(output,'binding_report.json'),'w');c=onCleanup(@()fclose(fid));fprintf(fid,'%s\n',jsonencode(report,PrettyPrint=true));
    end
    function guard
        assert(strcmp(policyHash,ejc_file_sha256(policyFile)) && strcmp(referenceHash,ejc_file_sha256(referenceFile)), ...
            'ejc:GramReportIntegrity','Policy or historical CSV changed.');
        for name=checkers
            assert(strcmp(checkerHashes.(name),ejc_file_sha256(which(name))), ...
                'ejc:GramReportIntegrity','Binding checker changed.');
        end
        assert(isequaln(inputs,ejc_input_snapshot(sources,references)), ...
            'ejc:GramReportIntegrity','Changed input or stale cached evidence.');
    end
end
function path=canonical(path),path=char(java.io.File(char(path)).getCanonicalPath());end
function [result,path]=source_run(directory,id,amplitude)
found=strings(0,1);result=[];
for f=dir(fullfile(directory,'runs','amplitude_*.mat')).'
    file=fullfile(f.folder,f.name);z=load(file,'result');
    if string(z.result.id)==id && isequal(z.result.amplitude,amplitude)
        found(end+1)=string(file);result=z.result; %#ok<AGROW>
    end
end
assert(isscalar(found),'ejc:GramReportSource','Missing or ambiguous model/amplitude source.');path=char(found);
end
