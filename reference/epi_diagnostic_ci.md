# Confidence intervals for diagnostic proportions

Calculates sensitivity, specificity, positive predictive value and
negative predictive value with Wilson or exact Clopper-Pearson binomial
intervals. Predictive values depend on sample prevalence and may not
generalize to a different setting. Conditional binomial intervals assume
independent subjects, accurate reference classification, representative
sampling, and fixed denominators; they do not incorporate uncertainty in
prevalence adjustment, clustering, verification bias, imperfect
reference standards, or sampling design. Likelihood ratios and Youden's
index are reported by
[`epi_diagnostic()`](https://tidyepidemio.in4metrix.dev/reference/epi_diagnostic.md)
without intervals.

## Usage

``` r
epi_diagnostic_ci(
  .data,
  test,
  truth,
  method = c("wilson", "exact"),
  conf_level = 0.95
)
```

## Arguments

- .data:

  A data frame with one row per subject.

- test:

  Binary index-test result, where 1 is positive.

- truth:

  Binary reference status, where 1 means diseased.

- method:

  `"wilson"` or `"exact"`.

- conf_level:

  Confidence level strictly between zero and one.

## Value

A four-row tibble with metric, numerator, denominator, estimate and
confidence limits. A zero denominator gives missing estimate and limits.

## Examples

``` r
d <- data.frame(test = c(1, 1, 0, 0), truth = c(1, 0, 1, 0))
epi_diagnostic_ci(d, test, truth, method = "exact")
#> # A tibble: 4 × 8
#>   metric     numerator denominator estimate conf_low conf_high conf_level method
#>   <chr>          <int>       <int>    <dbl>    <dbl>     <dbl>      <dbl> <chr> 
#> 1 sensitivi…         1           2      0.5   0.0126     0.987       0.95 exact 
#> 2 specifici…         1           2      0.5   0.0126     0.987       0.95 exact 
#> 3 ppv                1           2      0.5   0.0126     0.987       0.95 exact 
#> 4 npv                1           2      0.5   0.0126     0.987       0.95 exact 
```
