# Next workflow — collect verifier problems before another final full rerun

## Purpose and scope

The last full run stopped after fresh Studies 1 and 2. There is **no supplied fresh
Mac result for Studies 3–6 or P06**. Historical Windows self-comparisons can test
schema and internal consistency; they cannot establish Mac–Windows agreement.

Therefore do not promise a complete cross-machine preflight with no computation
if the necessary Mac results do not exist. Use what exists; generate only missing
diagnostic computation once when needed, using unchanged scientific functions.
This is a development/preflight campaign, not the decisive fresh full run.

## A. Inventory before computing

In the authorized MATLAB repository, list all stages, original validity checks,
portable comparisons, paper exports, plotting/source dependencies and available
outputs. Read manifest identities; do not assume a directory labelled 'complete'
or 'confirmation' proves completion or P08 confirmation.

Classify available outputs as:
- fresh Mac de77ad7 Study 1/2 outputs;
- older Mac fixtures, if actually present with demonstrated scientific-dependency
  identity and documented generating commits;
- historical Windows reference outputs;
- genuinely missing outputs.

Record producing and verifying commit/source-manifest hashes separately. Do not
modify or relabel original output directories. Preserve any already completed
Windows #2 run under its actual identifiers; do not change an active checkout.

## B. Complete read-only diagnostics on available outputs

With the tested amended verifier, recheck all 535 Study 1 outputs and all 46 Study 2
outputs, including the previously unprocessed `tables/run_metrics.csv`.

Run every accessible original and portable check and all affected paper/source
bindings. Use an isolated P07 collector that records independent failures rather
than aborting the entire investigation at the first comparison assertion.

Test all remaining historical sources for self-consistency and schema/binding
coverage. Label these SELF_CONSISTENCY, not CROSS_PLATFORM_PASS. Synthetic boundary
fixtures complement, but do not substitute for, real cross-machine comparisons.

Audit all remaining exact index/argmax/minimum/quantile-location requirements and
source/export inheritance sites as a GROUP. Distinguish fixed selection IDs and
scientific events from computed passive locators. Record the existing rule and
its scientific role; do not change any additional rule without authorization.

## C. Obtain missing Mac diagnostics once, if necessary

This prompt authorizes **diagnostic-only generation of missing existing study/P06
cases** needed for the consolidated inventory, not a new scientific experiment.

Reuse the existing verified plant/estimator/controller/study functions, exact
settings/seeds/records and original metrics. Do not duplicate, rewrite, retune,
reduce, enlarge or resample any scientific campaign.

Record the complete scientific-source and effective diagnostic-policy hashes
before execution. Keep them fixed throughout this diagnostic batch. Development
outputs may record a clean base commit plus an explicit verification-only diff
and dependency hashes; do not falsely label an uncommitted tree as a frozen
candidate. No final candidate commit is authorized in this session.

Prefer existing usable Mac outputs. Do not rerun the already generated 280
Study 1/2 controls merely because their comparison logic changed. Generate only
missing cases/stages in a new output area. Where no valid later Mac data exist,
computation for Studies 3–5/P06 is necessary; its runtime is not claimed to be zero.

Study 6 must use the explicitly selected Mac source studies for diagnostic
cross-machine testing; do not substitute historical Windows sources and call that
a Mac reproduction. A mixed-source self-test is permitted only with a clear label
and no cross-platform claim. Paper exports must similarly disclose their source
set. Do not silently fall back to historical tables.

## D. Failures remain failures, but independent diagnostics can continue

Preserve the normal production quick/full entry points' fail-closed behavior.
A new isolated collector, or a narrowly bounded verification-only diagnostic mode,
may gather independent checks while leaving the production mode unchanged.
A minimal P07 orchestration change is allowed; changes to scientific drivers or
algorithms are not. Stop if independent execution cannot be implemented within
that boundary.

- Source/config/reference integrity failure: stop the whole diagnostic batch.
- Invalid/nonfinite scientific output or a failed original scientific-validity
  check: preserve it, stop that dependency branch, and mark dependent work blocked.
  Independent valid stages may still be checked.
- Cross-run numerical, locator, claim, or source-binding comparison failure:
  record the actual failure and proceed to independent checks when source identity
  and scientific validity are established. Do not convert the failure to PASS.
- If a diagnostic later calculation uses scientifically valid Mac outputs whose
  cross-platform agreement failed, label that dependency and keep the combined
  reproduction verdict failed. Derived diagnostics do not certify their inputs.
- Missing prerequisites: record NOT_RUN / BLOCKED_DEPENDENCY, never a pass.
- No tolerance or rule changes during diagnostic collection.

The aim is one consolidated failure inventory, not a permissive success report.
Continue unrelated checks only when their inputs and interpretation are valid.

## E. Return and STOP before another final full run

Return `P07_CONSOLIDATED_PREFLIGHT_REVIEW.zip`, compact, with:

1. Tested verifier diff, source and effective-policy hashes; no invented new
   candidate identifier.
2. Regression results for document 02 and final integrated verifier tests.
3. Stage coverage table: fresh/reused/self-only/not-run status, producing source,
   verifying source, attempted/completed cases, files and mandatory checks.
4. Original FAILED verdicts, new diagnostic verdicts and qualified statuses
   separately. Include zero-count categories so absence is not ambiguous.
5. One grouped blocker inventory with coverage IDs, semantic keys, actual/ref
   values, rule, source/parent/claim meaning and compact fixtures.
6. Every maximum-locator site and source/paper alias audited; note which are
   covered by document 02 and which remain under unchanged rules.
7. Required versus completed totals from the actual frozen runner configuration:
   expected 2,877 scientific files, 2,073 controls and 329 Study 6 diagnostic
   batches in the supplied checkpoint. Account for every gap; do not assume these
   totals prove that all semantic checks executed.
8. Before/after protected integrity, original failed-run preservation, commands,
   environment and measured diagnostic runtime; retain large outputs locally.

If this diagnostic work encounters zero blockers, still return the package and
stop. HQ will approve the final verification start. Do not automatically pay for
another fresh end-to-end run in this session.

After all concrete blockers are settled: test and freeze one new candidate plus
its complete effective policy, run a fresh Mac quick/full from the beginning,
then Windows #2 on those identifiers. That final sequence is unchanged in intent.
A repeated fixed-seed run is numerical reproduction, not independent statistical
confirmation or proof of portability on all future platforms.

No cleanup, README overhaul, manuscript edits, public push/tag, or P07 closure.
