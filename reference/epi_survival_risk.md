# Kaplan-Meier event risk at fixed horizons

Estimates event risk at specified follow-up times as one minus
Kaplan-Meier survival. The step function is right-continuous, so events
exactly at a horizon are included. Confidence bounds reverse the log-log
survival limits. The returned risk set is the number of subjects whose
observed follow-up is at least the horizon, including those with an
event or censoring at that time. Horizons must not exceed the maximum
observed follow-up: this function does not extrapolate a survival curve
beyond its observed support.

## Usage

``` r
epi_survival_risk(.data, time, event, horizons, conf_level = 0.95)
```

## Arguments

- .data:

  An ungrouped data frame, one row per individual.

- time:

  Non-negative follow-up or exit time.

- event:

  Binary event indicator: 1 for event and 0 for censoring.

- horizons:

  Numeric non-negative evaluation times, in the same units as `time`; no
  value may exceed the largest observed follow-up time.

- conf_level:

  Confidence level strictly between zero and one.

## Value

A tibble with horizon, risk set, event risk and confidence limits.
Before the first observed event or censoring time, the risk and limits
are zero. Limits may be missing when survival limits are undefined.

## Details

Estimates assume independent censoring and independent subjects. This is
not a competing-risk cumulative incidence estimator and does not support
left truncation, covariates, weights, time-varying exposures or
clustering. For competing events use
[`epi_cumulative_incidence()`](https://tidyepidemio.in4metrix.dev/reference/epi_cumulative_incidence.md)
rather than censoring them as if they were independent.

## Examples

``` r
d <- data.frame(time = c(1, 2, 3, 4), event = c(1, 0, 1, 0))
epi_survival_risk(d, time, event, horizons = c(0, 2, 3))
#> # A tibble: 3 × 6
#>   horizon n_risk  risk conf_low conf_high conf_level
#>     <dbl>  <int> <dbl>    <dbl>     <dbl>      <dbl>
#> 1       0      4 0       0          0           0.95
#> 2       2      3 0.25    0.0395     0.872       0.95
#> 3       3      2 0.625   0.192      0.989       0.95
```
