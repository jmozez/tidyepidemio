# Estimate exponential growth from incidence

Fits a linear regression of log positive counts against numeric time.
Zero counts cannot be logged and are rejected. Time units determine the
growth rate units. This is not a count likelihood model.

## Usage

``` r
epi_growth_rate(.data, time, cases)

epi_doubling_time(.data, time, cases)
```

## Arguments

- .data:

  A data frame with one row per observation.

- time:

  Numeric time.

- cases:

  Positive incidence counts.

## Value

A one-row tibble with growth rate and descriptive sample size.

For doubling time, a tibble with growth rate and doubling time. A
non-positive growth rate gives `NA` doubling time.

## Examples

``` r
d <- data.frame(day = 1:4, cases = exp(0.2 * (1:4)))
epi_growth_rate(d, day, cases)
#> # A tibble: 1 × 2
#>   growth_rate     n
#>         <dbl> <int>
#> 1         0.2     4
epi_doubling_time(d, day, cases)
#> # A tibble: 1 × 3
#>   growth_rate     n doubling_time
#>         <dbl> <int>         <dbl>
#> 1         0.2     4          3.47
```
