# Marginal risk standardization via the g-formula

Fits a logistic outcome model with binary exposure and selected baseline
covariates, predicts each individual's risk under exposure 0 and
exposure 1, and averages predictions over the empirical covariate
distribution. Reports standardized risks, their difference and their
ratio. With no covariates the standardized risks equal the observed
risks in the two exposure groups.

## Usage

``` r
epi_gcomp(
  .data,
  exposure,
  outcome,
  adjust = c(),
  bootstrap = 0L,
  conf_level = 0.95
)
```

## Arguments

- .data:

  An ungrouped data frame of independent individuals.

- exposure:

  Binary 0/1 exposure column.

- outcome:

  Binary 0/1 outcome column.

- adjust:

  Tidy selection of complete baseline covariates; numeric, factor or
  logical. Defaults to no covariates.

- bootstrap:

  Number of resamples, either 0 or an integer from 100 to 2000.

- conf_level:

  Confidence level strictly between zero and one.

## Value

A tibble with four estimates (`risk_unexposed`, `risk_exposed`,
`risk_difference`, `risk_ratio`), confidence limits, record count,
requested and successful bootstrap replicates. Limits are `NA` without
bootstrap; the ratio is `NA` when the unexposed risk is zero.

## Details

A causal interpretation requires consistency, conditional
exchangeability (no unmeasured confounding), positivity/overlap,
appropriate temporal order, no informative missingness or censoring, and
a correctly specified outcome model. These assumptions cannot be
verified by the function. Only independent individual records, linear
numeric covariate terms and main effects are supported. No weighting,
interactions, time-varying confounding, clustered bootstrap, or
missing-data handling is implemented.

With `bootstrap > 0`, ordinary nonparametric individual resampling
refits the model and restandardizes to the resampled population.
Intervals are percentile intervals. Failed or warned fits are omitted,
with a warning; if more than 10 percent fail, the function aborts
without reporting intervals. Intervals conditional on successful fits
can still be biased. Set a seed for reproducibility; more than 100
replicates are generally advisable.

## Examples

``` r
d <- expand.grid(e = 0:1, age = 20:24, rep = 1:6)
d$y <- as.integer(d$rep <= 1 + d$e + (d$age %% 2))
epi_gcomp(d, e, y, adjust = age)
#> # A tibble: 4 × 7
#>   measure         estimate conf_low conf_high     n bootstrap bootstrap_success
#>   <chr>              <dbl>    <dbl>     <dbl> <int>     <int>             <int>
#> 1 risk_unexposed     0.233       NA        NA    60         0                 0
#> 2 risk_exposed       0.4         NA        NA    60         0                 0
#> 3 risk_difference    0.167       NA        NA    60         0                 0
#> 4 risk_ratio         1.71        NA        NA    60         0                 0
```
