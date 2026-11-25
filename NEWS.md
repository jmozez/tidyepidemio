# tidyepidemio 1.1.0

* Preserve epidemiological class and metadata across supported grouped,
  row-preserving dplyr operations, including ungrouping; reject grouped binding
  or casting when provenance or grouping differs.
* Added data-first `epi_fit_renewal()` and `epi_fit_compartmental()` helpers,
  including tidy selections and non-syntactic column names.
* Added randomized reference and conservation tests, an unrun multi-platform
  CI configuration, and a plan for independent validation.

# tidyepidemio 1.0.0

* Audited the requested implementation areas and added an implementation and
  limitations guide plus synthetic cohort, outbreak and clinical workflows.
* Added cross-module integration tests and an explicit low-level model example.
* Reject row-binding or casting plain frames with epidemiological subclasses to
  prevent unintended provenance inheritance; validate metadata names.
* Reject grouped data in low-level epidemic model engine fits, consistent with
  their documented single-series contract.

# tidyepidemio 0.9.0

* Added restricted mean survival time with Greenwood standard errors and clipped
  Wald confidence limits; validates the chosen horizon against observed follow-up.
* Added stratified individual bootstrap percentile intervals for empirical ROC
  AUC, and exact paired diagnostic sensitivity and specificity comparisons.

# tidyepidemio 0.8.0

* Added cohort follow-up with optional administrative censoring, and empirical
  ROC curves and plotting with tie-aware AUC and predictive values.
* Added propensity-weighted risks and contrasts with optional individual
  percentile bootstrap that refits the exposure model in every replicate.
* Added explicit-history baking for supported epidemiological recipe steps and
  a training-only seasonal Fourier Poisson surveillance screen.
* Improved upper-tail Poisson quantile calculations for very small alert levels.

# tidyepidemio 0.7.0

* Added group-aware temporal lags and past-only rolling means with explicitly
  supplied history and strict within-group time ordering.
* Added expanding rolling-origin renewal forecast backtesting, with uncertainty
  and training-only estimation at each origin.
* Added Fisher exact and Mantel-Haenszel association tests and predictive values
  transported to user-supplied target prevalences. Uninformative stratified
  tests now fail explicitly rather than returning NaN.

# tidyepidemio 0.6.0

* Added attributable fractions, descriptive number needed to treat or harm,
  fixed-horizon Kaplan-Meier risk, binary calibration summaries and tables, and
  decision curves.
* Added deterministic square spatial-block assignment for spatial resampling.
* Fixed integer overflow in odds ratios and Mantel-Haenszel odds ratios for
  large cohorts; added large-sample regression tests.

# tidyepidemio 0.5.0

* Added marginal logistic g-computation with optional individual bootstrap,
  stabilized and unstabilized ATE propensity weights, weighted risk contrasts,
  and standardized mean-difference balance diagnostics.
* Added daily and Monday-start weekly epidemic curves with explicit zero filling,
  and a t confidence interval for the mean serial interval.
* Documented identification assumptions, separation diagnostics, bootstrap fit
  failures, fixed reference variance for balance, and limitations of each method.

# tidyepidemio 0.4.0

* Added reporting-delay nowcasts, robust modified-Poisson risk ratios, an SEIR
  parsnip engine, and a conditional Poisson prospective space-time scan.

# tidyepidemio 0.1.0

* Introduced descriptive epidemiology, standardization, diagnostic measures,
  survival analysis, renewal dynamics, SIR/SEIR simulation, surveillance,
  spatial resampling and scans, recipe steps, metrics, models and plots.
