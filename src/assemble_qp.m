function qp = assemble_qp(A, B, c, C, xi, uCommitted, reference, settings)
%ASSEMBLE_QP Condense the frozen affine MPC problem, Eqs. (36)-(39).
% reference is p-by-N; Q is p-by-p or p-by-p-by-N (terminal included).
% R weights increments. Hu/hu, Hdu/hdu and optional Hy/hy specify bounds.
% Seps weights one nonnegative slack per output-inequality row and step.
% z = [u_1; ...; u_{N-1}; epsilon_1; ...; epsilon_N]. The first
% predicted transition uses uCommitted, which is never a decision variable.

validateattributes(A, {'double'}, {'2d','real','finite','square','nonempty'});
n = size(A,1);
validateattributes(B, {'double'}, {'2d','real','finite','nrows',n,'nonempty'});
m = size(B,2);
validateattributes(C, {'double'}, {'2d','real','finite','ncols',n,'nonempty'});
p = size(C,1);
validateattributes(c, {'double'}, {'real','finite','size',[n,1]});
validateattributes(xi, {'double'}, {'real','finite','size',[n,1]});
validateattributes(uCommitted, {'double'}, {'real','finite','size',[m,1]});
validateattributes(reference, {'double'}, {'2d','real','finite','nrows',p});
N = size(reference,2);
assert(N >= 2, 'ejc:InvalidHorizon', 'The prediction horizon must be at least two.');
assert(isstruct(settings) && isscalar(settings), 'ejc:InvalidSettings', ...
    'Settings must be a scalar structure.');
Q = settings.Q;
if isequal(size(Q), [p,p])
    Q = repmat(Q,1,1,N);
end
validateattributes(Q, {'double'}, {'real','finite','size',[p,p,N]});
for i = 1:N
    check_weight(Q(:,:,i), p, false, 'Q');
end
check_weight(settings.R, m, true, 'R');
[Hu,hu] = inequalities(settings, 'Hu', 'hu', m);
[Hdu,hdu] = inequalities(settings, 'Hdu', 'hdu', m);
[Hy,hy] = inequalities(settings, 'Hy', 'hy', p);
nc = size(Hy,1);
% A previously accepted QP input may have roundoff at an active bound.
% Use the same normalized feasibility threshold as SOLVE_MPC; do not
% project or otherwise change the already committed input.
inputResidual = (Hu*uCommitted-hu)./(1+abs(hu)+abs(Hu)*abs(uCommitted));
assert(all(inputResidual <= 1e-7), 'ejc:CommittedInputBounds', ...
    'The committed input must satisfy the input bounds.');
if nc > 0
    check_weight(settings.Seps, nc, true, 'Seps');
    Sbar = kron(eye(N),settings.Seps);
else
    Sbar = zeros(0);
end

nU = m*(N-1);
Y0 = zeros(p*N,1);
Yu = zeros(p*N,nU);
x0 = xi;
Xu = zeros(n,nU);
for i = 1:N
    x0 = c + A*x0;
    Xu = A*Xu;
    if i == 1
        x0 = x0 + B*uCommitted;
    else
        cols = (i-2)*m+(1:m);
        Xu(:,cols) = Xu(:,cols) + B;
    end
    rows = (i-1)*p+(1:p);
    Y0(rows) = C*x0;
    Yu(rows,:) = C*Xu;
end

% D*U+d contains u_1-u_0, u_2-u_1, ..., u_{N-1}-u_{N-2}.
D = eye(nU);
for i = 2:N-1
    rows = (i-1)*m+(1:m);
    D(rows,rows-m) = -eye(m);
end
d = zeros(nU,1);
d(1:m) = -uCommitted;
Qbar = zeros(p*N);
for i = 1:N
    rows = (i-1)*p+(1:p);
    Qbar(rows,rows) = Q(:,:,i);
end
Rbar = kron(eye(N-1),settings.R);
error0 = Y0-reference(:);
Huu = Yu'*Qbar*Yu + D'*Rbar*D;
H = blkdiag(Huu,Sbar);
% Symmetrization removes multiplication roundoff, without regularization.
H = (H+H')/2;
f = [Yu'*Qbar*error0 + D'*Rbar*d; zeros(nc*N,1)];

Au = kron(eye(N-1),Hu);
Adu = kron(eye(N-1),Hdu);
Ay = kron(eye(N),Hy);
Aineq = [Au, zeros(size(Au,1),nc*N); ...
    Adu*D, zeros(size(Adu,1),nc*N); ...
    Ay*Yu, -eye(nc*N)];
bineq = [repmat(hu,N-1,1); repmat(hdu,N-1,1)-Adu*d; ...
    repmat(hy,N,1)-Ay*Y0];

qp = struct('H',H,'f',f,'Aineq',Aineq,'bineq',bineq, ...
    'lb',[-inf(nU,1);zeros(nc*N,1)],'ub',inf(nU+nc*N,1), ...
    'constant',0.5*(error0'*Qbar*error0+d'*Rbar*d), ...
    'Y0',Y0,'Yu',Yu,'D',D,'d',d,'nU',nU,'N',N, ...
    'p',p,'m',m,'nc',nc,'uCommitted',uCommitted);
assert(all(isfinite(H(:))) && all(isfinite(f)) && ...
    all(isfinite(Aineq(:))) && all(isfinite(bineq)) && ...
    isfinite(qp.constant), 'ejc:NonfiniteQP', ...
    'The frozen prediction produced nonfinite QP data.');
end

function [H,h] = inequalities(settings, matrixName, vectorName, dimension)
if ~isfield(settings,matrixName) || isempty(settings.(matrixName))
    assert(~isfield(settings,vectorName) || isempty(settings.(vectorName)), ...
        'ejc:InvalidBounds','An absent constraint matrix needs an empty bound.');
    H = zeros(0,dimension);
    h = zeros(0,1);
    return
end
H = settings.(matrixName);
h = settings.(vectorName);
validateattributes(H, {'double'}, {'2d','real','finite','ncols',dimension});
validateattributes(h, {'double'}, {'real','finite','size',[size(H,1),1]});
end

function check_weight(W, dimension, positiveDefinite, name)
validateattributes(W, {'double'}, {'real','finite','size',[dimension,dimension]});
assert(issymmetric(W), 'ejc:InvalidWeight','%s must be symmetric.',name);
if positiveDefinite
    [~,flag] = chol(W);
    valid = flag == 0;
else
    valid = all(eig(W) >= 0);
end
assert(valid, 'ejc:InvalidWeight','%s has invalid definiteness.',name);
end
