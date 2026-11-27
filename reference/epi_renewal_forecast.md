# Probabilistic renewal forecasts

Simulates a renewal process forward from observed recent incidence. For
each trajectory, future counts are independent Poisson draws conditional
on the previous observed/simulated history:
`I[t] ~ Poisson(R * sum(w[s] * I[t-s]))`. Use a fixed `rt`, or supply
`rt_shape` and `rt_rate` to draw a single Gamma(shape, rate)
reproduction number per trajectory. The latter can propagate a
compatible gamma posterior, but does not model time variation in R. The
initial history is treated as exact and remains observed; future counts
recursively use simulated counts. The forecast has no future imports,
reporting process, uncertain weights, depletion of susceptibles, or
interventions. An all-zero history is absorbing. Prediction intervals
are empirical Monte Carlo quantiles, not guaranteed-calibrated
intervals. Set a seed for reproducibility.

## Usage

``` r
epi_renewal_forecast(
  .data,
  cases,
  weights,
  horizon = 7L,
  rt = NULL,
  rt_shape = NULL,
  rt_rate = NULL,
  nsim = 1000L,
  conf_level = 0.95
)
```

## Arguments

- .data:

  An ungrouped data frame of incidence in chronological order at equally
  spaced time intervals, with at least one row per generation lag.

- cases:

  Non-negative integer incidence counts.

- weights:

  Non-negative generation-interval probabilities for lags 1 onward,
  summing to one.

- horizon:

  Positive integer number of future steps.

- rt:

  A fixed non-negative reproduction number; mutually exclusive with
  `rt_shape` and `rt_rate`.

- rt_shape, rt_rate:

  Positive shape and rate for an optional gamma distribution of R, both
  required if `rt` is not provided.

- nsim:

  Number of independent Monte Carlo trajectories, at least two.

- conf_level:

  Central prediction interval probability, strictly between zero and
  one.

## Value

A tibble with future step, Monte Carlo mean, median, interval bounds,
and number of simulations. Time zero is the last observation; actual
dates must be assigned by the caller. Values are counts, not rates.

## Examples

``` r
d <- data.frame(cases = c(1, 2, 4, 8))
set.seed(1)
epi_renewal_forecast(d, cases, weights = 1, horizon = 3, rt = 1.2, nsim = 100)
#> # A tibble: 3 × 6
#>    step  mean median lower upper simulations
#>   <int> <dbl>  <dbl> <dbl> <dbl>       <int>
#> 1     1  9.72      9     5    15         100
#> 2     2 11.1      11     4    20         100
#> 3     3 13.0      13     2    30         100
```
