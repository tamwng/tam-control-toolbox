"""Audit the runner's saved scalar tables; no fitting, rollouts or resampling."""
from pathlib import Path
import csv,json,math,hashlib,statistics

ROOT=Path(r'C:/Users/tamwi/OneDrive - Kyoto University/research/projects/tam-control-toolbox')
CAMPAIGN=ROOT/'results/p06_sensitivity_20260924_225708'
EXPORT=Path(__file__).resolve().parent

def read(name):
    with (CAMPAIGN/name).open(encoding='utf-8-sig',newline='') as f:return list(csv.DictReader(f))

def number(value):return float(value)
def yes(value):return value in ['1','true','True']

def percentile(values,p):
    if not values or not all(math.isfinite(x) for x in values):return math.nan
    values=sorted(values); position=(len(values)-1)*p
    lo=math.floor(position);hi=math.ceil(position)
    return values[lo]+(position-lo)*(values[hi]-values[lo])

def same(a,b):
    return math.isnan(a) and math.isnan(b) or math.isclose(a,b,rel_tol=2e-12,abs_tol=2e-14)

def output(name,rows):
    with (EXPORT/name).open('x',encoding='utf-8',newline='') as f:
        writer=csv.DictWriter(f,fieldnames=list(rows[0]));writer.writeheader();writer.writerows(rows)

def main():
    manifest=read('P06_RUN_MANIFEST.csv');runs=read('tables/runs.csv')
    summaries=read('tables/noisy_summaries.csv');paired=read('tables/paired_contrasts.csv')
    gates=read('tables/baseline_gate.csv')
    expected={r['runId']:r for r in manifest};actual={r['runId']:r for r in runs}
    assert len(expected)==len(manifest)==len(actual)==len(runs)==1558
    assert set(expected)==set(actual)
    assert sum(not yes(r['noisy']) for r in runs)==38
    assert sum(yes(r['noisy']) for r in runs)==1520
    assert len(summaries)==152 and len(paired)==116
    assert len(gates)==204 and all(yes(r['passed']) for r in gates)
    gate_ids={r['runId'] for r in manifest if yes(r['baselineGate'])}
    assert gate_ids=={r['runId'] for r in gates} and len(gate_ids)==12
    for runid,row in actual.items():
        for column in expected[runid]:
            if column!='executionStatus':assert row[column]==expected[runid][column],(runid,column)
        assert row['executionStatus']!='PROPOSED_NOT_RUN'
        assert (CAMPAIGN/'runs'/(runid+'.mat')).is_file()
    groups={}
    for r in runs:groups.setdefault((r['configuration'],r['modelId']),[]).append(r)
    assert len(groups)==38
    counts=[]
    for (config,model),block in groups.items():
        assert sorted(int(r['trial']) for r in block)==list(range(41))
        noisy=[r for r in block if yes(r['noisy'])]
        assert len(noisy)==40
        if model=='K':
            assert config in ['baseline','R_half','R_double']
            assert all(math.isnan(number(r['alphaP'])) and math.isnan(number(r['fittingTransitions'])) and not yes(r['identificationApplicable']) for r in block)
        counts.append({'configuration':config,'modelId':model,'model':block[0]['model'],'planned':41,'attempted':len(block),'deterministic':1,'noisy':len(noisy),'completed':sum(yes(r['completed']) for r in block),'terminated':sum(r['executionStatus']=='TERMINATED' for r in block),'exceptions':sum(r['executionStatus']=='FAILED_SETUP_OR_EXECUTION' for r in block),'predictionComplete':sum(yes(r['predictionCompleted']) for r in block)})
    summary_checks=0
    for s in summaries:
        block=[r for r in groups[(s['configuration'],s['modelId'])] if yes(r['noisy'])]
        flag='predictionCompleted' if s['metric']=='predictionRMS' else 'completed'
        values=[number(r[s['metric']]) for r in block if yes(r[flag])]
        assert int(s['attempted'])==len(block)
        assert int(s['completedControl'])==sum(yes(r['completed']) for r in block)
        assert int(s['terminatedOrFailed'])==sum(not yes(r['completed']) for r in block)
        assert int(s['eligibleScores'])==len(values)
        assert int(s['finiteScores'])==sum(math.isfinite(x) for x in values)
        q1=percentile(values,.25);q3=percentile(values,.75)
        for col,val in [('median',percentile(values,.5)),('q1',q1),('q3',q3),('iqr',q3-q1)]:
            assert same(number(s[col]),val),(s,col,val)
            summary_checks+=1
    paired_checks=0
    for p in paired:
        left_config,left_model=p['left'].split(':');right_config,right_model=p['right'].split(':')
        left={r['trial']:r for r in groups[(left_config,left_model)] if yes(r['noisy'])}
        right={r['trial']:r for r in groups[(right_config,right_model)] if yes(r['noisy'])}
        flag='predictionCompleted' if p['metric']=='predictionRMS' else 'completed'
        trials=sorted(set(left)&set(right),key=int)
        complete=[t for t in trials if yes(left[t][flag]) and yes(right[t][flag])]
        delta=[number(left[t][p['metric']])-number(right[t][p['metric']]) for t in complete]
        assert int(p['attemptedPairs'])==len(trials)==40
        assert int(p['completePairs'])==len(complete)
        assert int(p['finitePairs'])==sum(math.isfinite(x) for x in delta)
        assert int(p['bootstrapResamples'])==2000
        assert same(number(p['medianDifference']),percentile(delta,.5)),p
        if delta and all(math.isfinite(x) for x in delta):
            assert math.isfinite(number(p['lower95'])) and number(p['lower95'])<=number(p['upper95'])
        paired_checks+=1
    gate_rows=[]
    for runid in sorted(gate_ids):
        rows=[r for r in gates if r['runId']==runid]
        assert len(rows)==17
        baseline=Path(expected[runid]['baselineFile'])
        digest=hashlib.sha256(baseline.read_bytes()).hexdigest()
        assert all(r['baselineSHA256']==digest for r in rows)
        gate_rows.append({'runId':runid,'comparisons':len(rows),'passed':sum(yes(r['passed']) for r in rows),'baselineFile':str(baseline),'baselineSHA256':digest})
    output('P06_CASE_COUNTS.csv',counts)
    output('P06_GATE_SUMMARY.csv',gate_rows)
    report={'manifestUnique':True,'planned':1558,'attempted':1558,'completed':sum(yes(r['completed']) for r in runs),'terminated':sum(r['executionStatus']=='TERMINATED' for r in runs),'exceptions':sum(r['executionStatus']=='FAILED_SETUP_OR_EXECUTION' for r in runs),'noisyAttemptsPerApplicableCombination':40,'knownIdentificationNonapplicability':'PASS','gateCases':12,'gateComparisonsPassed':204,'summaryScalarComparisons':summary_checks,'pairedMediansAndCountsChecked':paired_checks,'aggregateComparisonTolerance':{'absolute':2e-14,'relative':2e-12},'tolerancePurpose':'CSV serialization comparison only; approved baseline tolerances were not changed','bootstrapIntervals':'preserved runner endpoints and analysis RNG states; not resampled in this audit','extraTrajectoriesGenerated':False}
    with (EXPORT/'P06_TABLE_AUDIT.json').open('x') as f:json.dump(report,f,indent=2)
    print(json.dumps(report,indent=2))

if __name__=='__main__':main()
