# Renewal-equation effective reproduction number

Computes `I[t] / sum(I[t-s] * w[s])` for prior observed incidence. The
generation-interval weights start at lag 1, must sum to one, and are not
renormalized at the beginning of the series. Early estimates are `NA`
until all lags are observed; zero infectiousness also gives `NA`.
Imported cases, uncertainty, reporting delays, and right censoring are
not modeled.

## Usage

``` r
epi_rt(.data, cases, weights)
```

## Arguments

- .data:

  A data frame in chronological order with equally spaced rows.

- cases:

  Non-negative incidence counts.

- weights:

  Non-negative generation-interval probability mass by lag.

## Value

The input tibble with an `rt` column.

## Examples

``` r
epi_rt(data.frame(cases = c(1, 2, 4, 8)), cases, weights = 1)
#> # A tibble: 4 × 2
#>   cases    rt
#>   <dbl> <dbl>
#> 1     1    NA
#> 2     2     2
#> 3     4     2
#> 4     8     2
```
