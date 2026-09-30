# Gate B orchestration exception, recorded before remaining cases

The first representative attempt stopped after 14 complete cases (12 P06, 2 Study 2), at whole-configuration equality for Study 3. Preserve its failed/stopped status and all results; do not rerun those completed cases.

The saved Study 3 cfg has an additional execution field:
"Deterministic runs sequential; mixed-noise trials in four local MATLAB processes with disjoint trial ranges. Control times are concurrent-run observations, not real-time guarantees."

Current study3_settings has no execution field. Its only source consumer is study3_prepare, which copies the description into environment metadata. This is execution provenance, not a scientific setting or simulation input. The original generic whole-structure assertion conflated these.

The remaining-case harness first requires exact equality of every other saved/current configuration field. It saves both scientific configurations and the historical execution description. All numerical/discrete comparison rules remain exact, with no tolerance changes. The remaining runs are sequential, as already authorized. This is an orchestration correction, not a change to pre-refactor source, scientific configuration, solver behavior, or historical evidence.