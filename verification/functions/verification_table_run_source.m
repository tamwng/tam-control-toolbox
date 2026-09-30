function file=verification_table_run_source(study,row,sources)
%VERIFICATION_TABLE_RUN_SOURCE Closed source resolver for original per-run table keys.
study=string(study);assert(istable(row) && height(row)==1,'ejc:TableSource','One source row required.');
base=sources.(study);
switch study
    case "study1"
        file=fullfile(base,'data',sprintf('%s_%s_%03d.mat',row.campaign,row.model,row.trial));
    case "study2"
        if row.kind=="constraintAudit",name="constraint_"+row.model+".mat";
        else
            c=load(fullfile(base,'settings.mat'),'cfg');ix=find(c.cfg.amplitudes==row.amplitude);
            assert(isscalar(ix),'ejc:TableSource','Ambiguous amplitude source.');
            name=sprintf('amplitude_%02d_%s.mat',ix,row.model);
        end
        file=fullfile(base,'runs',name);
    case "study3"
        file=fullfile(base,'runs',sprintf('%s_%s_%03d.mat',row.scenario,row.caseId,row.trial));
    case "study4"
        file=fullfile(base,'runs',sprintf('%s_%s.mat',row.scenarioId,row.modelId));
    case "study5"
        file=fullfile(base,'runs',row.modelId+".mat");
    case "p06"
        assert(ismember('runId',row.Properties.VariableNames),'ejc:TableSource','Sensitivity requires its exact runId.');
        file=fullfile(base,'runs',row.runId+".mat");
    otherwise,error('ejc:TableSource','No per-run source mapping for %s.',study);
end
assert(isfile(file),'ejc:TableSource','Required own-run source is missing: %s.',file);
end
