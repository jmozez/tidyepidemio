# Mantel-Haenszel test and confidence interval

Calculates the asymptotic Cochran-Mantel-Haenszel test for conditional
association between binary exposure and outcome given strata, together
with the Mantel-Haenszel common odds ratio and its approximate
confidence interval. `correction=TRUE` applies the continuity correction
to the test statistic. Assumes independent records and a sufficiently
informative set of strata; the common odds ratio is most interpretable
when stratum odds ratios are reasonably homogeneous. The test itself
does not test homogeneity, adjust for other confounders, or establish
causality.

## Usage

``` r
epi_mantel_haenszel_test(
  .data,
  exposure,
  outcome,
  strata,
  correction = FALSE,
  conf_level = 0.95
)
```

## Arguments

- .data:

  An ungrouped data frame of individual records.

- exposure:

  Binary 0/1 exposure indicator.

- outcome:

  Binary 0/1 outcome indicator.

- strata:

  Non-missing categorical or numeric stratum column.

- correction:

  Whether to use a continuity correction.

- conf_level:

  Confidence level strictly between zero and one.

## Value

An `epi_result` tibble with common odds ratio, confidence limits,
chi-squared statistic, p-value and number of strata.

## Examples

``` r
d <- data.frame(e = rep(c(0, 0, 1, 1), 2), y = rep(c(0, 1, 0, 1), 2), s = rep(1:2, each = 4))
epi_mantel_haenszel_test(d, e, y, s)
#> # A tibble: 1 × 8
#>   measure        estimate conf_low conf_high statistic p_value strata correction
#>   <chr>             <dbl>    <dbl>     <dbl>     <dbl>   <dbl>  <int> <lgl>     
#> 1 mantel_haensz…        1   0.0625      16.0         0       1      2 FALSE     
```
