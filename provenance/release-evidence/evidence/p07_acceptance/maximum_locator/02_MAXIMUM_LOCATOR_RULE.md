# Binding rule — a passive maximum locator is not automatically an exact invariant

## Authorized scope

Source scope: F0698, Study 2 `tables/run_diagnostics.csv`, `qpConditionMax`.
Confirm this mapping against the current full inventory before binding it.

Apply to **every eligible instance of this scope**, not only model K, amplitudes
0.2/0.6, or indices 148/348/548. Eligibility is defined below, not by observed
failure or discrepancy magnitude.

Verified exact copies of this same source quantity may inherit the treatment only
with unchanged semantic row keys, run identity, selection, units, source-value
and CSV-representation checks. Do not wait for an exact alias to fail before
checking it. Do not extend by fuzzy field-name matching. Inventory other extrema
sites during the consolidated preflight, but do not automatically apply this
amendment to different scientific quantities or unsupported scopes.

## Prerequisites — all remain mandatory

1. **Same experiment and selection.** Source identities, model, amplitude, timing,
   full selected index set, dimensions, classes, finite/applicable masks, counts,
   weights, units and original selection convention match. No reordering,
   omitted maxima, approximate joins, or changed window definitions.
2. **Passive locator only.** The index locates a descriptive condition maximum;
   it does not determine a controller action, a recovery/event/activation time,
   a claimed ordering or timing, or a scientifically selected example. Check the
   current claim map. Missing or contradictory applicability blocks this route.
3. **Valid resolved parents.** Retain every existing QP matrix, decomposition,
   spectrum, condition-envelope, solver, constraint, finite-value and outcome
   requirement. In particular, no Gram exception or matching Inf rule applies.
4. **Full-history numerical agreement.** Every selected corresponding unrounded
   condition entry must satisfy the existing P6 bound:

       |c_i - r_i| <= delta_i,   delta_i = 1e-8 + 1e-7 |r_i|.

   Reuse the existing predicate and its units/finite handling. Passing only the
   aggregate maximum or a rounded CSV entry is insufficient.
5. **Own-run exactness.** Recompute each maximum and its first maximizing index
   from that run's complete selected unrounded history, under the unchanged
   MATLAB reduction convention. Each stored source maximum/index, if present,
   must correspond to its OWN history. Retain both actual indices and exact
   maximizer sets. A wrong own-run index still fails. CSV views follow the already
   approved P13 representation rule, not a new equality to unrounded decimals.
6. **Maximum-value agreement.** The two independently reduced unrounded maxima
   must pass the unchanged P6 scalar rule; the exported values must retain the
   existing source/serialization checks.

## Comparing different maximizer indices

Let i_c and i_r be the first maximizers of c and r on the same selected index set.
Let M_c=c[i_c] and M_r=r[i_r]. If the indices differ, retain them and explicitly
check:

    0 <= M_c - c[i_r] <= delta[i_c] + delta[i_r]
    0 <= M_r - r[i_c] <= delta[i_c] + delta[i_r].

This is a **derived consistency allowance**, not a new empirical epsilon or an
increase to P6. With pointwise agreement, r[i_c] <= r[i_r] and c[i_r] <= c[i_c],
the inequalities follow directly by adding the two relevant pointwise bounds.
The independently checked maximum-value bound in prerequisite 6 remains in force.

Keep the exact source checks on matrices at each selected maximizing position.
Validate current/reference counterparts at the SAME index for both i_c and i_r,
as well as each run's own maximum witness. Do not demand equality between
matrices at two different times merely because each locally attains the maximum.
Do not skip already-required matrix checks elsewhere in the histories.

The supplied fixtures satisfy these numeric prerequisites, but local complete
source, validity and claim checks must still run. No current arbitrary tie-band
or a constant chosen from the observed 1e-11 differences is authorized.

## Verdict and data retention

For unequal indices with all prerequisites satisfied, record a distinct status,
for example `NUMERICAL_AGREEMENT_MAX_LOCATOR_DIFFERENT`.

Retain:
- old strict failure and original policy/candidate IDs;
- both histories' actual first indices, exact-maximizer sets and raw maxima;
- source hashes and selections, cross-index losses and derived budgets;
- independent maximum/source/parent/validity verdicts;
- `maximumLocationClaim = NOT_ASSERTED` and the verified claim-map location.

This means the maximum and its history meet reproduction requirements, while
**exact maximum-location agreement is not claimed**. Do not call it a reproduced
peak time, snap values, rewrite an index, create a canonical tie-breaker in the
scientific producer, or count it as an unresolved Gram condition.

## Regression requirements

Include both actual fixtures and synthetic tests demonstrating:
- same-index agreement and numerically tied different-index agreement;
- incorrect own-run first index or maximum remains a failure;
- equal aggregate maxima with an out-of-bound history remain a failure;
- changed selected indices/masks/counts/source keys remain failures;
- nonfinite, unresolved, indefinite/invalid required QP parents remain failures;
- an asserted maximum-time/event or active index is not eligible;
- exact source aliases inherit only after all parent/source checks;
- other condition/scientific fields retain their previous behavior;
- all assertions after the old stopping point still execute; no catch-and-skip.

No new scalar/trajectory/condition/spectral tolerance is authorized. The amended
cross-index requirement must be versioned because it changes the effective
acceptance policy even though numerical constants do not change.
