# Covariate balance before and after weighting

Computes standardized mean differences (SMDs) between binary exposure
groups for numeric covariates and indicators for each observed factor or
logical level. Both unweighted and weighted SMDs use the same
denominator: the square root of the mean of the two **unweighted sample
variances** within exposure groups. The numerator is the exposed mean
minus the unexposed mean, before or after separate group normalization
of weights. Using a fixed denominator helps avoid apparent balance
improvements caused only by changing weighted variance.

## Usage

``` r
epi_balance(.data, exposure, covariates, weights = NULL)
```

## Arguments

- .data:

  An ungrouped data frame of individual observations.

- exposure:

  Binary 0/1 exposure column.

- covariates:

  Tidy selection of complete numeric, factor or logical covariate
  columns. Factor and logical variables expand to level indicators.

- weights:

  Optional non-negative numeric weight column. Defaults to equal
  weights; each exposure group must have positive total weight.

## Value

A tibble with covariate, level (`NA` for numeric variables), unweighted
and weighted group means, fixed reference standard deviation and
unweighted and weighted SMDs. Exposure 1 minus exposure 0 defines the
sign.

## Details

SMDs are descriptive diagnostics, not tests of exchangeability,
positivity, correct model specification or causal validity. They do not
diagnose balance of interactions or nonlinear transformations unless
supplied as columns, and there is no universally sufficient threshold.
Undefined SMDs caused by a zero pooled standard deviation are `NA`; this
may indicate severe non-overlap.

## Examples

``` r
d <- data.frame(e = c(0, 0, 1, 1), age = c(20, 30, 30, 40), w = c(1, 2, 2, 1))
epi_balance(d, e, age, weights = w)
#> # A tibble: 1 × 9
#>   covariate level mean_unexposed mean_exposed weighted_mean_unexposed
#>   <chr>     <chr>          <dbl>        <dbl>                   <dbl>
#> 1 age       NA                25           35                    26.7
#> # ℹ 4 more variables: weighted_mean_exposed <dbl>, reference_sd <dbl>,
#> #   smd_unweighted <dbl>, smd_weighted <dbl>
```
