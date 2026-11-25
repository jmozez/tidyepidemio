# tidyepidemio

<!-- badges: start -->
[![R-CMD-check](https://github.com/jmozez/tidyepidemio/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/jmozez/tidyepidemio/actions/workflows/R-CMD-check.yaml)
<!-- badges: end -->

Documentation: <https://jmozez.github.io/tidyepidemio/>

An early-stage R package for transparent, data-first epidemiological analysis.
This is a **prototype**, not a comprehensive or clinically validated toolkit.
Review the assumptions below, and validate methods for the intended application.
A clean local `R CMD check` is not CRAN acceptance or evidence of clinical validity.

## Installation

Install the development version from GitHub:

```r
# install.packages("remotes")
remotes::install_github("jmozez/tidyepidemio")
```

## Examples

```r
library(tidyepidemio)
d <- data.frame(exposure = c(0,0,0,0,1,1,1,1),
                outcome = c(0,0,0,1,0,1,1,1))
effect <- d |> epi_risk_ratio(exposure, outcome)
generics::tidy(effect)
ggplot2::autoplot(effect)

sample <- expand.grid(e=0:1, age=20:24, replicate=1:6)
sample$y <- as.integer(sample$replicate <= 1 + sample$e + (sample$age %% 2))
epi_gcomp(sample, e, y, adjust=age)
weighted <- epi_propensity_weights(sample, e, adjust=age)
epi_balance(weighted, e, age, weights=ipw)
epi_weighted_effect(weighted, e, y, ipw)
epi_ipw(sample, e, y, adjust=age) # set bootstrap=100 or more for intervals

predictions <- data.frame(y=c(0,0,1,0,1,0,1,1),
                          p=c(.1,.2,.3,.4,.5,.6,.7,.8))
epi_calibration(predictions, y, p, bins=4)
epi_calibration_summary(predictions, y, p)
epi_decision_curve(predictions, y, p, thresholds=c(.25,.5,.75))
epi_plot_roc(epi_roc_curve(predictions, y, p))
set.seed(17)
epi_auc_ci(predictions, y, p, bootstrap=100)
predictions$test_a <- as.integer(predictions$p >= .4)
predictions$test_b <- as.integer(predictions$p >= .5)
epi_paired_diagnostic(predictions, test_a, test_b, y)

cohort <- data.frame(entry=as.Date("2024-01-01") + c(0, 1),
                     exit=as.Date("2024-01-01") + c(5, 10), event=c(1, 1))
epi_follow_up(cohort, entry, exit, event, censor_at=as.Date("2024-01-08"))
survival_data <- data.frame(t=c(1,2,3,4,5,6), e=c(1,0,1,0,1,0))
epi_rmst(survival_data, t, e, tau=5)

sim <- epi_simulate(data.frame(S=999,I=1,R=0), beta=.3, gamma=.1, steps=30)
series <- data.frame(time=1:6, cases=c(1,2,4,8,16,32))
spec <- epi_renewal() |> parsnip::set_engine("tidyepidemio", weights=1)
fit <- parsnip::fit(spec, cases ~ time, data=series)
predict(fit, new_data=data.frame(time=7:8))
generics::tidy(fit$fit)
# A direct data-first alternative returns an epi_model rather than a parsnip fit:
direct_fit <- epi_fit_renewal(series, time, cases, weights=1)
predict(direct_fit, newdata=data.frame(time=7:8))

series |> epi_surveillance(cases, window=3)
training <- data.frame(t=1:40, cases=rep(c(4,6,8,6),10))
new <- data.frame(t=41:42, cases=c(20,5))
epi_seasonal_surveillance(new, t, cases, training=training, period=4)
series |> epi_rt_gamma(cases, weights=1, window=3)
set.seed(1)
backtest <- epi_renewal_backtest(series, time, cases, weights=1,
                                 initial=3, horizon=2, nsim=100)
wis(backtest, observed, forecast_median, forecast_low, forecast_high, alpha=.05)
epi_temporal_features(series[4:6, ], cases, time=time,
                      history=series[1:3, ], window=2)
reported <- data.frame(onset=as.Date("2024-01-01")+0:2, reports=c(10,8,3))
epi_nowcast(reported, onset, reports, as_of=as.Date("2024-01-03"),
            delay_prob=c(.5,.3,.2))
set.seed(1)
series |> epi_renewal_forecast(cases, weights=1, rt=1.1, horizon=3)

rates <- data.frame(beta=c(.3,.3,.1,.1), gamma=.1)
epi_simulate_schedule(rates, initial=data.frame(S=999,I=1,R=0))

locations <- data.frame(x=c(0,1,10,11), y=0,
                        cases=c(8,7,1,1), pop=100)
set.seed(1)
epi_spatial_scan(locations, x, y, cases, pop, radii=c(.1,1), nsim=99)
```

## Implemented scope

- Frequency, binary risk/odds/rate ratios and risk difference, diagnostics,
  direct/indirect standardization, Mantel-Haenszel pooled odds ratio with Breslow-Day heterogeneity test,
  adjusted logistic odds ratios (with weights, robust or cluster errors, effect
  modification and spline terms), robust modified-Poisson risk ratios, Poisson rate
  ratios, Cox hazard ratios, Kaplan-Meier survival and fixed-horizon risks,
  attributable fractions, number needed to treat/harm, and Aalen-Johansen
  competing-risk cumulative incidence.
  Wilson/binomial, Poisson, diagnostic and standardized-rate confidence intervals
  are available, along with Fisher exact and Mantel-Haenszel tests and
  prevalence-adjusted predictive values, empirical ROC curves and AUC bootstrap
  intervals, exact paired diagnostic comparisons with score intervals, restricted mean survival time,
  and cohort
  follow-up with optional administrative censoring.
- Logistic g-computation with optional individual-level percentile bootstrap;
  ATE propensity weights, weighted risk contrasts and balance diagnostics;
  IPW contrasts can also use an individual-level refitting bootstrap.
- Equal-width calibration tables, calibration slope/intercepts, Brier score, ROC
  AUC and decision curves for binary risk predictions.
- Growth, doubling time, serial intervals and t intervals, filled daily/weekly
  epidemic curves, descriptive renewal Rt,
  a sliding-window gamma-Poisson posterior Rt, and deterministic/stochastic
  discrete-time SIR/SEIR simulation, including externally scheduled rates;
  conditional Monte Carlo renewal forecasts and prediction intervals; and a
  reporting-delay nowcast with negative-binomial predictive intervals; and
  rolling-origin renewal forecast backtesting.
- Four recipe feature steps, explicit-history baking for supported steps,
  a separate explicit-history temporal-feature helper,
  non-overlapping rolling-origin splits and
  square-grid spatial block construction and spatial-block cross-validation
  with optional planar distance buffers;
  multi-interval WIS and decision-curve net benefit; parsnip specifications for
  a constant-R renewal
  model and deterministic SIR/SEIR fits; broom-style generics for results and
  fits.
- Epicurve, forest, Lexis, Rt and ROC plots; simple and training-only seasonal
  Fourier Poisson surveillance flags and
  planar neighboring-location counts, a conditional Poisson circular spatial
  and prospective space-time scans with global Monte Carlo p-values, and a
  Poisson CUSUM with optional finite-horizon Monte Carlo threshold calibration.

## Important limitations

Most items below are statistical assumptions that no software can remove; they
describe when results can be trusted. Version 1.2.0 closed the remaining
feature gaps in association, regression, survival, causal, diagnostic and
surveillance methods (see NEWS).

- Binary outcomes and exposures must be non-missing 0/1; grouped inputs for
  core analysis are rejected rather than silently pooled. Wald intervals are
  approximate; zero cells give undefined estimates unless an explicit
  `correction` (such as 0.5) is requested, which biases towards the null.
  Standardization intervals use Poisson assumptions. The Breslow-Day
  heterogeneity test has low power with few or sparse strata.
- Adjusted logistic, modified-Poisson and Poisson models assume a correctly
  specified model, adequate overlap and independent observations or clusters.
  Sandwich (HC0/HC1, cluster) errors use normal inference and can be
  unreliable with few clusters. Missing data are not handled. Attributable
  fractions and numbers needed to treat or harm are unadjusted contrasts.
  Causal interpretation of any estimate requires an appropriate design and
  assumptions.
- The Cox model assumes proportional hazards. Kaplan-Meier and cumulative
  incidence support delayed entry, which must be independent of the event
  processes, but not covariate adjustment. All survival methods require
  independent censoring. Restricted mean survival time is limited to observed
  follow-up; its Greenwood Wald interval may be unreliable with heavy censoring
  or small samples.
- G-computation and propensity weighting require consistency, positivity,
  exchangeability, appropriate temporal ordering and correct model
  specification; neither proves those assumptions. Bootstrap intervals in
  `epi_weighted_effect()` hold the supplied weights fixed (usually conservative
  for inverse-probability weights); `epi_ipw()` re-estimates the propensity
  model in each resample. Failed or warned bootstrap fits are omitted (more than
  10% abort); conditioning on successful fits may bias intervals.
- `epi_rt()` is a descriptive renewal ratio. `epi_rt_gamma()` adds a
  conditional gamma-Poisson posterior and optional imported counts, but neither
  method directly corrects for reporting delays, uncertain generation intervals
  or right censoring. `epi_nowcast()` separately models reporting delays given a
  fixed known delay distribution; it cannot recover never-reported infections.
- The parsnip renewal fit estimates a single constant R using a conditional
  Poisson mean, known generation weights, no imports and point forecasts.
  The SIR/SEIR fit estimates beta by least squares with fixed population,
  gamma, progression rate (SEIR) and initial compartment values; estimation can
  be weakly identified. Neither accounts for observation error or changing
  parameters. Renewal forecast intervals assume fixed future R, no imports and
  no observation model, and are not guaranteed calibrated.
- SIR/SEIR simulation is a discrete-time approximation, not a continuous ODE
  solver. Epidemiological model outputs are not validated for operational
  decisions.
- Recipe lag/rolling/exposure steps assume sorted, ungrouped data and do not
  retain history between training and new data; `epi_bake_history()` supplies
  explicit history for one series at a time. Current-row windows and later
  assessment outcomes can leak information. Renewal backtests assume counts were
  available without delay; real surveillance should use data vintages.
- Spatial CV uses user-provided or square-grid blocks with point-to-point
  buffers on planar projected coordinates. The spatial and space-time scans
  assume a homogeneous Poisson null (and, for space-time, constant risk over
  time) and do not adjust for confounding or reporting bias.
- Surveillance screens support negative binomial baselines for overdispersion
  and multiple-testing adjustment across screened rows, and CUSUM calibration
  supports overdispersed nulls and several independent series. All still assume
  a correctly specified, outbreak-free baseline and ignore reporting delays and
  baseline parameter uncertainty. An alert is not an outbreak diagnosis.
- Risk-prediction calibration, discrimination and decision curves should be
  evaluated on independent validation data and do not account for clustering.
  AUC intervals do not refit models or correct optimism. Paired diagnostic
  comparisons assume an accurate shared reference standard. The yardstick
  `net_benefit()` metric returns one threshold per call by design; use
  `epi_decision_curve()` for many thresholds.
- Combining epidemiological subclasses with plain data frames is rejected;
  summarise, group_modify and rowwise conversion can drop class metadata, and
  joins keep the left table's metadata.
- Longitudinal (time-varying) causal methods and fully Bayesian outbreak models
  are outside the scope of this package.
- Tests cover documented behaviour, reference implementations and key edge
  cases, not every data type, dependency version or platform.

## Implementation guide and workflows

The source tree contains `inst/guide/implementation.md`, a milestone and
limitations audit, `inst/guide/validation-plan.md`, an unexecuted external
validation plan, and runnable synthetic workflows under `inst/examples/`.
A GitHub Actions multi-platform check configuration is included in the source
and runs on every push and pull request.
After installation, locate these with
`system.file("guide", package="tidyepidemio")` and
`system.file("examples", package="tidyepidemio")`.

## Development

```r
roxygen2::roxygenise()
testthat::test_local()
```
