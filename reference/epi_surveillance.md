# Prospective Poisson surveillance threshold

Uses a trailing window of preceding counts to estimate a constant
Poisson mean and flags the current count if it exceeds the `(1-alpha)`
Poisson quantile. This is a simple screening rule, not a validated
outbreak detection system: it ignores seasonality, trends, reporting
delays and changes in population. With `family = "negbin"`, a negative
binomial null is used whose dispersion is estimated by moments from the
same window (Poisson when the window variance does not exceed its mean);
short windows give unstable dispersion. Each screened row gets an
upper-tail p-value, and `adjust` applies
[`stats::p.adjust()`](https://rdrr.io/r/stats/p.adjust.html) across all
screened rows. Flags are not outbreak diagnoses.

## Usage

``` r
epi_surveillance(
  .data,
  cases,
  window = 4L,
  alpha = 0.05,
  family = c("poisson", "negbin"),
  adjust = "none"
)
```

## Arguments

- .data:

  An ungrouped data frame in chronological order at regular intervals.

- cases:

  Non-negative integer counts.

- window:

  Number of preceding observations in the baseline.

- alpha:

  Nominal upper-tail probability, strictly between zero and one.

- family:

  Null count model: `"poisson"` or `"negbin"`.

- adjust:

  Multiple-testing adjustment passed to
  [`stats::p.adjust()`](https://rdrr.io/r/stats/p.adjust.html).

## Value

Input tibble with baseline mean, threshold, p-value, adjusted p-value
and logical alert columns. These are `NA` for the first `window` rows.

## Examples

``` r
d <- data.frame(day = 1:6, cases = c(1, 2, 1, 2, 1, 10))
epi_surveillance(d, cases, window = 3, alpha = 0.05)
#> # A tibble: 6 × 7
#>     day cases baseline_mean threshold     p_value  p_adjusted alert
#>   <int> <dbl>         <dbl>     <dbl>       <dbl>       <dbl> <lgl>
#> 1     1     1         NA           NA NA          NA          NA   
#> 2     2     2         NA           NA NA          NA          NA   
#> 3     3     1         NA           NA NA          NA          NA   
#> 4     4     2          1.33         3  0.385       0.385      FALSE
#> 5     5     1          1.67         4  0.811       0.811      FALSE
#> 6     6    10          1.33         3  0.00000147  0.00000147 TRUE 
```
