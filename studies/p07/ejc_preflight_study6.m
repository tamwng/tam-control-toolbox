function report=ejc_preflight_study6(output,sources,provenance)
%EJC_PREFLIGHT_STUDY6 Diagnostic dispatch of unchanged saved-data machinery.
% Production run_study6 and its clean-candidate validator remain unchanged.
% No scientific algorithm is reimplemented here. Explicit scientifically
% valid Mac inputs may retain FAILED cross-platform comparison verdicts.
root=fileparts(fileparts(fileparts(mfilename('fullpath'))));
assert(~isfolder(output) && ~isfile(output),'ejc:ExistingEvidence','New diagnostic output required.');
assert(provenance.diagnosticOnly && all(provenance.originalValidityPassed) && ...
    numel(provenance.originalValidityPassed)==5,'ejc:PreflightDependency','Five valid explicit Mac parents are required.');
before=ejc_input_snapshot(sources,struct);
assert(isequaln(before,provenance.inputSnapshot),'ejc:PreflightIntegrity','Diagnostic parent bytes changed before dispatch.');
cfg=study6_settings;cfg.sourceMode='Mac diagnostic preflight; not a frozen certification';
cfg.sourceDirectories=cell(1,5);
for s=1:5
    key=sprintf('study%d',s);assert(isfield(sources,key),'ejc:PreflightDependency','Missing source.');
    cfg.sourceDirectories{s}=char(sources.(key));[~,cfg.sources{s}]=fileparts(cfg.sourceDirectories{s});
end
bound=sources;sources=cell(1,5);
for s=1:5,sources{s}=load(fullfile(study6_source(root,cfg,s),'settings.mat'));end
mkdir(output);
for name={'primary','online','measurement','change','tables','figures'},mkdir(fullfile(output,name{1}));end
environment=struct('matlab',version,'execution','Missing Mac diagnostics only; unchanged evaluators; no new trajectories.');
save(fullfile(output,'settings.mat'),'cfg','sources','environment');
summary.primary=study6_primary(output,root,cfg);
summary.online=study6_online(output,root,cfg);
[summary.measurement,summary.change]=study6_secondary(output,root,cfg);
[summary.constraintHistory,summary.constraintSummary]=study6_constraints(output,root,cfg);
summary.study4Grid=study6_grid_context(root,cfg);
summary.main=summary.primary(summary.primary.fittingTransitions==200,:);
save(fullfile(output,'summary.mat'),'summary');
for name=string(fieldnames(summary)).',writetable(summary.(name),fullfile(output,'tables',name+".csv"));end
verification=study6_verify_results(output);save(fullfile(output,'verification.mat'),'verification');
after=ejc_input_snapshot(bound,struct);
assert(isequaln(before,after),'ejc:PreflightIntegrity','Mac parent bytes changed during derivation.');
report=struct('passed',true,'diagnosticOnly',true,'provenance',provenance,'inputsUnchanged',true);
save(fullfile(fileparts(output),'study6_diagnostic_provenance.mat'),'report','-v7');
end
