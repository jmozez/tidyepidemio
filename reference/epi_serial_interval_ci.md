# Confidence interval for a mean serial interval

Computes the sample mean and an ordinary Student t confidence interval
for paired onset-date differences, in days. Intervals can be negative.
The method assumes independent transmission pairs and approximate
normality of the sample mean; it does not account for right truncation,
interval censoring, epidemic-phase bias, uncertainty in transmission
links, or repeated infectors. These limitations can be severe during an
ongoing outbreak.

## Usage

``` r
epi_serial_interval_ci(.data, infector, infectee, conf_level = 0.95)
```

## Arguments

- .data:

  A data frame of transmission pairs.

- infector:

  Non-missing infector onset Date column.

- infectee:

  Non-missing infectee onset Date column.

- conf_level:

  Confidence level strictly between zero and one.

## Value

A one-row tibble with number of pairs, mean and sample standard
deviation in days, confidence limits, and confidence level.

## Examples

``` r
d <- data.frame(a = as.Date("2024-01-01") + 0:3, b = as.Date("2024-01-01") + c(2, 4, 5, 7))
epi_serial_interval_ci(d, a, b)
#> # A tibble: 1 × 6
#>       n mean_days sd_days conf_low conf_high conf_level
#>   <int>     <dbl>   <dbl>    <dbl>     <dbl>      <dbl>
#> 1     4         3   0.816     1.70      4.30       0.95
```
