# Sliding-window renewal Rt with gamma posterior intervals

With fixed lag weights and a gamma(shape, rate) prior, assumes
independent local incidence `I[t] ~ Poisson(R * lambda[t])`, with
infectiousness `lambda[t] = sum_s w[s] * (local[t-s] + imported[t-s])`.
Assumes a constant R within each rolling window. Imported incidence
contributes to infectiousness but not the likelihood numerator. Only
windows whose entire lag history is observed are estimated. Zero
infectiousness with positive local incidence is incompatible and
rejected. Overlapping windows are correlated. The model does not account
for uncertain generation intervals, reporting delays, incomplete
ascertainment, superspreading, or right censoring; intervals are
conditional on the supplied counts, imports, weights and prior.

## Usage

``` r
epi_rt_gamma(
  .data,
  cases,
  weights,
  window = 7L,
  imported = NULL,
  prior_shape = 1,
  prior_rate = 1,
  conf_level = 0.95
)
```

## Arguments

- .data:

  An ungrouped data frame sorted in equally spaced time order.

- cases:

  Local non-negative integer incidence counts.

- weights:

  Non-negative discrete generation interval probabilities for lags 1
  onward, summing to one.

- window:

  Number of likelihood days in each rolling window.

- imported:

  Optional non-negative integer imported count column. Defaults to zero
  imports. Imported cases must be classified before analysis.

- prior_shape, prior_rate:

  Positive shape and rate of the gamma prior.

- conf_level:

  Posterior credible level strictly between zero and one.

## Value

Input tibble with `infectiousness`, `rt_mean`, `rt_low`, `rt_high`;
early rows without full history/window are `NA`.

## Examples

``` r
d <- data.frame(day = 1:8, cases = c(1, 2, 4, 8, 16, 32, 64, 128))
epi_rt_gamma(d, cases, weights = 1, window = 3)
#> # A tibble: 8 × 6
#>     day cases infectiousness rt_mean rt_low rt_high
#>   <int> <dbl>          <dbl>   <dbl>  <dbl>   <dbl>
#> 1     1     1             NA   NA     NA      NA   
#> 2     2     2              1   NA     NA      NA   
#> 3     3     4              2   NA     NA      NA   
#> 4     4     8              4    1.88   1.05    2.94
#> 5     5    16              8    1.93   1.29    2.70
#> 6     6    32             16    1.97   1.49    2.51
#> 7     7    64             32    1.98   1.63    2.36
#> 8     8   128             64    1.99   1.74    2.26
```
