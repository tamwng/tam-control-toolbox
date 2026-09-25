function run_gate_b_cases
%RUN_GATE_B_CASES Fixed pre-refactor cases; immutable archives are inputs only.
evidence = fileparts(mfilename('fullpath')); root = fileparts(fileparts(evidence));
prior = jsondecode(fileread(fullfile(evidence,'checks','status.json')));
assert(strcmp(prior.status,'PASSED'),'p07:PriorGate','Existing checks must pass first.');
output = fullfile(evidence,'cases');
assert(~isfolder(output) && ~isfile(output),'p07:ExistingOutput','Never overwrite an attempt.');
mkdir(output); diary(fullfile(output,'matlab_diary.txt')); finish = onCleanup(@() diary('off'));
oldPath = path; restore = onCleanup(@() path(oldPath));
addpath(root,fullfile(root,'src'),fullfile(root,'studies','p06'));
for s = 1:6, addpath(fullfile(root,'studies',sprintf('study%d',s))); end
state = struct('baselineSHA','0ac937f94fbcc10c64742e9b4a47367e4d929cc1', ...
    'status','RUNNING','startedUTC',char(datetime('now','TimeZone','UTC')), ...
    'completedCases',0,'comparisonRule','BASELINE_PLAN.md; exact additional representatives; original P06 gate');
timer = tic; rows = table;
try
    [status,head] = system(sprintf('git -C "%s" rev-parse HEAD',root));
    assert(status == 0 && strcmp(strtrim(head),state.baselineSHA),'p07:BaselineSHA','Source SHA changed.');
    [plan,manifest] = p06_plan; saved = load(plan.recordFile,'records');
    for index = find(manifest.baselineGate).'
        item = manifest(index,:); [result,scores] = p06_case(item,plan,saved.records);
        reference = load(item.baselineFile,'result');
        checks = p06_gate(result,reference.result,plan.cfg);
        checks.caseId = repmat("p06_"+item.runId,height(checks),1);
        checks.reference = repmat(item.baselineFile,height(checks),1);
        checks.exact = checks.passed & checks.maxAbsoluteDifference == 0;
        save(fullfile(output,"p06_"+item.runId+".mat"),'item','result','scores','checks');
        rows = [rows;checks]; %#ok<AGROW>
        writetable(rows,fullfile(output,'p06_comparisons.csv'));
        assert(all(checks.passed),'p07:BaselineMismatch','Original P06 gate failed: %s.',item.runId);
        state.completedCases = state.completedCases+1;
        fprintf('Baseline %s: %d comparisons, maximum difference %.17g.\n',item.runId,height(checks),max(checks.maxAbsoluteDifference));
    end
    exactRows = table;
    archive = fullfile(root,'results','study2_pilot_20260918');
    s = load(fullfile(archive,'settings.mat'),'cfg'); cfg = study2_settings;
    assert(isequaln(cfg,s.cfg),'p07:Settings','Study 2 settings differ.');
    s = load(fullfile(archive,'records.mat'),'initialization');
    for id = ["E","K"]
        [~,fit] = study2_fit(id,s.initialization,cfg);
        ref = load(fullfile(archive,'fits',id+".mat"),'fit');
        exactRows = record_compare(exactRows,output,"study2_fit_"+id,fit,ref.fit);
        if id == "E"
            result = study2_trajectory(id,fit,cfg.amplitudes(3),cfg); name = 'amplitude_03_E';
        else
            audit = cfg; audit.kind = 'constraintAudit'; audit.duration = 10; audit.K = 100;
            audit.initialState = 1.4; audit.constantReference = .6; audit.control.hy = [.85;.85];
            result = study2_trajectory(id,fit,NaN,audit); name = 'constraint_K';
        end
        ref = load(fullfile(archive,'runs',[name '.mat']),'result');
        exactRows = record_compare(exactRows,output,"study2_"+name,result,ref.result);
        state.completedCases = state.completedCases+1;
    end
    archive = fullfile(root,'results','study3_pilot_20260918');
    s = load(fullfile(archive,'settings.mat'),'cfg'); cfg = study3_settings;
    % Historical execution descriptions are provenance, not scientific settings.
    assert(isequaln(cfg,s.cfg),'p07:Settings','Study 3 settings differ.');
    s = load(fullfile(archive,'records.mat'),'records'); records = s.records;
    for trial = 0:1
        training = records.initialization;
        training.measurementNoise = zeros(1,201); training.processNoise = zeros(1,200);
        noise = struct('measurement',zeros(1,cfg.K+1),'process',zeros(1,cfg.K));
        scenarios = ["abrupt","drift"];
        if trial > 0
            training.measurementNoise = records.initialMeasurementNoise(trial,:);
            training.processNoise = records.initialProcessNoise(trial,:);
            for j = 1:200
                training.x(j+1) = study3_plant(training.x(j),training.u(j),.45,training.processNoise(j));
            end
            training.y = training.x+training.measurementNoise;
            noise.measurement = records.controlMeasurementNoise(trial,:);
            noise.process = records.controlProcessNoise(trial,:); scenarios = "abrupt";
        end
        [~,fit] = study1_fit('S',training,cfg);
        ref = load(fullfile(archive,'fits',sprintf('fit_S_%03d.mat',trial)),'fit');
        exactRows = record_compare(exactRows,output,sprintf('study3_fit_S_%03d',trial),fit,ref.fit);
        for scenario = scenarios
            result = study3_trajectory('S_vrf',fit,char(scenario),trial,noise,cfg);
            name = sprintf('%s_S_vrf_%03d',scenario,trial);
            ref = load(fullfile(archive,'runs',[name '.mat']),'result');
            exactRows = record_compare(exactRows,output,"study3_"+name,result,ref.result);
            state.completedCases = state.completedCases+1;
        end
    end
    archive = fullfile(root,'results','study4_pilot_20260922');
    s = load(fullfile(archive,'settings.mat'),'cfg'); cfg = study4_settings;
    assert(isequaln(cfg,s.cfg),'p07:Settings','Study 4 settings differ.');
    s = load(fullfile(archive,'records.mat'),'records');
    fit = study4_fit('Aplus',s.records.initialization,cfg);
    ref = load(fullfile(archive,'fits','fit_Aplus.mat'),'fit');
    exactRows = record_compare(exactRows,output,'study4_fit_Aplus',fit,ref.fit);
    for scenario = string(cfg.scenarios)
        result = study4_trajectory('Aplus',fit,scenario,cfg);
        name = scenario+"_Aplus"; ref = load(fullfile(archive,'runs',name+".mat"),'result');
        exactRows = record_compare(exactRows,output,"study4_"+name,result,ref.result);
        evaluation = study4_evaluate(result,cfg);
        ref = load(fullfile(archive,'evaluation',name+".mat"),'evaluation');
        exactRows = record_compare(exactRows,output,"study4_grid_"+name,evaluation,ref.evaluation);
        state.completedCases = state.completedCases+1;
    end
    archive = fullfile(root,'results','study5_pilot_20260922');
    s = load(fullfile(archive,'settings.mat'),'cfg'); cfg = study5_settings;
    assert(isequaln(cfg,s.cfg),'p07:Settings','Study 5 settings differ.');
    s = load(fullfile(archive,'records.mat'),'records');
    fit = study5_fit('I',s.records.initialization,cfg);
    ref = load(fullfile(archive,'fits','fit_I.mat'),'fit');
    exactRows = record_compare(exactRows,output,'study5_fit_I',fit,ref.fit);
    result = study5_trajectory('I',fit,cfg); ref = load(fullfile(archive,'runs','I.mat'),'result');
    exactRows = record_compare(exactRows,output,'study5_I',result,ref.result);
    state.completedCases = state.completedCases+1;
    state.status = 'PASSED'; state.p06ComparisonCount = height(rows);
    state.exactComparisonCount = height(exactRows);
catch exception
    state.status = 'FAILED_OR_BLOCKED'; state.identifier = exception.identifier;
    state.message = exception.message; state.report = getReport(exception,'extended','hyperlinks','off');
    state.elapsedSeconds = toc(timer); state.completedUTC = char(datetime('now','TimeZone','UTC'));
    save(fullfile(output,'status.mat'),'state'); write_json(fullfile(output,'status.json'),state);
    rethrow(exception)
end
state.elapsedSeconds = toc(timer); state.completedUTC = char(datetime('now','TimeZone','UTC'));
save(fullfile(output,'status.mat'),'state'); write_json(fullfile(output,'status.json'),state);
fprintf('Gate B cases: %s, %d completed cases.\n',state.status,state.completedCases);
end

function rows = record_compare(rows,output,caseId,current,reference)
checks = compare_tree(current,reference,"value",string(caseId));
save(fullfile(output,string(caseId)+".mat"),'current','checks');
rows = [rows;checks]; writetable(rows,fullfile(output,'exact_comparisons.csv'));
assert(all(checks.passed),'p07:BaselineMismatch','Exact baseline mismatch: %s. See saved comparisons.',caseId);
fprintf('Baseline %s: %d exact quantities matched.\n',caseId,height(checks));
end

function rows = compare_tree(a,b,field,caseId)
rows = table;
if isstruct(a) && isstruct(b) && isequal(size(a),size(b)) && isequal(sort(fieldnames(a)),sort(fieldnames(b)))
    for k = 1:numel(a)
        for name = string(fieldnames(a)).'
            if name == "controlTime", continue; end
            rows = [rows;compare_tree(a(k).(name),b(k).(name),field+"."+name+"["+k+"]",caseId)]; %#ok<AGROW>
        end
    end
elseif iscell(a) && iscell(b) && isequal(size(a),size(b))
    for k = 1:numel(a)
        rows = [rows;compare_tree(a{k},b{k},field+"{"+k+"}",caseId)]; %#ok<AGROW>
    end
else
    passed = isequaln(a,b); maximum = NaN; index = NaN;
    if (isnumeric(a) || islogical(a)) && (isnumeric(b) || islogical(b)) && isequal(size(a),size(b))
        finite = isfinite(a) & isfinite(b); indices = find(finite);
        delta = abs(double(a(finite))-double(b(finite)));
        maximum = 0;
        if ~isempty(delta), [maximum,k] = max(delta); index = indices(k); end
    end
    rows = table(caseId,field,0,0,maximum,index,passed,'VariableNames', ...
        {'caseId','quantity','absoluteTolerance','relativeTolerance','maxAbsoluteDifference','linearIndex','passed'});
end
end

function write_json(file,value)
fid = fopen(file,'w'); assert(fid >= 0); cleanup = onCleanup(@() fclose(fid));
fprintf(fid,'%s\n',jsonencode(value,PrettyPrint=true));
end
