function [report,details]=ejc_pair_run_screen(a,b,study,cfg,fitA,fitB,coverageId)
%EJC_PAIR_RUN_SCREEN Scientific parent/condition checks on two saved runs.
% Never solves, fits, changes a matrix, or uses a retained trajectory as fresh.
details=struct('index',{},'kind',{},'actual',{},'reference',{}, ...
    'regressorsCurrent',{},'regressorsReference',{},'checks',{});
keepDetails=nargout>1;
report=struct('passed',false,'reason',"",'qualifiedCount',0,'gramRows',struct([]), ...
    'covarianceNorms',nan(1,b.nSteps),'gramNorms',nan(1,b.nSteps), ...
    'covarianceCount',0,'gramCount',0,'hessianCount',0);
required=["completed","nSteps","controlAccepted","idAttempted","idAccepted","mappingActivated", ...
    "events","gramCount","gramRank","gramValid","exitflag", ...
    "id","modelId","scenario","campaign","trial","kind","amplitude","Ts","time","nEstimated"];
for name=required
    if xor(isfield(a,name),isfield(b,name)) || (isfield(a,name) && ~isequaln(a.(name),b.(name)))
        report.reason="Exact original run outcome differs: "+name;return
    end
end
if isfield(a,'energy') || isfield(b,'energy')
    if ~isfield(a,'energy') || ~isfield(b,'energy') || ~isequal(a.energy>1,b.energy>1)
        report.reason="Exact original variable-forgetting energy branch differs";return
    end
end
if ~isequal(a.lambda<1,b.lambda<1)
    report.reason="Exact original forgetting activation differs";return
end
if isfield(a,'fit'),fitA=a.fit;fitB=b.fit;end
if isfield(a,'D'),fitA.D=a.D;fitB.D=b.D;end
if isfield(a,'nEstimated'),n=a.nEstimated;else,n=fitA.nEstimated;end
if isfield(a,'controlSettings'),settingsA=a.controlSettings;settingsB=b.controlSettings;
else,settingsA=cfg.control;settingsB=cfg.control;end
if isfield(a,'p06'),settingsA.R=a.p06.R;settingsB.R=b.p06.R;end
identicalInputs=isequaln(a,b) && isequaln(fitA,fitB) && isequaln(settingsA,settingsB);
% Reuse only calculations on inputs whose complete arrays were compared
% exactly in this call. Own validity/decomposition/envelope checks still run;
% a matching path, hash label, status, or unchecked success flag is insufficient.
report.identicalInputCalculationReuse=identicalInputs;
if ~isequaln(settingsA,settingsB) || ~isequal(settingsA.Hy,[1;-1])
    report.reason="Unsupported or changed QP coordinates/settings";return
end
N=size(a.plannedOutput,1);
if N~=cfg.N || size(a.plannedInput,1)~=N-1 || size(a.slack,1)~=2 || size(a.slack,2)~=N || ...
        ~isequal(size(a.plannedInput),size(b.plannedInput)) || ~isequal(size(a.slack),size(b.slack))
    report.reason="Unsupported plan coordinates/shape";return
end
names=["passiveUse","sourceMembership","coordinateDefinitions","matrixAgreement", ...
    "regressorAgreement","spectralAgreement","masksAndSigns","originalRanks", ...
    "originalCounts","originalFlags","outcomes","publicationChecks", ...
    "noRequiredUniqueSupplementalRankClaim"];
checks=cell2struct(repmat({false},size(names)),cellstr(names),2);
scopes=struct('study1',["F0069","F3914"],'study2',["F0533","F2462"], ...
    'study3',"F0894",'study4',"F1344",'study5',"F1896",'p06',"F3589");
if ~isfield(scopes,study) || ~any(string(coverageId)==scopes.(study))
    report.reason="Unlisted study/Gram scope pair";return
end
root=fileparts(fileparts(fileparts(mfilename('fullpath'))));
files=dir(fullfile(root,'src','**','*.m'));passive=~isempty(files);
for file=files.'
    passive=passive && ~contains(fileread(fullfile(file.folder,file.name)),'gramCondition');
end
checks.passiveUse=passive;
checks.sourceMembership=any(string(coverageId)==scopes.(study)) && ...
    a.nSteps==b.nSteps && a.nSteps<=numel(a.controlAccepted) && ...
    a.nSteps<=numel(b.controlAccepted) && isequal(a.id,b.id);
checks.coordinateDefinitions=isequal(size(fitA.D),size(fitB.D)) && ...
    all(isfinite(fitA.D)) && all(isfinite(fitB.D)) && all(fitA.D>0) && all(fitB.D>0);
checks.outcomes=all(arrayfun(@(name)~isfield(a,name) || isequaln(a.(name),b.(name)),required));
checks.noRequiredUniqueSupplementalRankClaim=checks.passiveUse && checks.sourceMembership;
checks.rawConditionOrigin="UNSUPPORTED";
if ~isfield(a,'gramRank') && ~isfield(a,'gramValid') && ...
        ~isfield(b,'gramRank') && ~isfield(b,'gramValid')
    if any(study==["study1","p06"])
        checks.rawConditionOrigin="study1_trajectory:spectrum:cond";
    elseif study=="study2"
        checks.rawConditionOrigin="study2_trajectory:spectrum:cond";
    end
end
allRowsA=zeros(0,n);allRowsB=zeros(0,n);
if n>0
    allRowsA=ejc_gram_rows(a,study,cfg,fitA);
    if identicalInputs,allRowsB=allRowsA;else,allRowsB=ejc_gram_rows(b,study,cfg,fitB);end
    pending=struct('index',NaN,'status',"NOT_EXECUTED",'eligibleToAdvance',false, ...
        'qualifiedCount',0,'rawCurrent',NaN,'rawReference',NaN, ...
        'pointRankCurrent',NaN,'pointRankReference',NaN,'intervalCurrent',[NaN NaN], ...
        'intervalReference',[NaN NaN],'matrixAgreement',false,'regressorAgreement',false, ...
        'spectralAgreement',false,'rawConditionOrigin',"NOT_EXECUTED", ...
        'originalRankPresent',false,'reason',"Required parent check not executed");
    report.gramRows=repmat(pending,max(0,a.nSteps-1),1);
end
for j=1:a.nSteps
    for r={a,b}
        r=r{1};
        if r.controlAccepted(j)
            if any(~isfinite(r.plannedInput(:,j))) || any(~isfinite(r.plannedOutput(:,j))) || ...
                    any(~isfinite(r.slack(:,:,j)),'all') || ~isequal(r.u(j+1),r.plannedInput(1,j)) || ...
                    r.exitflag(j)<=0 || any(~isfinite(r.solverResiduals(:,j))) || any(r.solverResiduals(:,j)>1e-7)
                report.reason="Required accepted plan, exact action or original solver validity failed at "+j;return
            end
        elseif ~isequal(r.u(j+1),r.u(j))
            report.reason="Original fallback relation failed at "+j;return
        end
    end
    if n>0
        pa=ejc_matrix_screen(a.covariance(:,:,j),"covariance",StoredCondition=a.covarianceCondition(j));
        if identicalInputs,pb=pa;
        else,pb=ejc_matrix_screen(b.covariance(:,:,j),"covariance",StoredCondition=b.covarianceCondition(j));end
        report.covarianceCount=report.covarianceCount+1;report.covarianceNorms(j)=pb.norm2;
        v=ejc_acceptance_numeric(a.covarianceCondition(j),b.covarianceCondition(j),1e-8,1e-7,true);
        if ~(pa.valid && pb.valid && pa.resolved && pb.resolved && pa.conditionInsideEnvelope && pb.conditionInsideEnvelope && v.passed)
            capture(j,"covariance",pa,pb,[],[],struct);
            report.reason="Required P6 covariance condition failed at "+j;return
        end
        sides={{a,pa},{b,pb}};if identicalInputs,sides=sides(1);end
        for pair=sides
            r=pair{1}{1};p=pair{1}{2};ev=sort(p.eigenvalues);
            v=ejc_acceptance_numeric(r.covarianceEigenvalues(:,j),ev([1 end]),1e-10*max(1,p.norm2),1e-7,true(2,1));
            if ~v.passed,capture(j,"covariance",pa,pb,[],[],struct);report.reason="Own covariance eigenvalue source failed at "+j;return;end
        end
        if j>1
            selected=max(1,j-50):j-1;
            Ra=allRowsA(selected,:);Rb=allRowsB(selected,:);
            ga=ejc_matrix_screen(a.gram(:,:,j),"gram",Regressors=Ra,StoredCondition=a.gramCondition(j),RequireRank=true);
            if identicalInputs,gb=ga;
            else,gb=ejc_matrix_screen(b.gram(:,:,j),"gram",Regressors=Rb,StoredCondition=b.gramCondition(j),RequireRank=true);end
            if ~ga.valid || ~gb.valid,capture(j,"gram",ga,gb,Ra,Rb,checks);report.reason="Invalid Gram parent at "+j;return;end
            report.gramNorms(j)=gb.norm2;report.gramCount=report.gramCount+1;
            checks.matrixAgreement=identicalInputs || ejc_acceptance_numeric(a.gram(:,:,j),b.gram(:,:,j),1e-10,1e-7,true(size(ga.matrix))).passed;
            checks.regressorAgreement=identicalInputs || ejc_acceptance_numeric(Ra,Rb,1e-8,1e-7,true(size(Ra))).passed;
            checks.spectralAgreement=identicalInputs || ejc_acceptance_numeric(sort(ga.eigenvalues),sort(gb.eigenvalues),1e-10*max(1,gb.norm2),1e-7,true(size(gb.eigenvalues))).passed;
            checks.permittedRankInfinity=isfield(a,'gramRank') && isfield(b,'gramRank') && ...
                a.gramRank(j)<n && b.gramRank(j)<n;
            checks.originalCounts=r_count(a,j,Ra) && r_count(b,j,Rb) && a.gramCount(j)==b.gramCount(j);
            checks.masksAndSigns=isequal(isnan(a.gramCondition(j)),isnan(b.gramCondition(j))) && ...
                isequal(isinf(a.gramCondition(j)),isinf(b.gramCondition(j))) && ...
                (~isinf(a.gramCondition(j)) || isequal(a.gramCondition(j),b.gramCondition(j)));
            if isfield(a,'gramRank')
                checks.originalRanks=isequal(a.gramRank(j),ga.pointThresholdRank) && isequal(b.gramRank(j),gb.pointThresholdRank);
                checks.originalFlags=a.gramValid(j) && b.gramValid(j);
                if a.gramRank(j)<n,checks.originalFlags=checks.originalFlags && isequal(a.gramCondition(j),Inf);end
                if b.gramRank(j)<n,checks.originalFlags=checks.originalFlags && isequal(b.gramCondition(j),Inf);end
            else
                checks.originalRanks=~isfield(b,'gramRank') && checks.rawConditionOrigin~="UNSUPPORTED";
                checks.originalFlags=~isfield(a,'gramValid') && ~isfield(b,'gramValid') && checks.originalRanks;
            end
            if isfinite(a.gramCondition(j)) && all(isfinite(ga.envelope)),checks.originalFlags=checks.originalFlags && ga.conditionInsideEnvelope;end
            if isfinite(b.gramCondition(j)) && all(isfinite(gb.envelope)),checks.originalFlags=checks.originalFlags && gb.conditionInsideEnvelope;end
            % This component checks the exact original rank/count/outcome
            % facts. Full report/contrast claims remain a separate caller gate.
            checks.publicationChecks=checks.originalRanks && checks.originalCounts && ...
                checks.originalFlags && checks.outcomes && checks.sourceMembership;
            sides={{a,ga},{b,gb}};if identicalInputs,sides=sides(1);end
            for pair=sides
                r=pair{1}{1};g=pair{1}{2};ev=sort(g.eigenvalues);
                v=ejc_acceptance_numeric(r.gramEigenvalues(:,j),ev([1 end]),1e-10*max(1,g.norm2),1e-7,true(2,1));
                if ~v.passed,capture(j,"gram",ga,gb,Ra,Rb,checks);report.reason="Own Gram eigenvalue source failed at "+j;return;end
            end
            verdict=ejc_p7_qualify(ga,gb,coverageId,checks);
            row=struct('index',j,'status',verdict.status,'eligibleToAdvance',verdict.eligibleToAdvance, ...
                'qualifiedCount',verdict.qualifiedCount,'rawCurrent',a.gramCondition(j),'rawReference',b.gramCondition(j), ...
                'pointRankCurrent',ga.pointThresholdRank,'pointRankReference',gb.pointThresholdRank, ...
                'intervalCurrent',[ga.rankLower ga.rankUpper],'intervalReference',[gb.rankLower gb.rankUpper], ...
                'matrixAgreement',checks.matrixAgreement,'regressorAgreement',checks.regressorAgreement, ...
                'spectralAgreement',checks.spectralAgreement,'rawConditionOrigin',checks.rawConditionOrigin, ...
                'originalRankPresent',isfield(a,'gramRank'),'reason',verdict.reason);
            report.gramRows(j-1)=row;
            if verdict.qualifiedCount>0 || ~verdict.eligibleToAdvance || verdict.status=="EXACT_STRUCTURAL_ZERO_GRAM"
                capture(j,"gram",ga,gb,Ra,Rb,checks);
            end
            if ~verdict.eligibleToAdvance,report.reason="Paired Gram failure at "+j+": "+verdict.reason;return;end
            report.qualifiedCount=report.qualifiedCount+verdict.qualifiedCount;
        end
    end
    qa=assemble_qp(a.A(j),a.B(j),a.c(j),1,a.y(j),a.u(j),zeros(1,N),settingsA);
    ha=ejc_matrix_screen(qa.H,"hessian",StoredCondition=a.qpCondition(j));
    if identicalInputs,hb=ha;
    else
        qb=assemble_qp(b.A(j),b.B(j),b.c(j),1,b.y(j),b.u(j),zeros(1,N),settingsB);
        hb=ejc_matrix_screen(qb.H,"hessian",StoredCondition=b.qpCondition(j));
    end
    report.hessianCount=report.hessianCount+1;
    v=ejc_acceptance_numeric(a.qpCondition(j),b.qpCondition(j),1e-8,1e-7,true);
    if ~(ha.valid && hb.valid && ha.resolved && hb.resolved && ha.conditionInsideEnvelope && hb.conditionInsideEnvelope && v.passed)
        capture(j,"hessian",ha,hb,[],[],struct);
        report.reason="Required P6 Hessian condition failed at "+j;return
    end
end
report.passed=true;
    function capture(index,kind,current,reference,rowsA,rowsB,facts)
        if ~keepDetails,return;end
        details(end+1)=struct('index',index,'kind',kind,'actual',current,'reference',reference, ...
            'regressorsCurrent',rowsA,'regressorsReference',rowsB,'checks',facts);
    end
end
function yes=r_count(r,j,R)
yes=r.gramCount(j)==size(R,1) && size(R,1)==min(50,j-1);
end
