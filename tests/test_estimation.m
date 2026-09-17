function tests = test_estimation
%TEST_ESTIMATION Independent batch, scaling, and forgetting checks.
tests = functiontests(localfunctions);
end

function testWeightedBatchForEveryForgettingMode(testCase)
theta0 = [0.2; -0.4; 0.1];
P0 = [1.5 0.1 0.05; 0.1 0.9 -0.02; 0.05 -0.02 2];
D = [0.6; 1.4; 2.1];
rows = [0.7; 1.3];
rules = {struct('mode', 'none'), struct('mode', 'fixed', 'lambda', 0.91), ...
    struct('mode', 'variable', 'Nf', 4, 'sigma', 0.12, 'eta', 0.08, 'gamma', 3)};
for mode = 1:numel(rules)
    estimator = RlsEstimator(theta0, P0, rows, D, rules{mode});
    regressors = zeros(2, 3, 14);
    responses = zeros(2, 14);
    lambdas = ones(14, 1);
    for k = 1:14
        % All three coefficients are shared across these two response rows.
        Phi = [1 sin(k/3) k/11; cos(k/4) 1 (-1)^k/2];
        b = Phi*[0.5; -0.2; 0.8] + 0.03*[sin(2*k); cos(3*k)];
        regressors(:, :, k) = (rows.*Phi)./D.';
        responses(:, k) = rows.*b;
        info = estimator.update(b, Phi);
        verifyTrue(testCase, info.accepted, info.message);
        lambdas(k) = info.lambda;
        [batchBeta, batchP] = weightedBatch(D.*theta0, P0, ...
            regressors(:, :, 1:k), responses(:, 1:k), lambdas(1:k));
        verifyEqual(testCase, estimator.Beta, batchBeta, 'AbsTol', 2e-12);
        verifyEqual(testCase, estimator.Covariance, batchP, 'AbsTol', 2e-12);
    end
end
end

function testActualResidualWindowAndCap(testCase)
f = struct('mode', 'variable', 'Nf', 3, 'sigma', 2, 'eta', 0.2, 'gamma', 2.5);
estimator = RlsEstimator(0, 1, 1, 1, f);
% Zero regressors isolate the forgetting rule from parameter adaptation.
data = [0 2 2 10 0 0 0];
for k = 1:numel(data)
    info = estimator.update(data(k), 0);
    start = max(1, k-f.Nf+1);
    expectedEnergy = sqrt(sum(data(start:k).^2)/(k-start+1))/f.sigma;
    expectedLambda = 1;
    if expectedEnergy > 1
        expectedLambda = 1/(1+f.eta*min(expectedEnergy, f.gamma));
    end
    verifyTrue(testCase, info.accepted, info.message);
    verifyEqual(testCase, info.energy, expectedEnergy, 'AbsTol', 2e-15);
    verifyEqual(testCase, info.lambda, expectedLambda, 'AbsTol', 2e-15);
    verifyEqual(testCase, estimator.ResidualSquares, data(start:k)'.^2);
end
verifyEqual(testCase, info.lambda, 1);
end

function testThresholdAndVectorNorm(testCase)
f = struct('mode', 'variable', 'Nf', 1, 'sigma', 1, 'eta', 0.25, 'gamma', 10);
estimator = RlsEstimator(0, 1, 1, 1, f);
info = estimator.update(1, 0);
verifyEqual(testCase, info.energy, 1);
verifyEqual(testCase, info.lambda, 1);
info = estimator.update(1+1e-8, 0);
verifyEqual(testCase, info.lambda, 1/(1+0.25*(1+1e-8)), 'AbsTol', 2e-15);
info = estimator.update([1; 1], zeros(2, 1));
verifyEqual(testCase, info.energy, sqrt(2), 'AbsTol', 2e-15);
verifyEqual(testCase, info.lambda, 1/(1+0.25*sqrt(2)), 'AbsTol', 2e-15);
end

function testCalibrationRmsAndNormalizedVariance(testCase)
samples = cat(3, [1 2 3; 4 5 6], [2 4 1; 3 2 5], [5 1 2; 1 3 4]);
rows = [2; 0.5];
D = regression_scaling(samples, rows);
expected = zeros(3, 1);
for j = 1:3
    values = reshape(rows.*samples(:, j, :), [], 1);
    expected(j) = norm(values)/sqrt(numel(values));
end
verifyEqual(testCase, D, expected, 'AbsTol', 1e-14);
normalized = (rows.*samples)./D.';
verifyEqual(testCase, reshape(mean(normalized.^2, [1 3]), [], 1), ones(3, 1), 'AbsTol', 1e-14);
% The mean scalar-row prior regression variance is 100 for P_beta=100/n I.
priorVariances = (100/3)*sum(normalized.^2, 2);
verifyEqual(testCase, mean(priorVariances, 'all'), 100, 'AbsTol', 1e-12);
verifyError(testCase, @() regression_scaling(zeros(2, 3, 2), 1), ...
    'regression_scaling:InvalidColumnScale');
end

function testColumnScalingEquivalentWithMatchingPrior(testCase)
theta0 = [0.2; -0.7];
physicalP0 = [2 0.3; 0.3 0.8];
D = [3; 0.25];
f = struct('mode', 'fixed', 'lambda', 0.94);
plain = RlsEstimator(theta0, physicalP0, 1, ones(2, 1), f);
scaled = RlsEstimator(theta0, diag(D)*physicalP0*diag(D), 1, D, f);
for k = 1:12
    Phi = [1 sin(k/2); k/10 cos(k/3)];
    b = Phi*[0.6; -0.2] + 0.01*[cos(k); sin(k)];
    info1 = plain.update(b, Phi);
    info2 = scaled.update(b, Phi);
    verifyTrue(testCase, info1.accepted && info2.accepted);
    verifyEqual(testCase, scaled.RawParameters, plain.RawParameters, 'AbsTol', 1e-12);
    verifyEqual(testCase, scaled.Covariance, diag(D)*plain.Covariance*diag(D), 'AbsTol', 1e-12);
    verifyEqual(testCase, Phi*scaled.RawParameters, Phi*plain.RawParameters, 'AbsTol', 1e-12);
end
end

function testUniformRowScalingWithMatchingPriorAndResidualScale(testCase)
theta0 = [0.1; 0.3];
P0 = [1.4 0.2; 0.2 0.7];
rowMultiplier = 3;
f = struct('mode', 'variable', 'Nf', 3, 'sigma', 0.2, 'eta', 0.03, 'gamma', 4);
scaledF = f;
scaledF.sigma = rowMultiplier*f.sigma;
plain = RlsEstimator(theta0, P0, 1, [1; 1], f);
scaled = RlsEstimator(theta0, P0/rowMultiplier^2, rowMultiplier, [1; 1], scaledF);
for k = 1:9
    Phi = [1 k/7];
    b = Phi*[0.8; -0.2] + 0.03*sin(k);
    info1 = plain.update(b, Phi);
    info2 = scaled.update(b, Phi);
    verifyTrue(testCase, info1.accepted && info2.accepted);
    verifyEqual(testCase, scaled.RawParameters, plain.RawParameters, 'AbsTol', 1e-12);
    verifyEqual(testCase, scaled.Covariance, plain.Covariance/rowMultiplier^2, 'AbsTol', 1e-12);
    verifyEqual(testCase, info2.lambda, info1.lambda, 'AbsTol', 1e-14);
end
end

function testMappingNeverFeedsBack(testCase)
map = @(theta) min(max(theta, [0.2; 0]), [3; 2]);
raw = RlsEstimator([0.8; 0.3], eye(2), 1, [1; 1]);
mapped = RlsEstimator([0.8; 0.3], eye(2), 1, [1; 1], [], map);
for k = 1:4
    b = [8; -4];
    info1 = raw.update(b, eye(2));
    info2 = mapped.update(b, eye(2));
    verifyTrue(testCase, info1.accepted && info2.accepted);
    verifyEqual(testCase, mapped.Beta, raw.Beta);
    verifyEqual(testCase, mapped.Covariance, raw.Covariance);
    verifyEqual(testCase, mapped.RawParameters, raw.RawParameters);
    verifyEqual(testCase, mapped.Parameters, [3; 0]);
    verifyGreaterThan(testCase, mapped.RawParameters(1), 3);
    verifyLessThan(testCase, mapped.RawParameters(2), 0);
end
end

function testRejectedUpdatesRetainLastValidState(testCase)
f = struct('mode', 'variable', 'Nf', 3, 'sigma', 1, 'eta', 0.1, 'gamma', 4);
estimator = RlsEstimator([0; 0], eye(2), 1, [1; 1], f);
first = estimator.update(0.5, [1 0.5]);
verifyTrue(testCase, first.accepted);
beta = estimator.Beta;
P = estimator.Covariance;
window = estimator.ResidualSquares;
invalidData = {NaN, [1 2]; 1, [Inf 1]; 1, [1 2 3]; realmax, [1 0]};
for k = 1:size(invalidData, 1)
    info = estimator.update(invalidData{k, 1}, invalidData{k, 2});
    verifyFalse(testCase, info.accepted);
    verifyNotEmpty(testCase, info.message);
    verifyEqual(testCase, estimator.Beta, beta);
    verifyEqual(testCase, estimator.Covariance, P);
    verifyEqual(testCase, estimator.ResidualSquares, window);
end
% Finite data may still produce an unrepresentable covariance calculation.
unstable = RlsEstimator(0, 1, 1, 1, f);
info = unstable.update(1, 1e200);
verifyFalse(testCase, info.accepted);
verifyEqual(testCase, unstable.Beta, 0);
verifyEqual(testCase, unstable.Covariance, 1);
verifyEqual(testCase, unstable.ResidualSquares, 1);
end

function testExplicitRecordRestartPreservesFit(testCase)
f = struct('mode', 'variable', 'Nf', 4, 'sigma', 1, 'eta', 0.1, 'gamma', 3);
estimator = RlsEstimator(0, 1, 1, 1, f);
info = estimator.update(2, 1);
verifyTrue(testCase, info.accepted);
beta = estimator.Beta;
P = estimator.Covariance;
estimator.resetResidualWindow();
verifyEmpty(testCase, estimator.ResidualSquares);
verifyEqual(testCase, estimator.Beta, beta);
verifyEqual(testCase, estimator.Covariance, P);
info = estimator.update(0, 0);
verifyEqual(testCase, info.energy, 0);
verifyEqual(testCase, info.lambda, 1);
end

function testInvalidInitializationAndMapping(testCase)
verifyError(testCase, @() RlsEstimator([0; 0], [1 2; 2 1], 1, [1; 1]), ...
    'RlsEstimator:InvalidCovariance');
verifyError(testCase, @() RlsEstimator(0, 1, 1, 1, struct('mode', 'ratio')), ...
    'RlsEstimator:InvalidForgetting');
estimator = RlsEstimator(0, 1, 1, 1, [], @(theta) [theta; theta]);
verifyError(testCase, @() estimator.Parameters, 'RlsEstimator:InvalidMappedParameters');
end

function [beta, covariance] = weightedBatch(beta0, P0, regressors, responses, lambda)
% Solve the augmented weighted least-squares problem independently of RLS.
rootPrior = chol(P0\eye(size(P0)));
A = sqrt(prod(lambda))*rootPrior;
b = A*beta0;
for j = 1:numel(lambda)
    weight = sqrt(prod(lambda(j+1:end)));
    A = [A; weight*regressors(:, :, j)]; %#ok<AGROW>
    b = [b; weight*responses(:, j)]; %#ok<AGROW>
end
beta = A\b;
covariance = (A.'*A)\eye(size(P0));
end
