# Covariate-adjusted Cox proportional hazards ratio

Fits a Cox model with a binary exposure and optional covariates, using
the `survival` package. Entry times allow left truncation via
`(entry, time]` risk intervals. The exposure coefficient is
exponentiated and accompanied by a normal-Wald confidence interval. Ties
use the specified Cox method.

## Usage

``` r
epi_cox_hazard_ratio(
  .data,
  time,
  event,
  exposure,
  adjust = c(),
  entry = NULL,
  ties = c("efron", "breslow", "exact"),
  conf_level = 0.95
)
```

## Arguments

- .data:

  An ungrouped data frame, one independent record per person.

- time:

  Non-negative observed exit or follow-up time.

- event:

  Binary indicator: 1 for the event, 0 for censoring.

- exposure:

  Binary 0/1 exposure.

- adjust:

  Tidy selection of complete numeric, factor or logical covariate
  columns; defaults to no additional covariates.

- entry:

  Optional non-negative entry time column for left truncation; values
  must be strictly less than exit time. Defaults to no truncation.

- ties:

  One of `"efron"`, `"breslow"`, or `"exact"`.

- conf_level:

  Confidence level strictly between zero and one.

## Value

An `epi_result` tibble with hazard ratio, Wald confidence limits, number
of observations and events, and covariate names.

## Details

Requires independent observations, independent censoring/truncation
conditional on covariates, correct covariate specification and
proportional hazards. The function does not check these assumptions,
account for competing risks, clustering, time-varying covariates, or
assess a causal effect. Sparse data or separation can make the estimates
unreliable.

## Examples

``` r
d <- data.frame(
  t = 1:12, event = c(1, 0, 1, 1, 0, 1, 1, 0, 1, 0, 1, 1),
  e = rep(0:1, 6), age = rep(30:33, 3)
)
epi_cox_hazard_ratio(d, t, event, e, adjust = age)
#> # A tibble: 1 × 7
#>   measure      estimate conf_low conf_high     n events adjusted_for
#>   <chr>           <dbl>    <dbl>     <dbl> <int>  <dbl> <chr>       
#> 1 hazard_ratio    0.425   0.0688      2.63    12      8 age         
```
