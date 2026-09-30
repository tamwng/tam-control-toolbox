function tests=test_verification_acceptance_numeric
tests=functiontests(localfunctions);
end
function setupOnce(t)
root=fileparts(fileparts(mfilename('fullpath')));t.TestData.path=path;
addpath(fullfile(root,'verification','functions'));
end
function teardownOnce(t)
path(t.TestData.path);
end
function test_all_numeric_rule_boundaries(t)
rules={"A1","";"A2","";"A3","";"A4","";"A5",""; ...
    "P1","";"P2","";"P3","calibration";"P3","lambda_energy";"P3","regression"; ...
    "P4","entries";"P4","eigenvalues";"P5","entries";"P5","eigenvalues"; ...
    "P6","";"P8","kkt";"P8","identity";"P9","state";"P9","diagnostic"; ...
    "P10","";"P11","";"P12",""};
for j=1:size(rules,1)
    [at,rt]=verification_acceptance_limits(rules{j,1},rules{j,2},1,2);
    for b=[0 1 -1 1e4]
        bound=at+rt*abs(b);inside=b+bound;
        while abs(inside-b)>bound,inside=inside-eps(abs(inside));end
        while abs(inside+eps(abs(inside))-b)<=bound,inside=inside+eps(abs(inside));end
        values=[b inside inside+eps(abs(inside)) b+10*bound];
        expected=[true true false false];
        for k=1:4
            r=verification_acceptance_numeric(values(k),b,at,rt,true);
            verifyEqual(t,r.passed,expected(k),rules{j,1}+"/"+rules{j,2});
        end
    end
    r=verification_acceptance_numeric(at,0,at,rt,true);verifyTrue(t,r.passed);
    r=verification_acceptance_numeric(-at,0,at,rt,true);verifyTrue(t,r.passed);
end
end
function test_additive_all_elements(t)
r=verification_acceptance_numeric(1+1.05e-7,1,1e-8,1e-7,true);verifyTrue(t,r.passed);
verifyFalse(t,abs(1+1.05e-7-1)<=1e-8 || abs(1+1.05e-7-1)<=1e-7);
r=verification_acceptance_numeric([0 0 1e-5],[0 0 0],1e-8,1e-7,true(1,3));
verifyFalse(t,r.passed);verifyEqual(t,r.failedCount,1);verifyEqual(t,r.maximumLinearIndex,3);
end
function test_shape_class_masks_and_nonapplicability(t)
cases={{single(0),0,true};{[0 0],[0;0],true(1,2)};{NaN,NaN,true}; ...
    {Inf,Inf,true};{Inf,-Inf,true};{NaN,0,false};{0,0,false};{complex(1,1),complex(1,1),true}};
for j=1:numel(cases)
    c=cases{j};r=verification_acceptance_numeric(c{1},c{2},1e-8,1e-7,c{3});verifyFalse(t,r.passed);
end
r=verification_acceptance_numeric(NaN,NaN,1e-8,1e-7,false);
verifyTrue(t,r.passed);verifyEqual(t,r.requiredCount,0);verifyEqual(t,r.notApplicableCount,1);
end
function test_no_numeric_fallback_or_observed_scale(t)
for family=["E0","P7","P13","unknown"]
    verifyError(t,@()verification_acceptance_limits(family),'ejc:UnknownRule');
end
verifyError(t,@()verification_acceptance_limits("P3"),'ejc:UnknownRule');
verifyError(t,@()verification_acceptance_limits("P4","eigenvalues"),'ejc:MissingParent');
verifyError(t,@()verification_acceptance_limits("P1","",2),'ejc:UnsupportedUnits');
end
