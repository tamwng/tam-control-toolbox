function evidence=ejc_claim_parents(row,scope,c,side)
%EJC_CLAIM_PARENTS Read-only, own-package proofs for a semantic classification.
% Scientific reductions are supplied by the unchanged source-binding pipeline.
% No forecast path, controller, optimizer, seed or bootstrap is changed here.
if side=="current",sources=c.sources;bindings=c.claimBindingsA;else,sources=c.references;bindings=c.claimBindingsB;end
assert(isfield(sources,scope.sourceStudy),'ejc:ClaimParents','Missing own source package.');
base=string(sources.(scope.sourceStudy));cache=c.parentCache;
sourceKey='P07_CLAIM_SOURCE_PROOF';
if ~isKey(cache,sourceKey),cache(sourceKey)=ejc_claim_source_guard;end
sourceProof=cache(sourceKey);
relative=scope.sourceFile;
if relative=="summary.mat"
 token=regexp(char(scope.sourceField),'\.summary\[\]\.([^.]+)\.','tokens','once');
 assert(~isempty(token),'ejc:ClaimScope','Missing exact summary-table selector.');relative="tables/"+string(token{1})+".csv";
end
paired=ismember('contrast',row.Properties.VariableNames);
if paired
 assert(scope.sourceStudy=="study1" && any(relative==["tables/forecast_paired_contrasts.csv","tables/measured_initialization_paired_contrasts.csv"]), ...
  'ejc:ClaimScope','No source-defined algebraic pairing for this table.');
 original=read_cached(base,relative,"study1",cache);
 ix=select_row(original,row,["campaign","contrast","metric","auditType","fittingTransitions","inputMode","horizon"]);
 assert(isequaln(row,original(ix,:)),'ejc:ClaimExportLink','Paired source/export values or metadata differ.');
 binding=binding_for(bindings,"study1",relative);
 assert(binding.sourceKind=="RECOMPUTED_SAVED_REDUCTION" && all(startsWith(string(binding.parents),base+filesep)),'ejc:ClaimBootstrap','Unchanged paired reducer binding missing.');
 values=binding.values;assert(height(values)==height(original),'ejc:ClaimBootstrap','Paired row count differs.');
 exact=setdiff(string(original.Properties.VariableNames),["medianDifference","lower95","upper95"],'stable');
 assert(isequaln(original(ix,exact),values(ix,exact)),'ejc:ClaimBootstrap','Pair/seed/reduction metadata differs.');
 for field=["medianDifference","lower95","upper95"]
  scalar_link(original.(field)(ix),values.(field)(ix),true,"P11");
 end
 assert(row.lower95<=row.upper95 && values.lower95(ix)<=values.upper95(ix),'ejc:ClaimInterval','Unordered source interval.');
 cfg=load_cfg(base,cache);assert(cfg.bootstrapCount==2000 && cfg.pilot.bootstrapSeed==1401 && cfg.confirmation.bootstrapSeed==2401, ...
  'ejc:ClaimBootstrap','Frozen Study 1 bootstrap configuration differs.');
 assert(any(row.campaign==["pilot","confirmation"]),'ejc:ClaimPairing','Unknown campaign.');
 n=cfg.(row.campaign).noiseTrials;
 assert(row.attemptedPairs==n && row.completePairs==n && row.finitePairs==n && row.bootstrapResamples==cfg.bootstrapCount, ...
  'ejc:ClaimPairing','Every prescribed noisy pair is required.');
 assert(any(row.contrast==["S-A","S-W","S-R","R-P2"]),'ejc:ClaimPairing','Unknown paired model membership.');
 proofKey=char("CLAIM_PAIRED_PROOF|"+base+"|"+relative+"|"+scope.kind+"|"+string(jsonencode(table2struct(row),ConvertInfAndNaN=false)));
 if isKey(cache,proofKey),evidence=cache(proofKey);return;end
 ids=split(row.contrast,'-');parts=cell(2,n);
 measured=relative=="tables/measured_initialization_paired_contrasts.csv";
 parentFile="tables/common_query_forecasts.csv";if measured,parentFile="tables/measured_initialization_audit.csv";end
 tableParents=read_cached(base,parentFile,"study1",cache);
 for m=1:2
  query=row;query.model=ids(m);
  group=select_group(tableParents,query,["campaign","model","auditType","fittingTransitions","inputMode","horizon"]);
  group=group(tableParents.trial(group)>0);
  assert(isequal(sort(tableParents.trial(group)),(1:n)'),'ejc:ClaimPairing','Trial membership, duplicates or count differs.');
  for trial=1:n
   j=group(tableParents.trial(group)==trial);parent=tableParents(j,:);
   if measured,parts{m,trial}=measured_parent(base,parent,cfg,cache,scope.kind=="STRUCTURAL_NULL_CONTRAST");
   else,parts{m,trial}=common_parent("study1",base,parent,cfg,cache);end
   if scope.kind=="STRUCTURAL_NULL_CONTRAST"
    assert(measured && parts{m,trial}.maxAbsFreezing<=1e-11, ...
     'ejc:ClaimIdentity','One parent exceeds the unchanged contact/affine limit.');
    scalar_link(parent.freezingRMS,parts{m,trial}.freezingRMS,true,"P10");
    assert(abs(parent.freezingRMS-parts{m,trial}.freezingRMS)<=ejc_csv_encoding_budget(parts{m,trial}.freezingRMS), ...
     'ejc:ClaimReduction','Identity parent RMS is not its own raw-array encoding.');
   else
    assert(row.metric=="meanCrossTerm",'ejc:ClaimScope','Unsupported paired algebraic cross term.');
    scalar_link(parent.meanCrossTerm,parts{m,trial}.meanCrossTerm,true,"P10");
   end
  end
 end
 evidence=struct('passed',true,'sourceRow',ix,'sourceFile',string(fullfile(base,relative)), ...
  'sourceSHA256',string(ejc_file_sha256(fullfile(base,relative))),'sourceProof',sourceProof, ...
  'sourceAndBootstrapPassed',true,'exactExportLinkPassed',true,'trialIds',(1:n)', ...
  'bootstrapSeed',cfg.(row.campaign).bootstrapSeed,'bootstrapResamples',cfg.bootstrapCount, ...
  'bootstrapMembershipAuthority',"Unchanged pinned study1_summarize query_summaries; exact trial groups/order and mt19937ar configuration; unchanged source-binding reducer executed", ...
  'parentChecks',{parts},'leftMaximum',max(cellfun(@(v)v.maxAbsFreezing,parts(1,:))), ...
  'rightMaximum',max(cellfun(@(v)v.maxAbsFreezing,parts(2,:))),'identityLimit',1e-11);
 cache(proofKey)=evidence;
else
 if scope.sourceStudy=="study1"
  cfg=load_cfg(base,cache);
  if relative=="tables/measured_initialization_audit.csv",evidence=measured_parent(base,row,cfg,cache);
  elseif relative=="tables/common_query_forecasts.csv",evidence=common_parent("study1",base,row,cfg,cache);
  else,error('ejc:ClaimScope','Unsupported Study 1 cross-term source.');end
 elseif scope.sourceStudy=="study2"
  assert(relative=="tables/common_query_forecasts.csv",'ejc:ClaimScope','Unsupported Study 2 source.');
  evidence=common_parent("study2",base,row,load_cfg(base,cache),cache);
 elseif scope.sourceStudy=="study6"
  paperLink=struct;csvLink=struct;
  if c.isCSV && c.study=="study6"
   [row,csvLink]=study6_csv_source_keys(base,relative,row,c,side,cache);
  end
  if ~ismember('sourceFile',row.Properties.VariableNames)
   assert(c.study=="paper" && c.file=="paper_table12.csv" && ~c.isCSV, ...
    'ejc:ClaimSourceLink','Only the original unrounded Table 12 selection omits this source path.');
   [row,paperLink]=table12_source_row(base,row,cache);
  end
  evidence=study6_parent(base,row,cache);
  evidence.paperSelectionLink=paperLink;
  evidence.csvSourceIdentity=csvLink;
 else,error('ejc:ClaimScope','Unsupported cross-term parent study.');end
 field=string(regexp(char(scope.sourceField),'[^.]+$','match','once'));
 assert(any(field==["meanCrossTerm","meanCombinedCrossTerm"]),'ejc:ClaimScope','Unsupported algebraic scalar.');
 scalar_link(row.(field),evidence.(field),c.isCSV,"P10");
 evidence.sourceProof=sourceProof;
end
end
function [row,link]=study6_csv_source_keys(base,relative,row,c,side,cache)
% P13 already binds these literal CSV rows to an existing unrounded table.
% Resolve exact parent keys there; do not introduce a fuzzy identity join.
assert(any(relative=="tables/"+["primary","online","measurement","change","main"]+".csv"), ...
 'ejc:ClaimSourceLink','Unsupported Study 6 direct-table source.');
binding=c.bindingA;if side=="reference",binding=c.bindingB;end
file=string(fullfile(base,'summary.mat'));
assert(binding.sourceKind=="DIRECT_SAVED_UNROUNDED_TABLE" && isequal(string(binding.parents),file), ...
 'ejc:ClaimSourceLink','Original direct saved-table binding required.');
key=char("CLAIM_STUDY6_CSV_BINDING|"+base+"|"+relative+"|"+side);
if ~isKey(cache,key)
 [~,name]=fileparts(relative);z=load(file,'summary');T=z.summary.(name);
 assert(isequaln(binding.values,T),'ejc:ClaimSourceLink','Declared unrounded binding differs from its own saved table.');
 raw=read_cached(base,relative,"study6",cache);encoding=ejc_csv_mat_link(fullfile(base,relative),T);
 assert(encoding.passed && height(raw)==height(T),'ejc:ClaimExportLink','Original CSV/source encoding check failed.');
 cache(key)=struct('raw',raw,'values',T,'encoding',encoding,'summarySHA256',string(ejc_file_sha256(file)));
end
bundle=cache(key);j=c.rowIndex;
assert(isscalar(j)&&isfinite(j)&&j==fix(j)&&j>=1&&j<=height(bundle.raw) && ...
 isequaln(row,bundle.raw(j,:)),'ejc:ClaimExportLink','Claim row differs from its exact saved CSV row.');
keys=study6_keys;originalKeys=row(:,keys);unrounded=bundle.values(j,keys);
row(:,keys)=unrounded;
link=struct('passed',true,'sourceRow',j,'sourceFile',file,'sourceSHA256',bundle.summarySHA256, ...
 'rawCSVKeys',originalKeys,'exactUnroundedKeys',unrounded,'existingP13EncodingCheck',bundle.encoding);
end
function [row,link]=table12_source_row(base,row,cache)
% The original paper callback removes only sourceFile. Recover it from the
% exact own unrounded selection, never by accepting a missing general key.
key=char("CLAIM_TABLE12_SOURCE|"+base);
if ~isKey(cache,key)
 file=fullfile(base,'summary.mat');z=load(file,'summary');T=z.summary.measurement;
 T=T(T.kind=="measurementInitialization" & T.sourceStudy==1 & T.sourceCampaign=="confirmation" & ...
  T.trial==0 & T.inputMode=="recordedRateLimited" & T.initialization=="measured",:);
 T=sortrows(T,{'modelId','horizon'});selection=T;selection.sourceFile=[];
 [verified,csvLink]=ejc_paper_table12_source(base,selection);
 assert(isequaln(selection,verified),'ejc:ClaimExportLink','Original unrounded Table 12 selection differs.');
 cache(key)=struct('values',T,'sourceSHA256',string(ejc_file_sha256(file)),'csvLink',csvLink);
end
bundle=cache(key);keys=study6_keys;keys(keys=="sourceFile")=[];
ix=select_row(bundle.values,row,keys);source=bundle.values(ix,:);selected=source;selected.sourceFile=[];
assert(isequaln(row,selected),'ejc:ClaimExportLink','Table 12 value or metadata differs from its exact own source row.');
row.sourceFile=source.sourceFile;
link=struct('passed',true,'sourceRow',ix,'sourceFile',source.sourceFile, ...
 'summarySHA256',bundle.sourceSHA256,'csvLink',bundle.csvLink,'originalExcludedField',"sourceFile");
end
function p=measured_parent(base,row,cfg,cache,identityRequired)
if nargin<5,identityRequired=false;end
assert(row.auditType=="within-run measured-initial-state sensitivity" && any(row.campaign==["pilot","confirmation"]) && ...
 any(row.model==string(cfg.modelIds)) && row.trial>=0 && row.trial<=cfg.(row.campaign).noiseTrials && mod(row.trial,1)==0, ...
 'ejc:ClaimParents','Measured parent keys differ.');
name=sprintf('%s_%s_%03d.mat',row.campaign,row.model,row.trial);
file=fullfile(base,'audits',name);run=fullfile(base,'data',name);key=char("CLAIM_MEASURED|"+file);
if ~isKey(cache,key)
 a=load(file,'audit');r=load(run,'result');p=ejc_measured_parent_check(a.audit,r.result,cfg);
 p.sourceFile=string(file);p.sourceSHA256=string(ejc_file_sha256(file));p.runSHA256=string(ejc_file_sha256(run));cache(key)=p;
end
p=cache(key);h=find(p.horizons==row.horizon);m=find(p.inputModes==row.inputMode);
assert(isscalar(h)&&isscalar(m)&&p.model==row.model&&p.campaign==row.campaign&&p.trial==row.trial, ...
 'ejc:ClaimQueries','Exact measured parent selection failed.');
assert(row.attemptedCount==p.queryCount&&row.validCount==p.queryCount&&row.invalidCount==0&&row.allQueriesValid, ...
 'ejc:ClaimValidity','Measured count/validity link differs.');
p.selection=[h m];p.maxAbsFreezing=p.maxAbsFreezing(h,m);p.freezingRMS=p.freezingRMS(h,m);p.meanCrossTerm=p.meanCrossTerm(h,m);
if identityRequired,assert(p.maxAbsFreezing<=1e-11,'ejc:ClaimIdentity','One model parent exceeds the unchanged identity limit.');end
scalar_link(row.freezingRMS,p.freezingRMS,true,"P10");scalar_link(row.meanCrossTerm,p.meanCrossTerm,true,"P10");
end
function p=common_parent(study,base,row,cfg,cache)
if study=="study1"
 name=sprintf('%s_%s_%03d.mat',row.campaign,row.model,row.trial);file=fullfile(base,'data',name);
 key=char("CLAIM_COMMON|"+file);
 if ~isKey(cache,key)
  z=load(file,'result');r=z.result;
  assert(string(r.id)==row.model && string(r.campaign)==row.campaign && r.trial==row.trial,'ejc:ClaimParents','Common source identity differs.');
  p=common_check(r.forecasts,cfg);p.sourceFile=string(file);p.sourceSHA256=string(ejc_file_sha256(file));cache(key)=p;
 end
else
 file=fullfile(base,'evaluation',row.model+".mat");key=char("CLAIM_COMMON|"+file+"|"+row.evaluationRange);
 if ~isKey(cache,key)
  z=load(file,'evaluations');ix=find([z.evaluations.evaluationRange]==row.evaluationRange);assert(isscalar(ix),'ejc:ClaimQueries','Evaluation range ambiguous.');
  p=common_check(z.evaluations(ix),cfg);p.sourceFile=string(file);p.sourceSHA256=string(ejc_file_sha256(file));cache(key)=p;
 end
end
p=cache(key);h=find(p.horizons==row.horizon);m=find(p.inputModes==row.inputMode);s=find(p.fitSteps==row.fittingTransitions);
assert(isscalar(h)&&isscalar(m)&&isscalar(s),'ejc:ClaimQueries','Common-query selector differs.');
assert(row.queryCount==p.queryCount&&row.validCount==p.queryCount,'ejc:ClaimValidity','Common-query counts differ.');
p.selection=[h m s];p.meanCrossTerm=p.meanCrossTerm(h,m,s);p.maxAbsFreezing=p.maxAbsFreezing(h,m,s);p.freezingRMS=p.freezingRMS(h,m,s);
scalar_link(row.meanCrossTerm,p.meanCrossTerm,true,"P10");
end
function p=common_check(f,cfg)
shape=[numel(cfg.anchors),numel(cfg.horizons),2,numel(cfg.fitSteps)];
assert(isequal(f.anchors,cfg.anchors)&&isequal(f.horizons,cfg.horizons)&&isequal(f.fitSteps,cfg.fitSteps)&& ...
 isequal(string(f.inputModes),["held","rateLimited"]),'ejc:ClaimQueries','Original common-query membership differs.');
assert(isequal(size(f.valid),shape)&&all(f.valid,'all')&&isempty(f.failures)&&all(isfinite(f.oneStepErrors),'all'), ...
 'ejc:ClaimValidity','A prescribed common query is invalid.');
for name=["modelError","freezingError","totalError","crossTerm"]
 assert(isequal(size(f.(name)),shape)&&all(isfinite(f.(name)),'all'),'ejc:ClaimValidity','Invalid common error arrays.');
end
em=f.modelError;ef=f.freezingError;et=f.totalError;scale=max([1;abs(em(:));abs(ef(:));abs(et(:))]);
assert(isequal(f.crossTerm,2*em.*ef)&&max(abs(et-em-ef),[],'all')<=1e-11*scale && ...
 max(abs(et.^2-em.^2-ef.^2-f.crossTerm),[],'all')<=1e-11*scale^2, ...
 'ejc:ClaimDecomposition','Common-query decomposition failed.');
p=struct('passed',true,'horizons',f.horizons,'inputModes',string(f.inputModes),'fitSteps',f.fitSteps, ...
 'queryCount',numel(cfg.anchors),'meanCrossTerm',squeeze(mean(f.crossTerm,1)), ...
 'maxAbsFreezing',squeeze(max(abs(ef),[],1)),'freezingRMS',squeeze(sqrt(mean(ef.^2,1))), ...
 'validityPassed',true,'decompositionPassed',true);
end
function p=study6_parent(base,row,cache)
key=char("CLAIM_STUDY6|"+base);
if ~isKey(cache,key)
 tables=table;paths=strings(0,1);hashes=strings(0,1);
 for folder=["primary","online","measurement","change"]
  files=dir(fullfile(base,folder,'*.mat'));
  expected=35;if folder=="online"||folder=="change",expected=18;elseif folder=="measurement",expected=258;end
  assert(numel(files)==expected,'ejc:ClaimParents','Study 6 parent inventory differs.');
  for file=files'
   path=fullfile(file.folder,file.name);z=load(path,'out','q');o=z.out;q=z.q;
   study6_check(o,q);
   assert(all(o.valid,'all')&&isempty(o.failures)&&isequal(q.matlabColumns,q.indices+1),'ejc:ClaimValidity','Study 6 required paths invalid.');
   assert(isequal(o.modelError,o.nonlinear-q.truthY)&&isequal(o.freezingError,o.affine-o.nonlinear)&& ...
    isequal(o.totalError,o.affine-q.truthY)&&isequal(o.combinedError,o.affine-q.truthFuture)&& ...
    isequal(o.crossTerm,2*o.modelError.*o.freezingError)&& ...
    isequal(o.combinedCrossTerm,o.crossTerm+2*(o.totalError.*o.initializationError+o.totalError.*o.changeError+o.initializationError.*o.changeError)), ...
    'ejc:ClaimDecomposition','Study 6 component/source identities differ.');
   T=study6_summary(o,q);tables=[tables;T]; %#ok<AGROW>
   paths=[paths;repmat(string(path),height(T),1)];hashes=[hashes;repmat(string(ejc_file_sha256(path)),height(T),1)]; %#ok<AGROW>
  end
 end
 keys=study6_keys;index=containers.Map('KeyType','char','ValueType','double');
 for j=1:height(tables)
  id=row_key(tables(j,:),keys);assert(~isKey(index,id),'ejc:ClaimSourceLink','Duplicate Study 6 parent key.');index(id)=j;
 end
 cache(key)=struct('values',tables,'paths',paths,'hashes',hashes,'index',index);
end
bundle=cache(key);T=bundle.values;
id=row_key(row,study6_keys);assert(isKey(bundle.index,id),'ejc:ClaimSourceLink','Missing exact Study 6 parent row.');
ix=bundle.index(id);source=T(ix,:);
assert(isequaln(row.sourceFile,source.sourceFile) && isequal(row.unit,source.unit)&&isequal(row.squaredUnit,source.squaredUnit) && ...
 row.squaredUnit=="("+row.unit+")^2"&&row.attemptedQueries==source.attemptedQueries && ...
 row.finiteQueries==source.attemptedQueries&&row.failedQueries==0,'ejc:ClaimUnits','Unit/query/validity source link differs.');
p=struct('passed',true,'sourceFile',bundle.paths(ix),'sourceSHA256',bundle.hashes(ix),'selection',ix, ...
 'meanCrossTerm',source.meanCrossTerm,'meanCombinedCrossTerm',source.meanCombinedCrossTerm, ...
 'queryCount',source.attemptedQueries,'validityPassed',true,'decompositionPassed',true);
end
function cfg=load_cfg(base,cache)
key=char("CLAIM_CFG|"+base);
if ~isKey(cache,key),z=load(fullfile(base,'settings.mat'),'cfg');cache(key)=z.cfg;end
cfg=cache(key);
end
function T=read_cached(base,relative,study,cache)
key=char("CLAIM_TABLE|"+fullfile(base,relative));
if ~isKey(cache,key),cache(key)=ejc_csv_read(fullfile(base,relative),study,relative);end
T=cache(key);
end
function b=binding_for(bindings,study,file)
ix=find(string({bindings.study})==study&string({bindings.file})==file);
assert(isscalar(ix),'ejc:ClaimBootstrap','Missing or ambiguous original reduction binding.');b=bindings(ix);
end
function ix=select_row(T,row,keys)
ix=select_group(T,row,keys);assert(isscalar(ix),'ejc:ClaimSourceLink','Missing/ambiguous exact source row.');
end
function ix=select_group(T,row,keys)
keys=keys(ismember(keys,string(T.Properties.VariableNames)));
assert(all(ismember(keys,string(row.Properties.VariableNames))),'ejc:ClaimSourceLink','Missing row identity key.');
mask=true(height(T),1);
for name=keys
 a=T.(name);b=row.(name);
 if isnumeric(a),same=(a==b)|(isnan(a)&isnan(b));
 elseif isstring(a),same=(a==b)|(ismissing(a)&ismissing(b));
 else,same=a==b;end
 mask=mask & same;
end
ix=find(mask);
end
function scalar_link(a,b,csv,family)
[atol,rtol]=ejc_acceptance_limits(family);
if csv && isfinite(a)&&isfinite(b),atol=atol+ejc_csv_encoding_budget(a)+(1+rtol)*ejc_csv_encoding_budget(b);end
v=ejc_acceptance_numeric(a,b,atol,rtol,true);
assert(v.passed,'ejc:ClaimReduction','Own-source scalar reduction failed its existing rule.');
end

function keys=study6_keys
keys=["kind","sourceStudy","plant","modelId","sourceFile","sourceCampaign","trial","scenario","evaluationRange", ...
 "snapshot","fittingTransitions","snapshotTime","inputMode","initialization","horizon"];
end
function key=row_key(row,keys)
assert(all(ismember(keys,string(row.Properties.VariableNames))),'ejc:ClaimSourceLink','Missing exact Study 6 key.');
key=jsonencode(table2struct(row(:,keys)),ConvertInfAndNaN=false);
end
