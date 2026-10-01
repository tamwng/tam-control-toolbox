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

The [sensitivity guide](studies/sensitivity/README.md) explains the paired design. Inspect selected cases instead of plotting the entire campaign.

Optional complete reproduction is expensive: six studies plus 1,558 sensitivity cases.

```matlab
paper = generate_results('all',OutputDirectory='paper_run',ConfirmFull=true);
```

## Checks and reference comparison

Generation applies the applicable mathematical, solver, finite-value and constraint checks. `check_result` and `check_study_results` recheck saved calculations; `run_component_tests` runs the small public regression suite. These checks do not establish agreement with a reference.

Canonical comparison inputs are included under `references/`. Compare the saved example separately:

```matlab
referenceFile = fullfile(pwd,'references','study1', ...
    'data','confirmation_S_000.mat');
comparison = compare_reference(resultFile,referenceFile,'example_comparison');
```

For a completed individual study, comparison reuses its saved output:

```matlab
references = reference_directories;
comparison = compare_study_reference(struct('study1',s1),references,'study1_comparison');
```

Use the `sensitivity` key for the sensitivity dataset. The [verification guide](CROSS_PLATFORM_VERIFICATION.md) lists the required parents and fixed numerical rules. Missing or altered reference data raises an error; comparison never silently downloads or substitutes data.

**PASS** applies to the reported checks. **FAIL** means a requirement failed. **QUALIFIED** records a specified limitation, including unresolved passive Gram diagnostics; it does not mean numerical equality. Comparing a run with itself is not independent verification.

`src/` contains the mathematical implementation; `studies/study1`–`study6` and `studies/sensitivity` contain study definitions; `verification/` contains comparison functions and fixed specifications; `references/` contains supplied paper results; `results/` is for new output. `private/` holds MATLAB-only helpers, `tests/` holds the component tests, and `paper/` contains the accompanying preprint.

## Citation and license

Please cite the accompanying preprint and identify the software commit used for your results:

Tam W. Nguyen (2026). *A Numerical Investigation of Indirect Adaptive Predictive Control with Structure-Informed Nonlinear Regressors*. arXiv:2602.12016v2, 30 September 2026.

[Paper (PDF)](paper/2602.12016v2.pdf) · [arXiv v2](https://arxiv.org/abs/2602.12016v2) · [DOI](https://doi.org/10.48550/arXiv.2602.12016)

Paper and software citation metadata is in [CITATION.cff](CITATION.cff). The software uses the [BSD 3-Clause license](LICENSE.txt); the paper retains the license shown on its arXiv page.
