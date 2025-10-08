classdef test_kernel < matlab.unittest.TestCase
    methods (Test)
        function testOnes(tc)
            s = make_sk(1,1,2, [10 20], [1 2 3]);
            spec = struct('type','ones');
            g = kernel('eval',spec,s);
            tc.verifyEqual(g, ones(1,1));
            tc.verifyEqual(kernel('dim',spec), 1);
            tc.verifyEqual(string(kernel('describe',spec)), "ones");
        end

        function testLinearEvalAndDim(tc)
            s = make_sk(1,1,2, [10 20], [1 2 3]); % d=5 → [10;20;1;2;3]
            d = numel([s.y(:); s.u(:)]);
            spec = struct('type','linear','d',d);
            g = kernel('eval',spec,s);
            expected = [1; 10;20;1;2;3];
            tc.verifyEqual(g, expected);
            tc.verifyEqual(kernel('dim',spec), 1 + d);
            tc.verifyEqual(string(kernel('describe',spec)), "linear");
        end

        function testPolyNoneDeg2(tc)
            s = make_sk(1,1,2, [10 20], [1 2 3]); % svec=[10;20;1;2;3]
            svec = [s.y(:); s.u(:)];
            d = numel(svec);
            spec = struct('type','poly','degree',2,'cross','none','d',d);
            g = kernel('eval',spec,s);
            expected = [1; svec; svec.^2];
            tc.verifyEqual(g, expected);
            tc.verifyEqual(kernel('dim',spec), 1 + d*2);
            tc.verifyEqual(string(kernel('describe',spec)), "poly(deg=2, cross=none)");
        end

        function testPolyPairwiseDeg2(tc)
            s = make_sk(1,1,2, [10 20], [1 2 3]);
            svec = [s.y(:); s.u(:)];
            d = numel(svec);
            spec = struct('type','poly','degree',2,'cross','pairwise','d',d);
            g = kernel('eval',spec,s);

            squares = svec.^2;
            inter = [];
            for i=1:d-1
                inter = [inter; svec(i)*svec(i+1:d)]; %#ok<AGROW>
            end
            expected = [1; svec; squares; inter];
            tc.verifyEqual(g, expected);

            tc.verifyEqual(kernel('dim',spec), 1 + d + d + nchoosek(d,2));
            tc.verifyEqual(string(kernel('describe',spec)), "poly(deg=2, cross=pairwise)");
        end

        function testPolyFullDeg2(tc)
            % Use small d to check monomial order. Let d=3 here.
            s = make_sk(1,1,2, [2 3], [5 7 11]); % svec=[2;3;5;7;11], d=5
            svec = [s.y(:); s.u(:)];
            d = numel(svec);
            deg = 2;
            spec = struct('type','poly','degree',deg,'cross','full','d',d);
            g = kernel('eval',spec,s);

            exps = enumerate_exponents_ref(d, deg);
            expected = ones(size(exps,1),1);
            for k=1:size(exps,1)
                expected(k) = prod(svec(:)'.^exps(k,:));
            end
            tc.verifyEqual(g, expected, 'AbsTol', 1e-12);
            tc.verifyEqual(kernel('dim',spec), nchoosek(d+deg,deg));
        end

        function testRbfScalarSigma(tc)
            s = make_sk(1,1,2, [1 2], [3 4 5]); % d=5
            svec = [s.y(:); s.u(:)]';
            C = [zeros(1,5); ones(1,5)]; % q=2 centers
            sig = 2.0;
            spec = struct('type','rbf','centers',C,'sigma',sig);
            g = kernel('eval',spec,s);
            diffs = C - svec;
            expected = exp(-0.5 * sum(diffs.^2,2) / (sig^2));
            tc.verifyEqual(g, expected, 'AbsTol', 1e-12);
            tc.verifyEqual(kernel('dim',spec), 2);
            ds = string(kernel('describe',spec));
            tc.verifyTrue(contains(ds,"rbf("));
        end

        function testRbfVectorSigma(tc)
            s = make_sk(1,1,1, [1], [2 3]); % d=3
            svec = [s.y(:); s.u(:)]';
            C = [0 0 0; 1 1 1; -1 -1 -1]; % q=3
            sigma = [1.0 2.0 3.0];
            spec = struct('type','rbf','centers',C,'sigma',sigma);
            g = kernel('eval',spec,s);
            diffs = C - svec;             % q×d
            Sig = repmat(sigma(:),1,size(C,2)); % q×d
            expected = exp(-0.5 * sum((diffs./Sig).^2,2));
            tc.verifyEqual(g, expected, 'AbsTol', 1e-12);
            tc.verifyEqual(kernel('dim',spec), 3);
        end

        function testMixConcat(tc)
            s = make_sk(1,1,2, [1 2], [3 4 5]); % d=5
            d = numel([s.y(:); s.u(:)]);
            lin = struct('type','linear','d',d);
            C = [zeros(1,d); ones(1,d)];
            rbf = struct('type','rbf','centers',C,'sigma',1.5);
            spec = struct('type','mix','parts',{{lin, rbf}});
            g = kernel('eval',spec,s);
            g_lin = kernel('eval',lin,s);
            g_rbf = kernel('eval',rbf,s);
            tc.verifyEqual(g, [g_lin; g_rbf], 'AbsTol', 1e-12);
            tc.verifyEqual(kernel('dim',spec), kernel('dim',lin) + kernel('dim',rbf));
            ds = string(kernel('describe',spec));
            tc.verifyTrue(startsWith(ds,"mix["));
        end

        function testCenterScale(tc)
            s = make_sk(1,1,2, [10 20], [1 2 3]); % svec=[10;20;1;2;3]
            svec = [s.y(:); s.u(:)];
            d = numel(svec);
            spec = struct('type','linear','d',d,'center',svec,'scale',ones(d,1));
            g = kernel('eval',spec,s);
            expected = [1; zeros(d,1)];
            tc.verifyEqual(g, expected, 'AbsTol', 1e-12);
        end

        function testDimErrors(tc)
            s = make_sk(1,1,1,[1],[2 3]);
        
            % 1) linear dim requires spec.d
            bad = struct('type','linear');
            thrown = false; ME = [];
            try, kernel('dim',bad); catch ME, thrown = true; end
            tc.verifyTrue(thrown);
            tc.verifyTrue(contains(ME.message,"set spec.d"), "Unexpected message for linear/d.");
        
            % 2) rbf centers size mismatch
            bad2 = struct('type','rbf','centers',rand(2,4),'sigma',1.0);
            thrown = false; ME = [];
            try, kernel('eval',bad2,s); catch ME, thrown = true; end
            tc.verifyTrue(thrown);
            tc.verifyTrue(contains(ME.message,"rbf.centers second dimension"), "RBF dim check failed.");
        
            % 3) mix requires nonempty parts
            bad3 = struct('type','mix','parts',{{}});
            thrown = false; ME = [];
            try, kernel('dim',bad3); catch ME, thrown = true; end
            tc.verifyTrue(thrown);
            tc.verifyTrue(contains(ME.message,"nonempty cell array"), "mix.parts emptiness check failed.");
        end

        function testDeterminism(tc)
            s = make_sk(1,1,2, [3 4], [5 6 7]);
            d = numel([s.y(:); s.u(:)]);
            spec = struct('type','poly','degree',2,'cross','pairwise','d',d);
            g1 = kernel('eval',spec,s);
            g2 = kernel('eval',spec,s);
            tc.verifyEqual(g1, g2, 'AbsTol', 0);
        end
    end
end

%% ---- local helpers for the test file ----
function s = make_sk(p,m,ell, yvals, uvals)
% Build a window struct with shapes:
%   y: p×ell, columns [y_{k-1},...,y_{k-ell}]
%   u: m×(ell+1), columns [u_k, u_{k-1},...,u_{k-ell}]
    y = reshape(yvals, p, ell);
    u = reshape(uvals, m, ell+1);
    s = struct('y', y, 'u', u);
end

function exps = enumerate_exponents_ref(d, r)
% All exponent vectors e ∈ N_0^d with sum(e) ≤ r, graded lex order.
    exps = zeros(1,d);
    for total=1:r
        exps = [exps; compositions_ref(total,d)]; %#ok<AGROW>
    end
end

function comps = compositions_ref(total,d)
% Lex-ordered nonnegative integer tuples summing to 'total'.
    if d==1
        comps = total;
        return
    end
    comps = [];
    for k=0:total
        tail = compositions_ref(total-k, d-1);
        comps = [comps; [k*ones(size(tail,1),1), tail]]; %#ok<AGROW>
    end
end
