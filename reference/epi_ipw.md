# Propensity-weighted marginal effects with optional bootstrap

Fits a logistic propensity model for a binary exposure and computes
separately normalized (Hájek) inverse-probability-weighted outcome
risks, their difference and their ratio for the average-treatment-effect
target population. Stabilized weights use the sample marginal exposure
probabilities; group normalization means stabilized and unstabilized
weights yield the same point risks. The returned propensity range,
maximum weight and group effective sample sizes are descriptive
diagnostics, not evidence that overlap or balance is adequate.

## Usage

``` r
epi_ipw(
  .data,
  exposure,
  outcome,
  adjust = c(),
  stabilized = TRUE,
  bootstrap = 0L,
  conf_level = 0.95
)
```

## Arguments

- .data:

  An ungrouped data frame of independent individuals.

- exposure:

  Binary 0/1 exposure column.

- outcome:

  Binary 0/1 outcome column.

- adjust:

  Tidy selection of complete baseline numeric, factor or logical
  covariates; defaults to an intercept-only exposure model.

- stabilized:

  Whether to use stabilized ATE weights.

- bootstrap:

  Number of individual bootstrap resamples, either 0 or an integer
  between 100 and 2000.

- conf_level:

  Confidence level strictly between zero and one.

## Value

A four-row tibble of weighted risks, risk difference and risk ratio,
with percentile limits (missing without bootstrap), group effective
sample sizes, propensity range, maximum weight and bootstrap counts.

## Details

With `bootstrap > 0`, individual records are resampled, the propensity
model is refit, and weights and contrasts are recalculated in every
replicate. Intervals are percentile intervals; no cluster or
survey-design bootstrap is included. Warned or failed bootstrap fits are
omitted; more than 10 percent failures abort the analysis. Intervals
conditional on successful fits can still be biased. Set a seed for
reproducibility. Uncertainty from model selection or unmeasured
confounding is not included.

Causal interpretation requires consistency, conditional exchangeability,
positivity, correct exposure-model specification, pre-exposure
covariates, independent observations and appropriate censoring and
missingness assumptions. These assumptions cannot be verified here. No
weight trimming, missing-data handling, interactions, nonlinear terms or
longitudinal treatment is provided. Use
[`epi_balance()`](https://tidyepidemio.in4metrix.dev/reference/epi_balance.md)
and substantive knowledge to assess the design.

## Examples

``` r
d <- expand.grid(e = 0:1, age = 20:24, rep = 1:6)
d$y <- as.integer(d$rep <= 1 + d$e + (d$age %% 2))
epi_ipw(d, e, y, adjust = age)
#> # A tibble: 4 × 12
#>   measure         estimate conf_low conf_high     n ess_unexposed ess_exposed
#>   <chr>              <dbl>    <dbl>     <dbl> <int>         <dbl>       <dbl>
#> 1 risk_unexposed     0.233       NA        NA    60            30          30
#> 2 risk_exposed       0.4         NA        NA    60            30          30
#> 3 risk_difference    0.167       NA        NA    60            30          30
#> 4 risk_ratio         1.71        NA        NA    60            30          30
#> # ℹ 5 more variables: propensity_min <dbl>, propensity_max <dbl>,
#> #   max_weight <dbl>, bootstrap <int>, bootstrap_success <int>
```
