# Read-only manuscript/response scope check

No explicit strict nonzero advantage for the selected identity-null freezing contrasts was found in the inspected current v1 source and response passages. This is not a complete paper claim-map approval. Numerical performance claims outside these identities remain unchanged.

## sections/numerical_study/diagnostics.tex:33-50
SHA-256 `304fb3686a35e232d0087961f9e8e484b3df20e8d6531d9178dbd7f56d797d0e`

```tex
Define the terminal model, freezing, and total errors by
\begin{equation}
 e_H^{\mathrm m}=z_H^{\mathrm n}-z_H^\star,\qquad
 e_H^{\mathrm f}=z_H^{\mathrm a}-z_H^{\mathrm n},\qquad
 e_H^{\mathrm t}=z_H^{\mathrm a}-z_H^\star.
 \label{eq:num-decomposed-errors}
\end{equation}
These errors satisfy
\begin{equation}
 e_H^{\mathrm t}=e_H^{\mathrm m}+e_H^{\mathrm f},\qquad
 (e_H^{\mathrm t})^2
 =(e_H^{\mathrm m})^2+(e_H^{\mathrm f})^2
 +2e_H^{\mathrm m}e_H^{\mathrm f}.
 \label{eq:num-decomposition-identity}
\end{equation}
RMS errors use the same query set, and the mean cross term is retained.
At $H=1$, the freezing error is zero to numerical tolerance.
For a complete affine learned map, it is zero at every horizon.
```

## sections/numerical_study/diagnostics.tex:129-170
SHA-256 `304fb3686a35e232d0087961f9e8e484b3df20e8d6531d9178dbd7f56d797d0e`

```tex
First-step freezing errors are zero to numerical precision and omitted
from the logarithmic axes.}
\label{fig:study6-main}
\end{figure}

The held-input comparisons separate this effect from identification error.
For the shared Plant A model and the exact-sine Plant B model, the freezing
errors remain at numerical roundoff when the input is held at its
linearization value. At fixed input, both reconstructed maps are affine
in the state, so the frozen predictor reproduces their nonlinear rollout.
This property does not hold for the nonlinear state dependence of Plant C.
The integrated physical model for Plant C has a held-input freezing RMSE of
$1.866\times10^{-2}$~rad\,s$^{-1}$ at one second, compared with a
nonlinear-model RMSE of $1.002\times10^{-4}$~rad\,s$^{-1}$.

The signed cross term in the squared-error decomposition is retained.
Model and freezing errors can partly cancel; their mean-square errors
cannot simply be added. The first-step freezing errors are at numerical
roundoff, and complete affine models reproduce their nonlinear forecasts
at every tested horizon. All archived forecast paths are finite.
These diagnostics under prescribed input sequences isolate prediction effects.
This fixed-model forecast comparison is separate from the receding-horizon
closed-loop comparison and does not establish a closed-loop performance
ordering. The receding-horizon controllers receive new measurements and
reconstruct their predictors at subsequent control instants.\EJCAuditMargin{N23}

\paragraph{Initialization and unforeseen changes}
Separate audits initialize learned forecasts from $y_k$ or cross an actual
plant change. Their total errors include initialization or future-change
effects in addition to the terms isolated above. Neither effect is
attributed to dictionary approximation or affine freezing.

The measurement-initialization audit uses only the saved Study~1
queries. Even the known-model reference has a nonzero error when prediction
starts from the measured rather than the true state.
For held-input forecasts, the median initialization-contribution RMSE over
the 40 archived noisy trials is $6.331\times10^{-3}$ at one step and
$2.650\times10^{-4}$ at ten steps.
The nonlinear-model and freezing contributions are at roundoff in this
particular known-model comparison, so the remaining error is attributable
to initialization. The observed decay applies to these trajectories, not
to arbitrary nonlinear plants.
```

## appendices/numerical_protocol.tex:379-401
SHA-256 `9dda8995c16a9245ab09fa37153c4e83b0974176727a9c3b44f1363c1f6f65f9`

```tex
% "For repeated trials, report attempted and completed counts."
% Preserve the subsequent pilot/confirmation paragraph and its PENDING note.
For the repeated-trial comparisons, Table~\ref{tab:ejcArchivePaired}
reports selected median within-pair differences and the stored 95\%
paired-bootstrap intervals from 2,000 resamples. A difference is the
first-listed score minus the second-listed score; its median need not
equal the difference of the two marginal medians. Every listed contrast
has 40 attempted, complete, and finite pairs. The intervals are
contrast-specific summaries, not simultaneous confidence intervals.
The prediction contrasts use the independent evaluation record after
200 noisy fitting transitions. Tracking contrasts retain the stated
whole-run, event, and late windows, including their reference-preview
effects. No new bootstrap samples or closed-loop runs are generated
for this reporting addition.\EJCAuditMargin{Archive-P08-P}

\begin{table}[tbp]
\centering
\caption{Selected paired RMSE differences from the existing noisy
comparisons. Every row has 40 complete finite pairs and 2,000 stored
bootstrap resamples. Differences are in dimensionless state units.
Positive differences indicate a smaller score for the second-listed
case, not a general controller advantage.}
\label{tab:ejcArchivePaired}
```

## responses/responses.tex:109-118
SHA-256 `063d6080d16581a2bbd6b7ab7a316ee1b92ac00bbec1f2df69596b20329997ec`

```tex
% Baseline: EJC_archive_reporting_annotated.pdf (59 pages). Recheck locators after compiling.
Thank you for your comment. The revised formulation replaces the former feature-scheduled predictor and its exactness statement. At time $t_k$, the input $u_k$ is already committed and the controller computes $u_{k+1}$; the completed transition was generated by $u_{k-1}$ (Section~2.2, pp.~6--7). The reconstructed nonlinear map and its Jacobian are evaluated at $(\xi_k,u_k)$, with the affine offset retained (Section~5.1, p.~14).

Equations~(33)--(37) (pp.~14--15) consequently give
\[
  \xi_{1|k}=c_k+A_k\xi_k+B_ku_k=\widehat F_k(\xi_k,u_k).
\]
Thus, the first affine prediction agrees with the identified nonlinear predictor, not necessarily with the plant. This is zero first-step freezing error, not zero plant-model error. Later predictions need not retain this agreement, and the control horizon uses $N\geq2$.

To address the requested trajectory-based assessment, Section~6.5 and Table~12 (pp.~43--44) report forecasts from 29 origins, at $t_k=2,4,\ldots,58$~s, on each of the six noise-free stationary Plant~A control trajectories. The online model at each origin is held fixed while the subsequently recorded applied inputs are replayed for horizons $H\in\{1,2,5,10,20\}$. These are retrospective within-run diagnostics, not the original QP input plans or forecasts assuming that the later inputs were known. They are reported separately from the common-query comparison and cover the stated origins rather than every sample of every study.
```

## responses/responses.tex:333-351
SHA-256 `063d6080d16581a2bbd6b7ab7a316ee1b92ac00bbec1f2df69596b20329997ec`

```tex

% SLOT 26 | R2-C6 | DONE
% CURRENT LOCATION: Sec. 6.5, Eqs. (64)-(66), pp. 39-40; Table 11, p. 41; Fig. 6, p. 42; interpretation, pp. 40-41
\EJCDeclareResponse{R2-C6}{%
% Author-response payload only. Preserve the existing reviewer comment verbatim.
% Baseline: EJC_archive_reporting_annotated.pdf (59 pages). Recheck locators after compiling.
Thank you for your comment. We added a separate diagnostic of the approximation used by the controller. Section~6.5 compares the identified nonlinear model propagated recursively with its frozen-affine approximation and the true plant map. The forecasts use common initial states and both held and rate-limited input sequences, so the comparison separates nonlinear-model error from affine-freezing error.

Equations~(64)--(66) define the errors (pp.~39--40), Table~11 reports the one-second comparison (p.~41), and Fig.~6 shows horizon dependence for $H\in\{1,2,5,10,20\}$ (p.~42). The text discusses the held-input versus rate-limited conditions and their different effects across plants (pp.~40--41). These results characterize prediction under the stated queries; they do not provide a universal operating-region characterization or rank closed-loop controllers.
}

% SLOT 27 | R2-C7 | DONE
% CURRENT LOCATION: Sec. 6.5, pp. 39-44; Table 11, p. 41; Fig. 6, p. 42; Table 12, p. 44
\EJCDeclareResponse{R2-C7}{%
% Author-response payload only. Preserve the existing reviewer comment verbatim.
% Baseline: EJC_archive_reporting_annotated.pdf (59 pages). Recheck locators after compiling.
Thank you for your comment. We agree that one-step accuracy alone does not establish multistep accuracy. Section~6.5 now reports nonlinear-model, freezing, and total forecast errors over $H\in\{1,2,5,10,20\}$, with the model estimates held fixed during each forecast. See Eqs.~(64)--(66) (pp.~39--40), Table~11 (p.~41), and Fig.~6 (p.~42). Table~12 (p.~44) additionally reports total multistep forecast errors along the selected stationary Plant~A control trajectories. The two diagnostics retain their distinct query definitions.
}

```
