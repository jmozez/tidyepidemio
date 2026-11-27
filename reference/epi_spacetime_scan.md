# Prospective circular space-time Poisson scan

Searches circles centered on input locations and trailing windows ending
at the most recent time period. `cases` selects one integer-count column
per consecutive, equally sized time period, ordered oldest to newest.
Each circle-window is compared with all remaining location-time cells
using the conditional Poisson log likelihood ratio; only increases are
considered. Under the null, the total cases are distributed
multinomially with each location-time cell weighted by that location's
fixed population. The global Monte Carlo p-value compares the maximum
observed score with the maxima across the identical candidate set in
each null simulation, using `(1 + number >= observed) / (nsim + 1)`.
`nsim=0` skips the test.

## Usage

``` r
epi_spacetime_scan(
  .data,
  x,
  y,
  cases,
  population,
  radii,
  windows = NULL,
  max_fraction = 0.5,
  nsim = 199L
)
```

## Arguments

- .data:

  Data frame, one row per location, with case-count columns for each
  equally spaced time period.

- x, y:

  Numeric finite projected coordinate columns, in units of radii.

- cases:

  Tidy selection of case-count columns ordered oldest to newest.

- population:

  Positive population or exposure at each location, held constant across
  all time periods.

- radii:

  Positive distinct candidate circle radii.

- windows:

  Positive distinct integer trailing window lengths no larger than the
  number of selected case columns. Defaults to all possible lengths.

- max_fraction:

  Maximum fraction of total population within each circle, strictly
  between zero and one.

- nsim:

  Number of conditional null simulations; 0 skips the test.

## Value

One-row tibble describing the maximum-scoring circle and trailing
window, inside observed and expected counts, relative risk, log
likelihood ratio, and globally calibrated Monte Carlo p-value. If all
scores are zero, the first candidate is arbitrary. Relative risk is
infinite when all cases are inside the winning space-time window.

## Details

Assumptions are a constant underlying risk over space and time,
independent Poisson counts, fixed populations, comparable periods, and a
spatial point representation of each location. The candidate set uses
projected planar coordinates, not latitude/longitude, and does not
adjust for seasonality, trends, covariates, changing populations,
reporting delay or overdispersion. It does not implement a flexible
space-time scan or multiple-outbreak correction across repeated runs. A
flag is not evidence of causation. Set a seed to reproduce Monte Carlo
results. Simultaneous testing across repeated surveillance dates
requires additional calibration.

## References

Kulldorff M (2001). Prospective time periodic geographical disease
surveillance using a scan statistic. Journal of the Royal Statistical
Society Series A 164:61-72. doi:10.1111/1467-985X.00186

## Examples

``` r
d <- data.frame(
  x = c(0, 1, 10, 11), y = 0, pop = 100,
  day1 = c(1, 1, 1, 1), day2 = c(8, 7, 1, 1)
)
set.seed(1)
epi_spacetime_scan(d, x, y, c(day1, day2), pop, radii = c(.1, 1), nsim = 19)
#> # A tibble: 1 × 11
#>   center_x center_y radius window observed expected relative_risk
#>      <dbl>    <dbl>  <dbl>  <int>    <dbl>    <dbl>         <dbl>
#> 1        0        0      1      1       15     5.25           7.5
#> # ℹ 4 more variables: log_likelihood_ratio <dbl>, p_value <dbl>,
#> #   simulations <int>, candidates <int>
```
