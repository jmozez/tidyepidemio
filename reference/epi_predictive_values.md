# Predictive values at specified disease prevalences

Estimates sensitivity and specificity from the supplied test/reference
data, then uses Bayes' rule to calculate positive and negative
predictive values at each specified target prevalence. Both diseased and
non-diseased subjects are required in the reference data. The method
assumes that sensitivity and specificity transport unchanged to the
target setting and that the supplied prevalence is appropriate. Spectrum
effects, imperfect reference standards, verification bias and
uncertainty in prevalence or test accuracy are not addressed. Intervals
are not calculated.

## Usage

``` r
epi_predictive_values(.data, test, truth, prevalence)
```

## Arguments

- .data:

  An ungrouped data frame of individual test observations.

- test:

  Binary test indicator, where 1 denotes a positive result.

- truth:

  Binary reference disease indicator, where 1 denotes disease.

- prevalence:

  Numeric vector of distinct target prevalences in `[0,1]`.

## Value

A tibble with each target prevalence, sample sensitivity and
specificity, and implied positive and negative predictive values. A zero
probability of a positive or negative test yields the corresponding
`NA`.

## Examples

``` r
d <- data.frame(test = c(1, 1, 0, 0), truth = c(1, 0, 1, 0))
epi_predictive_values(d, test, truth, prevalence = c(.01, .1, .5))
#> # A tibble: 3 × 5
#>   prevalence sensitivity specificity   ppv   npv
#>        <dbl>       <dbl>       <dbl> <dbl> <dbl>
#> 1       0.01         0.5         0.5  0.01  0.99
#> 2       0.1          0.5         0.5  0.1   0.9 
#> 3       0.5          0.5         0.5  0.5   0.5 
```
