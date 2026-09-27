# Required regressions — add to the existing verifier suite

Preserve original strict C0 failures. Test the applicability selector separately
from the numerical comparator. No mutable whitelist of failed CSV row numbers.

1. All 30 new failed leaves / 18 unique rows: identity selector matches the
   correct source class; raw old sign/interval failures remain recorded.
2. All 40 eligible rows in the complete 480-row table: apply the same rule,
   including previously passing rows; do not select by observed result.
3. The remaining freezingRMS contrasts: retain existing P11 guards. In particular,
   R-P2 at H>1 and S-A/S-W/S-R with recordedRateLimited input at H>1 are NOT
   eligible merely because a scalar or coefficient is small.
4. First-step contact: every listed model at H=1 and each original input mode.
   Verify same measured starting state and same first input; mismatches block.
5. Held-input affine-state contact: A/S/W/R/K source forms with estimates held
   fixed. P2 at H>1, unknown features, modified source and changing input block.
6. Both parent error arrays checked against unchanged 1e-11 identity criterion.
   Inject identical large freezing errors into both models: their zero contrast
   must NOT conceal failure. Inject an identity failure in a single parent: block.
7. Alter source row/trial/query membership, unit, horizon, mode, validity, paired
   counts, bootstrap indices or seed: corresponding existing check still blocks.
8. Failed quantitative agreement cannot be rescued by structural-null status.
   NaN/Inf, invalid endpoints and missing parents cannot receive this status.
9. True published tracking/prediction/parameter/interval claim changes still fail,
   even where their numerical agreement test happens to pass.
10. Raw negative/positive/zero values and endpoint membership remain intact in
    reports; no rounding-to-zero, absolute-value conversion, row deletion, or
    claimed reproduction of statistical significance.
11. One-pair pilot retains original pair count and raw [d,d] output. Do not treat
    it as a 40-pair inference or silently alter resampling.
12. Previous cross-term amendment regressions still pass, including the 858
    original cross-term sign differences and the 22 additional leaf failures.
13. All saved-table source/serialization, Gram/covariance/Hessian, solver and
    original Study 1 validity tests still execute. No catch-and-skip wrapper.
14. Lifecycle tests distinguish tested policy from producing commit; final fresh
    quick/full execution must use the newly frozen identifiers and no old output
    directory or resumed trajectory results.

No requirement to fake fixtures for unavailable inputs. Use actual local saved
parents and synthetic negative fixtures where appropriate. Report any missing
coverage explicitly; do not label it tested.
