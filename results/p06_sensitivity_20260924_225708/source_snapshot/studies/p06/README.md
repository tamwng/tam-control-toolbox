# P06 implementation review

This separate runner implements the seven approved Study 1 sensitivity settings.
Production has not been launched. P06, P07 and P08 remain unresolved.

From the repository root:

```matlab
addpath('studies/p06');
run_p06('C:/path/to/new/p06_dry_run');
run_p06_tests('C:/path/to/new/p06_local_tests');
```

The default dry-run writes only `P06_RUN_MANIFEST.csv`. It reads the saved
Study 1 records/settings and hashes source files; it performs no fitting,
prediction, plant propagation, QP solution, bootstrap, or campaign execution.
The local tests use synthetic observations/mocks and copied saved baseline
cases. They do not call the global verification suite or generate study runs.

Only after separate production authorization:

```matlab
addpath('studies/p06');
run_p06('C:/path/to/new/p06_execution','execute','P06_PRODUCTION_AUTHORIZED');
```

The full proposal has 38 distinct combinations: five adaptive models times
seven OFAT configurations, plus three known-model input weights. Each has one
deterministic and 40 paired noisy runs, totalling 1,558. The first 12 are the
six nominal models at trials 0 and 1; a baseline mismatch stops the rest.
These 12 are included in the count. Old outputs are comparison references,
not substituted campaign observations. The known-model prior/length variants
are aliases, not extra runs. There is no fit cache: every adaptive case starts
from the original coefficients and selected normalized prior, fits its paired
record prefix, and passes the returned estimator directly into the unchanged
Study 1 trajectory routine. Both coefficients and covariance are preserved.

Only two existing files have approved changes: `study1_fit` accepts a positive
fourth argument multiplying its normalized initial covariance; the omitted
argument and 1 preserve baseline arithmetic. `study1_summarize('p06_helpers')`
returns handles to the unchanged run, fit, diagnostic and percentile helpers.
Its original two-argument path is untouched. No other existing source is edited.

Source data: `results/study1_candidate_20260917/data/records_confirmation.mat`.
The historical label is retained as an identifier. Pairing those records is
intentional sensitivity reuse, not independent confirmation. Seeds are 2101,
2102, 2200+j and 2300+j. The arrays are never regenerated. Fifty/100-transition
fits use the first 51/101 endpoint measurements and 50/100 inputs. Control noise
always starts from its first sample, independent of the chosen fitting length.
Scaling stays on the original fixed calibration grid. R varies only in the QP.

Whole-run metrics use [0,120); applied increments use mathematical k=1:1199.
The original unused terminal input is excluded. MAT files retain original
finite-prefix rows with status; complete-run table scores are NaN for incomplete
control. Prediction eligibility separately requires all 600 evaluation queries.
No recovery score or extra forecast campaign is added. Existing raw Gram
condition diagnostics are labelled as such, not as the corrected rank convention.

No standalone paired-bootstrap helper exists in Study 1; its resampling is
inline. P06 uses that same paired-median sampling convention and calls the
existing percentile helper. Analysis stream mt19937ar/7401 is separate from
plant/noise records. Stable order: configurations, pairs S-A/S-W/S-R/R-P2, then
prediction/tracking; next adaptive models A/S/W/R/P2, changed configurations
in manifest order, then prediction/tracking. Trial IDs are sorted. Initial,
pre-contrast and final analysis states are saved. Intervals are contrast-specific.

Predeclared future gate: fitted theta/beta/P and initialization prediction use
absolute and relative tolerances 1e-10; x/y/u/online theta/prospective prediction
use 1e-7 each; whole-run scores use 1e-8 absolute plus 1e-7 relative. Completion,
step counts, update acceptance and control acceptance must agree exactly.
Nonfinite masks must match. These are proposed engineering tolerances, not
claimed historical thresholds; they allow floating-point/QP roundoff without
allowing changed timing, records or failure decisions. Do not loosen them after
a mismatch. Timing and condition estimates are not reproduction targets.

The regression fixture was captured before either interface edit at base
05000a19bad01e52d852e1d63ac21f607d7596ae. It contains twelve-transition synthetic
fits and the unmodified summarizer outputs on two copied saved Shared cases.
It contains no newly generated plant trajectory. Local regression tests compare
whole returned structures exactly, not a preferred scientific ranking.
