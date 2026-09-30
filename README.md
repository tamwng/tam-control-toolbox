# Structure-Informed Indirect Adaptive Predictive Control

MATLAB studies of nonlinear identification, prediction and constrained control. The software compares regressor structures and coefficient relations in an adaptive predictive controller. The results are exploratory numerical evidence, not general stability, feasibility or convergence guarantees.

**Requirements:** MATLAB and a licensed Optimization Toolbox (`quadprog`). The example has been tested with MATLAB R2026a Update 5 on Windows. Start MATLAB in the repository root.

## First example

```matlab
[output, summary] = run_example;
```

This runs one fixed, noise-free Shared-model example: 200 fitting transitions, 600 evaluation transitions and 120 seconds of control. It needs no previous results. A new `results/example_*` folder contains the saved calculation, metrics, settings and internal-check summary.

Inspect the saved result without rerunning:

```matlab
inspect_results(1,'confirmation_S_000',output);
resultFile = fullfile(output,'data','confirmation_S_000.mat');
checks = check_result(resultFile);
```

Add `'SaveTo',fullfile(output,'response.png')` to `inspect_results` to save the plot. Use a new output directory for each run.

## Studies

| Selection | Scientific question |
|---|---|
| `study1` | Regressor structure, identification and prediction |
| `study2` | Input range, measurement noise and constraints |
| `study3` | Parameter changes and forgetting |
| `study4` | Changes in represented and unrepresented dynamics |
| `study5` | Physical-parameter reconstruction |
| `study6` | Forecast and constraint diagnostics from Studies 1–5 |

Run a complete individual study, check it and plot its saved outputs:

```matlab
s1 = generate_results('study1',OutputDirectory='study1_run');
check_study_results('study1',s1);
plot_results('study1',s1);
```

Complete studies are substantially more expensive than the example. Study 6 requires explicit newly generated Studies 1–5 in the `Sources` option. Study 2 publication plots additionally require its canonical rank table; see the [verification guide](CROSS_PLATFORM_VERIFICATION.md).

For tuning and initialization sensitivity:

```matlab
run_sensitivity('plan');                 % List cases; no simulation.
run_sensitivity('case',Case='baseline_S_000');
```

The [sensitivity guide](studies/p06/README.md) explains the paired design. Inspect selected cases instead of plotting the entire campaign.

Optional complete reproduction is expensive: six studies plus 1,558 sensitivity cases.

```matlab
paper = generate_results('all',OutputDirectory='paper_run',ConfirmFull=true);
```

## Checks and reference comparison

Generation applies the applicable mathematical, solver, finite-value and constraint checks. `check_result` and `check_study_results` recheck saved calculations; `run_component_tests` runs the small public regression suite. These checks do not establish agreement with a reference.

Canonical comparison inputs are included under `results/`. Compare the saved example separately:

```matlab
referenceFile = fullfile(pwd,'results','study1_candidate_20260917', ...
    'data','confirmation_S_000.mat');
comparison = compare_reference(resultFile,referenceFile,'example_comparison');
```

For completed studies, use `compare_study_reference(sources,references,output)` with explicit generated and canonical directories. The [verification guide](CROSS_PLATFORM_VERIFICATION.md) lists the required parents and fixed numerical rules. Missing or altered reference data raises an error; comparison never silently downloads or substitutes data.

**PASS** applies to the reported checks. **FAIL** means a requirement failed. **QUALIFIED** records a specified limitation, including unresolved passive Gram diagnostics; it does not mean numerical equality. Comparing a run with itself is not independent verification.

`src/` contains the mathematical implementation; `studies/` contains study definitions and comparison routines; `tests/` contains public prerequisites; `results/` contains canonical inputs and new outputs. Keep the required reference paths and bytes intact.

## Citation and license

Software citation metadata is in `CITATION.cff`; terms are in [LICENSE.txt](LICENSE.txt).

The citation and DOI for the revised arXiv version will be added when that version is announced.
