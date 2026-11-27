# Weighted marginal risks and contrasts

Computes separately normalized (Hájek) weighted risks for the exposed
and unexposed groups, their difference, and their ratio. Effective
sample sizes are `(sum w)^2 / sum(w^2)` within each group. With
`bootstrap > 0`, records are resampled with their supplied weights held
fixed and percentile intervals are returned for the risk difference and
ratio. Holding estimated propensity weights fixed ignores their
estimation; for inverse-probability weights this usually makes intervals
conservative. Use
[`epi_ipw()`](https://tidyepidemio.in4metrix.dev/reference/epi_ipw.md)
to re-estimate the propensity model in every resample. This function
does not test covariate balance or establish a causal interpretation.

## Usage

``` r
epi_weighted_effect(
  .data,
  exposure,
  outcome,
  weights,
  bootstrap = 0L,
  conf_level = 0.95
)
```

## Arguments

- .data:

  A data frame of individual records.

- exposure:

  Binary 0/1 exposure column.

- outcome:

  Binary 0/1 outcome column.

- weights:

  Non-negative numeric weights, with a positive total in each exposure
  group. Zero weights are allowed.

- bootstrap:

  Number of individual bootstrap resamples: 0 (no intervals) or an
  integer from 100 to 2000.

- conf_level:

  Confidence level strictly between zero and one.

## Value

A one-row tibble with group risks, risk difference, risk ratio,
effective sample sizes and original sample size, plus percentile limits
for the difference and ratio when bootstrapping. An undefined ratio is
`NA`.

## Examples

``` r
d <- data.frame(e = c(0, 0, 1, 1), y = c(0, 1, 1, 1), w = c(1, 1, 2, 1))
epi_weighted_effect(d, e, y, w)
#> # A tibble: 1 × 7
#>   risk_unexposed risk_exposed risk_difference risk_ratio ess_unexposed
#>            <dbl>        <dbl>           <dbl>      <dbl>         <dbl>
#> 1            0.5            1             0.5          2             2
#> # ℹ 2 more variables: ess_exposed <dbl>, n <int>
```
