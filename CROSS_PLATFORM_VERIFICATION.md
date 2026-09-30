# Reproduction and numerical verification

Use `run_example` to generate the fixed Shared-model example, `check_result` to inspect internal validity, `inspect_results` to view a saved response, and `compare_reference` to compare that saved example with a separately identified canonical record. These are distinct activities. None requires or produces a historical source certificate.

## Representative comparison contract

The supported record is Study 1, model `S`, campaign `confirmation`, trial 0, with the unmodified `study1_settings`. The generated file contains `result`, `cfg` and its generated input `records`. The reference must be the canonical `study1_candidate_20260917/data/confirmation_S_000.mat`, SHA-256 `4ba023851eec31b4dc4a9ac118c1ec1c3a0086fb009deb94f1342d07281c44e6`. Supply the file explicitly; no reference is inferred from an existing output folder.

`compare_reference(resultFile,referenceFile)` first checks missing inputs, distinct paths, canonical identity, policy/inventory bytes, fixed settings and own-result validity. It then calls the existing `ejc_compare_representative` implementation once. Saved field order, class/shape, discrete outcomes and applicable numerical requirements are preserved. `controlTime` remains the declared wall-clock exclusion. Output includes all field outcomes, parent matrix checks and qualified Gram diagnostics. A missing/wrong reference raises an error before comparison; other failed or blocked checks retain `passed=false` and a reason.

The released specification is available locally:

- [Effective numerical policy](studies/p07/p07_acceptance_policy.json), SHA-256 `ca9101ea01a6eb093664d383a3d6bd1734598ba84aed2ee35b28cfa7412aec58`.
- [Complete field inventory](evidence/p07_acceptance/full_field_coverage.csv), including the representative's fixed F3879–F3957 field mapping.
- Field units are described below. The [qualification implementation](studies/p07/ejc_p7_qualify.m) fixes the 19 permitted passive Gram scopes.
- [Claim applicability](evidence/p07_acceptance/freezing_identity/CLAIM_APPLICABILITY.csv) for the retained full-study specification; it does not enlarge the representative command's coverage.

These are frozen numerical specifications, not private certification directories. Their historical identifiers are retained to identify the exact rules. Public generation needs no historical dataset, source-pin certificate or private audit archive. Complete-study comparison separately checks each supplied package and its source dependencies.

## Strict and portable comparison

The low-level `ejc_compare_results` function has two modes. Without its optional adapter it requires exact scientific values, classes, shapes, ordering and nonfinite masks; CSV numbers are compared at their stored precision and underlying MAT arrays are checked separately. Only declared timing/source metadata, the named legacy forecast flags and the separately evaluated sensitivity baseline maxima receive their specified treatment.

`compare_study_reference` supplies the portable adapter. Each scientific field then uses its own fixed policy family and required saved-data parents. There is no single tolerance for an entire file. Exact requirements, scoped representation allowances, claim checks and qualified matrix diagnostics remain distinct. Neither mode reruns a simulation or turns an unavailable reference into agreement.

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

## Complete studies and supplied references

`generate_results('study1')` through `generate_results('study5')` execute the complete selected study with the applicable component and own-record checks. Study 6 requires explicit newly generated parents in `Sources`. Sensitivity provides `run_sensitivity('plan')`, a named `case`, and an explicitly confirmed `all`. These commands do not read historical results. The complete selection `generate_results('all',ConfirmFull=true)` is expensive and is separate from reference comparison and historical certification.

`check_study_results` rechecks a completed saved package; `plot_results` exports saved study figures. The ordinary `inspect_results` viewer remains independent of reference material. Publication plotting for Study 2 also requires the canonical rank CSV and its original source relationship.

For general comparison, supply explicit local directories to `compare_study_reference(sources,references,output)`. The following names identify the canonical roots in the frozen membership inventory, not download URLs:

| Structure key | Canonical dataset identity |
|---|---|
| study1 | study1_candidate_20260917 |
| study2 | study2_pilot_20260918 |
| study3 | study3_pilot_20260918 |
| study4 | study4_pilot_20260922 |
| study5 | study5_pilot_20260922 |
| study6 | study6_pilot_20260922 |
| p06 | p06_sensitivity_20260924_225708 |

The local resolver verifies each supplied canonical file against [the immutable membership inventory](evidence/p07_gate_b/P07_SOURCE_SHA256.csv). A copied comparison dataset must retain the required MAT/CSV relative paths and hashes. The inventory describes the original complete snapshot; unused historical prose, scripts and rendered figures are not required distribution inputs. Study 6 comparison requires both explicit five-study parent sets. Sensitivity comparison requires the canonical Study 1 records and saved cases for the original twelve-case/204-check baseline reduction; no new simulation is performed by that comparison. The baseline table is separate comparison evidence and does not modify generated data.

Study 2 publication export additionally needs `gram_numerical_rank_check.csv`, identified as `results/study2_journal/gram_numerical_rank_check.csv` in the same inventory, and its canonical Study 2 parents. Missing files or parents, incorrect identities, incomplete generated outputs and self-reference are failures/unavailable outcomes, never PASS. The resolver neither downloads nor substitutes data. The repository includes the required canonical MAT/CSV inputs under `results/`. Their paths, sizes and SHA-256 hashes remain those in the original membership inventory. Keep these records separate from newly generated results and supply the listed directories explicitly. The stored reference bytes are preserved during Git checkout and archive export. Missing or altered records fail verification.

Before complete-study comparison, `verify_source_relationship` checks the current files and scientific definitions against `verification/cleaned_source_relationship.json` and its fixed offline anchor. The comparator also checks generated-package identities, canonical references and source bindings. A source-identity check alone does not establish numerical agreement. A relationship that is not enabled for comparison returns an error; explicitly requested provisional comparisons never return overall reference PASS. The fixed-example command has the separate contract described above.

A component test, saved fixture or representative run does not establish execution of every study or a new cross-platform certification. Historical generating revisions and retired evidence remain recoverable from Git history and the author’s backup. The current source relationship verifies only its declared scope; it does not transfer a historical certificate to a new revision.
