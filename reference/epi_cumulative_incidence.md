# Cumulative incidence with competing risks

Uses the Aalen-Johansen product-limit estimator for one event cause. At
each event time, increments the target cumulative incidence by survival
just before the time multiplied by target events divided by the risk
set; survival is then updated for all event causes. Censored individuals
at a given time remain in the risk set for events at that time.

## Usage

``` r
epi_cumulative_incidence(
  .data,
  time,
  status,
  cause = 1L,
  strata = NULL,
  conf_level = 0.95,
  entry = NULL
)
```

## Arguments

- .data:

  An ungrouped data frame of independent individuals.

- time:

  Non-negative follow-up or exit time.

- status:

  Non-negative integer event code: 0 means censored, and every positive
  value denotes a distinct event cause.

- cause:

  Positive integer code identifying the event of interest.

- strata:

  Optional complete grouping column; defaults to one curve.

- conf_level:

  Confidence level strictly between zero and one.

- entry:

  Optional delayed-entry (left-truncation) time, strictly less than
  `time` for every row; defaults to entry at time zero.

## Value

A tibble of stratum, observed times, risk set, target and competing
event counts, censor counts, event-free survival, and target cumulative
incidence with confidence limits. The pre-event time-zero row is not
inserted automatically.

## Details

Confidence limits come from the Aalen-Johansen variance computed by
[`survival::survfit()`](https://rdrr.io/pkg/survival/man/survfit.html)
for a multi-state outcome, on the log scale; they can be unreliable with
few events. With `entry`, individuals join the risk set only after their
delayed-entry time (left truncation), which must be independent of the
event processes. Assumes independent censoring within strata; there is
no covariate adjustment. Treating competing events as ordinary censoring
in Kaplan-Meier would not estimate this quantity.

## Examples

``` r
d <- data.frame(time = 1:4, status = c(1, 2, 0, 1))
epi_cumulative_incidence(d, time, status, cause = 1)
#> # A tibble: 4 × 10
#>   strata  time n_risk n_target n_competing n_censor event_free_survival
#>   <chr>  <int>  <dbl>    <dbl>       <dbl>    <dbl>               <dbl>
#> 1 All        1      4        1           0        0                0.75
#> 2 All        2      3        0           1        0                0.5 
#> 3 All        3      2        0           0        1                0.5 
#> 4 All        4      1        1           0        0                0   
#> # ℹ 3 more variables: cumulative_incidence <dbl>, conf_low <dbl>,
#> #   conf_high <dbl>
```
