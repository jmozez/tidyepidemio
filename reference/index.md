# Package index

## Datasets

Real, published epidemiological data used in the examples and articles.

- [`nz_covid_2020`](https://tidyepidemio.in4metrix.dev/reference/nz_covid_2020.md)
  : Daily COVID-19 cases in New Zealand, first wave 2020
- [`nz_covid_outcomes_2020`](https://tidyepidemio.in4metrix.dev/reference/nz_covid_outcomes_2020.md)
  : Daily COVID-19 cases and deaths in New Zealand, first wave 2020
- [`ny_covid_counties_2020`](https://tidyepidemio.in4metrix.dev/reference/ny_covid_counties_2020.md)
  : Weekly COVID-19 cases in New York State counties, spring 2020
- [`flu_boarding_school_1978`](https://tidyepidemio.in4metrix.dev/reference/flu_boarding_school_1978.md)
  : Influenza outbreak in an English boarding school, 1978
- [`british_doctors`](https://tidyepidemio.in4metrix.dev/reference/british_doctors.md)
  : British Doctors Study: smoking and coronary deaths
- [`nc_sids`](https://tidyepidemio.in4metrix.dev/reference/nc_sids.md) :
  Sudden infant death syndrome in North Carolina counties

## Epidemiological data classes

- [`epi_linelist()`](https://tidyepidemio.in4metrix.dev/reference/epi_linelist.md)
  [`epi_cohort()`](https://tidyepidemio.in4metrix.dev/reference/epi_linelist.md)
  [`epi_ts()`](https://tidyepidemio.in4metrix.dev/reference/epi_linelist.md)
  : Create epidemiological tibble subclasses

## Frequency measures

- [`epi_incidence()`](https://tidyepidemio.in4metrix.dev/reference/epi_incidence.md)
  [`epi_prevalence()`](https://tidyepidemio.in4metrix.dev/reference/epi_incidence.md)
  [`epi_attack_rate()`](https://tidyepidemio.in4metrix.dev/reference/epi_incidence.md)
  [`epi_person_time()`](https://tidyepidemio.in4metrix.dev/reference/epi_incidence.md)
  : Epidemiological frequency measures
- [`epi_cumulative_incidence()`](https://tidyepidemio.in4metrix.dev/reference/epi_cumulative_incidence.md)
  : Cumulative incidence with competing risks
- [`epi_follow_up()`](https://tidyepidemio.in4metrix.dev/reference/epi_follow_up.md)
  : Derive cohort follow-up and administrative censoring
- [`epi_proportion_ci()`](https://tidyepidemio.in4metrix.dev/reference/epi_proportion_ci.md)
  : Confidence interval for a binary proportion
- [`epi_rate_ci()`](https://tidyepidemio.in4metrix.dev/reference/epi_rate_ci.md)
  : Exact Poisson confidence interval for an incidence rate

## Measures of association

- [`epi_risk_ratio()`](https://tidyepidemio.in4metrix.dev/reference/epi_risk_ratio.md)
  [`epi_odds_ratio()`](https://tidyepidemio.in4metrix.dev/reference/epi_risk_ratio.md)
  [`epi_attributable_risk()`](https://tidyepidemio.in4metrix.dev/reference/epi_risk_ratio.md)
  [`epi_rate_ratio()`](https://tidyepidemio.in4metrix.dev/reference/epi_risk_ratio.md)
  : Measures of association for individual-level binary data
- [`epi_mantel_haenszel()`](https://tidyepidemio.in4metrix.dev/reference/epi_mantel_haenszel.md)
  : Mantel-Haenszel pooled odds ratio
- [`epi_mantel_haenszel_test()`](https://tidyepidemio.in4metrix.dev/reference/epi_mantel_haenszel_test.md)
  : Mantel-Haenszel test and confidence interval
- [`epi_fisher_test()`](https://tidyepidemio.in4metrix.dev/reference/epi_fisher_test.md)
  : Fisher's exact test for binary exposure and outcome
- [`epi_adjusted_risk_ratio()`](https://tidyepidemio.in4metrix.dev/reference/epi_adjusted_risk_ratio.md)
  : Adjusted risk ratio using modified Poisson regression
- [`epi_adjusted_odds_ratio()`](https://tidyepidemio.in4metrix.dev/reference/epi_adjusted_odds_ratio.md)
  : Covariate-adjusted odds ratio
- [`epi_adjusted_rate_ratio()`](https://tidyepidemio.in4metrix.dev/reference/epi_adjusted_rate_ratio.md)
  : Covariate-adjusted Poisson incidence rate ratio
- [`epi_attributable_fraction()`](https://tidyepidemio.in4metrix.dev/reference/epi_attributable_fraction.md)
  : Attributable fractions from individual-level risks
- [`epi_number_needed()`](https://tidyepidemio.in4metrix.dev/reference/epi_number_needed.md)
  : Number needed to treat or harm

## Standardization

- [`epi_standardize()`](https://tidyepidemio.in4metrix.dev/reference/epi_standardize.md)
  : Standardize rates across strata
- [`epi_standardize_ci()`](https://tidyepidemio.in4metrix.dev/reference/epi_standardize_ci.md)
  : Confidence intervals for standardized rates and ratios

## Causal inference

- [`epi_propensity_weights()`](https://tidyepidemio.in4metrix.dev/reference/epi_propensity_weights.md)
  : Estimate inverse-probability exposure weights
- [`epi_weighted_effect()`](https://tidyepidemio.in4metrix.dev/reference/epi_weighted_effect.md)
  : Weighted marginal risks and contrasts
- [`epi_ipw()`](https://tidyepidemio.in4metrix.dev/reference/epi_ipw.md)
  : Propensity-weighted marginal effects with optional bootstrap
- [`epi_gcomp()`](https://tidyepidemio.in4metrix.dev/reference/epi_gcomp.md)
  : Marginal risk standardization via the g-formula
- [`epi_balance()`](https://tidyepidemio.in4metrix.dev/reference/epi_balance.md)
  : Covariate balance before and after weighting

## Diagnostic and clinical epidemiology

- [`epi_diagnostic()`](https://tidyepidemio.in4metrix.dev/reference/epi_diagnostic.md)
  : Diagnostic test performance
- [`epi_diagnostic_ci()`](https://tidyepidemio.in4metrix.dev/reference/epi_diagnostic_ci.md)
  : Confidence intervals for diagnostic proportions
- [`epi_paired_diagnostic()`](https://tidyepidemio.in4metrix.dev/reference/epi_paired_diagnostic.md)
  : Compare paired diagnostic test sensitivity and specificity
- [`epi_predictive_values()`](https://tidyepidemio.in4metrix.dev/reference/epi_predictive_values.md)
  : Predictive values at specified disease prevalences
- [`epi_roc_curve()`](https://tidyepidemio.in4metrix.dev/reference/epi_roc_curve.md)
  : Empirical ROC curve for a diagnostic score
- [`epi_plot_roc()`](https://tidyepidemio.in4metrix.dev/reference/epi_plot_roc.md)
  : Plot an empirical ROC curve
- [`epi_auc_ci()`](https://tidyepidemio.in4metrix.dev/reference/epi_auc_ci.md)
  : Stratified bootstrap confidence interval for empirical ROC AUC
- [`epi_calibration()`](https://tidyepidemio.in4metrix.dev/reference/epi_calibration.md)
  : Grouped binary risk calibration
- [`epi_calibration_summary()`](https://tidyepidemio.in4metrix.dev/reference/epi_calibration_summary.md)
  : Binary prediction calibration and discrimination summary
- [`epi_decision_curve()`](https://tidyepidemio.in4metrix.dev/reference/epi_decision_curve.md)
  : Decision-curve analysis over thresholds
- [`net_benefit()`](https://tidyepidemio.in4metrix.dev/reference/net_benefit.md)
  [`net_benefit_vec()`](https://tidyepidemio.in4metrix.dev/reference/net_benefit.md)
  : Decision-curve net benefit

## Survival analysis

- [`epi_kaplan_meier()`](https://tidyepidemio.in4metrix.dev/reference/epi_kaplan_meier.md)
  : Kaplan-Meier survival estimates
- [`epi_survival_risk()`](https://tidyepidemio.in4metrix.dev/reference/epi_survival_risk.md)
  : Kaplan-Meier event risk at fixed horizons
- [`epi_rmst()`](https://tidyepidemio.in4metrix.dev/reference/epi_rmst.md)
  : Restricted mean survival time
- [`epi_cox_hazard_ratio()`](https://tidyepidemio.in4metrix.dev/reference/epi_cox_hazard_ratio.md)
  : Covariate-adjusted Cox proportional hazards ratio

## Infectious disease dynamics

- [`epi_epicurve()`](https://tidyepidemio.in4metrix.dev/reference/epi_epicurve.md)
  : Aggregate an epidemic curve
- [`epi_growth_rate()`](https://tidyepidemio.in4metrix.dev/reference/epi_growth_rate.md)
  [`epi_doubling_time()`](https://tidyepidemio.in4metrix.dev/reference/epi_growth_rate.md)
  : Estimate exponential growth from incidence
- [`epi_rt()`](https://tidyepidemio.in4metrix.dev/reference/epi_rt.md) :
  Renewal-equation effective reproduction number
- [`epi_rt_gamma()`](https://tidyepidemio.in4metrix.dev/reference/epi_rt_gamma.md)
  : Sliding-window renewal Rt with gamma posterior intervals
- [`epi_serial_interval()`](https://tidyepidemio.in4metrix.dev/reference/epi_serial_interval.md)
  : Summarize observed serial intervals
- [`epi_serial_interval_ci()`](https://tidyepidemio.in4metrix.dev/reference/epi_serial_interval_ci.md)
  : Confidence interval for a mean serial interval
- [`epi_delay_dist()`](https://tidyepidemio.in4metrix.dev/reference/epi_delay_dist.md)
  : Estimate an epidemiological delay distribution
- [`epi_delay_pmf()`](https://tidyepidemio.in4metrix.dev/reference/epi_delay_pmf.md)
  : Discretised probabilities of a fitted delay
- [`epi_offspring()`](https://tidyepidemio.in4metrix.dev/reference/epi_offspring.md)
  [`epi_chain_size()`](https://tidyepidemio.in4metrix.dev/reference/epi_offspring.md)
  : Reproduction number and dispersion of secondary cases
  (superspreading)
- [`epi_cfr()`](https://tidyepidemio.in4metrix.dev/reference/epi_cfr.md)
  : Naive and delay-adjusted case fatality ratio
- [`epi_simulate()`](https://tidyepidemio.in4metrix.dev/reference/epi_simulate.md)
  : Simulate a discrete-time SIR or SEIR epidemic
- [`epi_simulate_schedule()`](https://tidyepidemio.in4metrix.dev/reference/epi_simulate_schedule.md)
  : Simulate SIR or SEIR with time-varying rates

## Nowcasting and forecasting

- [`epi_nowcast()`](https://tidyepidemio.in4metrix.dev/reference/epi_nowcast.md)
  : Nowcast final reported incidence from reporting delays
- [`epi_renewal()`](https://tidyepidemio.in4metrix.dev/reference/epi_renewal.md)
  [`epi_compartmental()`](https://tidyepidemio.in4metrix.dev/reference/epi_renewal.md)
  : Parsnip epidemic model specifications
- [`epi_fit_renewal()`](https://tidyepidemio.in4metrix.dev/reference/epi_fit_renewal.md)
  [`epi_fit_compartmental()`](https://tidyepidemio.in4metrix.dev/reference/epi_fit_renewal.md)
  : Fit simplified epidemic models with data-first column selection
- [`fit_epi_renewal()`](https://tidyepidemio.in4metrix.dev/reference/fit_epi_renewal.md)
  [`fit_epi_compartmental()`](https://tidyepidemio.in4metrix.dev/reference/fit_epi_renewal.md)
  : Epidemic model engine functions
- [`epi_renewal_forecast()`](https://tidyepidemio.in4metrix.dev/reference/epi_renewal_forecast.md)
  : Probabilistic renewal forecasts
- [`epi_renewal_backtest()`](https://tidyepidemio.in4metrix.dev/reference/epi_renewal_backtest.md)
  : Rolling-origin renewal forecast backtesting

## Surveillance

- [`epi_surveillance()`](https://tidyepidemio.in4metrix.dev/reference/epi_surveillance.md)
  : Prospective Poisson surveillance threshold
- [`epi_seasonal_surveillance()`](https://tidyepidemio.in4metrix.dev/reference/epi_seasonal_surveillance.md)
  : Seasonal Poisson surveillance using an earlier baseline
- [`epi_cusum()`](https://tidyepidemio.in4metrix.dev/reference/epi_cusum.md)
  : One-sided Poisson CUSUM surveillance
- [`epi_cusum_calibrate()`](https://tidyepidemio.in4metrix.dev/reference/epi_cusum_calibrate.md)
  : Monte Carlo calibration of a finite-horizon Poisson CUSUM

## Spatial and space-time analysis

- [`epi_spatial_neighbors()`](https://tidyepidemio.in4metrix.dev/reference/epi_spatial_neighbors.md)
  : Count neighboring locations within a distance
- [`epi_spatial_scan()`](https://tidyepidemio.in4metrix.dev/reference/epi_spatial_scan.md)
  : Circular Poisson spatial scan statistic
- [`epi_spacetime_scan()`](https://tidyepidemio.in4metrix.dev/reference/epi_spacetime_scan.md)
  : Prospective circular space-time Poisson scan

## Preprocessing (recipes)

- [`step_epi_lags()`](https://tidyepidemio.in4metrix.dev/reference/step_epi_lags.md)
  [`step_epi_rolling()`](https://tidyepidemio.in4metrix.dev/reference/step_epi_lags.md)
  [`step_epi_rates()`](https://tidyepidemio.in4metrix.dev/reference/step_epi_lags.md)
  [`step_epi_exposure_window()`](https://tidyepidemio.in4metrix.dev/reference/step_epi_lags.md)
  : Epidemiological recipe steps
- [`epi_bake_history()`](https://tidyepidemio.in4metrix.dev/reference/epi_bake_history.md)
  : Bake epidemiological recipe features with explicit history
- [`epi_temporal_features()`](https://tidyepidemio.in4metrix.dev/reference/epi_temporal_features.md)
  : Past-only temporal features with explicit history

## Resampling (rsample)

- [`epi_rolling_origin()`](https://tidyepidemio.in4metrix.dev/reference/epi_rolling_origin.md)
  : Rolling-origin resampling
- [`epi_spatial_blocks()`](https://tidyepidemio.in4metrix.dev/reference/epi_spatial_blocks.md)
  : Create square spatial blocks
- [`epi_spatial_cv()`](https://tidyepidemio.in4metrix.dev/reference/epi_spatial_cv.md)
  : Group-blocked cross-validation

## Forecast evaluation (yardstick)

- [`wis()`](https://tidyepidemio.in4metrix.dev/reference/wis.md)
  [`wis_vec()`](https://tidyepidemio.in4metrix.dev/reference/wis.md) :
  Weighted interval score
- [`wis_metric()`](https://tidyepidemio.in4metrix.dev/reference/wis_metric.md)
  : Create a WIS metric for yardstick metric sets

## Statistical advice

Advice on which estimator to use and plain-language interpretation of
results, used by the tidyvisor package.

- [`tep_advise()`](https://tidyepidemio.in4metrix.dev/reference/tep_advise.md)
  [`tep_interpret()`](https://tidyepidemio.in4metrix.dev/reference/tep_advise.md)
  : Statistical advice and interpretation for epidemiology

## Tidying and plotting

- [`tidy(`*`<epi_result>`*`)`](https://tidyepidemio.in4metrix.dev/reference/tidy.epi_result.md)
  [`glance(`*`<epi_result>`*`)`](https://tidyepidemio.in4metrix.dev/reference/tidy.epi_result.md)
  [`tidy(`*`<epi_model>`*`)`](https://tidyepidemio.in4metrix.dev/reference/tidy.epi_result.md)
  [`glance(`*`<epi_model>`*`)`](https://tidyepidemio.in4metrix.dev/reference/tidy.epi_result.md)
  [`augment(`*`<epi_model>`*`)`](https://tidyepidemio.in4metrix.dev/reference/tidy.epi_result.md)
  : Tidy epidemiological results and fitted epidemic models
- [`autoplot(`*`<epi_ts>`*`)`](https://tidyepidemio.in4metrix.dev/reference/autoplot.epi_ts.md)
  [`autoplot(`*`<epi_linelist>`*`)`](https://tidyepidemio.in4metrix.dev/reference/autoplot.epi_ts.md)
  [`autoplot(`*`<epi_cohort>`*`)`](https://tidyepidemio.in4metrix.dev/reference/autoplot.epi_ts.md)
  [`autoplot(`*`<epi_result>`*`)`](https://tidyepidemio.in4metrix.dev/reference/autoplot.epi_ts.md)
  : Plot epidemiological data and results
