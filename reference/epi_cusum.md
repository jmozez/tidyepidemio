# One-sided Poisson CUSUM surveillance

Calculates the prospective upper-sided log-likelihood CUSUM for
detecting an increase from baseline mean `mu[t]` to
`relative_risk * mu[t]`:
`S[t] = max(0, S[t-1] + cases[t]*log(relative_risk) - (relative_risk-1)*mu[t])`.
A flag occurs when `S[t] >= threshold`. The statistic is not reset on an
alert. Baseline values must be supplied from external or previously
available information; estimating them using future observations leaks
information. The threshold is not automatically calibrated: choose it
through simulation or an appropriate monitoring design. Serial
dependence, overdispersion, seasonality, reporting delays, repeated
testing and baseline uncertainty affect false-alarm rates. Flags are not
outbreak diagnoses.

## Usage

``` r
epi_cusum(
  .data,
  cases,
  baseline,
  relative_risk = 2,
  threshold = 5,
  initial = 0
)
```

## Arguments

- .data:

  Ungrouped data ordered chronologically at equal time intervals.

- cases:

  Non-negative integer counts.

- baseline:

  Positive expected counts for each corresponding time period.

- relative_risk:

  Alternative-to-baseline rate ratio, strictly above one.

- threshold:

  Positive log-likelihood CUSUM alert threshold.

- initial:

  Non-negative statistic at start of the series.

## Value

Input tibble with `cusum` and logical `alert` columns.

## Examples

``` r
d <- data.frame(day = 1:5, cases = c(2, 1, 3, 7, 9), baseline = rep(2, 5))
epi_cusum(d, cases, baseline, relative_risk = 2, threshold = 3)
#> # A tibble: 5 × 5
#>     day cases baseline  cusum alert
#>   <int> <dbl>    <dbl>  <dbl> <lgl>
#> 1     1     2        2 0      FALSE
#> 2     2     1        2 0      FALSE
#> 3     3     3        2 0.0794 FALSE
#> 4     4     7        2 2.93   FALSE
#> 5     5     9        2 7.17   TRUE 
```
