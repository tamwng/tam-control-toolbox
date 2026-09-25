function run_gate_b_remaining
%RUN_GATE_B_REMAINING Unrun representatives after separating execution metadata.
evidence = fileparts(mfilename('fullpath')); root = fileparts(fileparts(evidence));
prior = jsondecode(fileread(fullfile(evidence,'cases','status.json')));
assert(strcmp(prior.identifier,'p07:Settings') && prior.completedCases == 14, ...
    'p07:PriorAttempt','Require the preserved metadata-only stopped attempt.');
output = fullfile(evidence,'remaining_cases');
assert(~isfolder(output) && ~isfile(output),'p07:ExistingOutput','Never overwrite an attempt.');
mkdir(output); diary(fullfile(output,'matlab_diary.txt')); finish = onCleanup(@() diary('off'));
oldPath = path; restore = onCleanup(@() path(oldPath));
addpath(root,fullfile(root,'src'));
for s = 1:6, addpath(fullfile(root,'studies',sprintf('study%d',s))); end
state = struct('baselineSHA','0ac937f94fbcc10c64742e9b4a47367e4d929cc1', ...
    'status','RUNNING','startedUTC',char(datetime('now','TimeZone','UTC')), ...
    'completedCases',0,'priorCompletedCases',14, ...
    'configurationException','Only historical Study 3 execution-description metadata is compared separately.');
timer = tic; exactRows = table;
try
    archive = fullfile(root,'results','study3_pilot_20260918');
    s = load(fullfile(archive,'settings.mat'),'cfg'); cfg = study3_settings;
    historicalExecution = s.cfg.execution;
    savedScientificConfiguration = rmfield(s.cfg,'execution');
    configurationExactlyMatches = isequaln(cfg,savedScientificConfiguration);
    save(fullfile(output,'study3_configuration_comparison.mat'),'cfg','savedScientificConfiguration','historicalExecution','configurationExactlyMatches');
    assert(configurationExactlyMatches,'p07:Settings','Study 3 scientific configuration differs.');
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
    state.status = 'PASSED'; state.exactComparisonCount = height(exactRows);
catch exception
    state.status = 'FAILED_OR_BLOCKED'; state.identifier = exception.identifier;
    state.message = exception.message; state.report = getReport(exception,'extended','hyperlinks','off');
    state.elapsedSeconds = toc(timer); state.completedUTC = char(datetime('now','TimeZone','UTC'));
    save(fullfile(output,'status.mat'),'state'); write_json(fullfile(output,'status.json'),state);
    rethrow(exception)
end
state.elapsedSeconds = toc(timer); state.completedUTC = char(datetime('now','TimeZone','UTC'));
save(fullfile(output,'status.mat'),'state'); write_json(fullfile(output,'status.json'),state);
fprintf('Gate B remaining cases: %s, %d completed cases; earlier 14 cases not repeated.\n',state.status,state.completedCases);
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
