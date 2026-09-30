function bindings=verification_csv_source_tables(sources,destination,inputs)
%VERIFICATION_CSV_SOURCE_TABLES Frozen CSV producers/selected MAT tables, saved inputs only.
% RECOMPUTED_SAVED_REDUCTION is not an unrounded historical scalar. In particular
% unstable historical Gram extrema are not replaced by the present calculation.
if nargin<3,inputs=struct;end
assert(~isfolder(destination) && ~isfile(destination),'ejc:ExistingOutput','New binding directory required.');
assert_output_writable(destination);mkdir(destination);
bindings=struct('study',{},'file',{},'values',{},'authority',{},'sourceKind',{},'parents',{});
for s=1:3
    study="study"+s;if ~isfield(sources,study),continue;end
    base=sources.(study);z=load(fullfile(base,'settings.mat'),'cfg');
    reducer=str2func("study"+s+"_summarize");
    summary=reducer(base,z.cfg,fullfile(destination,study));
    if s==1
        names=["metrics","diagnostics","initialization","parameters","forecasts","events", ...
            "counts","noisy","paired","initializationNoisy","initializationPaired", ...
            "forecastsNoisy","forecastsPaired","measuredNoisy","measuredPaired"];
        files=["run_metrics","run_diagnostics","initialization_scores","parameter_components", ...
            "common_query_forecasts","events","trial_counts","noisy_summaries","paired_contrasts", ...
            "initialization_noisy_summaries","initialization_paired_contrasts", ...
            "forecast_noisy_summaries","forecast_paired_contrasts", ...
            "measured_initialization_noisy_summaries","measured_initialization_paired_contrasts"];
        measured=measured_rows(base,z.cfg);
        put(study,"tables/measured_initialization_audit.csv",measured, ...
            "study1_measured_audits.m:summary_rows; original campaign/model/trial/mode/horizon order", ...
            "RECOMPUTED_SAVED_REDUCTION",parents(base));
    elseif s==2
        names=["metrics","diagnostics","initialization","parameters","forecasts","constraint","fitDiagnostics","events","records","counts"];
        files=["run_metrics","run_diagnostics","initialization_scores","parameter_components","common_query_forecasts", ...
            "constraint_audit","initialization_diagnostics","events","record_ranges","run_counts"];
    else
        names=["metrics","diagnostics","parameters","recovery","events","counts","recoveryCounts","noisy","paired","initialization","fitDiagnostics","initializationNoisy"];
        files=["run_metrics","run_diagnostics","parameter_components","recovery","events","run_counts", ...
            "recovery_counts","noisy_summaries","paired_contrasts","initialization_scores","initialization_diagnostics","initialization_noisy_summaries"];
    end
    for j=1:numel(names)
        put(study,"tables/"+files(j)+".csv",summary.(names(j)), ...
            "unchanged "+study+"_summarize.m:summary."+names(j), ...
            "RECOMPUTED_SAVED_REDUCTION",parents(base));
    end
end
for study=["study4","study5","study6"]
    if ~isfield(sources,study),continue;end
    base=sources.(study);z=load(fullfile(base,'summary.mat'),'summary');
    for name=string(fieldnames(z.summary)).'
        put(study,"tables/"+name+".csv",z.summary.(name), ...
            "summary.mat:summary."+name,"DIRECT_SAVED_UNROUNDED_TABLE",string(fullfile(base,'summary.mat')));
    end
    if study=="study6"
        v=study6_verify_results(base,fullfile(destination,'study6_validity'));
        put(study,"tables/verification.csv",struct2table(v), ...
            "unchanged study6_verify_results.m; all 329 batches and original validity checks", ...
            "RECOMPUTED_SAVED_REDUCTION",parents(base));
    end
end
if isfield(sources,'p06')
    base=sources.p06;
    if isfield(inputs,'sensitivityPlan')
        plan=inputs.sensitivityPlan;manifest=inputs.sensitivityManifest;
        gateArchive=inputs.sensitivityReference;
    else
        [plan,manifest]=sensitivity_plan;gateArchive=plan.archive;
    end
    put("p06","P06_RUN_MANIFEST.csv",manifest,"sensitivity_plan.m", ...
        "EXACT_FIXED_DESIGN",string({plan.recordFile,plan.settingsFile}));
    listing=verification_csv_read(fullfile(base,'tables/runs.csv'),"p06","tables/runs.csv");
    items=cell(height(listing),1);gates=table;
    for j=1:height(listing)
        file=fullfile(base,'runs',listing.runId(j)+".mat");z=load(file,'item','result');
        assert(string(z.item.runId)==listing.runId(j),'ejc:CSVSource','Sensitivity item identity differs.');
        items{j}=z.item;
        if z.item.baselineGate
            expected=fullfile(gateArchive,'data',sprintf('confirmation_%s_%03d.mat',z.item.modelId,z.item.trial));
            old=load(expected,'result');g=sensitivity_baseline_check(z.result,old.result,plan.cfg);
            g.runId=repmat(string(z.item.runId),height(g),1);
            g.baselineSHA256=repmat(string(sensitivity_hash(expected)),height(g),1);gates=[gates;g]; %#ok<AGROW>
        end
    end
    runs=struct2table(vertcat(items{:}));
    assert(isequal(sort(runs.runId),sort(manifest.runId)),'ejc:CSVSource','Sensitivity run inventory differs.');
    put("p06","tables/runs.csv",runs,"runs/<runId>.mat:item, original execution row order", ...
        "DIRECT_SAVED_UNROUNDED_TABLE",parents(base));
    put("p06","tables/deterministic.csv",runs(~runs.noisy,:), ...
        "runs.csv unrounded item table: ~noisy, order unchanged","DIRECT_SAVED_UNROUNDED_TABLE",parents(base));
    put("p06","tables/known_reference_aliases.csv",plan.knownAliases, ...
        "sensitivity_plan.m:knownAliases","EXACT_FIXED_DESIGN",string(plan.settingsFile));
    put("p06","tables/baseline_gate.csv",gates, ...
        "sensitivity_baseline_check on saved sensitivity and Study 1 arrays; historical zero is not a target", ...
        "ACTUAL_ARRAY_P06_GATE",parents(base));
    [summaries,contrasts,analysis]=sensitivity_summarize(runs,plan);
    old=load(fullfile(base,'analysis_randomness.mat'),'analysis');
    assert(isequaln(analysis,old.analysis),'ejc:CSVSource','Sensitivity bootstrap selections/state differ.');
    put("p06","tables/noisy_summaries.csv",summaries,"sensitivity_summarize.m; saved item rows; exact analysis_randomness.mat", ...
        "RECOMPUTED_SAVED_REDUCTION",parents(base));
    put("p06","tables/paired_contrasts.csv",contrasts,"sensitivity_summarize.m/sensitivity_contrast.m; exact pairing/bootstrap", ...
        "RECOMPUTED_SAVED_REDUCTION",parents(base));
end
if isfield(sources,'paper')
    base=sources.paper;z=load(fullfile(base,'paper_report.mat'),'report');r=z.report;
    put("paper","paper_A14_conditioning.csv",r.conditioning,"paper_report.mat:report.conditioning", ...
        "DIRECT_SAVED_UNROUNDED_TABLE",string(fullfile(base,'paper_report.mat')));
    put("paper","paper_primary_run_counts.csv",r.primaryRunCounts,"paper_report.mat:report.primaryRunCounts", ...
        "DIRECT_SAVED_UNROUNDED_TABLE",string(fullfile(base,'paper_report.mat')));
    put("paper","paper_source_bindings.csv",r.sourceBindings,"paper_report.mat:report.sourceBindings", ...
        "DIRECT_SAVED_UNROUNDED_TABLE",string(fullfile(base,'paper_report.mat')));
    put("paper","paper_result_sources.csv",r.resultSources,"paper_report.mat:report.resultSources", ...
        "DIRECT_SAVED_UNROUNDED_TABLE",string(fullfile(base,'paper_report.mat')));
    exports={ ...
        'study1','paired_contrasts','paper_A17_study1_control'; ...
        'study1','initialization_paired_contrasts','paper_A17_study1_initialization'; ...
        'study1','forecast_paired_contrasts','paper_A17_study1_common_forecasts'; ...
        'study1','measured_initialization_paired_contrasts','paper_A17_study1_retrospective'; ...
        'study3','paired_contrasts','paper_A17_study3'; ...
        'p06','noisy_summaries','paper_A18_noisy_summaries'; ...
        'p06','paired_contrasts','paper_A18_paired_contrasts'};
    for k=1:size(exports,1)
        st=string(exports{k,1});relative="tables/"+exports{k,2}+".csv";
        % Current paper exports bind to the paper package's own siblings.
        % The reference Table 12 alone binds to the historical reference root.
        paperParent=fullfile(fileparts(base),st);
        assert(isfolder(paperParent),'ejc:CSVSource','Paper own-parent package is absent.');
        file=fullfile(paperParent,relative);v=verification_csv_read(file,st,relative);
        if st=="study1",v=v(v.campaign=="confirmation",:);end
        put("paper",string(exports{k,3})+".csv",v, ...
            "verification_paper_report.m: explicit "+st+"/"+relative+" selection; confirmation only for Study 1", ...
            "EXACT_SERIALIZED_SOURCE_SELECTION",string(file));
    end
    for name=["paper_table12.csv","paper_table12_reference.csv"]
        parent=sources.study6;
        if name=="paper_table12.csv",parent=fullfile(fileparts(base),'study6');end
        file=fullfile(parent,'tables/measurement.csv');
        v=verification_csv_read(file,"study6","tables/measurement.csv");
        v=v(v.kind=="measurementInitialization" & v.sourceStudy==1 & v.sourceCampaign=="confirmation" & ...
            v.trial==0 & v.inputMode=="recordedRateLimited" & v.initialization=="measured",:);
        v=sortrows(v,{'modelId','horizon'});
        assert(height(v)==30 && numel(unique(v.modelId))==6 && isequal(sort(unique(v.horizon)),[1;2;5;10;20]) && ...
            all(v.attemptedQueries==29),'ejc:CSVSource','Table 12 selection differs.');
        put("paper",name,v,"verification_paper_report.m:measurement_rows; six models, five horizons, 29 queries", ...
            "EXACT_SERIALIZED_SOURCE_SELECTION",string(file));
    end
end
save(fullfile(destination,'csv_source_tables.mat'),'bindings','-v7');
    function put(study,file,values,authority,kind,files)
        assert(istable(values),'ejc:CSVSource','A binding must resolve to an explicit table.');
        bindings(end+1)=struct('study',study,'file',file,'values',values,'authority',authority, ...
            'sourceKind',kind,'parents',files); %#ok<AGROW>
    end
end
function files=parents(base)
entries=dir(fullfile(base,'**','*.mat'));files=string(fullfile({entries.folder},{entries.name})).';
files=files(~contains(replace(files,filesep,'/'),["/review/","/source_snapshot/"]));
end
function values=measured_rows(base,cfg)
rows=struct([]);
for campaign=["pilot","confirmation"]
    for id=string(cfg.modelIds)
        for trial=0:cfg.(campaign).noiseTrials
            z=load(fullfile(base,'audits',sprintf('%s_%s_%03d.mat',campaign,id,trial)),'audit');a=z.audit;
            assert(string(a.campaign)==campaign && string(a.id)==id && a.trial==trial,'ejc:CSVSource','Audit identity mismatch.');
            for mode=1:numel(a.inputModes)
                for h=1:numel(a.horizons)
                    valid=a.valid(:,h,mode);
                    r=struct('campaign',string(a.campaign),'model',string(a.id),'trial',a.trial,'noise',a.trial>0, ...
                        'auditType',"within-run measured-initial-state sensitivity",'inputMode',string(a.inputModes{mode}), ...
                        'horizon',a.horizons(h),'attemptedCount',numel(valid),'validCount',nnz(valid), ...
                        'invalidCount',nnz(~valid),'allQueriesValid',all(valid));
                    for pair={"measuredModelRMS","measuredModelError";"freezingRMS","freezingError"; ...
                            "totalRMS","totalError";"cleanModelRMS","cleanModelError";"initializationEffectRMS","initializationEffect"}'
                        r.(pair{1})=sqrt(mean(a.(pair{2})(:,h,mode).^2));
                    end
                    r.meanCrossTerm=mean(a.crossTerm(:,h,mode));rows=[rows;r]; %#ok<AGROW>
                end
            end
        end
    end
end
values=struct2table(rows);
end
