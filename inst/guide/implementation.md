# Implementation and milestone audit

This report maps the bounded, originally requested package scope to its
implementation. It is not a claim that every epidemiological method exists or
that this code is fit for clinical or public-health decisions without independent
validation. See individual help pages and the README for assumptions.

## Milestones

| Requested area | Implementation | Status and important boundary |
|---|---|---|
| Package structure and documentation | DESCRIPTION, NAMESPACE, LICENSE.md, README.Rmd; roxygen-generated man pages and testthat edition 3 tests | Implemented; source tree contains LICENSE.md and README.Rmd, which are excluded from the built tarball as redundant build inputs. |
| Tidy epidemiological classes | `epi_linelist()`, `epi_cohort()`, `epi_ts()` and vctrs/dplyr restoration methods | Implemented for supported row-preserving grouped and ungrouped operations. Summarizing, group_modify, rowwise conversion and untested operations may drop class or metadata; joins preserve left-side metadata only. Binding or casting with incompatible provenance is rejected. |
| Frequency | Incidence, prevalence, attack rate, person-time and proportion/rate intervals | Implemented as documented crude measures; cumulative incidence is a simple proportion and does not adjust for censoring. |
| Association and standardization | Risk, odds and rate ratios; risk difference; direct/indirect standardization; Mantel-Haenszel point estimate and test; adjusted models | Implemented with stated Wald, Poisson and model assumptions; no universal corrections or automatic heterogeneity assessment. |
| Diagnostics and clinical epidemiology | Diagnostic measures and intervals, ROC/AUC, predictive values, calibration, decision curves, survival, competing risks | Implemented with specified assumptions; these are not clinical validation. |
| Infectious-disease dynamics | Growth, doubling time, serial interval, descriptive and gamma-Poisson Rt, SIR/SEIR deterministic and stochastic simulators | Implemented; compartment models use discrete-time steps, not continuous-time ODEs; Rt and serial-interval methods have documented assumptions. |
| Recipe steps | Lag, rolling mean, rate and exposure-window steps; prep/bake/print/tidy/required_pkgs; explicit history helper | Implemented, with one-series row-order semantics. Current-row and later-assessment values can leak information. |
| Resampling | Rolling-origin and spatial-block CV with optional buffers | Implemented using rsample; spatial distances require projected coordinates and blocks supplied or created separately. |
| Evaluation metrics | WIS and net benefit, vector and data-frame methods, yardstick metric-set support | Implemented; use `wis_metric()` to capture interval columns for metric sets. WIS requires prediction intervals. |
| Parsnip models | Renewal and compartmental regression engines, fit/predict, model summaries | Implemented for the documented restricted models, with direct data-first fitting helpers; prediction uncertainty and many mechanisms are not modeled. |
| Broom and plots | tidy/glance/augment methods; epicurve, forest, Lexis and Rt autoplots | Implemented for documented object types and fixed schemas. |
| Surveillance and spatial/outbreak analysis | Poisson screens, seasonal baseline, CUSUM, spatial and space-time scans, nowcasts and renewal forecasts | Implemented under explicit simplified statistical assumptions; not operationally calibrated or validated. |
| Integration and release checks | Per-feature and cross-module tests; examples; `R CMD check` | Tested on the available R system only. An unexecuted multi-platform CI configuration and external validation plan are provided. Check logs and release-specific status are distributed alongside the release. Remote CRAN incoming checks and PDF manual checks are not represented by a no-manual local check. |

## API and evidence boundaries

- Ordinary analysis functions use data-first arguments and unquoted column
  selection. Framework-required S3 methods, recipe objects, vector metric
  functions, model-engine fit helpers, and model specifications necessarily
  follow their documented framework signatures or do not use a data frame as
  their first substantive input. A literal universal `.data`-first rule is not
  met by these exceptions.
- The source includes feature tests and executable synthetic end-to-end examples
  under `inst/examples/`. Passing them is not proof of correctness for all data,
  platforms, dependency versions or extreme inputs.
- Examples, simulated validation and local checks cannot establish external
  clinical, epidemiological or surveillance validity. Independent review,
  representative datasets, validation of assumptions and prospective testing
  are required for any substantive application.
- No CRAN submission, remote incoming checks or multi-platform verification is
  implied. Undertake release checks in the
  intended environments before considering submission.
