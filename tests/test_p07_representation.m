function tests=test_p07_representation
tests=functiontests(localfunctions);
end
function setupOnce(t)
root=fileparts(fileparts(mfilename('fullpath')));t.TestData.path=path;addpath(fullfile(root,'studies','p07'));
end
function teardownOnce(t)
path(t.TestData.path);
end
function test_csv_quotes_windows_and_schema(t)
p=[tempname '.csv'];c=onCleanup(@()delete(p));f=fopen(p,'w');
fprintf(f,'id,path,value\r\nA,"C:\\Users\\Tam\\a,b.mat",1.25e-7\r\n');fclose(f);
v=ejc_csv_tokens(p,["id","path","value"]);
verifyEqual(t,v{1,2},'C:\Users\Tam\a,b.mat');verifyEqual(t,ejc_csv_number(v{1,3}),1.25e-7);
verifyError(t,@()ejc_csv_tokens(p,["id","value","path"]),'ejc:CSVSchema');
f=fopen(p,'w');fprintf(f,'a,a\n1,2\n');fclose(f);
verifyError(t,@()ejc_csv_tokens(p,["a","a"]),'ejc:CSVSchema');
f=fopen(p,'w');fprintf(f,'a\n"unclosed');fclose(f);
verifyError(t,@()ejc_csv_tokens(p,"a"),'ejc:CSVQuotes');
f=fopen(p,'w');fclose(f);verifyEqual(t,size(ejc_csv_tokens(p,strings(1,0))),[0 0]);
end
function test_unquoted_fast_path_preserves_exact_tokens(t)
f=t.applyFixture(matlab.unittest.fixtures.TemporaryFolderFixture);
file=fullfile(f.Folder,'plain.csv');
for newline={sprintf('\n'),sprintf('\r\n'),sprintf('\r')}
    nl=newline{1};
    for trailing=[false true]
        text=['a,b,c',nl,'1,,C:\\work\\file',nl,',-0,Inf'];
        if trailing,text=[text nl];end %#ok<AGROW>
        fid=fopen(file,'wb');fwrite(fid,text);fclose(fid);
        got=ejc_csv_tokens(file,["a","b","c"]);
        verifyEqual(t,got,{'1','','C:\\work\\file';'','-0','Inf'});
    end
end
for bad={sprintf('a,b\n1,2,3\n'),sprintf('a,b\n1,2\n\n'),['a,b' char(10) '1,' char(0)]}
    fid=fopen(file,'wb');fwrite(fid,bad{1});fclose(fid);
    if contains(bad{1},char(0)),id='ejc:CSVQuotes';else,id='ejc:CSVSchema';end
    verifyError(t,@()ejc_csv_tokens(file,["a","b"]),id);
end
end
function test_actual_writer_encoding(t)
values=[0;-0;1;-1;10-eps(10);10;10+eps(10);realmin;eps(0);pi];
p=[tempname '.csv'];c=onCleanup(@()delete(p));writetable(table(values),p);
tokens=ejc_csv_tokens(p,"values");parsed=cellfun(@ejc_csv_number,tokens);
budget=ejc_csv_encoding_budget(values);
verifyLessThanOrEqual(t,abs(values-parsed),budget);verifyEqual(t,budget(1),0);
verifyTrue(t,isnan(ejc_csv_number('NaN')));verifyEqual(t,ejc_csv_number('-Inf'),-Inf);
verifyError(t,@()ejc_csv_number('1,2'),'ejc:CSVNumericToken');
verifyError(t,@()ejc_csv_number('1e-999'),'ejc:CSVNumericRange');
verifyError(t,@()ejc_csv_number('1e999'),'ejc:CSVNumericRange');
% The actual 15-digit writer may round realmax above binary64 range.
% The frozen contract blocks that representation; it must not become Inf PASS.
writetable(table(realmax,'VariableNames',{'value'}),p);
overflow=ejc_csv_tokens(p,"value");
verifyError(t,@()ejc_csv_number(overflow{1}),'ejc:CSVNumericRange');
verifyError(t,@()ejc_csv_encoding_budget(single(1)),'ejc:CSVEncoding');
end
function test_claims_and_margins(t)
verifyTrue(t,ejc_claim_check(1,2,"signedContrast").passed);
verifyFalse(t,ejc_claim_check(-1e-14,1e-14,"signedContrast").passed);
verifyFalse(t,ejc_claim_check(0,1e-14,"signedContrast").passed);
verifyTrue(t,ejc_claim_check([-1 2],[-2 3],"intervalZeroContainment").passed);
verifyFalse(t,ejc_claim_check([0 2],[eps 3],"intervalZeroContainment").passed);
v=ejc_claim_check([1 2],[1 2],"strictOrdering");verifyEqual(t,v.status,"NOT_AN_EXPLICIT_CLAIM");
verifyTrue(t,ejc_claim_check([1 2],[1 2],"strictOrdering",ExplicitClaim=true,ReproductionBand=[.1 .1]).passed);
verifyFalse(t,ejc_claim_check([1 2],[1 2],"strictOrdering",ExplicitClaim=true,ReproductionBand=[.6 .6]).passed);
end
function test_direct_source_link_rejects_tampering(t)
p=[tempname '.csv'];c=onCleanup(@()delete(p));
source=table([1;2],[true;false],["A";"B"],'VariableNames',{'value','accepted','id'});
writetable(source,p);verifyTrue(t,ejc_csv_mat_link(p,source).passed);
bad=source;bad.value(2)=3;verifyFalse(t,ejc_csv_mat_link(p,bad).passed);
bad=source;bad.accepted(2)=true;verifyFalse(t,ejc_csv_mat_link(p,bad).passed);
bad=source;bad.id(2)="C";verifyFalse(t,ejc_csv_mat_link(p,bad).passed);
end
function test_serialized_contract_requires_source_and_masks(t)
c=struct('knownDouble15DigitEmitter',true,'currentSourceValidated',true, ...
    'referenceSourceValidated',true,'historicalUnroundedAbsent',true);
r=ejc_csv_serialized_compare(1+1e-8,1,1e-8,1e-7,true,c);verifyTrue(t,r.passed);
verifyFalse(t,r.unroundedHistoricalAgreementEstablished);
r=ejc_csv_serialized_compare(1+1e-5,1,1e-8,1e-7,true,c);verifyFalse(t,r.passed);
r=ejc_csv_serialized_compare(NaN,NaN,1e-8,1e-7,true,c);verifyFalse(t,r.passed);
for name=string(fieldnames(c)).'
    bad=c;bad.(name)=false;
    verifyError(t,@()ejc_csv_serialized_compare(1,1,1e-8,1e-7,true,bad),'ejc:CSVContract');
end
end
