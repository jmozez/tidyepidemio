# Nowcast final reported incidence from reporting delays

Models observed reports for each onset date as a Poisson-thinned count
with known reporting fraction `F(age)`, where `age` is days from onset
to the analysis date. Independent gamma(shape, rate) priors are assigned
to each date's ultimate expected reported count. Conditional on the
observed count, the number of future reports has a negative-binomial
posterior predictive distribution with size `prior_shape + observed` and
success probability `(prior_rate + F) / (prior_rate + 1)`. The nowcast
is the already observed count plus this future-report count. The bounds
are posterior predictive intervals for the **final reported count**, not
intervals for the latent mean or the total number of infections.

## Usage

``` r
epi_nowcast(
  .data,
  onset,
  reported,
  as_of,
  delay_prob,
  prior_shape = 1,
  prior_rate = 1,
  conf_level = 0.95
)
```

## Arguments

- .data:

  An ungrouped data frame with one row per unique onset date.

- onset:

  Non-missing `Date` column containing onset dates.

- reported:

  Non-negative integer number of reports received by `as_of`.

- as_of:

  A single `Date` representing the data extraction date.

- delay_prob:

  Non-negative delay probabilities indexed from delay zero, summing to
  one. Include the entire assumed eventual reporting distribution.

- prior_shape, prior_rate:

  Positive shape and rate of the gamma prior for each onset date's
  eventual mean reported count.

- conf_level:

  Central posterior predictive interval probability in (0,1).

## Value

Input tibble with `reporting_fraction`, `nowcast_mean`, `nowcast_low`,
and `nowcast_high`. Rows with full reporting fraction have a degenerate
prediction equal to the observed count.

## Details

Assumes the provided delay distribution is known, constant across dates
and representative of eventual reports. It does not correct for
permanently unreported infections, changing delay distributions,
reporting day effects, revisions, duplicated reports, unknown onset
dates, or temporal dependence. The gamma prior is independent across
dates and can dominate dates with low reporting completeness. Missing
dates are not inserted. Delay probabilities are discrete for delays 0,
1, ..., with total one. All input observations must represent reports
actually available as of `as_of`.

## Examples

``` r
d <- data.frame(onset = as.Date("2024-01-01") + 0:2, reported = c(10, 8, 3))
epi_nowcast(d, onset, reported,
  as_of = as.Date("2024-01-03"),
  delay_prob = c(.5, .3, .2), prior_shape = 2, prior_rate = 1
)
#> # A tibble: 3 × 6
#>   onset      reported reporting_fraction nowcast_mean nowcast_low nowcast_high
#>   <date>        <dbl>              <dbl>        <dbl>       <dbl>        <dbl>
#> 1 2024-01-01       10                1          10             10           10
#> 2 2024-01-02        8                0.8         9.11           8           12
#> 3 2024-01-03        3                0.5         4.67           3            8
```
