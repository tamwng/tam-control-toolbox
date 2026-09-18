function study3_verify_results(output,cfg)
%STUDY3_VERIFY_RESULTS Independent saved-data checks for the complete pilot.
% Explicit plant/dictionary formulas and weighted batch QR verify causality
% and numerical obligations without imposing a scientific ranking. Relative
% batch tolerance is 1e-8; data/timing tolerance is 1e-12; QP residuals 1e-7.
saved = load(fullfile(output,'records.mat'),'records'); records = saved.records;
check_record(records.initialization,200,.5,cfg.inputSeed);
check_record(records.evaluation,600,.5,cfg.evaluationSeed);
check_streams(records,cfg);
count = 0; fitsChecked = 0;
for trial = 0:cfg.noiseTrials
    models = {'A','S'}; cases = cfg.caseIds; scenarios = cfg.scenarios;
    measurementNoise = zeros(1,cfg.K+1); processNoise = zeros(1,cfg.K);
    if trial > 0
        models = {'S'}; cases = cfg.noisyCases; scenarios = {'abrupt'};
        measurementNoise = records.controlMeasurementNoise(trial,:);
        processNoise = records.controlProcessNoise(trial,:);
    end
    fits = struct;
    for m = 1:numel(models)
        id = models{m};
        saved = load(fullfile(output,'fits',sprintf('fit_%s_%03d.mat',id,trial)), ...
            'fit','training');
        fit = saved.fit; training = saved.training;
        check_training(training,records,trial);
        check_fit(fit,training,cfg);
        forecasts = load(fullfile(output,'evaluation', ...
            sprintf('evaluation_%s_%03d.mat',id,trial)),'forecasts');
        check_forecasts(forecasts.forecasts,fit,records.evaluation,cfg);
        fits.(id) = fit; fitsChecked = fitsChecked+1;
    end
    for s = 1:numel(scenarios)
        scenario = scenarios{s};
        for m = 1:numel(cases)
            id = cases{m}; spec = study3_case(id);
            modelId = spec.modelId; if strcmp(modelId,'K'), modelId = 'S'; end
            saved = load(fullfile(output,'runs', ...
                sprintf('%s_%s_%03d.mat',scenario,id,trial)),'result');
            r = saved.result;
            assert(strcmp(r.id,id) && strcmp(r.scenario,scenario) && r.trial == trial);
            assert(strcmp(r.modelId,spec.modelId) && strcmp(r.mode,spec.mode));
            assert(isequal(r.forgetting,spec.forgetting) && isequal(r.controlSettings,cfg.control));
            check_run(r,fits.(modelId),measurementNoise,processNoise,cfg);
            count = count+1;
        end
    end
end
expected = numel(cfg.caseIds)*numel(cfg.scenarios)+numel(cfg.noisyCases)*cfg.noiseTrials;
assert(count == expected && numel(dir(fullfile(output,'runs','*.mat'))) == expected);
assert(fitsChecked == cfg.noiseTrials+2);
assert(numel(dir(fullfile(output,'fits','*.mat'))) == fitsChecked);
assert(numel(dir(fullfile(output,'evaluation','*.mat'))) == fitsChecked);
% Both deterministic plants have an identical past through measurement x500.
for id = cfg.caseIds
    a = load(fullfile(output,'runs',['abrupt_' id{1} '_000.mat']),'result');
    d = load(fullfile(output,'runs',['drift_' id{1} '_000.mat']),'result');
    last = min([501,a.result.nSteps,d.result.nSteps]);
    close(a.result.x(1:last),d.result.x(1:last));
    if ~strcmp(id{1},'K')
        close(a.result.theta(:,1:last),d.result.theta(:,1:last));
        close(a.result.beta(:,1:last),d.result.beta(:,1:last));
        close(a.result.covariance(:,:,1:last),d.result.covariance(:,:,1:last));
        close(a.result.u(1:last+1),d.result.u(1:last+1));
    end
end
fprintf(['Study 3 saved-data verification: %d/%d runs, %d fits; timing, pairing, ' ...
    'weighted batch, VRF, frozen controls, ranks, and QP checks passed.\n'],count,expected,fitsChecked);
end

function check_streams(records,cfg)
fields = {'initialMeasurementNoise','initialProcessNoise','controlMeasurementNoise','controlProcessNoise'};
bases = [cfg.initialMeasurementBase,cfg.initialProcessBase,cfg.controlMeasurementBase,cfg.controlProcessBase];
counts = [201,200,cfg.K+1,cfg.K];
scales = [cfg.measurementSigma,cfg.processSigma,cfg.measurementSigma,cfg.processSigma];
assert(numel(unique([cfg.inputSeed,cfg.evaluationSeed,bases,cfg.bootstrapSeed])) == 7);
for f = 1:numel(fields)
    data = records.(fields{f}); assert(isequal(size(data),[cfg.noiseTrials,counts(f)]));
    for trial = 1:cfg.noiseTrials
        stream = RandStream('mt19937ar','Seed',bases(f)+trial);
        assert(isequal(data(trial,:),scales(f)*randn(stream,1,counts(f))));
    end
end
end

function check_record(r,count,L,seed)
assert(numel(r.u) == count && numel(r.x) == count+1 && isequal(r.x,r.y));
assert(r.L == L && r.seed == seed && r.x(1) == 0 && r.u(1) == 0);
assert(all(abs(r.u) <= L+1e-14) && all(abs(diff(r.u)) <= .25+1e-14));
assert(all(ismember(r.target,L*[-1,-.5,0,.5,1])));
close(reshape(r.target,5,[]),repmat(r.target(1:5:end),5,1));
close(r.x(2:end),plant(r.x(1:end-1),r.u,.45));
end

function check_training(r,records,trial)
assert(isequal(r.u,records.initialization.u));
assert(isequal(r.target,records.initialization.target));
assert(r.x(1) == 0);
v = zeros(1,201); w = zeros(1,200);
if trial > 0
    v = records.initialMeasurementNoise(trial,:); w = records.initialProcessNoise(trial,:);
end
assert(isequal(r.measurementNoise,v) && isequal(r.processNoise,w));
close(r.y,r.x+v); close(r.x(2:end),plant(r.x(1:end-1),r.u,.45)+w);
end

function check_fit(fit,r,cfg)
[x,u] = ndgrid(linspace(-1.2,1.2,41),linspace(-1,1,41));
grid = features(fit.id,x(:),u(:));
close(fit.D,sqrt(mean(grid.^2,1)).'); close(fit.P0,(100/3)*eye(3));
close(fit.theta0,[0;.5;.25]); close(fit.beta,fit.D.*fit.theta);
rows = features(fit.id,r.y(1:end-1),r.u)./fit.D.';
A = sqrt(3/100)*eye(3); b = A*(fit.D.*fit.theta0);
for j = 1:200
    assert(fit.attempted(j));
    if fit.accepted(j)
        assert(fit.lambda(j) == 1);
        close(fit.residual(j),r.y(j+1)-rows(j,:)*fit.beta(:,j));
        A = [A;rows(j,:)]; b = [b;r.y(j+1)]; %#ok<AGROW>
    else
        assert(~isempty(fit.message{j}));
        close(fit.beta(:,j+1),fit.beta(:,j));
        close(fit.covariance(:,:,j+1),fit.covariance(:,:,j));
    end
    if ismember(j,cfg.fitSteps), batch(A,b,fit.beta(:,j+1),fit.covariance(:,:,j+1)); end
end
close(fit.checkpointTheta,fit.theta(:,cfg.fitSteps+1));
close(fit.checkpointCovariance,fit.covariance(:,:,cfg.fitSteps+1));
end

function check_run(r,fit,v,w,cfg)
n = r.nSteps;
assert(n >= 0 && n <= cfg.K && r.x(1) == 0 && r.u(1) == 0 && r.Ts == .1);
assert(~r.completed || (n == cfg.K && all(isfinite(r.x)) && all(abs(r.x) <= 5)));
assert(r.completed || ~isempty(r.terminationReason));
assert(isequal(r.measurementNoise,v) && isequal(r.processNoise,w));
close(r.time,(0:cfg.K)*.1); close(r.r,study1_reference(r.time));
gain = .45-.15*((0:cfg.K-1) >= 500);
if strcmp(r.scenario,'drift'), gain = .45-.15*min(1,max(0,((0:cfg.K-1)-500)/400)); end
close(r.trueGain,gain);
close(r.y(1:n+1),r.x(1:n+1)+v(1:n+1));
close(r.x(2:n+1),plant(r.x(1:n),r.u(1:n),gain(1:n))+w(1:n));
close(r.D,fit.D); assert(~any(r.mappingActivated));
adaptive = strcmp(r.mode,'adaptive'); known = strcmp(r.mode,'known');
theta0 = fit.theta(:,end); P0 = fit.covariance(:,:,end);
if strcmp(r.mode,'prior'), theta0 = fit.theta0; P0 = fit.P0; end
if known, theta0 = [.03;.65;.45]; P0 = zeros(0); end
close(r.initialTheta,theta0); close(r.initialBeta,fit.D.*theta0); close(r.initialCovariance,P0);
if known
    assert(isempty(r.covariance) && isempty(r.gram) && r.nEstimated == 0);
    assert(~any(r.gramValid) && all(isnan(r.gramRank)) && all(isnan(r.gramCondition)));
else
    assert(r.nEstimated == 3);
    close(r.theta(:,1),theta0); close(r.beta(:,1),fit.D.*theta0);
    close(r.covariance(:,:,1),P0);
    online = features(r.modelId,r.y(1:max(0,n-1)),r.u(1:max(0,n-1)))./r.D.';
end
if adaptive
    assert(~r.idAttempted(1) && all(r.idAttempted(2:n)) && isnan(r.lambda(1)));
    A = chol(P0\eye(size(P0))); b = A*r.initialBeta;
else
    assert(~any(r.idAttempted) && ~any(r.idAccepted) && all(isnan(r.lambda)));
end
residuals = zeros(1,0);
for j = 1:n
    if known
        close(r.theta(:,j),[.03;.65;gain(j)]);
    elseif ~adaptive
        close(r.theta(:,j),theta0); close(r.beta(:,j),r.initialBeta);
        close(r.covariance(:,:,j),P0);
    elseif j > 1
        residual = r.y(j)-online(j-1,:)*r.beta(:,j-1);
        if isfinite(residual)
            close(r.residual(j),residual);
            residuals = [residuals,residual]; %#ok<AGROW>
            [lambda,energy,windowCount] = forgetting(r.forgetting,residuals);
            close(r.lambda(j),lambda); close(r.energy(j),energy);
            assert(r.residualWindowCount(j) == windowCount);
        end
        if r.idAccepted(j)
            A = [sqrt(r.lambda(j))*A;online(j-1,:)];
            b = [sqrt(r.lambda(j))*b;r.y(j)];
        else
            assert(isequal(r.beta(:,j),r.beta(:,j-1)));
            assert(isequal(r.covariance(:,:,j),r.covariance(:,:,j-1)));
            assert(any([r.events.index] == j-1 & strcmp({r.events.stage},'identification')));
        end
        if ismember(j,[2,50,499,500,501,502,900,901,n])
            batch(A,b,r.beta(:,j),r.covariance(:,:,j));
        end
    end
    close(r.beta(:,j),r.D.*r.theta(:,j));
    if ~known && j > 1
        first = max(1,j-50); window = online(first:j-1,:);
        G = window.'*window/size(window,1);
        close(r.gram(:,:,j),G); assert(r.gramCount(j) == min(50,j-1));
        singular = svd(G); rank = nnz(singular > 1e-10*singular(1));
        condition = Inf; if rank == size(G,1), condition = singular(1)/singular(end); end
        assert(r.gramValid(j) && r.gramRank(j) == rank);
        close(r.gramCondition(j),condition);
    end
    value = features(r.modelId,r.y(j),r.u(j))*r.theta(:,j);
    close(r.prediction(j),value); close(r.A(j)*r.y(j)+r.B(j)*r.u(j)+r.c(j),value);
    check_control(r,j);
end
end

function [lambda,energy,count] = forgetting(rule,residuals)
energy = NaN; count = 1; lambda = 1;
if strcmp(rule.mode,'fixed')
    lambda = .99;
elseif strcmp(rule.mode,'variable')
    count = min(10,numel(residuals));
    energy = norm(residuals(end-count+1:end))/sqrt(count)/.03;
    if energy > 1, lambda = 1/(1+.02*min(energy,10)); end
end
end

function check_control(r,j)
if ~r.controlAccepted(j)
    assert(r.u(j+1) == r.u(j));
    assert(any([r.events.index] == j-1 & strcmp({r.events.stage},'control')));
    return
end
assert(all(isfinite(r.solverResiduals(:,j))) && all(r.solverResiduals(:,j) <= 1e-7));
U = r.plannedInput(:,j).'; Y = r.plannedOutput(:,j).'; E = r.slack(:,:,j);
close(r.u(j+1),U(1)); close(Y(1),r.prediction(j));
expected = r.y(j); allInputs = [r.u(j),U];
for h = 1:numel(Y)
    expected = r.A(j)*expected+r.B(j)*allInputs(h)+r.c(j);
    close(Y(h),expected);
end
s = r.controlSettings; prior = [r.u(j),U(1:end-1)];
assert(all((abs(U)-s.hu(1))./(1+s.hu(1)+abs(U)) <= 1e-7));
assert(all((abs(U-prior)-s.hdu(1))./(1+s.hdu(1)+abs(U)+abs(prior)) <= 1e-7));
assert(all(E(:) >= -1e-7));
violation = [Y;-Y]-s.hy-E;
assert(all(violation./(1+s.hy+abs(Y)+abs(E)) <= 1e-7,'all'));
end

function check_forecasts(f,fit,r,cfg)
assert(isequal(f.anchors,cfg.anchors) && isequal(f.horizons,cfg.horizons));
assert(f.allQueriesValid == (all(f.valid(:)) && all(isfinite(f.oneStepErrors(:)))));
if ~f.allQueriesValid, assert(~isempty(f.failures)); end
for s = 1:numel(cfg.fitSteps)
    theta = fit.checkpointTheta(:,s);
    close(f.oneStepErrors(:,s),features(fit.id,r.x(1:end-1),r.u)*theta-r.x(2:end).');
    for mode = 1:2
        indices = cfg.anchors+1; truth = r.x(indices).';
        learned = truth; affine = truth; u0 = r.u(indices).'; h = 1e-5;
        A = (features(fit.id,truth+h,u0)*theta-features(fit.id,truth-h,u0)*theta)/(2*h);
        B = (features(fit.id,truth,u0+h)*theta-features(fit.id,truth,u0-h)*theta)/(2*h);
        c = features(fit.id,truth,u0)*theta-A.*truth-B.*u0;
        for step = 1:max(cfg.horizons)
            u = u0; if mode == 2, u = r.u(indices+step-1).'; end
            truth = plant(truth,u,.45); learned = features(fit.id,learned,u)*theta;
            affine = A.*affine+B.*u+c;
            ih = find(cfg.horizons == step,1); if isempty(ih), continue; end
            em = learned-truth; ef = affine-learned; et = affine-truth;
            close(f.modelError(:,ih,mode,s),em,1e-8);
            close(f.freezingError(:,ih,mode,s),ef,1e-8);
            close(f.totalError(:,ih,mode,s),et,1e-8);
            close(f.crossTerm(:,ih,mode,s),2*em.*ef,1e-8);
        end
    end
end
assert(f.maxFirstStepFreezingError <= 1e-11);
if strcmp(fit.id,'A'), assert(f.maxAffineFreezingError <= 1e-11); end
end

function batch(A,b,beta,P)
close(beta,A\b,1e-8);
[~,R] = qr(A,0); close(P,R\(R.'\eye(size(R,2))),1e-8);
end

function close(actual,expected,tolerance)
if nargin < 3, tolerance = 1e-12; end
assert(isequal(size(actual),size(expected)) && isequal(isnan(actual),isnan(expected)) && ...
    isequal(isinf(actual),isinf(expected)));
nonfinite = ~isfinite(expected);
assert(isequaln(actual(nonfinite),expected(nonfinite)));
valid = isfinite(expected);
if any(valid(:))
    assert(max(abs(actual(valid)-expected(valid))) <= tolerance*max(1,max(abs(expected(valid)))));
end
end

function values = plant(x,u,b)
values = .03+.65*x+b.*(1+.35*x).*u;
end

function rows = features(id,x,u)
x = x(:); u = u(:);
if strcmp(id,'A'), rows = [ones(size(x)),x,u];
else, rows = [ones(size(x)),x,(1+.35*x).*u]; end
end
