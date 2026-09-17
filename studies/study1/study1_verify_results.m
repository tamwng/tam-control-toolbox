function study1_verify_results(outputDir,cfg)
%STUDY1_VERIFY_RESULTS Audit saved data without performance-ranking criteria.
% Checks all trajectories and declared trials. Independent regularized batch
% solutions check fitted and online snapshots, using accepted transitions only.
% Relative coefficient/covariance tolerance is 1e-8; timing/plant tolerance
% 1e-12; accepted QP feasibility is checked in the core's 1e-7 coordinates.
campaigns = {'pilot','confirmation'};
count = 0;
expected = 0;
for c = 1:numel(campaigns)
    campaign = campaigns{c};
    saved = load(fullfile(outputDir,'data',['records_' campaign '.mat']),'records');
    records = saved.records;
    settings = cfg.(campaign);
    expected = expected+numel(cfg.modelIds)*(settings.noiseTrials+1);
    check_record(records.initialization,200);
    check_record(records.evaluation,600);
    for trial = 0:settings.noiseTrials
        trainingY = records.initialization.x;
        noise = zeros(1,cfg.K+1);
        if trial > 0
            trainingY = trainingY+records.initialNoise(trial,:);
            noise = records.controlNoise(trial,:);
        end
        for m = 1:numel(cfg.modelIds)
            id = cfg.modelIds{m};
            file = fullfile(outputDir,'data',sprintf('%s_%s_%03d.mat',campaign,id,trial));
            assert(isfile(file),'study1:MissingRun','A required trial is missing: %s.',file);
            saved = load(file,'result');
            r = saved.result;
            n = r.nSteps;
            assert(strcmp(r.id,id) && r.trial==trial && strcmp(r.campaign,campaign));
            assert(n>=0 && n<=cfg.K && r.u(1)==0 && r.x(1)==0);
            assert(~r.completed || (n==cfg.K && all(isfinite(r.x)) && all(abs(r.x)<=5)));
            assert(r.completed || ~isempty(r.terminationReason));
            assert(all(abs(r.y(1:n+1)-r.x(1:n+1)-noise(1:n+1)) < 1e-12 | ...
                (~isfinite(r.y(1:n+1)) & ~isfinite(r.x(1:n+1)))));
            predictedPlant = .03+.65*r.x(1:n)+.45*(1+.35*r.x(1:n)).*r.u(1:n);
            assert(all(abs(r.x(2:n+1)-predictedPlant)<1e-12 | ...
                (~isfinite(r.x(2:n+1)) & ~isfinite(predictedPlant))));
            assert(isequal(r.r,study1_reference(r.time)));
            for j = 1:n
                if ~r.controlAccepted(j)
                    assert(r.u(j+1)==r.u(j),'study1:Fallback','A rejected control changed the input.');
                else
                    assert(abs(r.u(j+1)-r.plannedInput(1,j))<1e-12);
                    assert(abs(r.plannedOutput(1,j)-r.prediction(j))<1e-12);
                    assert(all(r.solverResiduals(:,j)<=1e-7));
                    U = r.plannedInput(:,j).';
                    Y = r.plannedOutput(:,j).';
                    E = r.slack(:,:,j);
                    du = diff([r.u(j),U]);
                    assert(all((abs(U)-1)./(2+abs(U)) <= 1e-7));
                    % Normalize exactly the defining increment inequality terms.
                    prior = [r.u(j),U(1:end-1)];
                    assert(all((abs(du)-.25)./(1.25+abs(U)+abs(prior))<=1e-7));
                    assert(all(E(:)>=-1e-7));
                    violation = [Y;-Y]-1.2-E;
                    assert(all(violation./(2.2+abs(Y)+abs(E))<=1e-7,'all'));
                end
            end
            [model,~,~] = study1_model(id);
            verify_forecasts(r.forecasts,r.fit,records.evaluation,cfg);
            if ~strcmp(id,'K')
                assert(~r.idAttempted(1) && all(r.idAttempted(2:n)));
                assert(all(r.lambda(r.idAccepted)==1));
                assert(~any(r.mappingActivated));
                verify_batch(r,model,records.initialization,trainingY,cfg);
                normalizedRows = zeros(max(0,n-1),numel(r.fit.D));
                for j = 2:n
                    [~,row] = model_regression(model,r.y(j-1),r.y(j),r.u(j-1));
                    normalizedRows(j-1,:) = row./r.fit.D.';
                    first = max(1,j-50);
                    phi = normalizedRows(first:j-1,:);
                    G = phi.'*phi/size(phi,1);
                    assert(r.gramCount(j)==min(j-1,50));
                    assert(norm(r.gram(:,:,j)-G,'fro')<=1e-12*max(1,norm(G,'fro')));
                end
            else
                assert(~any(r.idAttempted) && isempty(r.covariance));
            end
            for j = unique([1,min(2,n),min(50,n),n])
                if j<1, continue; end
                value = forward_map(model,r.y(j),r.u(j),r.theta(:,j));
                assert(abs(value-r.prediction(j))<=1e-12*max(1,abs(value)));
            end
            count = count+1;
        end
    end
end
files = dir(fullfile(outputDir,'data','*.mat'));
assert(numel(files)==expected+numel(campaigns),'study1:UnexpectedRun','Unexpected data-file count.');
audits = dir(fullfile(outputDir,'audits','*.mat'));
assert(numel(audits)==expected,'study1:MissingAudit','Every run requires a measured-initial-state audit.');
fprintf('Study 1 saved-data audit: %d/%d runs checked; timing, pairing, batch, constraints and diagnostics passed.\n',count,expected);
end

function verify_forecasts(forecasts,fit,record,cfg)
assert(isequal(forecasts.anchors,cfg.anchors) && isequal(forecasts.horizons,cfg.horizons));
assert(forecasts.allQueriesValid == (all(forecasts.valid(:)) && all(isfinite(forecasts.oneStepErrors(:)))));
if ~forecasts.allQueriesValid
    assert(~isempty(forecasts.failures),'study1:MissingFailure','Invalid forecasts require explicit failure records.');
end
anchors = cfg.anchors+1;
for j = 1:numel(cfg.fitSteps)
    theta = fit.checkpointTheta(:,j);
    expected = explicit_map(fit.id,theta,record.x(1:end-1),record.u)-record.x(2:end);
    check_close(forecasts.oneStepErrors(:,j).',expected);
    for mode = 1:2
        x = record.x(anchors);
        learned = x; affine = x;
        u0 = record.u(anchors);
        % Numerical central differences independently verify the stored
        % analytical affine forecasts to their expected derivative precision.
        h = 1e-5;
        A = (explicit_map(fit.id,theta,x+h,u0)-explicit_map(fit.id,theta,x-h,u0))/(2*h);
        B = (explicit_map(fit.id,theta,x,u0+h)-explicit_map(fit.id,theta,x,u0-h))/(2*h);
        c = explicit_map(fit.id,theta,x,u0)-A.*x-B.*u0;
        for step = 1:max(cfg.horizons)
            if mode==1, u=u0; else, u=record.u(anchors+step-1); end
            x = .03+.65*x+.45*(1+.35*x).*u;
            learned = explicit_map(fit.id,theta,learned,u);
            affine = c+A.*affine+B.*u;
            ih = find(cfg.horizons==step,1);
            if isempty(ih), continue; end
            em = learned-x; ef = affine-learned; et = affine-x;
            check_close(forecasts.modelError(:,ih,mode,j).',em);
            check_close(forecasts.freezingError(:,ih,mode,j).',ef);
            check_close(forecasts.totalError(:,ih,mode,j).',et);
            check_close(forecasts.crossTerm(:,ih,mode,j).',2*em.*ef);
        end
    end
end
finite = forecasts.valid;
em = forecasts.modelError(finite); ef=forecasts.freezingError(finite); et=forecasts.totalError(finite);
assert(all(abs(et-em-ef)<=1e-11*max(1,max(abs(et)))));
assert(all(abs(et.^2-em.^2-ef.^2-forecasts.crossTerm(finite))<=1e-11*max(1,max(abs(et))^2)));
assert(forecasts.maxFirstStepFreezingError<=1e-11);
if strcmp(fit.id,'A'), assert(forecasts.maxAffineFreezingError<=1e-11); end
end

function y = explicit_map(id,t,x,u)
switch id
    case 'A', y=t(1)+t(2)*x+t(3)*u;
    case {'S','K'}, y=t(1)+t(2)*x+t(3)*(1+.35*x).*u;
    case 'W', y=t(1)+t(2)*x+t(3)*(1-.35*x).*u;
    case 'R', y=t(1)+t(2)*x+t(3)*u+t(4)*x.*u;
    case 'P2', y=t(1)+t(2)*x+t(3)*u+t(4)*x.^2+t(5)*x.*u+t(6)*u.^2;
end
end

function check_close(actual,expected)
mask=isfinite(actual) & isfinite(expected);
assert(isequal(isfinite(actual),isfinite(expected)));
assert(all(abs(actual(mask)-expected(mask))<=1e-8*max(1,max(abs(expected(mask))))));
end

function check_record(record,n)
assert(numel(record.u)==n && numel(record.x)==n+1 && record.x(1)==0 && record.u(1)==0);
assert(all(abs(record.u)<=.5) && all(abs(diff(record.u))<=.25));
truth = .03+.65*record.x(1:n)+.45*(1+.35*record.x(1:n)).*record.u;
assert(max(abs(truth-record.x(2:end)))<1e-12);
end

function verify_batch(r,model,record,y,cfg)
n = numel(r.fit.D);
rootPrior = chol(r.fit.P0\eye(n));
A = rootPrior;
b = rootPrior*(r.fit.D.*r.fit.theta0);
for k = 1:200
    if r.fit.accepted(k)
        [response,Phi] = model_regression(model,y(k),y(k+1),record.u(k));
        A = [A;Phi./r.fit.D.']; b = [b;response]; %#ok<AGROW>
    end
    if ismember(k,cfg.fitSteps)
        assert(norm(A\b-r.fit.beta(:,k+1))<=1e-8*max(1,norm(A\b)));
    end
end
assert(norm(r.beta(:,1)-r.fit.beta(:,end))<1e-12);
assert(norm(r.covariance(:,:,1)-r.fit.covariance(:,:,end),'fro')<1e-12);
queries = unique([2,50,200,r.nSteps]);
for j = 2:r.nSteps
    if r.idAccepted(j)
        [response,Phi] = model_regression(model,r.y(j-1),r.y(j),r.u(j-1));
        A = [A;Phi./r.fit.D.']; b = [b;response]; %#ok<AGROW>
    end
    if ismember(j,queries)
        beta = A\b;
        P = (A.'*A)\eye(n);
        assert(norm(beta-r.beta(:,j))<=1e-8*max(1,norm(beta)));
        assert(norm(P-r.covariance(:,:,j),'fro')<=1e-8*max(1,norm(P,'fro')));
    end
end
end
