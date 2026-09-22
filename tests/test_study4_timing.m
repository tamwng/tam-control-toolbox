function tests = test_study4_timing
%TEST_STUDY4_TIMING Short event-boundary fixtures, not pilot repetitions.
tests = functiontests(localfunctions);
end
function setupOnce(testCase)
testCase.TestData.previousPath = path;
root = fileparts(fileparts(mfilename('fullpath')));
for s = 1:4, addpath(fullfile(root,'studies',sprintf('study%d',s))); end
cfg = study4_settings; cfg.K = 502;
record = study4_record(200,.5,cfg.inputSeed,cfg);
for id = ["A","Aplus","P2"]
    fit = study4_fit(id,record,cfg); testCase.TestData.fits.(id) = fit;
    for scenario = string(cfg.scenarios)
        testCase.TestData.runs.(id).(scenario) = study4_trajectory(id,fit,scenario,cfg);
    end
end
testCase.TestData.cfg = cfg;
end
function teardownOnce(testCase)
path(testCase.TestData.previousPath);
end
function testIdenticalStartsAndFirstAffectedTransition(testCase)
cfg = testCase.TestData.cfg;
for id = ["A","Aplus","P2"]
    fit = testCase.TestData.fits.(id); base = testCase.TestData.runs.(id).no_change;
    for scenario = string(cfg.scenarios)
        r = testCase.TestData.runs.(id).(scenario);
        verifyTrue(testCase,r.completed);
        verifyEqual(testCase,r.initialTheta,fit.theta(:,end));
        verifyEqual(testCase,r.initialCovariance,fit.covariance(:,:,end));
        verifyEqual(testCase,r.theta(:,1),fit.theta(:,end),'AbsTol',2e-15);
        verifyEqual(testCase,r.covariance(:,:,1),fit.covariance(:,:,end));
        verifyFalse(testCase,r.idAttempted(1)); verifyEqual(testCase,r.residualWindowCount(1),0);
        verifyEqual(testCase,r.theta(:,1:501),base.theta(:,1:501));
        verifyEqual(testCase,r.covariance(:,:,1:501),base.covariance(:,:,1:501));
        verifyEqual(testCase,r.x(1:501),base.x(1:501));
        verifyEqual(testCase,r.u(1:502),base.u(1:502));
        verifyEqual(testCase,r.lambda(1:501),base.lambda(1:501));
        [h,rho] = study4_schedule(500,scenario,cfg);
        change = h*base.x(501)^2+rho*sin(2*base.x(501));
        verifyEqual(testCase,r.x(502)-base.x(502),change,'AbsTol',2e-15);
        if scenario ~= "no_change"
            verifyGreaterThan(testCase,norm(r.theta(:,502)-base.theta(:,502)),1e-8);
        end
    end
end
end
function testNoEventResetAndAllCoefficientsUpdated(testCase)
for id = ["A","Aplus","P2"]
    for scenario = ["represented","unrepresented"]
        r = testCase.TestData.runs.(id).(scenario); n = r.nEstimated;
        verifyEqual(testCase,size(r.theta),[n 502]); verifyTrue(testCase,all(r.idAccepted(2:end)));
        verifyEqual(testCase,r.residualWindowCount,[0 1:9 repmat(10,1,492)]);
        for j = [501 502]
            rows = [ones(j-1,1),r.x(1:j-1).',r.u(1:j-1).'];
            if n >= 4, rows = [rows,r.x(1:j-1).'.^2]; end
            if n == 6, rows = [rows,r.x(1:j-1).'.*r.u(1:j-1).',r.u(1:j-1).'.^2]; end
            rows = rows./r.D.'; factors = r.lambda(2:j);
            root = chol(r.initialCovariance\eye(n));
            A = sqrt(prod(factors))*root; b = A*r.initialBeta;
            for k = 1:j-1
                weight = sqrt(prod(factors(k+1:end)));
                A = [A;weight*rows(k,:)]; b = [b;weight*r.x(k+1)]; %#ok<AGROW>
            end
            verifyEqual(testCase,r.beta(:,j),A\b,'AbsTol',1e-9);
            [~,R] = qr(A,0);
            verifyEqual(testCase,r.covariance(:,:,j),R\(R.'\eye(n)),'AbsTol',1e-8);
            energy = sqrt(mean(r.residual(j-9:j).^2))/.03;
            verifyEqual(testCase,r.energy(j),energy,'AbsTol',1e-13);
        end
    end
end
end
function testEvaluatorOnlyCommonGridAndUnavailableSineTargets(testCase)
cfg = testCase.TestData.cfg;
for id = ["A","Aplus","P2"]
    for scenario = string(cfg.scenarios)
        r = testCase.TestData.runs.(id).(scenario); before = r;
        e = study4_evaluate(r,cfg);
        verifyEqual(testCase,r,before); % Value-only snapshots; no live handles.
        [x,u] = ndgrid(linspace(-1,1,21),linspace(-.7,.7,21));
        verifyEqual(testCase,e.x,x(:)); verifyEqual(testCase,e.u,u(:));
        verifyEqual(testCase,e.time,0:50); verifyTrue(testCase,all(e.valid));
        % Grid errors depend on stored model snapshots, not the realized path.
        altered = r; altered.x(:) = 99; altered.y(:) = -99; altered.u(:) = 20;
        other = study4_evaluate(altered,cfg);
        verifyEqual(testCase,e.prediction,other.prediction); verifyEqual(testCase,e.truth,other.truth);
        if scenario == "unrepresented" || (id == "A" && scenario == "represented")
            verifyTrue(testCase,all(isnan(e.exactTarget(:,501:end)),'all'));
            verifyFalse(testCase,any(e.exactTargetAvailable(501:end)));
        elseif id ~= "A"
            verifyEqual(testCase,e.exactTarget(4,:),r.trueH);
        end
    end
end
end
