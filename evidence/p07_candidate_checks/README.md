# P07 interface checks before the committed candidate

These checks used the working source changes following baseline-evidence
commit `677258e4c676631806c9c8dd31f779004d511218`. They do not claim full-paper
reproduction. The expensive run must identify its later clean candidate SHA.
Core numerical functions under `src/` are unchanged.

| Attempt | Outcome |
|---|---|
| 01 | 130 checks passed; seven new comparator checks errored in collection construction. No scientific mismatch was evaluated. |
| 02 | Six comparator checks passed; missing/unexpected-file handling exposed scalar-string union orientation. |
| 03 | All seven comparator checks, 17 P06 checks, and the quick command passed. Archive regeneration stopped at P06 CSV logical flags; no archive was modified. |
| 04 | Archive regeneration passed using full-precision MAT items, including exact P06 summaries/bootstrap states, paper diagnostics, six journal figures, and before/after protected hashes. 83.7298072 s, excluding MATLAB startup. |
| 05 | Final root suite: 138 passed, zero failed/incomplete. This includes a successful inspection PNG export and overwrite rejection. Default `run_ejc('quick')`: 49 tests and exact fixed Shared trial 0 comparison, 7.533 s. Updated source-label report passed. |
| 06 | Comparator read all 2,877 scientific MAT/CSV files against themselves: all passed, maximum scientific difference zero. 198.328427 s. This checks reader/schema coverage only; it is not fresh reproduction. |

Fixes addressed collection/filename shapes and the archive reader. The P06
regenerator now takes only the saved run order from CSV and loads full-precision
MAT items for its statistics. No numerical method, acceptance tolerance,
experiment, seed, historical record, or expected controller ordering changed.
Original failed logs are retained; later attempts use separate output folders.
The 2,877-file reader check also verifies the final metadata-only mode label.

The original outputs are in `results/p07_candidate_checks_20260925_01` through
`_06`; the default quick output is `results/p07_quick_20260925_122543_764`.
Only compact logs, counts, manifests and test evidence are included here.
The complete per-file self-check evidence remains in attempt 06.

Cleanup review: no deletion is proposed. Legacy manuscript PDFs are already
absent from the working tree; historical journal/numerical artifacts remain
protected. No current manuscript PDF was added. No source outside the EJC
implementation was changed, and no historical archive was rewritten.
