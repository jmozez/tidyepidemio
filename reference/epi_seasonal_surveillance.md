# Seasonal Poisson surveillance using an earlier baseline

Fits a Poisson log-linear baseline with Fourier seasonal terms to a
separate training data frame, then flags later observed counts that
exceed the `(1 - alpha)` Poisson quantile at the fitted mean. The
training observations must all precede the new observations; the model
is never fit on the new counts. Fourier period is expressed in the same
units as the numeric time column. Optional linear trend is centered and
scaled using training time only.

## Usage

``` r
epi_seasonal_surveillance(
  .data,
  time,
  cases,
  training,
  period,
  harmonics = 1L,
  trend = FALSE,
  alpha = 0.05,
  family = c("poisson", "negbin"),
  adjust = "none"
)
```

## Arguments

- .data:

  An ungrouped data frame of later observations to screen.

- time:

  A numeric time column, strictly increasing in both datasets.

- cases:

  A non-negative integer count column, complete in both datasets.

- training:

  An ungrouped data frame of earlier baseline observations with the same
  `time` and `cases` columns.

- period:

  Positive length of a seasonal cycle in time units.

- harmonics:

  Number of sine/cosine harmonics, between 1 and 5.

- trend:

  Whether to include a linear time trend.

- alpha:

  Nominal upper-tail probability strictly between zero and one.

- family:

  Baseline count model: `"poisson"` or `"negbin"`.

- adjust:

  Multiple-testing adjustment passed to
  [`stats::p.adjust()`](https://rdrr.io/r/stats/p.adjust.html), such as
  `"none"`, `"holm"`, `"bonferroni"` or `"BH"`.

## Value

Input tibble with `baseline_expected`, `threshold` (the unadjusted
per-row quantile), `p_value`, `p_adjusted` and logical `alert` columns.
Counts exactly equal to the threshold are not flagged.

## Details

The interval threshold is conditional on the fitted mean and ignores
parameter uncertainty. Independent Poisson counts, a correctly specified
seasonal pattern, a stable exposure/population, and an outbreak-free
training period are important assumptions. With `family = "negbin"` the
baseline is a negative binomial model
([`MASS::glm.nb()`](https://rdrr.io/pkg/MASS/man/glm.nb.html)), and
thresholds and p-values use its estimated dispersion, which reduces
false alerts from overdispersed counts. Each row gets an upper-tail
p-value `P(Y >= cases)`; with `adjust` other than `"none"`, alerts use
p-values adjusted across all screened rows by
[`stats::p.adjust()`](https://rdrr.io/r/stats/p.adjust.html),
controlling family-wise error or false discovery rate for the batch.
Reporting delays, holidays, changing population, baseline outbreaks,
trend extrapolation and model selection can still increase false alerts.
This is a screening rule, not a validated outbreak detection system; a
flag is not an outbreak diagnosis.

## Examples

``` r
train <- data.frame(t = 1:40, cases = rep(c(4, 6, 8, 6), 10))
new <- data.frame(t = 41:42, cases = c(20, 5))
epi_seasonal_surveillance(new, t, cases, training = train, period = 4)
#> # A tibble: 2 × 7
#>       t cases baseline_expected threshold      p_value   p_adjusted alert
#>   <int> <dbl>             <dbl>     <dbl>        <dbl>        <dbl> <lgl>
#> 1    41    20              4.17         8 0.0000000197 0.0000000197 TRUE 
#> 2    42     5              5.83        10 0.692        0.692        FALSE
```
