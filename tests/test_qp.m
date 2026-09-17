function tests = test_qp
% Deterministic checks against independently derived finite-horizon problems.
tests = functiontests(localfunctions);
end

function testUnconstrainedAnalyticalOptimum(testCase)
% y1=0.4+u0, y2=0.4+u1: only the second tracking term changes u1.
settings = struct('Q',reshape([3,5],1,1,2),'R',2);
qp = assemble_qp(0,1,0.4,1,0.7,0.2,[9,1.6],settings);
solution = solve_mpc(qp);
expected = (5*(1.6-0.4)+2*0.2)/(5+2);
verifyTrue(testCase,solution.accepted,solution.message);
verifyEqual(testCase,solution.uNext,expected,'AbsTol',1e-8);
verifyEqual(testCase,solution.Y,[0.6,0.4+expected],'AbsTol',1e-8);
expectedCost = 0.5*(3*(0.6-9)^2+5*(0.4+expected-1.6)^2 ...
    +2*(expected-0.2)^2);
verifyEqual(testCase,solution.objective,expectedCost,'AbsTol',1e-9);
verifySize(testCase,solution.slack,[0,2]);
checkResiduals(testCase,solution);
end

function testAnalyticalActiveInputAndIncrementBounds(testCase)
settings = struct('Q',1,'R',0.2,'Hu',[1;-1],'hu',[0.4;0.4], ...
    'Hdu',[1;-1],'hdu',[0.15;0.15]);
qp = assemble_qp(0,1,0,1,0,0.3,[1,2],settings);
solution = solve_mpc(qp);
verifyTrue(testCase,solution.accepted,solution.message);
verifyEqual(testCase,solution.uNext,0.4,'AbsTol',1e-7);
checkResiduals(testCase,solution);
qp = assemble_qp(0,1,0,1,0,0,[1,2],settings);
solution = solve_mpc(qp);
verifyTrue(testCase,solution.accepted,solution.message);
verifyEqual(testCase,solution.uNext,0.15,'AbsTol',1e-7);
checkResiduals(testCase,solution);
end

function testCondensationAndObjectiveByExplicitPropagation(testCase)
% Two inputs, three states and two tracked outputs with a nonzero offset.
A = [0.6,0.1,0;0,0.7,0.2;0,0,0.5];
B = [1,0.2;0,0.5;0.3,-0.2];
C = [1,0,0;0,1,1];
c = [0.2;-0.1;0.15];
x = [0.7;-0.5;0.2];
u0 = [0.1;-0.2];
r = [0.2,0.4,0.6;0.1,0.2,0.3];
settings = struct('Q',cat(3,eye(2),[2,.2;.2,1],3*eye(2)), ...
    'R',[0.4,0.1;0.1,0.6],'Hy',[1,2;-1,0],'hy',[0.8;0.7], ...
    'Seps',[4,1;1,3]);
qp = assemble_qp(A,B,c,C,x,u0,r,settings);
U = [0.2,-0.1;-0.3,0.1];
slack = [0.1,0.2,0.3;0.3,0.2,0.1];
inputs = [u0,U];
Y = zeros(2,3);
directCost = 0;
for i = 1:3
    x = c+A*x+B*inputs(:,i);
    Y(:,i) = C*x;
    e = Y(:,i)-r(:,i);
    directCost = directCost+0.5*(e'*settings.Q(:,:,i)*e ...
        +slack(:,i)'*settings.Seps*slack(:,i));
    if i > 1
        du = inputs(:,i)-inputs(:,i-1);
        directCost = directCost+0.5*du'*settings.R*du;
    end
end
z = [U(:);slack(:)];
verifyEqual(testCase,reshape(qp.Y0+qp.Yu*U(:),2,3),Y,'AbsTol',1e-14);
verifyEqual(testCase,qp.D*U(:)+qp.d,reshape(diff(inputs,1,2),[],1),'AbsTol',1e-14);
verifyEqual(testCase,0.5*z'*qp.H*z+qp.f'*z+qp.constant,directCost,'AbsTol',1e-13);
outputResidual = settings.Hy*Y-settings.hy-slack;
verifyEqual(testCase,qp.Aineq*z-qp.bineq,outputResidual(:),'AbsTol',1e-14);
solution = solve_mpc(qp);
verifyTrue(testCase,solution.accepted,solution.message);
checkResiduals(testCase,solution);
end

function testUnequalInputAndOutputDimensions(testCase)
settings = struct('Q',2,'R',[1,0.2;0.2,2], ...
    'Hu',[eye(2);-eye(2)],'hu',0.8*ones(4,1), ...
    'Hdu',[eye(2);-eye(2)],'hdu',0.2*ones(4,1));
u0 = [0.1;-0.1];
qp = assemble_qp([0.7,0.1;0,0.5],eye(2),[0.03;-.02],[1,2], ...
    [0.1;0.2],u0,[1,2,1,0],settings);
solution = solve_mpc(qp);
verifyTrue(testCase,solution.accepted,solution.message);
verifySize(testCase,solution.U,[2,3]);
verifySize(testCase,solution.Y,[1,4]);
verifyEqual(testCase,solution.Y(1),[1,2]*([0.7,0.1;0,0.5]*[0.1;0.2] ...
    +[0.03;-.02]+u0),'AbsTol',1e-14);
verifyLessThanOrEqual(testCase,max(abs(solution.U(:))),0.8+1e-7);
du = diff([u0,solution.U],1,2);
verifyLessThanOrEqual(testCase,max(abs(du(:))),0.2+1e-7);
checkResiduals(testCase,solution);
end

function testCommittedFirstPredictionRequiresSlack(testCase)
% Eq. (67) gives 0.03+0.65*1.4=0.94 before any new input can act.
settings = struct('Q',1,'R',0.05,'Hu',[1;-1],'hu',[1.2;1.2], ...
    'Hdu',[1;-1],'hdu',[.25;.25],'Hy',[1;-1],'hy',[.85;.85], ...
    'Seps',1e4*eye(2));
qp = assemble_qp(.65,.4,.03,1,1.4,0,[.6,.6,.6],settings);
solution = solve_mpc(qp);
verifyTrue(testCase,solution.accepted,solution.message);
verifyEqual(testCase,solution.Y(1),.94,'AbsTol',1e-14);
verifyEqual(testCase,solution.slack(1,1),.09,'AbsTol',1e-7);
verifyLessThanOrEqual(testCase,max(settings.Hy*solution.Y-settings.hy-solution.slack,[],'all'),1e-7);
verifyGreaterThanOrEqual(testCase,min(solution.slack,[],'all'),-1e-7);
checkResiduals(testCase,solution);
end

function testInfeasibleQPAndInvalidDataHoldCommittedInput(testCase)
% Opposing increment constraints require both delta u <= -1 and >= 1.
settings = struct('Q',1,'R',1,'Hdu',[1;-1],'hdu',[-1;-1]);
qp = assemble_qp(0.5,1,.1,1,.2,.3,[0,0],settings);
solution = solve_mpc(qp);
verifyFalse(testCase,solution.accepted);
verifyEqual(testCase,solution.uNext,.3);
verifyNotEmpty(testCase,solution.message);
qp.H(1,1) = NaN;
solution = solve_mpc(qp);
verifyFalse(testCase,solution.accepted);
verifyEqual(testCase,solution.uNext,.3);
verifyNotEmpty(testCase,solution.message);
end

function testInvalidAssemblyRejected(testCase)
settings = struct('Q',1,'R',0);
verifyError(testCase,@() assemble_qp(1,1,0,1,0,0,[0,0],settings),'ejc:InvalidWeight');
settings.R = 1;
settings.Hu = [1;-1];
settings.hu = [.1;.1];
verifyError(testCase,@() assemble_qp(1,1,0,1,0,.2,[0,0],settings),'ejc:CommittedInputBounds');
end

function testAcceptedBoundPrecisionCanBecomeCommittedInput(testCase)
settings = struct('Q',1,'R',0.2,'Hu',[1;-1],'hu',[0.4;0.4]);
% This bound residual is below the existing solver acceptance threshold.
committed = 0.4+5e-8;
qp = assemble_qp(0,1,0,1,0,committed,[1,2],settings);
solution = solve_mpc(qp);
verifyTrue(testCase,solution.accepted,solution.message);
verifyEqual(testCase,solution.Y(1),committed);
verifyEqual(testCase,qp.uCommitted,committed);
checkResiduals(testCase,solution);
end

function checkResiduals(testCase,solution)
verifyLessThanOrEqual(testCase,solution.residuals.primal,1e-7);
verifyLessThanOrEqual(testCase,solution.residuals.stationarity,1e-7);
verifyLessThanOrEqual(testCase,solution.residuals.dual,1e-7);
verifyLessThanOrEqual(testCase,solution.residuals.complementarity,1e-7);
end
