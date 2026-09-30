function report=verification_study6_source_checks(source,parents,output)
%VERIFICATION_STUDY6_SOURCE_CHECKS Exact saved parent relationships; no simulations.
assert_output_writable(output);assert(~isfolder(output) && ~isfile(output),'ejc:ExistingEvidence','New source evidence required.');mkdir(output);
z=load(fullfile(source,'settings.mat'),'cfg');cfg=z.cfg;rows=struct([]);
for folder=["primary","online","measurement","change"]
    files=dir(fullfile(source,folder,'*.mat'));
    for f=files.'
        child=fullfile(f.folder,f.name);z=load(child,'out','q');o=z.out;q=z.q;m=o.meta.sourceStudy;
        key="study"+m;assert(isfield(parents,key),'ejc:Study6Source','Missing explicit parent.');
        label=string(cfg.sources{m})+"/";relative=replace(string(o.meta.sourceFile),'\','/');
        assert(startsWith(relative,label),'ejc:Study6Source','Source label differs.');
        relative=extractAfter(relative,strlength(label));
        assert(~startsWith(relative,'/') && ~any(split(relative,'/')==".."),'ejc:Study6Source','Unbound source path.');
        parent=fullfile(parents.(key),relative);z=load(parent);p=z;
        if folder=="primary"
            if m==1
                z=load(fullfile(parents.study1,'data','records_'+o.meta.sourceCampaign+'.mat'),'records');rec=z.records.evaluation;fit=p.result.fit;
            elseif m==2
                z=load(fullfile(parents.study2,'records.mat'),'evaluation');rec=z.evaluation([z.evaluation.L]==o.meta.evaluationRange);fit=p.fit;
            elseif m==5
                z=load(fullfile(parents.study5,'records.mat'),'records');rec=z.records.evaluation;fit=p.fit;
            else,error('ejc:Study6Source','Unlisted primary source study.');end
            raw=repmat(reshape(fit.checkpointTheta,size(fit.theta,1),1,4),1,numel(q.indices),1);
            assert(isequal(fit.checkpointTheta,fit.theta(:,o.meta.fitSteps+1)),'ejc:Study6Source','Own fit checkpoint differs.');
        elseif folder=="online"
            assert(m==3,'ejc:Study6Source','Online source must be Study 3.');
            z=load(fullfile(parents.study3,'records.mat'),'records');rec=z.records.evaluation;
            raw=repmat(reshape(p.result.theta(:,cfg.onlineIndices+1),size(p.result.theta,1),1,4),1,numel(q.indices),1);
        else
            rec=p.result;raw=rec.theta(:,q.matlabColumns);
        end
        expected=study6_queries(rec,q.indices,q.initialization);
        passed=isequal(o.rawTheta,raw) && isequal(q.x,expected.x) && ...
            isequal(q.y,expected.y) && isequal(q.inputs,expected.inputs) && ...
            isequal(q.matlabColumns,expected.matlabColumns);
        rows=[rows;struct('child',string(child),'parent',string(parent), ...
            'childSHA256',string(verification_file_sha256(child)),'parentSHA256',string(verification_file_sha256(parent)), ...
            'passed',passed,'kind',folder)]; %#ok<AGROW>
        if ~passed,finish;error('ejc:Study6Source','Own source copy failed: %s.',child);end
    end
end
z=load(fullfile(source,'constraint_audit.mat'),'runs');ids=["A","O3","E","K"];
for k=1:4
    parent=fullfile(parents.study2,'runs','constraint_'+ids(k)+'.mat');p=load(parent,'result');
    child=fullfile(source,'constraint_audit.mat');
    rows=[rows;struct('child',string(child)+"/runs{"+k+"}",'parent',string(parent), ...
        'childSHA256',string(verification_file_sha256(child)),'parentSHA256',string(verification_file_sha256(parent)), ...
        'passed',isequaln(z.runs{k},p.result),'kind',"constraint-copy")]; %#ok<AGROW>
end
finish;
assert(report.passed && report.diagnosticBatches==329 && report.copiedControlRecords==4, ...
    'ejc:Study6Source','Required Study 6 source relationships failed or are incomplete.');
    function finish
        report=struct('passed',~isempty(rows) && all([rows.passed]),'diagnosticBatches',nnz([rows.kind]~="constraint-copy"), ...
            'copiedControlRecords',nnz([rows.kind]=="constraint-copy"),'rows',rows);
        save(fullfile(output,'source_relationships.mat'),'report','-v7');
        writetable(struct2table(rows),fullfile(output,'source_relationships.csv'));
    end
end
