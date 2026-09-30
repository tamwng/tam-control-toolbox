# Reproduction and numerical verification

Use `run_example` to generate the fixed Shared-model example, `check_result` to inspect internal validity, `inspect_results` to view a saved response, and `compare_reference` to compare that saved example with a separately identified canonical record. These are distinct activities. None requires or produces a historical source certificate.

## Representative comparison contract

The supported record is Study 1, model `S`, campaign `confirmation`, trial 0, with the unmodified `study1_settings`. The generated file contains `result`, `cfg` and its generated input `records`. The reference must be the canonical `study1_candidate_20260917/data/confirmation_S_000.mat`, SHA-256 `4ba023851eec31b4dc4a9ac118c1ec1c3a0086fb009deb94f1342d07281c44e6`. Supply the file explicitly; no reference is inferred from an existing output folder.

`compare_reference(resultFile,referenceFile)` first checks missing inputs, distinct paths, canonical identity, policy/inventory bytes, fixed settings and own-result validity. It then calls the existing `ejc_compare_representative` implementation once. Saved field order, class/shape, discrete outcomes and applicable numerical requirements are preserved. `controlTime` remains the declared wall-clock exclusion. Output includes all field outcomes, parent matrix checks and qualified Gram diagnostics. A missing/wrong reference raises an error before comparison; other failed or blocked checks retain `passed=false` and a reason.

The released specification is available locally:

- [Effective numerical policy](studies/p07/p07_acceptance_policy.json), SHA-256 `ca9101ea01a6eb093664d383a3d6bd1734598ba84aed2ee35b28cfa7412aec58`.
- [Complete field inventory](evidence/p07_acceptance/full_field_coverage.csv), including the representative's closed F3879–F3957 mapping.
- [Units and dispatch](evidence/p07_acceptance/UNIT_AND_DISPATCH.md) and [qualified Gram scopes](evidence/p07_acceptance/P7_QUALIFIED_SCOPE.csv).
- [Claim applicability](evidence/p07_acceptance/freezing_identity/CLAIM_APPLICABILITY.csv) for the retained full-study specification; it does not enlarge the representative command's coverage.

These are frozen numerical specifications, not private certification directories. Their historical identifiers are retained to identify the exact rules. Public generation needs no historical dataset, source-pin certificate or private audit archive. General multi-study/source-bound comparison remains a separate retained workflow; this representative command does not bypass its source guards.

## Numerical agreement

For current value a and reference b, the ordinary elementwise rule is:

`abs(a-b) <= absolute + relative*abs(b)`

The terms are additive, not an absolute/relative OR or a mean-error test. Many trajectory/metric fields use `1e-8` in declared coordinate units plus `1e-7*abs(b)`; Study 1 A1–A4, scaling, matrices and diagnostics have distinct subrules. Use the actual field dispatch. Unit scales are fixed beforehand, never estimated from discrepancies.

Schema, class, shape, selections/order, settings/seeds, discrete outcomes, masks, source membership and own-source copies retain exact requirements. Required numeric slots must be finite. Non-applicable slots use explicit NaN sentinels; meaningful infinite Gram conditions have separate rules. The 24 legacy omissions are two flags in each of 12 named Study 1 pilot records, with both fresh flags validated. The narrow Study 6 outer variable-order exception preserves nested values and structure.

## Independent validity and units

Accepted QPs require positive exitflag, finite plans and normalized primal, stationarity, dual and complementarity residuals at most `1e-7`. Solver constraint/optimality tolerances are `1e-8`. Reproduction limits do not replace these checks. Contact/forecast identities retain existing `1e-11` limits and scaling; physical reconstruction retains its original integration/refinement checks. Agreement cannot excuse an invalid solve, path or identity.

Plants A/B use dimensionless coordinates. Plant C uses rad/s for output/slack, N m for input, kg m² for J, and N m/(rad/s)³ for d. RMS uses state units; MSE/cross terms use squared-state units. Mean input increment is per transition, not per second. RLS covariance uses normalized-regressor coordinates, not physical uncertainty. Some frozen RMSE inventory labels and the mixed-coordinate `archiveComparisonMax` label are imprecise; use the explicit definitions and bound implementation. Do not aggregate them into a global physical error norm or rewrite frozen metadata.

## Matrices, claims and exports

RLS covariance, recent Gram matrices and QP Hessians have different roles. Matrix checks require parent entries, decomposition, symmetry/definiteness where applicable and source/coordinate checks. Only the 19 listed passive Gram scopes can qualify unresolved condition/rank diagnostics after prescribed pairwise guards pass. Matching original ranks/outcomes remain required. Covariance and Hessian have no generic waiver. `ejc_matrix_screen.m` and `ejc_p7_qualify.m` implement engineering screens, not interval-certified spectra or algebraic-rank proofs for nonzero matrices.

A qualification is **not numerical equality**. Reductions with unresolved contributors remain explicitly qualified. F0698's passive maximum-locator rule preserves each own first maximum and bounds both cross-index losses; it does not assert equal peak times. The Study 2 report binding and Study 3/4 own-record hooks have separate exact scopes.

Statistical checks preserve pairs, order, seeds, bootstrap counts and interval ordering. Directional claims retain sign/zero-containment requirements except at explicitly mapped descriptive or identity-null fields. Small magnitude alone grants no exception. Identity-null freezing contrasts require the specified contact/affinity and every selected parent's existing bound; there is no generic exemption for Plant C or P2 at horizons greater than one. Raw signs, endpoints and previous verdicts remain visible.

CSV checks preserve exact keys, source recipes and the known 15-digit writer contract. Bounded representation allowances do not establish equality of an absent historical unrounded scalar. Rounded tables or a compact subset cannot replace full field/parent checks.

## Read the outcome

| Outcome | Meaning |
|---|---|
| PASS | All required checks in the stated scope executed and passed; identify that scope and both inputs. |
| FAIL | A required check failed; retain the discrepancy and rule. |
| `PASSED_WITH_GRAM_QUALIFICATIONS` | Applicable requirements passed with retained unresolved passive Gram diagnostics; no blanket equality claim. |
| BLOCKED / unavailable / not run | A required input, identity, dependency or execution is missing. No reference agreement is established. |

## Complete-study and paper reproduction

The following existing routes are documented from inspected source and retained execution. They were not executed for the public-interface checkpoint. They need the retained reproduction environment and its canonical archives, active fixtures, exact source relationships and original certification inputs. An edited development tree cannot satisfy the old exact-source guard. Do not alter that guard or transfer an old certificate to new source.

| Selection | Existing route | Dependency and output scope |
|---|---|---|
| Study 1 | `run_study1('new_study1',Figures=false)` | Whole-suite prerequisites, pilot and confirmation, saved-data audits and tables |
| Study 2 | `run_study2('new_study2',Figures=false)` | Whole-suite prerequisites, degree/restriction/range experiments and diagnostics |
| Studies 3 and 4 | `run_ejc('study3')`, `run_ejc('study4')` | Retains required own-record callback registration, source bindings and comparisons |
| Study 5 | `run_study5('new_study5',Figures=false)` | Whole-suite prerequisites and physical integration/reconstruction checks |
| Study 6 | `run_ejc('study6',Sources=sources)` | Requires completed fresh `sources.study1` through `sources.study5` with matching identities; derives diagnostics |
| Sensitivity | `run_ejc('p06')` | Original fixed seven-setting campaign and baseline/reference checks; see [sensitivity guide](studies/p06/README.md) |
| Complete paper | `[output,sources] = run_ejc('full')` | Sequential Studies 1–6 and sensitivity, source/archive checks, comparisons, publication checks and figures |

The retained orchestrator also supports `run_ejc('study1')`, `run_ejc('study2')` and `run_ejc('study5')` for generation plus historical comparison. The lower-level drivers still call the complete test suite, which includes archive dependencies. Study 3/4 callback requirements and Study 6 source binding must not be disabled to make a smaller distribution run.

Existing `plot_study1_journal` through `plot_study6_journal` operate on saved study packages; their table/parent dependencies differ from the single-result viewer. `run_ejc('archive')` regenerates historical summaries and figures, not fresh science. None is a substitute for generating a new calculation.

Complete reproduction is an explicit expensive action, with no automatic retry/resume. Retained full runs took roughly eight hours on their recorded hosts; this is not an estimate for the small example. The original runner checks its declared environment and storage requirements. Public canonical-data hosting and a downloadable complete reproduction bundle are not established here.

Historical certificates remain attached to their exact generating source and evidence. Mac FULL used `9855c14210643cc06908fb529afd47953413ed6c`; Windows #2 FULL used `b8754a2938104f5843aebd60c4d51162223407f3`, under the same effective policy above. Later tests or a representative comparison do not certify this development snapshot or a future cleaned release.
