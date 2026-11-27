# Mantel-Haenszel pooled odds ratio

Computes the Mantel-Haenszel common odds ratio from individual records,
with a Robins-Breslow-Greenland confidence interval and a Breslow-Day
test of homogeneity of the stratum odds ratios (with Tarone's
correction).

## Usage

``` r
epi_mantel_haenszel(.data, exposure, outcome, strata, conf_level = 0.95)
```

## Arguments

- .data:

  A data frame of individual records.

- exposure:

  Binary exposure indicator.

- outcome:

  Binary outcome indicator.

- strata:

  A non-missing stratum variable.

- conf_level:

  Confidence level between zero and one.

## Value

A one-row tibble with the pooled estimate, confidence limits, number of
strata, and the Breslow-Day statistic (`heterogeneity_statistic`),
degrees of freedom (`heterogeneity_df`) and p-value
(`heterogeneity_p_value`).

## Details

The heterogeneity test compares each stratum's exposed-case count with
its expectation under the pooled odds ratio. Strata with a zero margin
carry no information and are excluded from the test; its degrees of
freedom are the number of informative strata minus one. The test has low
power with few or sparse strata, and a non-significant result does not
prove homogeneity.

## Examples

``` r
d <- data.frame(e = rep(c(0, 0, 1, 1), 2), y = rep(c(0, 1, 0, 1), 2), s = rep(1:2, each = 4))
epi_mantel_haenszel(d, e, y, s)
#> # A tibble: 1 × 7
#>   estimate conf_low conf_high strata heterogeneity_statistic heterogeneity_df
#>      <dbl>    <dbl>     <dbl>  <int>                   <dbl>            <int>
#> 1        1   0.0625      16.0      2                       0                1
#> # ℹ 1 more variable: heterogeneity_p_value <dbl>
```
