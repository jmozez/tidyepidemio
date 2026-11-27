# Discretised probabilities of a fitted delay

Converts a delay distribution from
[`epi_delay_dist()`](https://tidyepidemio.in4metrix.dev/reference/epi_delay_dist.md)
into the probability of each whole-day delay, using the same double
interval censoring as the fit, so it can be used as a reporting delay
([`epi_cfr()`](https://tidyepidemio.in4metrix.dev/reference/epi_cfr.md),
[`epi_nowcast()`](https://tidyepidemio.in4metrix.dev/reference/epi_nowcast.md))
or as generation-interval weights
([`epi_rt()`](https://tidyepidemio.in4metrix.dev/reference/epi_rt.md),
after dropping day 0 and renormalising).

## Usage

``` r
epi_delay_pmf(fit, max_delay, family = NULL)
```

## Arguments

- fit:

  A `tep_delay` tibble from
  [`epi_delay_dist()`](https://tidyepidemio.in4metrix.dev/reference/epi_delay_dist.md).

- max_delay:

  Longest delay to include, in days.

- family:

  Family to use; defaults to the best by AIC (first row).

## Value

A tibble with `delay` (0 to `max_delay`) and `probability`, renormalised
to sum to one.

## Examples

``` r
set.seed(2)
d <- data.frame(delay = round(rgamma(200, 4, 1)))
fit <- epi_delay_dist(d, delay, family = "gamma")
epi_delay_pmf(fit, max_delay = 15)
#> # A tibble: 16 × 2
#>    delay probability
#>    <int>       <dbl>
#>  1     0    0.00484 
#>  2     1    0.0686  
#>  3     2    0.172   
#>  4     3    0.213   
#>  5     4    0.190   
#>  6     5    0.140   
#>  7     6    0.0913  
#>  8     7    0.0550  
#>  9     8    0.0311  
#> 10     9    0.0168  
#> 11    10    0.00879 
#> 12    11    0.00445 
#> 13    12    0.00220 
#> 14    13    0.00107 
#> 15    14    0.000508
#> 16    15    0.000239
```
