# Diagnostic test performance

Calculates sensitivity, specificity, predictive values, likelihood
ratios, and Youden's index from binary test and reference standard
observations. Predictive values depend on the prevalence in the supplied
sample.

## Usage

``` r
epi_diagnostic(.data, test, truth)
```

## Arguments

- .data:

  A data frame with one row per subject.

- test:

  Binary index-test result; 1 is positive.

- truth:

  Binary reference status; 1 is diseased.

## Value

A one-row tibble of counts and diagnostic estimates. Undefined
quantities are `NA`.

## Examples

``` r
d <- data.frame(test = c(1, 1, 0, 0), truth = c(1, 0, 1, 0))
epi_diagnostic(d, test, truth)
#> # A tibble: 1 × 11
#>      tp    fp    fn    tn sensitivity specificity   ppv   npv lr_positive
#>   <int> <int> <int> <int>       <dbl>       <dbl> <dbl> <dbl>       <dbl>
#> 1     1     1     1     1         0.5         0.5   0.5   0.5           1
#> # ℹ 2 more variables: lr_negative <dbl>, youden <dbl>
```
