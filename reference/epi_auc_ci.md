# Stratified bootstrap confidence interval for empirical ROC AUC

Computes the rank-based empirical AUC, counting tied case-control pairs
as one half. Individual cases and controls are resampled independently
within their outcome groups; a percentile interval is formed from the
resampled AUCs. A lower-is-positive score is supported via
`direction = "lower"`. Set a random seed for reproducible intervals.

## Usage

``` r
epi_auc_ci(
  .data,
  truth,
  score,
  direction = c("higher", "lower"),
  bootstrap = 1000L,
  conf_level = 0.95
)
```

## Arguments

- .data:

  An ungrouped data frame of independent subjects.

- truth:

  Binary reference outcome, 1 for the event.

- score:

  Finite numeric score; probabilities are not required.

- direction:

  Whether `"higher"` or `"lower"` scores are more positive.

- bootstrap:

  Number of resamples, an integer from 100 to 2000.

- conf_level:

  Confidence level strictly between zero and one.

## Value

One-row tibble with AUC, percentile confidence limits, numbers of cases
and controls, confidence level and bootstrap count.

## Details

This quantifies sampling uncertainty conditional on the observed numbers
of cases and controls and the supplied scores. It does not refit a
predictive model, correct training-set optimism, account for clustering
or survey sampling, or compare correlated AUCs. Use independent
validation data and independent individuals. Small samples and highly
discrete scores can give poor percentile-interval coverage; no clinical
operating threshold is chosen.

## Examples

``` r
d <- data.frame(y = rep(0:1, each = 5), score = c(1, 2, 3, 4, 5, 2, 3, 4, 5, 6))
set.seed(17)
epi_auc_ci(d, y, score, bootstrap = 100)
#> # A tibble: 1 × 7
#>   estimate conf_low conf_high cases controls conf_level bootstrap
#>      <dbl>    <dbl>     <dbl> <int>    <int>      <dbl>     <int>
#> 1     0.68    0.310      0.88     5        5       0.95       100
```
