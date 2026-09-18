function study2_verify_results(output,cfg)
%STUDY2_VERIFY_RESULTS Independent mathematical checks on saved pilot data.
% Explicit dictionaries, regularized batch solutions, and plant recurrences
% check implementation obligations, never a scientific performance ordering.
saved = load(fullfile(output,'records.mat'),'initialization','evaluation');
training = saved.initialization;
evaluation = saved.evaluation;
check_record(training,200,1.10,cfg.inputSeed);
assert(numel(evaluation) == 3);
for e = 1:3
    check_record(evaluation(e),600,cfg.evaluationRanges(e),cfg.evaluationSeeds(e));
end
count = 0;
for m = 1:numel(cfg.modelIds)
    id = cfg.modelIds{m};
    saved = load(fullfile(output,'fits',[id '.mat']),'fit'); fit = saved.fit;
    saved = load(fullfile(output,'evaluation',[id '.mat']),'evaluations');
    forecasts = saved.evaluations;
    assert(numel(forecasts) == 3);
    [gridX,gridU] = ndgrid(linspace(-1.2,1.2,41),linspace(-1.2,1.2,41));
    grid = features(id,gridX(:),gridU(:));
    close(fit.D,sqrt(mean(grid.^2,1)).');
    if ~strcmp(id,'K')
        check_fit(fit,training,cfg);
    else
        assert(fit.nEstimated == 0 && ~any(fit.attempted) && isempty(fit.covariance));
        close(fit.theta,repmat([.03;.65;.40],1,201));
    end
    for e = 1:3
        assert(forecasts(e).evaluationRange == cfg.evaluationRanges(e));
        check_forecasts(forecasts(e),fit,evaluation(e),cfg);
    end
    for a = 1:numel(cfg.amplitudes)
        saved = load(fullfile(output,'runs',sprintf('amplitude_%02d_%s.mat',a,id)),'result');
        r = saved.result;
        assert(strcmp(r.kind,'amplitude') && r.amplitude == cfg.amplitudes(a));
        assert(numel(r.time) == 801 && r.x(1) == 0 && r.u(1) == 0);
        close(r.r,.08+r.amplitude*sin(2*pi*.05*r.time));
        assert(isequal(r.controlSettings,cfg.control));
        check_run(r,fit,training);
        count = count+1;
    end
    if ismember(id,cfg.auditIds)
        saved = load(fullfile(output,'runs',['constraint_' id '.mat']),'result');
        r = saved.result;
        assert(strcmp(r.kind,'constraintAudit') && isnan(r.amplitude));
        assert(numel(r.time) == 101 && r.x(1) == 1.4 && r.u(1) == 0);
        assert(all(r.r == .6) && all(r.controlSettings.hy == .85));
        expected = cfg.control; expected.hy = [.85;.85];
        assert(isequal(r.controlSettings,expected));
        check_run(r,fit,training);
        close(r.x(2),.94);
        close(r.x(1)-.85,.55); close(r.x(2)-.85,.09);
        if strcmp(id,'K') && r.controlAccepted(1)
            close(r.plannedOutput(1,1),.94);
            assert(r.slack(1,1,1) >= .09-1e-7);
        end
        count = count+1;
    end
end
assert(numel(dir(fullfile(output,'runs','*.mat'))) == 22 && count == 22);
assert(numel(dir(fullfile(output,'fits','*.mat'))) == 6);
assert(numel(dir(fullfile(output,'evaluation','*.mat'))) == 6);
fprintf('Study 2 saved-data verification: 22 runs, 6 fits, 18 evaluation/model pairs passed.\n');
end

function check_record(r,count,L,seed)
assert(numel(r.u) == count && numel(r.x) == count+1 && isequal(r.x,r.y));
assert(r.L == L && r.seed == seed && r.x(1) == 0 && r.u(1) == 0);
assert(all(abs(r.u) <= L+1e-14) && all(abs(diff(r.u)) <= .25+1e-14));
assert(all(ismember(r.target,L*[-1,-.5,0,.5,1])));
close(reshape(r.target,5,[]),repmat(r.target(1:5:end),5,1));
close(r.x(2:end),.03+.65*r.x(1:end-1)+.40*sin(r.u));
end

function check_fit(fit,r,cfg)
n = fit.nEstimated;
close(fit.P0,(100/n)*eye(n));
A = sqrt(n/100)*eye(n); b = A*(fit.D.*fit.theta0);
Phi = features(fit.id,r.y(1:end-1).',r.u.')./fit.D.';
for j = 1:200
    assert(fit.attempted(j));
    if fit.accepted(j)
        assert(fit.lambda(j) == 1);
        A = [A;Phi(j,:)]; b = [b;r.y(j+1)]; %#ok<AGROW>
    else
        assert(~isempty(fit.message{j}));
        assert(isequal(fit.beta(:,j+1),fit.beta(:,j)));
        assert(isequal(fit.covariance(:,:,j+1),fit.covariance(:,:,j)));
    end
    if ismember(j,cfg.fitSteps)
        batch(A,b,fit.beta(:,j+1),fit.covariance(:,:,j+1));
    end
end
close(fit.checkpointTheta,fit.theta(:,cfg.fitSteps+1));
close(fit.checkpointCovariance,fit.covariance(:,:,cfg.fitSteps+1));
end

function check_run(r,fit,training)
n = r.nSteps; K = numel(r.time)-1;
assert(strcmp(r.id,fit.id) && n >= 0 && n <= K);
assert(~r.completed || (n == K && all(isfinite(r.x)) && all(abs(r.x) <= 5)));
assert(r.completed || ~isempty(r.terminationReason));
close(r.time,(0:K)*.1);
close(r.y(1:n+1),r.x(1:n+1));
close(r.x(2:n+1),.03+.65*r.x(1:n)+.40*sin(r.u(1:n)));
close(r.initialTheta,fit.theta(:,end)); close(r.initialBeta,fit.beta(:,end));
close(r.initialCovariance,fit.covariance(:,:,end));
assert(~any(r.mappingActivated));
known = strcmp(r.id,'K');
if known
    assert(~any(r.idAttempted) && isempty(r.covariance));
else
    assert(~r.idAttempted(1) && all(r.idAttempted(2:n)));
    close(r.theta(:,1),fit.theta(:,end));
    close(r.beta(:,1),fit.beta(:,end)); close(r.covariance(:,:,1),fit.covariance(:,:,end));
    p = fit.nEstimated;
    A = sqrt(p/100)*eye(p); b = A*(fit.D.*fit.theta0);
    rows = features(r.id,training.y(1:end-1).',training.u.')./fit.D.';
    A = [A;rows(fit.accepted,:)];
    response = training.y(2:end).'; b = [b;response(fit.accepted)];
    online = features(r.id,r.y(1:max(0,n-1)).',r.u(1:max(0,n-1)).')./fit.D.';
end
for j = 1:n
    if ~known && j > 1
        if r.idAccepted(j)
            assert(r.lambda(j) == 1);
            A = [A;online(j-1,:)]; b = [b;r.y(j)]; %#ok<AGROW>
        else
            assert(isequal(r.beta(:,j),r.beta(:,j-1)));
            assert(isequal(r.covariance(:,:,j),r.covariance(:,:,j-1)));
        end
        first = max(1,j-50); window = online(first:j-1,:);
        close(r.gram(:,:,j),window.'*window/size(window,1));
        assert(r.gramCount(j) == min(50,j-1));
        if ismember(j,[2,50,200,n]), batch(A,b,r.beta(:,j),r.covariance(:,:,j)); end
    end
    value = map(r.id,r.theta(:,j),r.y(j),r.u(j));
    close(r.prediction(j),value);
    close(r.A(j)*r.y(j)+r.B(j)*r.u(j)+r.c(j),value);
    if r.controlAccepted(j)
        assert(all(isfinite(r.solverResiduals(:,j))) && all(r.solverResiduals(:,j) <= 1e-7));
        U = r.plannedInput(:,j).'; Y = r.plannedOutput(:,j).'; E = r.slack(:,:,j);
        close(r.u(j+1),U(1)); close(Y(1),value);
        s = r.controlSettings;
        prior = [r.u(j),U(1:end-1)];
        assert(all((abs(U)-s.hu(1))./(1+s.hu(1)+abs(U)) <= 1e-7));
        assert(all((abs(U-prior)-s.hdu(1))./(1+s.hdu(1)+abs(U)+abs(prior)) <= 1e-7));
        assert(all(E(:) >= -1e-7));
        violation = [Y;-Y]-s.hy-E;
        assert(all(violation./(1+s.hy+abs(Y)+abs(E)) <= 1e-7,'all'));
    else
        assert(r.u(j+1) == r.u(j));
        assert(any([r.events.index] == j-1 & strcmp({r.events.stage},'control')));
    end
end
end

function check_forecasts(f,fit,r,cfg)
assert(isequal(f.anchors,cfg.anchors) && isequal(f.horizons,cfg.horizons));
assert(f.allQueriesValid == (all(f.valid(:)) && all(isfinite(f.oneStepErrors(:)))));
if ~f.allQueriesValid, assert(~isempty(f.failures)); end
for s = 1:numel(cfg.fitSteps)
    theta = fit.checkpointTheta(:,s);
    close(f.oneStepErrors(:,s),map(fit.id,theta,r.x(1:end-1).',r.u.')-r.x(2:end).');
    for mode = 1:2
        j = cfg.anchors+1;
        truth = r.x(j).'; learned = truth; affine = truth; u0 = r.u(j).';
        h = 1e-5;
        A = (map(fit.id,theta,truth+h,u0)-map(fit.id,theta,truth-h,u0))/(2*h);
        B = (map(fit.id,theta,truth,u0+h)-map(fit.id,theta,truth,u0-h))/(2*h);
        c = map(fit.id,theta,truth,u0)-A.*truth-B.*u0;
        for step = 1:max(cfg.horizons)
            u = u0; if mode == 2, u = r.u(j+step-1).'; end
            truth = .03+.65*truth+.40*sin(u);
            learned = map(fit.id,theta,learned,u);
            affine = c+A.*affine+B.*u;
            ih = find(cfg.horizons == step,1); if isempty(ih), continue; end
            em = learned-truth; ef = affine-learned; et = affine-truth;
            close(f.modelError(:,ih,mode,s),em);
            close(f.freezingError(:,ih,mode,s),ef);
            close(f.totalError(:,ih,mode,s),et);
            close(f.crossTerm(:,ih,mode,s),2*em.*ef);
        end
    end
end
v = f.valid; em = f.modelError(v); ef = f.freezingError(v); et = f.totalError(v);
close(et,em+ef); close(et.^2,em.^2+ef.^2+f.crossTerm(v));
if any(v(:))
    assert(f.maxFirstStepFreezingError <= 1e-11);
    if strcmp(fit.id,'A'), assert(f.maxAffineFreezingError <= 1e-11); end
end
end

function batch(A,b,beta,P)
close(beta,A\b);
[~,R] = qr(A,0);
close(P,R\(R.'\eye(size(R,2))));
end

function close(actual,expected)
assert(isequal(size(actual),size(expected)) && isequal(isfinite(actual),isfinite(expected)));
valid = isfinite(expected);
if any(valid(:))
    assert(max(abs(actual(valid)-expected(valid))) <= 1e-8*max(1,max(abs(expected(valid)))));
end
end

function value = map(id,theta,x,u)
value = features(id,x,u)*theta;
end

function Phi = features(id,x,u)
% Independent explicit dictionary for verification, not controller use.
x = x(:); u = u(:); one = ones(size(x));
switch id
    case 'A', Phi = [one,x,u];
    case {'E','K'}, Phi = [one,x,sin(u)];
    case 'O3', Phi = [one,x,u,u.^3];
    case 'O5', Phi = [one,x,u,u.^3,u.^5];
    case 'P3', Phi = [one,x,u,x.^2,x.*u,u.^2,x.^3,x.^2.*u,x.*u.^2,u.^3];
end
end
