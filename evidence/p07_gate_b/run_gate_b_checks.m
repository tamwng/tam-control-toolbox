function run_gate_b_checks
%RUN_GATE_B_CHECKS Preserve results of the unchanged pre-refactor test entry points.
evidence = fileparts(mfilename('fullpath'));
root = fileparts(fileparts(evidence));
output = fullfile(evidence,'checks');
assert(~isfolder(output) && ~isfile(output),'p07:ExistingOutput','Use a new attempt directory.');
mkdir(output);
diary(fullfile(output,'matlab_diary.txt'));
finishDiary = onCleanup(@() diary('off'));
oldPath = path; restore = onCleanup(@() path(oldPath));
addpath(root,fullfile(root,'src'),fullfile(root,'studies','p06'));
started = datetime('now','TimeZone','UTC'); timer = tic;
state = struct('baselineSHA','0ac937f94fbcc10c64742e9b4a47367e4d929cc1', ...
    'startedUTC',char(started),'status','RUNNING','projectSourceModified',false);
try
    [status,head] = system(sprintf('git -C "%s" rev-parse HEAD',root));
    assert(status == 0 && strcmp(strtrim(head),state.baselineSHA),'p07:BaselineSHA','Source SHA changed.');
    environment = struct('matlab',version,'computer',computer,'toolboxes',ver, ...
        'quadprogPath',which('quadprog'),'matlabPath',path,'temporaryDirectory',tempdir);
    options = optimoptions('quadprog','Algorithm','interior-point-convex', ...
        'Display','off','ConstraintTolerance',1e-8,'OptimalityTolerance',1e-8);
    for name = string(properties(options)).', environment.solverOptions.(name) = options.(name); end
    save(fullfile(output,'environment.mat'),'environment','state');
    verification = run_verification;
    save(fullfile(output,'root_tests.mat'),'verification');
    export_tests(verification,fullfile(output,'root_tests.csv'));
    addpath(fullfile(root,'studies','p06'));
    p06Tests = run_p06_tests(fullfile(output,'p06_tests'));
    save(fullfile(output,'p06_tests.mat'),'p06Tests');
    state.rootTestCount = numel(verification); state.p06TestCount = numel(p06Tests);
    state.status = 'PASSED';
catch exception
    state.status = 'FAILED_OR_BLOCKED'; state.identifier = exception.identifier;
    state.message = exception.message; state.report = getReport(exception,'extended','hyperlinks','off');
    state.elapsedSeconds = toc(timer); state.completedUTC = char(datetime('now','TimeZone','UTC'));
    save(fullfile(output,'status.mat'),'state'); write_json(fullfile(output,'status.json'),state);
    rethrow(exception)
end
state.elapsedSeconds = toc(timer); state.completedUTC = char(datetime('now','TimeZone','UTC'));
save(fullfile(output,'status.mat'),'state'); write_json(fullfile(output,'status.json'),state);
fprintf('Gate B existing checks: %s; source %s.\n',state.status,state.baselineSHA);
end

function export_tests(results,file)
names = string({results.Name}).'; passed = [results.Passed].';
failed = [results.Failed].'; incomplete = [results.Incomplete].'; seconds = [results.Duration].';
writetable(table(names,passed,failed,incomplete,seconds),file);
end

function write_json(file,value)
fid = fopen(file,'w'); assert(fid >= 0); cleanup = onCleanup(@() fclose(fid));
fprintf(fid,'%s\n',jsonencode(value,PrettyPrint=true));
end
