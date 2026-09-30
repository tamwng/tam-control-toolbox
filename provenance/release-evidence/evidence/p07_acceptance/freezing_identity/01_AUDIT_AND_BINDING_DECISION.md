# P07 — freezing-error contrasts: audit and binding disposition

## Decision

Approve a **versioned, post-failure, identity-based claim-applicability amendment**
for the narrowly specified Study 1 `freezingRMS` paired contrasts. Combine it with
the preceding approved algebraic-cross-term amendment, then complete verifier
integration and gates. This is not a new numerical tolerance, a statement that
the old run passed, or a global waiver of statistical/reproducibility checks.

The old candidate remains
`894eba817eaa43b882f849c5f830f64a8d6dbe39`; its frozen policy SHA-256 remains
`05c20f48e37a352f62ad3fb8975b7803be10ecd9e528bfeff61ac5005c97c451`.
Its full run remains FAILED under that policy. A new candidate and policy have
not been created by this audit.

This amendment is motivated by the observed failures. Documentation must not
claim it was specified before the failed Mac experiment.

## 1. What was actually checked

Input: `P07_CROSS_TERM_SCOPE_BLOCKER_COMPACT.zip`, SHA-256
`a4a6cf746d7019dc015cd980cf8b411801391b387ec884d8bfb17bb8ad3b54eb`.

- All 55 manifest-listed files match their byte counts and SHA-256 values.
- All 52 reported failed leaf values were checked using their binary64 hex and
  17-digit CSV values. Their row keys and reference values match the full
  historical paired table from an earlier supplied archive.
- The 30 new failed leaf checks comprise 12 median-sign checks and 9 distinct
  interval-zero checks, each of the latter reported at both endpoint fields.
  They affect 18 unique `freezingRMS` rows, not 30 different experiments.
- The largest failed-leaf difference is `1.0142340682799299e-16` dimensionless
  state units. All 52 pairs satisfy the unchanged numerical comparison even
  without adding a CSV serialization allowance. Magnitude is descriptive,
  not the eligibility rule.
- Ten of the 18 new failed rows are H=1 cases. The other eight use held input
  and contrasts among A/S/W/R models. All are covered by the identities below.
- Seven affected rows have one noisy pilot pair; eleven have 40 pairs in the
  archive campaign named `confirmation`. That campaign label does not establish
  independent confirmation.
- The complete historical paired table has 480 rows. The definition-based selector
  covers 40 rows / 120 median-and-endpoint cells, including already-passing rows.
  It is not a whitelist of the 18 failed rows.
- The historical measured-audit CSV supplies 1,066 unique contributing noisy
  trial/model/horizon/mode rows for this selector. Their query counts/validity are
  complete, and their largest `freezingRMS` is `3.17551626405881e-16`. This is a
  check of serialized historical parent scores, not a claim to have inspected
  every current raw per-query error.
- Exact copies of `study1_model.m`, `study1_measured_audits.m`, `freeze_predictor.m`,
  `forward_map.m`, and `direct_model.m` were recovered from prior supplied sources;
  each hash matches C0's 261-file dependency manifest. They support the identities
  and the definition of the measured-initialization freezing error.

The auditor did not execute MATLAB, inspect the live repository, or independently
hash the 1.36 GB protected tree. The package reports its integrity and the 258/258
original Study 1 validity result. Current raw per-query error arrays and full
current bootstrap parents remain local. They must be checked by the implementation
before using the new classification.

An older `study1_summarize.m` snapshot was inspected for context, but its hash is
NOT the C0 summarizer hash. The exact C0 summarizer is locally available and must
be verified and used. It must not be replaced by the older snapshot. This audit
does not claim independent reproduction of current full bootstrap calculations.

See `02_INDEPENDENT_CHECKS.json` for precise checks and limitations.

## 2. Mathematical reason for the bounded treatment

`freezingRMS` is the RMS of `audit.freezingError`, where the pinned producer defines

    ef = zAffine - zMeasured.

Both predictions start at the SAME measured state for this diagnostic. The true
plant forecast can start elsewhere; that changes model/initialization error,
not this identity. Parameter estimates and affine coefficients are held fixed
within each forecast.

### Identity A — first-step value contact

The implementation sets

    c = F(y,u0;theta) - A*y - B*u0.

Consequently, in exact arithmetic,

    zAffine_1 = c + A*y + B*u0 = F(y,u0;theta) = zMeasured_1.

The H=1 freezing error is zero for every listed differentiable Study 1 model,
including P2, regardless of estimation error or measurement noise. Both input
modes begin with the same u0. This is NOT zero plant-model error or zero tracking
error.

### Identity B — held input and affine dependence on state

For A, S, W, R (and K's verified shared form), the pinned model definitions have

    F(x,u;theta) = alpha(u;theta) + beta(u;theta)*x.

At fixed u=u0 the affine predictor is exactly this same state map. Its derivative
A=beta(u0;theta) and its combined offset c+B*u0=alpha(u0;theta). Starting the two
recursions at the same measured state proves by induction that their freezing
error is zero at every finite horizon, in exact arithmetic.

This is true even for incorrect sharing W: representation accuracy with respect
to the plant is irrelevant to being affine in x for fixed input. It does NOT
apply generally to P2 at H>1, to changing inputs for S/W/R, or to Plant C.

### Consequence for the paired statistics

When BOTH members meet one of these identities, each exact-arithmetic
`freezingRMS` is zero; every paired difference is zero. The finite-precision
median signs and tiny bootstrap endpoint signs then describe residual arithmetic,
not a model's advantage in approximating the plant. The paper claims first-step
contact and held-input freezing agreement, not a strict direction for these
particular paired zero-error contrasts.

The code's computed values and intervals are still real saved outputs and MUST
remain unmodified. Do not say the machine values were exactly zero or that their
literal sign/interval classifications reproduced. Retain them as diagnostic
information. An ordinary reported tracking/prediction comparison or a non-null
freezing comparison has no exemption under this argument.

For a one-pair pilot, resampling that sole observed difference always returns the
same difference. A saved `[d,d]` interval therefore adds no independent information
about sampling uncertainty. This explains the degenerate pilot entries; it is not
a general exemption for one-pair tables. Do not rewrite or regenerate those tables.

## 3. Authorized scope and required predicates

Only this additional scope is authorized:

- study: `study1`;
- file: `tables/measured_initialization_paired_contrasts.csv`;
- metric: exact `freezingRMS`;
- fields: `medianDifference`, `lower95`, `upper95` (existing F0301/F0302/F0303;
  verify identifiers against the live inventory);
- audit type: exact `within-run measured-initial-state sensitivity`;
- existing campaign labels, contrasts, modes, horizons, trial memberships and
  source identities remain unchanged.

Select by verified definitions, NOT row number, observed sign, or magnitude:

    first_step = horizon == 1
    held_affine = inputMode == 'held'
                  AND left model in {A,S,W,R,K}
                  AND right model in {A,S,W,R,K}
                  AND pinned sources verify their affine-in-state structure
    eligible = first_step OR held_affine

The actual table's four contrasts are S-A, S-W, S-R and R-P2. No new contrast is
being authorized or invented. For R-P2 only H=1 qualifies. `03_IDENTITY_SCOPE_ROWS.csv`
lists all 40 historical selector matches to aid testing; it is not a substitute
for source-based dispatch and does not itself confer a pass.

Before assigning the new status, ALL of the following must pass:

1. C0 source/policy/reference integrity and exact row keys, shapes, units, masks,
   trial identities, counts, input mode and horizon checks.
2. Verified parent links to the two models' measured-initialization audit arrays
   and their online snapshots. Parameters remain fixed during the forecast;
   both predictors start at the same measured state; held means u0 is replayed
   throughout the selected forecast, not merely an increment-limited input.
3. All prescribed parent queries and trials are finite and valid. Do not discard
   queries, pairs, endpoints or failing runs.
4. A per-parent check on the actual selected `freezingError` entries against the
   ALREADY EXISTING dimensionless 1e-11 first-step/affine-contact accuracy criterion
   in the pinned Study 1 producer. Reuse that numerical value unchanged for the
   source-proved held-input affine-in-state identity. This is an additional
   identity-specific guard, not a newly enlarged agreement tolerance. Apply it
   to each model, not just their difference: equal large errors must fail.
5. Existing P11 numerical agreement of medians/endpoints, P13 CSV/source checks,
   and parent metric/reduction/paired-bootstrap correspondence, with the original
   seeds, resample membership, percentile conventions and interval ordering.
6. All original scientific validity/constraint/identity/outcome checks remain
   mandatory, as do all existing published performance and interval claims.

If a historical per-query parent is genuinely unavailable, do not silently replace
it with a matching sign or a small contrast. A supplied RMS and verified finite
query count can bound the maximum error by sqrt(count)*RMS, but source/serialization
budgets and both sides must be accounted for. Prefer the locally retained arrays;
stop with a grouped report if a necessary parent cannot be validated.

For eligible, fully checked rows only, do NOT require exact raw median sign or
exact interval-zero containment as a scientific claim. Record an explicit status,
for example `NUMERICAL_AGREEMENT_STRUCTURAL_NULL_CONTRAST`, with:

- `identityClass`: FIRST_STEP_CONTACT or HELD_INPUT_AFFINE_IN_STATE;
- original values, signs, interval endpoints and raw zero-containment booleans;
- original strict verdict and amendment/version identity;
- both parent identity-residual maxima and applied unchanged limits;
- numerical-comparison and source/validity verdicts;
- `directionalClaimApplicability`: NOT_ASSERTED_FOR_STRUCTURAL_NULL;
- explicit statement: statistical-significance agreement is NOT being claimed.

All noneligible rows retain their exact existing guards. Explicit claimed
non-null signs/orderings or confidence conclusions retain their requirements.
An unrecognized model, changed source, unsupported mode or missing link blocks.
Do not turn off `signedContrast` or `intervalZeroContainment` globally, declare
all freezingRMS values negligible, or apply this rule to parameter/total/model/
tracking errors. Do not edit figures or statements to make a conflicting claim
disappear.

## 4. Relationship to the already approved cross-term amendment

The previous amendment covers the source-verified algebraic `meanCrossTerm` and
`meanCombinedCrossTerm` diagnostics and their descriptive summaries. It remains
as specified, with unchanged numerical/source/identity checks and explicit claim
mapping. The extra 22 failed cross-term leaf checks in this package remain part
of that prior scope. They are not 22 newly approved performance exceptions.

This handoff adds ONLY the identity-backed freezing-error-contrast scope above.
It supersedes the prior blanket instruction that no non-cross-term P11 row may
receive an applicability distinction, to this explicit extent only. Every other
restriction remains in force.

The repeated stops expose a design mismatch: exporting a statistic is not, by
itself, making a scientific claim about its strict sign. Correct that dispatch
semantically while preserving quantitative verification. Do not replace it with
case-by-case magic tolerances or a failed-row whitelist.

## 5. Execution and commit boundaries

Finish both approved amendments and their regressions. Recheck ALL 535 saved
Study 1 files, all 480 rows of the affected paired table, and every required
parent, not only the known failures. Run all mandatory lifecycle/source gates;
collect other safe, independent saved-data blockers in a single report if any
remain. A missing required check is not a pass.

After those gates pass, create NEW candidate and policy identifiers. The old C0
run remains failed. The user's latest instruction is a clean final verification:
Mac quick, then the entire full suite from the beginning on the same new commit
and policy, in a new output directory. This replaces the prior option of reusing
Study 1 results for the final full-suite verdict. Old outputs remain useful as
verifier fixtures, with their original producing identity.

No policy edits during the decisive new run. A subsequent mandatory failure stops
the run; do not quietly tune the policy. Passing a re-execution after policy design
shows reproducibility under the disclosed policy, not independent statistical
confirmation or proof of universal cross-platform portability.

Windows #2 must ultimately use the same new candidate/policy. Preserve any C0
outputs there; do not claim different policies represent one final protocol.
Do not change a shared checkout while a run is active.

## 6. Paper correspondence and scope

The latest available audited manuscript checkpoint is
`EJC_editorial_precision_annotated.pdf` (59 pages). Section 6.5, pp. 39–42,
states the first-step freezing identity, held-input affine-in-state interpretation,
and measured-initialization diagnostic. Table 4, p. 20, gives the relevant model
forms. Table A.17, p. 55, reports prediction/tracking contrasts, not the disputed
zero-freezing contrasts. Those reported performance conclusions remain protected.

P06 has subsequently been incorporated in Work's source; this audit does not
claim to have inspected a newer PDF not supplied here. Before final acceptance,
confirm that no newer manuscript or response asserts a strict nonzero advantage
for these identity-null freezing contrasts. Stop if one does. Do not edit prose
from this Mac task.

After final cross-machine results, repository documentation should distinguish
source/data integrity, numerical agreement, analytical identities, and explicit
scientific claims. Numerical sign at a structurally zero quantity is not a
scientific effect. Keep the retrofit history and qualifications transparent.
P07 is not closed by this handoff; P08 remains separate.

## 7. External background, not the basis for a blanket exception

MathWorks, "Floating-Point Numbers":
https://www.mathworks.com/help/matlab/matlab_prog/floating-point-numbers.html
Documents that roundoff and cancellation can produce nonzero computed residuals
for exact-zero expressions. It does not supply this project's acceptance limits.

MathWorks, "bootci":
https://www.mathworks.com/help/stats/bootci.html
Documents resampling with replacement. The project uses its own percentile
implementation; this citation does not establish that it calls bootci or uses
bootci defaults. The one-pair degeneracy and structural-null conclusion above
follow from the actual source definitions and elementary algebra.
