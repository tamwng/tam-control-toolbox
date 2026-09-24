"""Inventory immutable raw files and verify copied scalar values, after execution."""
from pathlib import Path
import csv, json, math, hashlib

ROOT=Path(r'C:/Users/tamwi/OneDrive - Kyoto University/research/projects/tam-control-toolbox')
CAMPAIGN=ROOT/'results/p06_sensitivity_20260924_225708'
EXPORT=Path(__file__).resolve().parent
COMPACT=EXPORT/'compact'

def read(path):
    with path.open(encoding='utf-8-sig',newline='') as f:return list(csv.DictReader(f))

def write(path,rows):
    with path.open('x',encoding='utf-8',newline='') as f:
        w=csv.DictWriter(f,fieldnames=list(rows[0]));w.writeheader();w.writerows(rows)

def digest(path):
    h=hashlib.sha256()
    with path.open('rb') as f:
        for block in iter(lambda:f.read(4*1024*1024),b''):h.update(block)
    return h.hexdigest()

def same(a,b):
    if a==b:return True
    try:
        a,b=float(a),float(b)
        return math.isnan(a) and math.isnan(b) or math.isclose(a,b,rel_tol=2e-12,abs_tol=2e-14)
    except ValueError:return False

def main():
    runs=read(CAMPAIGN/'tables/runs.csv')
    exact=read(COMPACT/'P06_CASE_SCALARS.csv')
    exact_by_id={r['runId']:r for r in exact}
    assert len(runs)==len(exact_by_id)==len(exact)==1558
    comparisons=0
    for row in runs:
        stored=exact_by_id[row['runId']]
        assert set(row)==set(stored)
        for name in row:
            assert same(row[name],stored[name]),(row['runId'],name,row[name],stored[name])
            comparisons+=1
    diagnostics=read(COMPACT/'P06_CASE_DIAGNOSTICS.csv')
    windows=read(COMPACT/'P06_SCORING_WINDOWS.csv')
    initialization=read(COMPACT/'P06_INITIALIZATION_SCORES.csv')
    exceptions=read(COMPACT/'P06_CASE_EXCEPTIONS.csv')
    assert len(exceptions)==1558
    raw=[]
    for row in sorted(runs,key=lambda r:r['runId']):
        path=CAMPAIGN/'runs'/(row['runId']+'.mat')
        raw.append({'runId':row['runId'],'relativeMATPath':path.relative_to(CAMPAIGN).as_posix(),
            'executionStatus':row['executionStatus'],'completed':row['completed'],
            'predictionCompleted':row['predictionCompleted'],'nSteps':row['nSteps'],
            'fileSizeBytes':path.stat().st_size,'SHA256':digest(path)})
    assert {p.name for p in (CAMPAIGN/'runs').glob('*.mat')}=={r['runId']+'.mat' for r in runs}
    write(EXPORT/'P06_RAW_ARCHIVE_INDEX.csv',raw)
    preflight=json.loads((EXPORT/'P06_PREFLIGHT.json').read_text())
    checks=[]
    for entry in preflight['sourceChecks']:
        actual=digest(Path(entry['file']))
        assert actual==entry['sha256'],entry['file']
        snapshot=CAMPAIGN/'source_snapshot'/Path(entry['file']).relative_to(ROOT)
        assert digest(snapshot)==actual,snapshot
        checks.append({'file':entry['file'],'sha256':actual,'matchesPreflight':True,'snapshotMatches':True})
    for stem in ['record','settings']:
        assert digest(Path(preflight[stem+'File']))==preflight[stem+'SHA256']
    reliability={}
    for field in ['initializationRejected','identificationRejected','controlRejected','mappingActivations',
                  'oneStepForecastInvalid','inputViolationCountOver1e8Tolerance','incrementViolationCountOver1e8Tolerance']:
        values=[float(r[field]) for r in diagnostics]
        reliability[field]={'total':sum(values),'casesWithNonzeroCount':sum(x!=0 for x in values)}
    for field in ['primalResidualMax','stationarityResidualMax','dualResidualMax','complementarityResidualMax',
                  'allOutputViolationPeak','allInputViolationPeak','allIncrementViolationPeak']:
        values=[float(r[field]) for r in diagnostics]
        reliability[field]={'maximum':max(values),'nonfiniteCaseCount':sum(not math.isfinite(x) for x in values)}
    report={'rawFiles':len(raw),'rawTotalBytes':sum(r['fileSizeBytes'] for r in raw),
        'scalarFieldComparisonsWithRunnerTable':comparisons,'diagnosticCases':len(diagnostics),
        'scoreWindowRows':len(windows),'initializationScoreRows':len(initialization),
        'sourceChecks':checks,'immutableRecordsAndSettingsMatch':True,
        'reliability':reliability,'trajectoriesIncludedInCompactPackage':False,
        'bootstrapResampledInExport':False,'simulationsOrFitsDuringExport':False}
    with (EXPORT/'P06_POSTFLIGHT.json').open('x') as f:json.dump(report,f,indent=2)
    summary={k:v for k,v in report.items() if k!='sourceChecks'}
    print(json.dumps(summary,indent=2))

if __name__=='__main__':main()
