# Tidy epidemiological results and fitted epidemic models

`tidy()` returns a tibble of effect estimates or model parameters.
`glance()` returns a one-row description. `augment()` on an `epi_model`
returns fitted and residual values for training data, or predictions for
supplied new data. For the renewal model, early fitted values are
missing until all lags exist.

## Usage

``` r
# S3 method for class 'epi_result'
tidy(x, ...)

# S3 method for class 'epi_result'
glance(x, ...)

# S3 method for class 'epi_model'
tidy(x, ...)

# S3 method for class 'epi_model'
glance(x, ...)

# S3 method for class 'epi_model'
augment(x, data = NULL, ...)
```

## Arguments

- x:

  An `epi_result` or `epi_model` object.

- ...:

  Unused.

- data:

  Optional new data for `augment()`; default uses training records.

## Value

A tibble of estimates, summary information, or augmented observations.

## Examples

``` r
d <- data.frame(e = rep(0:1, each = 4), y = c(0, 0, 0, 1, 0, 1, 1, 1))
x <- epi_risk_ratio(d, e, y)
generics::tidy(x)
#> # A tibble: 1 × 9
#>   measure    estimate conf_low conf_high exposed_events exposed_total
#>   <chr>         <dbl>    <dbl>     <dbl>          <dbl>         <dbl>
#> 1 risk_ratio        3    0.501      18.0              3             4
#> # ℹ 3 more variables: unexposed_events <dbl>, unexposed_total <dbl>,
#> #   correction <dbl>
f <- fit_epi_renewal(y ~ time, data.frame(time = 1:4, y = c(1, 2, 4, 8)))
generics::augment(f)
#> # A tibble: 4 × 4
#>    time     y .fitted .resid
#>   <int> <dbl>   <dbl>  <dbl>
#> 1     1     1      NA     NA
#> 2     2     2       2      0
#> 3     3     4       4      0
#> 4     4     8       8      0
```
