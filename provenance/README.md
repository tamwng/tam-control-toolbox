# Source and numerical provenance

`verification/cleaned_source_relationship.json` maps the current files and scientific definitions to their original source identities. `verify_source_relationship` checks this mapping against a fixed offline anchor and verifies every declared current file. The original authority hashes and numerical policy remain distinct from current-file hashes.

The representative interface originates at `eeadd876f450d478b97769ac0ec47ba126176d7d`. Historical full cross-platform reproductions used different generating revisions:

| Record | Generating revision |
|---|---|
| Successful Mac FULL | `9855c14210643cc06908fb529afd47953413ed6c` |
| Successful Windows #2 FULL | `b8754a2938104f5843aebd60c4d51162223407f3` |
| Intervening Mac-to-Windows test-only bridge | `b506689fff4dde55b4a72b1de22b7469eea08417` |

Windows #1 remains the historical reference. Later Mac tests and QUICK checks are not another Mac FULL. Both successful FULL records used numerical-policy SHA-256 `ca9101ea01a6eb093664d383a3d6bd1734598ba84aed2ee35b28cfa7412aec58`.

Historical certificates apply to their recorded sources and executions. They are not inherited by later revisions. A representative run, saved-data comparison or component test does not establish execution of every paper study or a new cross-platform certification.

Original certificates, source inventories, numerical records, the test-only bridge and material failure witnesses retain their identities. Interpretation records are separated in `release-evidence/`; active numerical specifications remain under `evidence/` and `studies/p07/`.

Some canonical reference packages contain original run instructions, logs and source snapshots. Their paths and bytes are fixed by the [canonical membership inventory](../evidence/p07_gate_b/P07_SOURCE_SHA256.csv). These historical records explain the data; they are not instructions for ordinary package use. Public commands do not load a private restoration archive. See the [verification guide](../CROSS_PLATFORM_VERIFICATION.md) for current usage and interpretation.
