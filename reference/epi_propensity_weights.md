# Estimate inverse-probability exposure weights

Fits a logistic propensity score model for binary exposure and returns
individual inverse-probability weights for the average treatment effect
(ATE). Unstabilized weights are `1/p` for exposed and `1/(1-p)` for
unexposed individuals. Stabilized weights replace the numerator with the
corresponding observed marginal exposure probability. No trimming or
clipping is performed. A warning flags extreme fitted propensities; it
does not prove adequate overlap when absent. Assess balance, overlap and
influential weights before interpreting results.

## Usage

``` r
epi_propensity_weights(.data, exposure, adjust = c(), stabilized = TRUE)
```

## Arguments

- .data:

  An ungrouped data frame of independent individuals.

- exposure:

  Binary 0/1 exposure column.

- adjust:

  Tidy selection of complete numeric, factor, or logical baseline
  covariate columns. Defaults to an intercept-only model.

- stabilized:

  Whether to calculate stabilized ATE weights.

## Value

Input tibble with `propensity` and `ipw` columns. Fitted propensities
must lie strictly between zero and one.

## Details

A causal interpretation requires consistency, no unmeasured confounding,
positivity, correct treatment-model specification, pre-exposure
covariates, and suitable missingness and censoring assumptions. The
function supports only complete data, main effects and linear numeric
covariates, and does not account for cluster sampling or time-varying
treatment. The returned weights alone do not estimate an effect or
uncertainty.

## Examples

``` r
d <- expand.grid(e = 0:1, age = 20:24, rep = 1:6)
d$y <- as.integer(d$rep <= 1 + d$e + (d$age %% 2))
weighted <- epi_propensity_weights(d, e, adjust = age)
epi_weighted_effect(weighted, e, y, ipw)
#> # A tibble: 1 × 7
#>   risk_unexposed risk_exposed risk_difference risk_ratio ess_unexposed
#>            <dbl>        <dbl>           <dbl>      <dbl>         <dbl>
#> 1          0.233          0.4           0.167       1.71            30
#> # ℹ 2 more variables: ess_exposed <dbl>, n <int>
```
