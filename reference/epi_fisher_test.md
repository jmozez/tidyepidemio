# Fisher's exact test for binary exposure and outcome

Applies Fisher's conditional exact test to an individual-level 2 by 2
table. The reported odds ratio is the conditional maximum-likelihood
estimate from
[`stats::fisher.test()`](https://rdrr.io/r/stats/fisher.test.html), not
necessarily the sample cross-product odds ratio. The confidence interval
is an exact conditional interval; one-sided limits may be zero or
infinite. Both exposure and outcome levels must be present. The test
conditions on observed margins and does not adjust for confounding,
clustering or multiple testing. Significance does not establish
causality.

## Usage

``` r
epi_fisher_test(
  .data,
  exposure,
  outcome,
  alternative = c("two.sided", "less", "greater"),
  conf_level = 0.95
)
```

## Arguments

- .data:

  An ungrouped data frame of individual records.

- exposure:

  Binary 0/1 exposure indicator.

- outcome:

  Binary 0/1 outcome indicator.

- alternative:

  `"two.sided"`, `"less"` or `"greater"`, referring to the exposed
  versus unexposed odds ratio.

- conf_level:

  Confidence level strictly between zero and one.

## Value

An `epi_result` tibble with conditional odds ratio, limits, p-value, and
cell counts. Infinite limits and estimates are possible.

## Examples

``` r
d <- data.frame(e = rep(0:1, each = 4), y = c(0, 0, 0, 1, 0, 1, 1, 1))
epi_fisher_test(d, e, y)
#> # A tibble: 1 × 10
#>   measure         estimate conf_low conf_high p_value alternative exposed_events
#>   <chr>              <dbl>    <dbl>     <dbl>   <dbl> <chr>                <int>
#> 1 fisher_odds_ra…     6.41    0.212      622.   0.486 two.sided                3
#> # ℹ 3 more variables: exposed_non_events <int>, unexposed_events <int>,
#> #   unexposed_non_events <int>
```
