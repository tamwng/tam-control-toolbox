function out=verification_acceptance_verdict(failed,unresolved,qualified)
%VERIFICATION_ACCEPTANCE_VERDICT Qualifications never erase a mandatory failure.
validateattributes([failed unresolved qualified],{'double'},{'real','finite','nonnegative','integer'});
out=struct('failed',failed,'unapprovedUnresolved',unresolved,'qualified',qualified, ...
    'eligibleToAdvance',false,'status',"BLOCKED");
if failed>0,out.status="FAILED";
elseif unresolved>0,out.status="BLOCKED";
elseif qualified>0,out.status="PASSED_WITH_GRAM_QUALIFICATIONS";out.eligibleToAdvance=true;
else,out.status="PASSED";out.eligibleToAdvance=true;
end
end
