function study4_verify_results(output,cfg)
%STUDY4_VERIFY_RESULTS Independent formulas and saved-data causal audits.
% No performance ordering is required. Verification does not rerun control.
saved = load(fullfile(output,'records.mat'),'records'); records = saved.records;
for name = ["initialization","evaluation"]
    r = records.(name);
    assert(r.x(1) == 0 && r.u(1) == 0 && isequal(r.x,r.y));
    close(r.x(2:end),.65*r.x(1:end-1)+.45*r.u);
    assert(all(abs(r.u) <= .5) && all(abs(diff(r.u)) <= .25));
    close(reshape(r.target,5,[]),repmat(r.target(1:5:end),5,1));
end
fits = struct;
for id = string(cfg.modelIds(1:3))
    saved = load(fullfile(output,'fits',sprintf('fit_%s.mat',id)),'fit'); f = saved.fit;
    n = f.nEstimated; r = records.initialization;
    [x,u] = ndgrid(linspace(-1.2,1.2,41),linspace(-1,1,41));
    close(f.D,sqrt(mean(features(id,x,u).^2,1)).');
    close(f.P0,100/n*eye(n)); close(f.theta0,[0;.5;.25;zeros(n-3,1)]);
    A = sqrt(n/100)*eye(n); b = A*(f.D.*f.theta0);
    F = features(id,r.x(1:end-1),r.u)./f.D.';
    assert(all(f.attempted) && numel(f.attempted) == 200);
    for j = 1:200
        close(f.residual(j),r.x(j+1)-F(j,:)*f.beta(:,j)); close(f.lambda(j),1);
        if f.accepted(j)
            A = [A;F(j,:)]; b = [b;r.x(j+1)]; %#ok<AGROW>
        else
            assert(~isempty(f.message{j}));
            close(f.beta(:,j+1),f.beta(:,j)); close(f.covariance(:,:,j+1),f.covariance(:,:,j));
        end
        if ismember(j,cfg.fitSteps), batch(A,b,f.beta(:,j+1),f.covariance(:,:,j+1)); end
    end
    close(f.beta,f.D.*f.theta); fits.(id) = f;
end
count = 0;
for id = string(cfg.modelIds)
    baseline = [];
    for scenario = string(cfg.scenarios)
        file = sprintf('%s_%s.mat',scenario,id);
        saved = load(fullfile(output,'runs',file),'result'); r = saved.result;
        saved = load(fullfile(output,'evaluation',file),'evaluation'); e = saved.evaluation;
        n = r.nSteps; indices = 1:n;
        assert(strcmp(r.id,id) && strcmp(r.scenario,scenario));
        assert(isequal(r.controlSettings,cfg.control) && r.x(1) == 0 && r.u(1) == 0);
        close(r.x,r.y); close(r.r,study1_reference(r.time));
        h = zeros(1,cfg.K); rho = h;
        if scenario == "represented", h(501:end) = .08; end
        if scenario == "unrepresented", rho(501:end) = .08*sqrt(.2/(.5-sin(4)/8)); end
        close(r.trueH,h); close(r.trueRho,rho);
        close(r.x(indices+1),.65*r.x(indices)+.45*r.u(indices)+h(indices).*r.x(indices).^2+rho(indices).*sin(2*r.x(indices)));
        assert(~r.completed || (n == cfg.K && all(isfinite(r.x)) && all(abs(r.x) <= 5)));
        assert(r.completed || ~isempty(r.terminationReason));
        if isempty(baseline), baseline = r;
        else
            last = min([501,n,baseline.nSteps]);
            close(r.x(1:last),baseline.x(1:last));
            if id ~= "K"
                close(r.theta(:,1:last),baseline.theta(:,1:last));
                close(r.covariance(:,:,1:last),baseline.covariance(:,:,1:last));
                close(r.u(1:last+1),baseline.u(1:last+1));
            end
        end
        F = features(id,r.x(indices),r.u(indices));
        close(r.prediction(indices),sum(F.'.*r.theta(:,indices),1));
        if id == "K"
            close(r.theta(:,indices),[zeros(1,n);.65*ones(1,n);.45*ones(1,n);h(indices);rho(indices)]);
            assert(~any(r.idAttempted) && all(isnan(r.gramRank)) && isempty(r.covariance));
        else
            f = fits.(id); close(r.initialTheta,f.theta(:,end));
            close(r.initialCovariance,f.covariance(:,:,end)); close(r.D,f.D);
            close(r.theta(:,1),f.theta(:,end)); close(r.covariance(:,:,1),r.initialCovariance);
            assert(~r.idAttempted(1) && r.residualWindowCount(1) == 0);
            assert(all(r.idAttempted(2:n)) && ~any(r.mappingActivated));
            close(r.beta(:,indices),r.D.*r.theta(:,indices));
            rows = F./r.D.';
            A = chol(r.initialCovariance\eye(r.nEstimated)); b = A*r.initialBeta;
            for j = 2:n
                residual = r.x(j)-rows(j-1,:)*r.beta(:,j-1);
                close(r.residual(j),residual);
                first = max(2,j-9); energy = sqrt(mean(r.residual(first:j).^2))/.03;
                lambda = 1; if energy > 1, lambda = 1/(1+.02*min(energy,10)); end
                close(r.energy(j),energy); close(r.lambda(j),lambda);
                assert(r.residualWindowCount(j) == min(j-1,10));
                if r.idAccepted(j)
                    A = [sqrt(lambda)*A;rows(j-1,:)]; b = [sqrt(lambda)*b;r.x(j)]; %#ok<AGROW>
                else
                    close(r.beta(:,j),r.beta(:,j-1)); close(r.covariance(:,:,j),r.covariance(:,:,j-1));
                end
                if ismember(j,[10,500,501,502,601,1001,n]), batch(A,b,r.beta(:,j),r.covariance(:,:,j)); end
                recent = rows(max(1,j-50):j-1,:); G = recent.'*recent/size(recent,1);
                close(r.gram(:,:,j),G); assert(r.gramCount(j) == size(recent,1));
                s = svd(G); rank = nnz(s > 1e-10*s(1));
                assert(r.gramValid(j) && r.gramRank(j) == rank);
                if rank < r.nEstimated, assert(isinf(r.gramCondition(j)));
                else, close(r.gramCondition(j),s(1)/s(end),1e-6); end
            end
        end
        for j = indices
            theta = r.theta(:,j); x = r.x(j); u = r.u(j);
            a = theta(2); b = theta(3);
            if id == "Aplus", a = a+2*theta(4)*x;
            elseif id == "P2", a = a+2*theta(4)*x+theta(5)*u; b = b+theta(5)*x+2*theta(6)*u;
            elseif id == "K", a = a+2*theta(4)*x+2*theta(5)*cos(2*x); end
            close([r.A(j),r.B(j),r.c(j)],[a,b,r.prediction(j)-a*x-b*u]);
            if r.controlAccepted(j), check_plan(r,j);
            else, close(r.u(j+1),r.u(j)); end
        end
        [x,u] = ndgrid(cfg.gridX,cfg.gridU); close(e.x,x(:)); close(e.u,u(:));
        close(e.sampleIndices,0:10:cfg.K-1);
        G = features(id,e.x,e.u);
        for j = find(e.attempted)
            index = e.sampleIndices(j)+1;
            close(e.prediction(:,j),G*r.theta(:,index));
            truth = .65*e.x+.45*e.u+h(index)*e.x.^2+rho(index)*sin(2*e.x);
            close(e.truth(:,j),truth); close(e.error(:,j),e.prediction(:,j)-truth);
            close(e.rms(j),sqrt(mean(e.error(:,j).^2)));
        end
        if id ~= "K"
            available = rho == 0 & (id ~= "A" | h == 0);
            assert(isequal(e.exactTargetAvailable,available));
            assert(all(isnan(e.exactTarget(:,~available)),'all'));
        end
        count = count+1;
    end
end
assert(count == 12 && numel(dir(fullfile(output,'runs','*.mat'))) == 12);
fprintf('Study 4 saved-data verification: 12 runs, 3 fits; batch, timing, grid, ranks, and QP checks passed.\n');
end
function rows = features(id,x,u)
x = x(:); u = u(:); rows = [ones(size(x)),x,u];
if id == "Aplus", rows = [rows,x.^2];
elseif id == "P2", rows = [rows,x.^2,x.*u,u.^2];
elseif id == "K", rows = [rows,x.^2,sin(2*x)]; end
end
function batch(A,b,beta,P)
close(beta,A\b,1e-8); [~,R] = qr(A,0); close(P,R\(R.'\eye(size(R,2))),1e-8);
end
function check_plan(r,j)
assert(all(isfinite(r.solverResiduals(:,j))) && all(r.solverResiduals(:,j) <= 1e-7));
U = r.plannedInput(:,j).'; Y = r.plannedOutput(:,j).'; E = r.slack(:,:,j);
close(r.u(j+1),U(1)); close(Y(1),r.prediction(j));
value = r.x(j); inputs = [r.u(j),U];
for h = 1:numel(Y)
    value = r.A(j)*value+r.B(j)*inputs(h)+r.c(j); close(Y(h),value);
end
s = r.controlSettings; prior = [r.u(j),U(1:end-1)];
assert(all((abs(U)-s.hu(1))./(1+s.hu(1)+abs(U)) <= 1e-7));
assert(all((abs(U-prior)-s.hdu(1))./(1+s.hdu(1)+abs(U)+abs(prior)) <= 1e-7));
assert(all(E(:) >= -1e-7));
assert(all(([Y;-Y]-s.hy-E)./(1+s.hy+abs(Y)+abs(E)) <= 1e-7,'all'));
end
function close(actual,expected,tolerance)
if nargin < 3, tolerance = 1e-12; end
assert(isequal(size(actual),size(expected)) && isequal(isnan(actual),isnan(expected)) && isequal(isinf(actual),isinf(expected)));
valid = isfinite(expected);
if any(valid(:)), assert(max(abs(actual(valid)-expected(valid))) <= tolerance*max(1,max(abs(expected(valid))))); end
end
