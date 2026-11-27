# Kaplan-Meier survival estimates

Estimates survival by product-limit with log-log confidence intervals
using
[`survival::survfit()`](https://rdrr.io/pkg/survival/man/survfit.html).
Each row is an individual with a non-negative observed follow-up time
and binary event indicator. Censoring must be non-informative
conditional on group. Events at the same time use the standard
Kaplan-Meier risk set. With `entry`, individuals enter the risk set only
after their delayed-entry time (left truncation); entry must be
independent of survival. Competing risks, weights, clustering, covariate
adjustment and continuous-time predictions are not supported. Follow-up
times and censoring times share the same units.

## Usage

``` r
epi_kaplan_meier(
  .data,
  time,
  event,
  strata = NULL,
  conf_level = 0.95,
  entry = NULL
)
```

## Arguments

- .data:

  An ungrouped data frame with one row per individual.

- time:

  Non-negative observed follow-up time.

- event:

  Binary event indicator, where 1 denotes the event.

- strata:

  Optional group column; defaults to one combined curve.

- conf_level:

  Confidence level strictly between zero and one.

- entry:

  Optional delayed-entry (left-truncation) time, strictly less than
  `time` for every row; defaults to entry at time zero.

## Value

Tibble of stratum, event/censor times, risk set, event and censor
counts, estimated survival and log-log confidence limits. The estimate
at time zero before the first event is not added automatically.
Confidence limits may be missing at boundary estimates.

## Examples

``` r
d <- data.frame(t = c(1, 2, 3, 4), event = c(1, 0, 1, 0), group = c("a", "a", "b", "b"))
epi_kaplan_meier(d, t, event)
#> # A tibble: 4 × 8
#>   strata  time n_risk n_event n_censor estimate conf_low conf_high
#>   <chr>  <dbl>  <dbl>   <dbl>    <dbl>    <dbl>    <dbl>     <dbl>
#> 1 All        1      4       1        0    0.75    0.128      0.961
#> 2 All        2      3       0        1    0.75    0.128      0.961
#> 3 All        3      2       1        0    0.375   0.0110     0.808
#> 4 All        4      1       0        1    0.375   0.0110     0.808
epi_kaplan_meier(d, t, event, strata = group)
#> # A tibble: 4 × 8
#>   strata  time n_risk n_event n_censor estimate conf_low conf_high
#>   <chr>  <dbl>  <dbl>   <dbl>    <dbl>    <dbl>    <dbl>     <dbl>
#> 1 a          1      2       1        0      0.5  0.00598     0.910
#> 2 a          2      1       0        1      0.5  0.00598     0.910
#> 3 b          3      2       1        0      0.5  0.00598     0.910
#> 4 b          4      1       0        1      0.5  0.00598     0.910
```
