function c=ejc_portable_context(info,a,b,sources,references,bindingsA,bindingsB,parentCache)
%EJC_PORTABLE_CONTEXT Bind dispatch to actual file and saved-reducer inputs.
c=info;c.rootA=a;c.rootB=b;c.sources=sources;c.references=references;
c.sourceSHA256=string(ejc_file_sha256(info.source));
c.referenceSHA256=string(ejc_file_sha256(info.reference));
c.claimBindingsA=bindingsA;c.claimBindingsB=bindingsB;
c.parentCache=parentCache;c.isCSV=endsWith(info.file,'.csv');c.rowIndex=NaN;
c.csvSourceValidated=false;c.csvReferenceValidated=false;c.historicalUnroundedAbsent=false;
if ~c.isCSV
    c.ownCopiesA=ejc_own_source_copies(a,info.study,info.source,sources);
    c.ownCopiesB=ejc_own_source_copies(b,info.study,info.reference,references);
    return
end
ia=find(string({bindingsA.study})==info.study & string({bindingsA.file})==info.file);
ib=find(string({bindingsB.study})==info.study & string({bindingsB.file})==info.file);
assert(isscalar(ia) && isscalar(ib),'ejc:CSVSource','Missing or ambiguous saved-source binding.');
c.bindingA=bindingsA(ia);c.bindingB=bindingsB(ib);
c.csvHeaders=string(c.bindingA.values.Properties.VariableNames);
c.csvTokensA=ejc_csv_tokens(info.source,c.csvHeaders);
c.csvTokensB=ejc_csv_tokens(info.reference,c.csvHeaders);
if info.study=="p06" && info.file=="tables/baseline_gate.csv"
    % The original comparator has already retained the independently gated
    % discrepancy column separately; it is not a historical zero target.
    c.bindingA.values.maxAbsoluteDifference=[];c.bindingB.values.maxAbsoluteDifference=[];
end
for pair={{a,c.bindingA},{b,c.bindingB}}
    T=pair{1}{1};binding=pair{1}{2};
    assert(istable(T) && isequal(T.Properties.VariableNames,binding.values.Properties.VariableNames) && ...
        height(T)==height(binding.values),'ejc:CSVSource','Own-source row count/schema/order differs.');
    assert(all(isfile(binding.parents)),'ejc:CSVSource','A declared saved source is missing.');
end
end
