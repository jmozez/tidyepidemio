# Confidence interval for a binary proportion

Calculates a Wilson score or Clopper-Pearson exact binomial confidence
interval. The interval assumes independent, identically distributed
Bernoulli outcomes; it does not account for clustering, survey design,
or weights.

## Usage

``` r
epi_proportion_ci(
  .data,
  event,
  conf_level = 0.95,
  method = c("wilson", "exact")
)
```

## Arguments

- .data:

  A data frame containing independent individual records.

- event:

  Binary 0/1 or logical event indicator, with no missing values.

- conf_level:

  Confidence level strictly between zero and one.

- method:

  Either `"wilson"` or `"exact"`.

## Value

A one-row tibble with events, total, estimate and confidence limits.

## Examples

``` r
epi_proportion_ci(data.frame(event = c(1, 1, 0, 0, 0)), event)
#> # A tibble: 1 × 7
#>   events total estimate conf_low conf_high conf_level method
#>    <dbl> <int>    <dbl>    <dbl>     <dbl>      <dbl> <chr> 
#> 1      2     5      0.4    0.118     0.769       0.95 wilson
epi_proportion_ci(data.frame(event = c(1, 1, 0, 0, 0)), event, method = "exact")
#> # A tibble: 1 × 7
#>   events total estimate conf_low conf_high conf_level method
#>    <dbl> <int>    <dbl>    <dbl>     <dbl>      <dbl> <chr> 
#> 1      2     5      0.4   0.0527     0.853       0.95 exact 
```
