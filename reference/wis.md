# Weighted interval score

Computes the mean WIS for a median and one or more central prediction
intervals. For K intervals it is
`(0.5 * |y - median| + sum(alpha/2 * IS)) / (K + 0.5)`, where IS is
interval width plus `2/alpha` times miss distance. Lower scores are
better. Pairs of lower and upper columns must be supplied in
corresponding order matching the miscoverage probabilities in `alpha`.
WIS requires interval columns in addition to the median; use
[`wis_metric()`](https://tidyepidemio.in4metrix.dev/reference/wis_metric.md)
to capture those columns for a yardstick `metric_set()`.

## Usage

``` r
wis(.data, ...)

wis_vec(
  truth,
  estimate,
  lower,
  upper,
  alpha = 0.1,
  na_rm = TRUE,
  case_weights = NULL,
  ...
)
```

## Arguments

- .data:

  A data frame; grouped data are summarized by group.

- ...:

  Not used.

- truth:

  Numeric observed outcome.

- estimate:

  Numeric predicted median.

- lower, upper:

  Tidy selections of numeric interval columns. For the vector method,
  numeric vectors for one interval, or numeric matrices with one row per
  observation and one column per interval.

- alpha:

  Numeric vector of interval miscoverage probabilities in (0,1).

- na_rm:

  Remove rows with missing inputs?

- case_weights:

  Optional non-negative case weights, or a weight column.

## Value

A yardstick-style tibble with `.metric`, `.estimator`, `.estimate`; the
vector method returns a numeric scalar.

## Examples

``` r
d <- data.frame(y = c(1, 2), med = c(1, 3), lo = c(0, 1), hi = c(2, 4))
wis(d, y, med, lo, hi, alpha = 0.1)
#>   .metric .estimator .estimate
#> 1     wis   standard      0.25
wis_vec(d$y, d$med, d$lo, d$hi, alpha = 0.1)
#> [1] 0.25
```
