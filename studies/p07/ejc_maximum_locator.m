function out=ejc_maximum_locator(a,b,proof)
%EJC_MAXIMUM_LOCATOR Approved passive F0698 reduction; no empirical tie band.
% Proof is assembled from actual source rows and the complete paired run
% screen by ejc_qp_max_locator. This component never certifies a campaign.
out=struct('passed',false,'status',"FAILED_MAX_LOCATOR",'reason',"", ...
    'maximumLocationClaim',"NOT_ASSERTED",'originalStrictPassed',false);
try
    assert(proof.coverageId=="F0698" && proof.maximumLocationClaim=="NOT_ASSERTED" && ...
        ~proof.activeIndex && ~proof.exactAlias,'ejc:LocatorScope','Unapproved locator, claim, or alias.');
    assert(isa(a,'double') && isa(b,'double') && isreal(a) && isreal(b) && ...
        isvector(a) && ~isempty(a) && isequal(size(a),size(b)) && all(isfinite(a)) && all(isfinite(b)), ...
        'ejc:LocatorHistory','Required complete finite double histories differ in shape/class/mask.');
    assert(isequal(proof.selectionCurrent,proof.selectionReference) && ...
        isequal(proof.selectionCurrent,1:numel(a)) && proof.countCurrent==numel(a) && proof.countReference==numel(b) && ...
        isequaln(proof.keysCurrent,proof.keysReference) && isequal(proof.timeCurrent,proof.timeReference) && ...
        isequaln(proof.settingsCurrent,proof.settingsReference) && proof.units=="dimensionless QP condition", ...
        'ejc:LocatorIdentity','Exact source, selection, count, time, settings or units differ.');
    assert(proof.parentPassed && proof.hessianCount==numel(a) && proof.ownSourcePassed, ...
        'ejc:LocatorParents','Complete own source and resolved parent checks are mandatory.');
    out.historyCurrent=a;out.historyReference=b;out.proof=proof;
    [ma,ia]=max(a);[mb,ib]=max(b);
    out.maximumCurrent=ma;out.maximumReference=mb;out.firstCurrent=ia;out.firstReference=ib;
    out.exactMaximizersCurrent=find(a==ma);out.exactMaximizersReference=find(b==mb);
    out.originalStrictPassed=isequal(ia,ib);
    assert(isequal(proof.ownMaximumCurrent,ma) && isequal(proof.ownMaximumReference,mb) && ...
        isequal(proof.ownIndexCurrent,ia) && isequal(proof.ownIndexReference,ib), ...
        'ejc:LocatorOwnMaximum','Wrong own-run maximum or first maximizing index.');
    out.history=ejc_acceptance_numeric(a,b,1e-8,1e-7,true(size(b)));
    out.maximum=ejc_acceptance_numeric(ma,mb,1e-8,1e-7,true);
    assert(out.history.passed && out.maximum.passed,'ejc:LocatorNumeric','Existing P6 history or maximum failed.');
    delta=1e-8+1e-7*abs(b);out.crossIndexBudget=delta(ia)+delta(ib);
    out.lossCurrent=ma-a(ib);out.lossReference=mb-b(ia);
    assert(out.lossCurrent>=0 && out.lossReference>=0 && ...
        out.lossCurrent<=out.crossIndexBudget && out.lossReference<=out.crossIndexBudget, ...
        'ejc:LocatorCrossIndex','Derived two-point consistency inequality failed.');
    out.witnessIndices=unique([ia ib]);out.witnessScreens=cell(numel(out.witnessIndices),2);
    assert(isequal(proof.witnessIndices,out.witnessIndices) && ...
        isequal(size(proof.hessians),[numel(out.witnessIndices) 2]),'ejc:LocatorWitness','Wrong same-index witness selection.');
    for k=1:numel(out.witnessIndices)
        j=out.witnessIndices(k);
        for side=1:2
            value=a(j);if side==2,value=b(j);end
            s=ejc_matrix_screen(proof.hessians{k,side},"hessian",StoredCondition=value);
            out.witnessScreens{k,side}=s;
            assert(s.valid && s.resolved && s.decompositionPassed && s.conditionInsideEnvelope, ...
                'ejc:LocatorWitness','Required QP witness is invalid, unresolved or outside its own envelope.');
        end
    end
    out.passed=true;out.status="NUMERICAL_AGREEMENT_MAX_LOCATOR_SAME";
    if ia~=ib,out.status="NUMERICAL_AGREEMENT_MAX_LOCATOR_DIFFERENT";end
catch e
    out.reason=string(e.identifier)+": "+string(e.message);
end
end
