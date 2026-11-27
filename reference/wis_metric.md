# Create a WIS metric for yardstick metric sets

Constructs a numeric yardstick metric that uses preselected lower and
upper interval columns. The selections are resolved against `.data` at
creation time and the resulting metric uses those names on each
evaluation. This allows WIS to be combined with ordinary numeric metrics
that accept only `truth` and `estimate` selections. The same interval
columns must be present whenever the metric is evaluated. WIS
interpretation and assumptions are identical to
[`wis()`](https://tidyepidemio.in4metrix.dev/reference/wis.md). Grouping
and case weights are supported.

## Usage

``` r
wis_metric(.data, lower, upper, alpha = 0.1)
```

## Arguments

- .data:

  A data frame used to resolve interval column selections.

- lower, upper:

  Tidy selections of lower and upper interval columns, in corresponding
  order.

- alpha:

  Numeric vector of distinct miscoverage probabilities, one per
  interval, in the same order as the selected columns.

## Value

A `yardstick` numeric metric function. Its result has `.metric` equal to
`"wis"`.

## Examples

``` r
d <- data.frame(y = c(1, 2), med = c(1, 3), lo = c(0, 1), hi = c(2, 4))
interval_score <- wis_metric(d, lo, hi, alpha = .1)
metrics <- yardstick::metric_set(yardstick::rmse, interval_score)
metrics(d, truth = y, estimate = med)
#> # A tibble: 2 × 3
#>   .metric .estimator .estimate
#>   <chr>   <chr>          <dbl>
#> 1 rmse    standard       0.707
#> 2 wis     standard       0.25 
```
