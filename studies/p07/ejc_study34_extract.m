function report=ejc_study34_extract(study,source,cfg,output)
%EJC_STUDY34_EXTRACT Execute all original requirements except the two bound
% scalar assertions. The callback EVALUATES and records those strict assertions;
% it does not accept them. Portable acceptance requires a subsequent complete
% parent/rule pass. No generic exception is caught inside a scientific verifier.
assert(any(string(study)==["study3","study4"]),'ejc:BindingScope','Unsupported study.');
assert(~isfolder(output) && ~isfile(output),'ejc:ExistingEvidence','Evidence already exists.');
mkdir(output);started=tic;
report=struct('study',string(study),'originalRequirementsCompleted',false, ...
    'portableStatus',"NOT_EVALUATED",'status',"RUNNING",'contexts',strings(0,1), ...
    'instances',0,'strictFailures',0,'elapsedSeconds',0,'exception',"");
root=fileparts(fileparts(fileparts(mfilename('fullpath'))));
report.verifierSHA256=ejc_file_sha256(fullfile(root,'studies',char(study),char(study)+"_verify_results.m"));
report.extractorSHA256=ejc_file_sha256(mfilename('fullpath')+".m");
report.policySHA256=ejc_file_sha256(fullfile(root,'studies/p07/p07_acceptance_policy.json'));
report.inputManifest=inventory(source);
current="";context=struct;
try
    verifier=str2func(char(study)+"_verify_results");verifier(source,cfg,@capture);
    flush;
    assert(isequal(report.inputManifest,inventory(source)), ...
        'ejc:SourceChanged','Study inputs changed while original requirements executed.');
    report.originalRequirementsCompleted=true;
    report.status="ORIGINAL_REQUIREMENTS_EXECUTED_PORTABLE_PENDING";
catch e
    flush;
    report.status="FAILED_ORIGINAL_REQUIREMENT";
    report.exception=string(getReport(e,'extended','hyperlinks','off'));
    report.identifier=string(e.identifier);report.stack=e.stack;
end
report.elapsedSeconds=toc(started);
save(fullfile(output,'original_requirements.mat'),'report');
fid=fopen(fullfile(output,'original_requirements.json'),'w');clean=onCleanup(@()fclose(fid));
fprintf(fid,'%s\n',jsonencode(report,PrettyPrint=true));

    function capture(r,G,R,j,pointRank,condition,sourceFile)
        if string(sourceFile)~=current
            flush;
            z=load(sourceFile,'result');
            assert(isequaln(z.result,r),'ejc:BindingSource','Callback does not use the actual saved result.');
            assert(startsWith(string(sourceFile),string(fullfile(source,'runs'))+filesep), ...
                'ejc:BindingSource','Callback source is outside the selected study.');
            current=string(sourceFile);[~,name]=fileparts(sourceFile);
            context=struct('sourceFile',current,'sourceSHA256',ejc_file_sha256(sourceFile), ...
                'study',string(study),'case',string(name),'indices',zeros(1,0), ...
                'matrices',zeros(size(G,1),size(G,2),0),'rows',zeros(0,size(R,2)), ...
                'ranks',zeros(1,0),'conditions',zeros(1,0),'strictPassed',false(1,0));
        end
        assert(j==numel(context.indices)+2,'ejc:BindingIndex','Missing, duplicate or unordered callback index.');
        first=max(1,j-50);
        if j>2
            assert(isequal(R(1:end-1,:),context.rows(first:j-2,:)), ...
                'ejc:BindingRows','Overlapping original regressor membership changed.');
        end
        context.rows(j-1,:)=R(end,:);k=numel(context.indices)+1;
        context.indices(k)=j;context.matrices(:,:,k)=G;
        context.ranks(k)=pointRank;context.conditions(k)=condition;
        a=r.gramCondition(j);
        if study=="study3",tolerance=1e-12;else,tolerance=1e-6;end
        if isfinite(a) && isfinite(condition)
            passed=abs(a-condition)<=tolerance*max(1,abs(condition));
        elseif study=="study4" && pointRank<r.nEstimated
            passed=isinf(a); % Preserve the literal original assertion result.
        else
            passed=isequaln(a,condition);
        end
        context.strictPassed(k)=passed;
        report.instances=report.instances+1;report.strictFailures=report.strictFailures+~passed;
    end
    function flush
        if strlength(current)==0,return;end
        assert(strcmp(context.sourceSHA256,ejc_file_sha256(current)), ...
            'ejc:SourceChanged','Current callback source changed.');
        file=fullfile(output,"context_"+context.case+".mat");
        assert(~isfile(file),'ejc:ExistingEvidence','Never replace extracted evidence.');
        save(file,'context');report.contexts(end+1,1)=file;
        current="";context=struct;
    end
end
function rows=inventory(source)
files=dir(fullfile(source,'**','*.mat'));rows=struct([]);
for f=files.'
    file=fullfile(f.folder,f.name);
    row=struct('path',string(file),'bytes',f.bytes,'sha256',ejc_file_sha256(file));
    rows=[rows;row]; %#ok<AGROW>
end
end
