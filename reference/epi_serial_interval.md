# Summarize observed serial intervals

Calculates the difference in days between infectee and infector onset
dates. Negative intervals are allowed and should be assessed for data
quality.

## Usage

``` r
epi_serial_interval(.data, infector, infectee)
```

## Arguments

- .data:

  A data frame with paired onset dates.

- infector:

  Onset date for the infector, as a Date.

- infectee:

  Onset date for the infectee, as a Date.

## Value

A tibble with count, mean and sample standard deviation in days.

## Examples

``` r
d <- data.frame(a = as.Date("2020-01-01") + 0:2, b = as.Date("2020-01-01") + 2:4)
epi_serial_interval(d, a, b)
#> # A tibble: 1 × 3
#>       n mean_days sd_days
#>   <int>     <dbl>   <dbl>
#> 1     3         2       0
```
