# Rolling-origin renewal forecast backtesting

At each expanding training origin, estimates a constant reproduction
number from only the preceding incidence using a gamma-Poisson renewal
posterior. It then forecasts `horizon` periods with
[`epi_renewal_forecast()`](https://tidyepidemio.in4metrix.dev/reference/epi_renewal_forecast.md)
and pairs each forecast with the later observed count. In `"posterior"`
mode, each trajectory draws a fixed future R from the training
posterior; `"fixed"` mode uses the posterior mean. Neither model learns
time variation or adjusts for imports, reporting delays, susceptible
depletion, data revisions or observation error. Posterior intervals are
conditional on the prior, known generation weights, model assumptions
and observed history; they are not automatically calibrated.

## Usage

``` r
epi_renewal_backtest(
  .data,
  time,
  cases,
  weights,
  initial,
  horizon = 1L,
  stride = 1L,
  mode = c("posterior", "fixed"),
  prior_shape = 1,
  prior_rate = 1,
  nsim = 1000L,
  conf_level = 0.95
)
```

## Arguments

- .data:

  Ungrouped data frame ordered by time with one row per period.

- time:

  Regular, strictly increasing numeric or whole-day Date column.

- cases:

  Non-negative integer incidence counts.

- weights:

  Discrete generation-interval probabilities for lags 1 onward, summing
  to one.

- initial:

  Number of observations in the first training window; must exceed the
  number of generation lags.

- horizon:

  Number of future periods per assessment window.

- stride:

  Number of rows between successive forecast origins.

- mode:

  Either `"posterior"` for gamma-distributed R or `"fixed"` for the
  training posterior mean.

- prior_shape, prior_rate:

  Positive gamma prior shape and rate for R.

- nsim:

  Number of simulation trajectories per origin, at least two.

- conf_level:

  Central prediction interval probability, strictly in (0,1).

## Value

One row per origin and future horizon, with origin/target times,
observed outcome, posterior mean R and forecast mean, median and
interval bounds. Each origin uses only its training observations.

## Details

The data must be a single complete series with regular numeric or Date
time. The initial period and every assessment horizon are disjoint
within an origin; assessment windows from different origins can overlap
and are dependent. The backtest assumes historical observations were
available without delay at their time of origin. In real surveillance,
use vintage data reflecting what was known at each forecast date rather
than revised final counts. Set a seed for reproducible Monte Carlo
forecasts.

## Examples

``` r
d <- data.frame(day = 1:8, cases = c(1, 2, 4, 8, 16, 32, 64, 128))
set.seed(1)
backtest <- epi_renewal_backtest(d, day, cases,
  weights = 1, initial = 4,
  horizon = 2, nsim = 100
)
wis(backtest, observed, forecast_median, forecast_low, forecast_high, alpha = .05)
#> # A tibble: 1 × 3
#>   .metric .estimator .estimate
#>   <chr>   <chr>          <dbl>
#> 1 wis     standard        2.77
```
