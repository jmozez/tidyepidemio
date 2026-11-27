# Exact Poisson confidence interval for an incidence rate

Uses the exact chi-squared interval for the count assuming a Poisson
model with fixed total person-time. This does not handle overdispersion,
recurrent event dependence, or complex sampling. A count of zero has a
lower bound of zero and a positive upper bound.

## Usage

``` r
epi_rate_ci(.data, events, time, conf_level = 0.95, multiplier = 1)
```

## Arguments

- .data:

  A data frame containing individual records or count totals.

- events:

  Non-negative integer event counts per row.

- time:

  Non-negative person-time per row; total must be positive.

- conf_level:

  Confidence level strictly between zero and one.

- multiplier:

  Positive scaling factor for the rate and limits.

## Value

A one-row tibble with counts, person-time, estimate and limits.

## Examples

``` r
epi_rate_ci(data.frame(events = c(1, 2, 0), time = c(2, 3, 1)), events, time, multiplier = 100)
#> # A tibble: 1 × 6
#>   events person_time estimate conf_low conf_high conf_level
#>    <dbl>       <dbl>    <dbl>    <dbl>     <dbl>      <dbl>
#> 1      3           6       50     10.3      146.       0.95
```
