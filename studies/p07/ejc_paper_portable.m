function report=ejc_paper_portable(sources,references,output)
%EJC_PAPER_PORTABLE Original paper selection with approved P07 field rules.
% A component only: all study comparisons and original validity must pass
% separately. The original report still makes its exact source/count checks.
assert(~isfolder(output) && ~isfile(output),'ejc:ExistingEvidence','New paper evidence required.');
inputsBefore=ejc_input_snapshot(sources,references);
cache=containers.Map('KeyType','char','ValueType','any');
report=ejc_paper_report(sources,references,output,@compare);
report.exportChecks=ejc_paper_export_checks(sources,references,output,report);
report.passed=report.passed && report.exportChecks.passed;
inputsAfter=ejc_input_snapshot(sources,references);
inputsUnchanged=isequaln(inputsBefore,inputsAfter);
save(fullfile(output,'paper_input_identity.mat'),'inputsBefore','inputsAfter','inputsUnchanged','-v7');
assert(inputsUnchanged,'ejc:InputChanged','A paper-report input changed during comparison.');
report.inputsUnchanged=inputsUnchanged;
report.fullStudyComparisonsRequired=true;
save(fullfile(output,'paper_portable.mat'),'report','-v7');
    function out=compare(kind,a,b)
        links=struct;
        if kind=="conditioning"
            file="paper_A14_conditioning.csv";
        else
            file="paper_table12.csv";
            [a,links.current]=ejc_paper_table12_source(sources.study6,a);
            [b,links.reference]=ejc_paper_table12_source(references.study6,b);
        end
        assert(isequal(a.Properties.VariableNames,b.Properties.VariableNames) && isequal(size(a),size(b)), ...
            'ejc:PaperSchema','Paper table schema/shape differs.');
        c=struct('study',"paper",'file',file,'rootA',a,'rootB',b,'sources',sources,'references',references, ...
            'sourceSHA256',"derived-in-this-invocation",'referenceSHA256',"derived-in-this-invocation", ...
            'parentCache',cache,'isCSV',false,'rowIndex',NaN);
        c.claimBindingsA=[];c.claimBindingsB=[];
        rows={};
        for name=string(a.Properties.VariableNames)
            for j=1:height(a)
                c.rowIndex=j;v=ejc_portable_leaf(a.(name)(j,:),b.(name)(j,:),"value."+name,a(j,:),b(j,:),c);
                v.field=name;v.row=j;rows{end+1,1}=v; %#ok<AGROW>
            end
        end
        out=struct('passed',all(cellfun(@(v)v.passed,rows)),'fields',numel(rows),'links',links, ...
            'ledger',string(fullfile(output,kind+"_portable_ledger.mat")));
        out.claimApplicabilityInstances=nnz(cellfun(@(v)isfield(v.claim,'directionalClaimApplicability'),rows));
        out.rawClaimDifferences=nnz(cellfun(@(v)isfield(v.claim,'directionalClaimApplicability') && ~v.claim.originalStrictVerdict.passed,rows));
        save(out.ledger,'rows','-v7');
    end
end
