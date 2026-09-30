function verdict=verification_portable_leaf(a,b,field,parentA,parentB,context)
%VERIFICATION_PORTABLE_LEAF Apply field-specific rules with each value's saved matrix parents.
% CONTEXT is created by the file comparator from its actually loaded inputs.
% A component verdict never substitutes for the original study requirements.
verdict=struct('passed',false,'status',"BLOCKED",'coverageId',"",'family',"", ...
    'qualifiedCount',0,'reason',"",'numeric',struct,'parents',struct,'claim',struct);
if isnumeric(a) && isscalar(a) && isnumeric(b) && isscalar(b)
    verdict.rawCurrent=a;verdict.rawReference=b;
end
try
    key=regexprep(string(field),'\(\d+\)','[]');key=regexprep(key,'\{\d+\}','{}');
    row=parentB;
    if istable(row) && height(row)~=1
        error('ejc:PortableRows','Table quantities must dispatch one original row at a time.');
    end
    rule=verification_rule_lookup(context.study,context.file,key,class(b),row);
    verdict.coverageId=rule.coverage_id;verdict.family=rule.policy_family;
    leaf=string(regexp(char(key),'[^.]+$','match','once'));
    if rule.original_group=="X_EXISTING"
        verdict.passed=true;verdict.status="EXPLICIT_EXISTING_EXCLUSION";return
    end
    if rule.policy_family=="E0"
        verdict.passed=isequaln(a,b);verdict.status="EXACT";
        [bound,identity]=verification_sensitivity_record_hash(a,b,key,context);
        if bound
            verdict.passed=identity.passed;verdict.status="EXACT_BOUND_INPUT_RECORDS";
            verdict.parents=identity;
        end
        if context.isCSV
            [sa,sb]=csv_sources(context,leaf);
            column=find(context.csvHeaders==leaf);
            verdict.passed=verdict.passed && isscalar(column) && ...
                exact_csv_source(a,sa,context.csvTokensA(context.rowIndex,column)) && ...
                exact_csv_source(b,sb,context.csvTokensB(context.rowIndex,column));
        end
        if ~verdict.passed,verdict.reason="Exact scientific value/class/shape differs";end
        return
    end
    if istable(parentB)
        [requiredB,~]=verification_table_applicability(context.study,context.file,key,leaf,parentB,context.references);
        [requiredA,~]=verification_table_applicability(context.study,context.file,key,leaf,parentA,context.sources);
    else
        requiredA=verification_mat_applicability(context.study,context.file,key,a,parentA,context.rootA);
        requiredB=verification_mat_applicability(context.study,context.file,key,b,parentB,context.rootB);
    end
    assert(isequal(requiredA,requiredB),'ejc:PortableApplicability','Original applicability differs.');
    required=requiredB;
    if rule.policy_family=="A1"
        assert(isfield(context.rootA,'result') && isfield(context.rootB,'result') && ...
            isequal(context.rootA.result.fit.D,context.rootB.result.fit.D), ...
            'ejc:PortableCalibration','A1 requires identical calibration D.');
        if contains(lower(leaf),'covariance'),screen_covariances(a);screen_covariances(b);end
    end
    parentNorm=NaN;parent=struct;
    if any(rule.policy_family==["P4","P5","P6","P7"])
        if isstruct(parentB) && isfield(parentB,'nSteps') && isfield(parentB,'controlAccepted')
            parent=run_pair(parentA,parentB,context);
            assert(parent.passed,'ejc:PortableParents','%s',parent.reason);
            if rule.original_group=="N_COV_EIG"
                parentNorm=history_norms(parentB.covariance,size(b));
            elseif rule.original_group=="N_GRAM_EIG"
                parentNorm=history_norms(parentB.gram,size(b));
            end
        elseif (any(rule.original_group==["N_COV_EIG","N_GRAM_EIG"]) && ...
                (istable(parentB) || context.study=="p06")) || ...
                (rule.policy_family=="P7" && leaf~="gramCondition")
            [pa,pb,parent]=diagnostic_pair(parentA,parentB,leaf,context);
            assert(parent.passed && pa.required==pb.required && isequal(pa.selection,pb.selection), ...
                'ejc:PortableParents','Diagnostic source/parent/selection failed.');
            assert(isequal(required,logical(pb.required)),'ejc:PortableApplicability','Diagnostic applicability differs.');
            parentNorm=pb.parentNorm;
            if rule.policy_family=="P7" && pb.required
                ownA=own_scalar(a,pa.sourceValue,context.isCSV);
                % A historical unrounded recomputed Study 1 scalar is not
                % invented. Its declared source recipe and all paired
                % contributing parents must pass before the passive reduction.
                ownB=own_scalar(b,pb.sourceValue,context.isCSV);
                if any(context.study==["study1","p06"])
                    % These original reducers recompute cond(G). Their old
                    % scalar cannot be reconstructed by inventing an old
                    % backend or argmax. The specified passive reduction
                    % requires immutable historical bytes, exact selection
                    % and executed paired parents; it remains qualified.
                    ownB=immutable_reference(context) && parent.passed;
                    if isequal(string(context.source),string(context.reference)) && ...
                            isequal(context.sourceSHA256,context.referenceSHA256)
                        ownA=ownB;
                    end
                end
                selected=ismember([parent.gramRows.index],pb.selection);
                if ~any([parent.gramRows(selected).qualifiedCount]>0)
                    % A resolved historical reduction is still numerical:
                    % identity of its bytes alone cannot validate its value.
                    ownA=ownA && resolved_reduction(a,pa.sourceValue,context.isCSV);
                    ownB=ownB && resolved_reduction(b,pb.sourceValue,context.isCSV);
                end
                verdict.parents=struct('current',pa,'reference',pb);
                verdict.parents.ownCurrentDefinition=ownA;verdict.parents.ownReferenceDefinition=ownB;
                v=verification_gram_reduce(a,b,pa.selection,pb.selection,parent.gramRows(selected),ownA && ownB);
                verdict.passed=v.eligibleToAdvance;verdict.status=v.status;verdict.qualifiedCount=v.qualifiedCount;
                verdict.reason=v.reason;
                return
            end
        elseif any(rule.policy_family==["P4","P5"]) && contains(lower(leaf),'covariance')
            screen_covariances(a);screen_covariances(b);
        elseif rule.policy_family=="P6" && any(required,'all')
            parent=condition_parents(a,b,leaf,parentA,parentB,context);
            verdict.parents=parent;
            assert(parent.passed,'ejc:PortableParents','Required condition parent/source check failed.');
        elseif rule.policy_family=="P7"
            error('ejc:PortableParents','Unbound passive Gram quantity.');
        end
    end
    if rule.policy_family=="P7" && leaf=="gramCondition"
        assert(isfield(parent,'passed') && parent.passed,'ejc:PortableParents','Missing paired Gram evidence.');
        assert(isa(a,'double') && isa(b,'double') && isreal(a) && isreal(b) && ...
            isequal(size(a),size(b),size(required)) && ...
            isequal(isnan(a),isnan(b)) && isequal(isinf(a),isinf(b)) && ...
            isequal(a(isinf(a)),b(isinf(b))) && ...
            all(isnan(a(~required))) && all(isnan(b(~required))), ...
            'ejc:PortableMasks','Gram class/shape/mask/sign differs.');
        verdict.passed=true;verdict.qualifiedCount=parent.qualifiedCount;
        verdict.status="GRAM_PARENT_VERDICTS";verdict.parents=parent;return
    elseif rule.policy_family=="P7"
        assert(~any(required),'ejc:PortableParents','Missing Gram reduction verdict.');
        verdict.numeric=verification_acceptance_numeric(a,b,0,0,required);
    else
        if any(rule.original_group==["N_COV_EIG","N_GRAM_EIG"])
            assert(all(isfinite(parentNorm),'all') || ~any(required,'all'), ...
                'ejc:PortableParents','Missing corresponding eigenvalue parent scale.');
            parentNorm(~required)=0;
            absolute=1e-10*max(1,parentNorm);relative=1e-7;
        else,[absolute,relative]=verification_rule_parameters(rule,parentB);end
        if context.isCSV
            [sa,sb]=csv_sources(context,leaf);
            currentSourceValidated=source_numeric(a,sa,absolute,relative,required,context.bindingA.sourceKind);
            referenceSourceValidated=source_numeric(b,sb,absolute,relative,required,context.bindingB.sourceKind);
            direct=["DIRECT_SAVED_UNROUNDED_TABLE","EXACT_FIXED_DESIGN","ACTUAL_ARRAY_P06_GATE"];
            hasUnrounded=any(context.bindingA.sourceKind==direct) && any(context.bindingB.sourceKind==direct);
            contract=struct('knownDouble15DigitEmitter',true, ...
                'currentSourceValidated',currentSourceValidated, ...
                'referenceSourceValidated',referenceSourceValidated, ...
                'historicalUnroundedAbsent',~hasUnrounded);
            if hasUnrounded
                assert(currentSourceValidated && referenceSourceValidated,'ejc:CSVSource','Own unrounded scalar link failed.');
                verdict.numeric=verification_acceptance_numeric(sa,sb,absolute,relative,required);
                verdict.numeric.mode="UNROUNDED_SAVED_SCALARS_WITH_OWN_CSV_ENCODING_CHECKS";
            else
                verdict.numeric=verification_csv_serialized_compare(a,b,absolute,relative,required,contract);
            end
        else
            verdict.numeric=verification_acceptance_numeric(a,b,absolute,relative,required);
        end
    end
    verdict.passed=verdict.numeric.passed;verdict.status="NUMERICAL_AGREEMENT";
    if verdict.passed && isfield(verdict.parents,'maximumLocator')
        verdict.status=verdict.parents.maximumLocator.status;
    end
    if ~any(required,'all'),verdict.status="NOT_APPLICABLE";end
    if ~verdict.passed,verdict.status="FAILED";verdict.reason=verdict.numeric.reason;end
    if verdict.passed && all(required,'all') && istable(parentB)
        if (rule.policy_family=="P11" && leaf=="medianDifference") || ...
                (rule.original_group=="N_CROSS" && any(leaf==["meanCrossTerm","meanCombinedCrossTerm"]))
            verdict.claim=verification_claim_check(a,b,"signedContrast");
        elseif rule.policy_family=="P11" && any(leaf==["lower95","upper95"])
            verdict.claim=verification_claim_check([parentA.lower95,parentA.upper95], ...
                [parentB.lower95,parentB.upper95],"intervalZeroContainment");
        end
        if isfield(verdict.claim,'passed')
            verdict.claim=verification_apply_claim_scope(verdict.claim,rule,a,b,parentA,parentB,context);
            if isfield(verdict.claim,'status'),verdict.status=verdict.claim.status;end
        end
        if isfield(verdict.claim,'passed') && ~verdict.claim.passed
            verdict.passed=false;verdict.status="FAILED_PUBLICATION_GUARD";verdict.reason=verdict.claim.reason;
        end
    end
catch e
    verdict.passed=false;verdict.status="BLOCKED";
    verdict.reason=string(e.identifier)+": "+string(e.message);
end
end
function yes=resolved_reduction(value,source,csv)
if isequal(value,Inf) && isequal(source,Inf)
    % The caller still requires an executed exact structural-zero parent.
    yes=true;return
end
absolute=1e-8;
if csv && isfinite(value) && isfinite(source)
    absolute=absolute+verification_csv_encoding_budget(value)+(1+1e-7)*verification_csv_encoding_budget(source);
end
v=verification_acceptance_numeric(value,source,absolute,1e-7,true);yes=v.passed;
end
function yes=immutable_reference(c)
root=fileparts(fileparts(fileparts(mfilename('fullpath'))));
persistent manifest
if isempty(manifest),manifest=readtable(fullfile(root,'verification/specification/reference_inventory.csv'),'TextType','string');end
path=replace(string(c.reference),string(root)+filesep,"");path=replace(path,filesep,'/');
if isfield(c,'canonicalReferencePath'),path=string(c.canonicalReferencePath);end
ix=find(manifest.relative_path==path);
yes=isscalar(ix) && manifest.sha256(ix)==string(c.referenceSHA256);
end
function passed=exact_csv_source(value,source,token)
% The frozen historical reader assigns double NaN to all-blank columns.
% Only a literal empty CSV token can encode an exactly empty source string;
% a literal NaN, a nonempty source, or a required numeric value cannot use it.
if isa(value,'double') && isscalar(value) && isnan(value) && isstring(source)
    passed=isscalar(source) && ~ismissing(source) && source=="" && ...
        isscalar(token) && isequal(token{1},'');
else,passed=own_encoding(value,source);end
end
function [a,b]=csv_sources(c,field)
assert(isfinite(c.rowIndex) && c.rowIndex>=1,'ejc:CSVSource','Missing exact row selection.');
a=c.bindingA.values.(field)(c.rowIndex,:);b=c.bindingB.values.(field)(c.rowIndex,:);
end
function passed=source_numeric(value,source,absolute,relative,required,kind)
if kind=="RECOMPUTED_SAVED_REDUCTION"
    ea=zeros(size(value));eb=zeros(size(source));
    ea(isfinite(value))=verification_csv_encoding_budget(value(isfinite(value)));
    eb(isfinite(source))=verification_csv_encoding_budget(source(isfinite(source)));
    v=verification_acceptance_numeric(value,source,absolute+ea+(1+relative)*eb,relative,required);passed=v.passed;
else,passed=own_encoding(value,source);end
end
function passed=own_encoding(value,source)
if isstring(value) || iscellstr(value) || ischar(value)
    value=string(value);source=string(source);value(ismissing(value))="";source(ismissing(source))="";
    passed=isequal(value,source);return
end
if islogical(source) && isa(value,'double'),passed=isequal(value,double(source));return;end
passed=strcmp(class(value),class(source)) && isequal(size(value),size(source));
if ~passed,return;end
if isnumeric(source)
    passed=isequal(isnan(value),isnan(source)) && isequal(isinf(value),isinf(source)) && ...
        isequal(value(isinf(value)),source(isinf(source)));
    finite=isfinite(source);
    if any(finite,'all'),passed=passed && all(abs(value(finite)-source(finite))<=verification_csv_encoding_budget(source(finite)));end
else,passed=isequaln(value,source);end
end
function norms=history_norms(M,shape)
norms=zeros(shape);
for j=1:size(M,3)
    if all(isfinite(M(:,:,j)),'all') && ~isempty(M(:,:,j)),norms(:,j)=norm(M(:,:,j),2);end
end
end
function screen_covariances(M)
if isempty(M),return;end
assert(size(M,1)==size(M,2),'ejc:PortableParents','Covariance shape differs.');
for j=1:size(M,3)
    s=verification_matrix_screen(M(:,:,j),"covariance");
    assert(s.valid,'ejc:PortableParents','Own covariance screen failed at %d.',j);
end
end
function yes=own_scalar(value,source,csv)
yes=isequaln(value,source);
if csv && isfinite(source) && isfinite(value),yes=abs(value-source)<=verification_csv_encoding_budget(source);end
end
function out=run_pair(a,b,c)
% File inputs and cfg/fit dependencies are supplied by the actual loader;
% the cache belongs to this comparison invocation, never a previous run.
cacheKey=c.study+":"+c.sourceSHA256+":"+c.referenceSHA256+":"+string(a.id);
if isfield(a,'scenario'),cacheKey=cacheKey+":"+string(a.scenario);end
if isKey(c.parentCache,cacheKey),out=c.parentCache(cacheKey);return;end
study=c.study;
if study=="study6",study="study2";end
if study=="p06",cfg=study1_settings;else
    x=load(fullfile(c.sources.(study),'settings.mat'),'cfg');cfg=x.cfg;
end
fa=fit_for(a,study,c.sources);fb=fit_for(b,study,c.references);
example="runs/example.mat";if study=="study1",example="data/example.mat";end
scope=verification_rule_lookup(study,example,"value[].result[].gramCondition","double");
if isKey(c.parentCache,'P07_MATRIX_EVIDENCE_DIRECTORY')
    [out,details]=verification_pair_run_screen(a,b,study,cfg,fa,fb,scope.coverage_id);
    if ~isempty(details)
        digest=java.security.MessageDigest.getInstance('SHA-256');digest.update(unicode2native(char(cacheKey),'UTF-8'));
        keyHash=lower(reshape(dec2hex(typecast(digest.digest(),'uint8'),2).',1,[]));
        file=fullfile(c.parentCache('P07_MATRIX_EVIDENCE_DIRECTORY'),[keyHash '.mat']);
        assert(~isfile(file),'ejc:ExistingEvidence','Matrix evidence already exists.');
        root=fileparts(fileparts(fileparts(mfilename('fullpath'))));
        metadata=struct('study',study,'scope',scope.coverage_id,'runId',string(a.id), ...
            'sourceSHA256',c.sourceSHA256,'referenceSHA256',c.referenceSHA256, ...
            'policySHA256',verification_file_sha256(fullfile(root,'verification/specification/numerical_policy.json')), ...
            'inputIdentitySHA256',c.parentCache('P07_INPUT_IDENTITY_SHA256'), ...
            'classifierSHA256',verification_file_sha256(which('verification_pair_run_screen')), ...
            'screenSHA256',verification_file_sha256(which('verification_matrix_screen')), ...
            'regressorBuilderSHA256',verification_file_sha256(which('verification_gram_rows')), ...
            'qualificationSHA256',verification_file_sha256(which('verification_gram_qualify')));
        save(file,'details','metadata','-v7');
        out.matrixEvidenceFile=string(file);out.matrixEvidenceSHA256=string(verification_file_sha256(file));
    end
else
    out=verification_pair_run_screen(a,b,study,cfg,fa,fb,scope.coverage_id);
end
c.parentCache(cacheKey)=out;
end
function fit=fit_for(r,study,sources)
if isfield(r,'fit'),fit=r.fit;
elseif study=="study2",x=load(fullfile(sources.study2,'fits',string(r.id)+".mat"),'fit');fit=x.fit;
else,fit=struct('D',r.D);end
end
function [pa,pb,parent]=diagnostic_pair(a,b,field,c)
study=c.study;file=c.file;
if ~istable(a),a=struct2table(a,'AsArray',true);b=struct2table(b,'AsArray',true);end
if study=="p06"
    ra=c.rootA.result;rb=c.rootB.result;file="tables/run_diagnostics.csv";
else
    source=verification_table_run_source(study,a,c.sources);reference=verification_table_run_source(study,b,c.references);
    x=load(source,'result');y=load(reference,'result');ra=x.result;rb=y.result;
    c.sourceSHA256=string(verification_file_sha256(source));c.referenceSHA256=string(verification_file_sha256(reference));
    if any(study==["study4","study5"]),file="tables/diagnostics.csv";end
end
pa=verification_diagnostic_parent(study,file,field,a,ra);pb=verification_diagnostic_parent(study,file,field,b,rb);
parent=run_pair(ra,rb,c);
end
function out=condition_parents(a,b,field,rowA,rowB,c)
out=struct('passed',false,'kind',"condition source",'sourceCurrent',NaN,'sourceReference',NaN);
if ~istable(rowA),rowA=struct2table(rowA,'AsArray',true);rowB=struct2table(rowB,'AsArray',true);end
if field=="finalCovarianceCondition"
    for side=1:2
        sources=c.sources;row=rowA;value=a;if side==2,sources=c.references;row=rowB;value=b;end
        if c.study=="study2",file=fullfile(sources.study2,'fits',row.model+".mat");
        elseif c.study=="study3",file=fullfile(sources.study3,'fits',sprintf('fit_%s_%03d.mat',row.model,row.trial));
        elseif c.study=="study4",file=fullfile(sources.study4,'fits',"fit_"+row.modelId+".mat");
        else,error('ejc:PortableParents','Unlisted final covariance condition source.');end
        z=load(file,'fit');fit=z.fit;M=fit.covariance(:,:,end);
        if c.study=="study4"
            settings=load(fullfile(sources.study4,'settings.mat'),'cfg');
            j=find(settings.cfg.fitSteps==row.fittingTransitions);assert(isscalar(j));
            assert(isequal(fit.checkpointCovariance(:,:,j),fit.covariance(:,:,row.fittingTransitions+1)), ...
                'ejc:PortableParents','Fit checkpoint differs from its exact own history.');
            M=fit.checkpointCovariance(:,:,j);
        end
        s=verification_matrix_screen(M,"covariance",StoredCondition=value);
        assert(s.valid && s.resolved && s.conditionInsideEnvelope,'ejc:PortableParents','Final covariance condition is not resolved within its own envelope.');
        out.("screen"+side)=s;
    end
    out.passed=true;return
end
if c.study=="paper"
    assert(ismember(rowB.quantity,["RLS_covariance","QP_Hessian"]) && rowA.quantity==rowB.quantity, ...
        'ejc:PortableParents','A.14 condition coordinates differ.');
    groups=rowB.study;if groups=="all_primary",groups="study"+(1:5);end
    expected=[246 22 218 12 5];checked=0;
    for study=reshape(groups,1,[])
        assert(any(study=="study"+(1:5)),'ejc:PortableParents','Unlisted A.14 group.');
        folder="runs";pattern="*.mat";if study=="study1",folder="data";pattern="confirmation_*.mat";end
        aa=dir(fullfile(c.sources.(study),folder,pattern));bb=dir(fullfile(c.references.(study),folder,pattern));
        assert(isequal(sort(string({aa.name})),sort(string({bb.name}))) && ...
            numel(aa)==expected(str2double(extractAfter(study,"study"))), ...
            'ejc:PortableParents','A.14 primary source coverage differs.');
        for f=aa.'
            sa=fullfile(f.folder,f.name);sb=fullfile(c.references.(study),folder,f.name);
            x=load(sa,'result');y=load(sb,'result');local=c;local.study=study;
            local.sourceSHA256=string(verification_file_sha256(sa));local.referenceSHA256=string(verification_file_sha256(sb));
            pair=run_pair(x.result,y.result,local);assert(pair.passed,'ejc:PortableParents','A.14 parent failed: %s.',pair.reason);
            checked=checked+1;
        end
    end
    out.passed=checked>0;out.primaryRunsChecked=checked;return
end
if c.study=="p06"
    ra=c.rootA.result;rb=c.rootB.result;
else
    sa=verification_table_run_source(c.study,rowA,c.sources);sb=verification_table_run_source(c.study,rowB,c.references);
    x=load(sa,'result');y=load(sb,'result');ra=x.result;rb=y.result;
    c.sourceSHA256=string(verification_file_sha256(sa));c.referenceSHA256=string(verification_file_sha256(sb));
end
pair=run_pair(ra,rb,c);assert(pair.passed,'ejc:PortableParents','%s',pair.reason);
for side=1:2
    r=ra;row=rowA;value=a;if side==2,r=rb;row=rowB;value=b;end
    ix=1:r.nSteps;
    if ismember('windowStart',row.Properties.VariableNames)
        ix=ix(r.time(ix)>=row.windowStart & r.time(ix)<row.windowEnd & ...
            isfinite(r.x(ix)) & isfinite(r.r(ix)) & isfinite(r.u(ix)));
        assert(numel(ix)==row.scoredSamples,'ejc:PortableParents','Condition source window count differs.');
    end
    if startsWith(field,"covariance"),values=r.covarianceCondition(ix);
    elseif startsWith(field,"qp"),values=r.qpCondition(ix);
    else,error('ejc:PortableParents','Unlisted condition source field.');end
    assert(~isempty(values) && all(isfinite(values)),'ejc:PortableParents','Required condition source is nonfinite.');
    if endsWith(field,"Median"),source=median(values);index=NaN;
    else,[source,position]=max(values);index=ix(position);end
    v=verification_acceptance_numeric(value,source,1e-8,1e-7,true);
    assert(v.passed,'ejc:PortableParents','Condition reduction differs from its own supported history.');
    if side==1,out.sourceCurrent=source;out.selectedCurrent=ix;out.argmaxCurrent=index;
    else,out.sourceReference=source;out.selectedReference=ix;out.argmaxReference=index;end
end
out.passed=isequal(out.selectedCurrent,out.selectedReference) && isequaln(out.argmaxCurrent,out.argmaxReference);
% Bounded post-failure amendment. Every eligible row is evaluated, including
% equal locators. All other scopes retain the original exact-index rule.
if c.study=="study2" && c.file=="tables/run_diagnostics.csv" && field=="qpConditionMax"
    out.maximumLocator=verification_qp_max_locator(ra,rb,rowA,rowB,c,pair,out);
    out.passed=out.maximumLocator.passed;
end
end
