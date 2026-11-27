# Measures of association for individual-level binary data

Exposure and outcome must be coded 0/1. By default no continuity
correction is applied. With `correction > 0` (for example the
Haldane-Anscombe value 0.5), that amount is added to all four cells of
the 2x2 table whenever any cell is zero; this keeps estimates and
intervals finite but biases them towards the null, so report it. Without
a correction, Undefined or infinite estimates are represented by `NA`;
zero estimates are retained but have `NA` log-scale intervals. Wald
intervals are approximate and require positive event counts (all cells
for odds ratios). Attributable risk is exposed risk minus unexposed
risk.

## Usage

``` r
epi_risk_ratio(.data, exposure, outcome, conf_level = 0.95, correction = 0)

epi_odds_ratio(.data, exposure, outcome, conf_level = 0.95, correction = 0)

epi_attributable_risk(
  .data,
  exposure,
  outcome,
  conf_level = 0.95,
  correction = 0
)

epi_rate_ratio(.data, exposure, outcome, time, conf_level = 0.95)
```

## Arguments

- .data:

  A data frame of individual records.

- exposure:

  Binary exposure indicator.

- outcome:

  Binary outcome indicator.

- conf_level:

  Confidence level between zero and one.

- correction:

  Non-negative amount added to every cell when any cell of the 2x2 table
  is zero. Ignored by `epi_rate_ratio()`.

- time:

  Non-negative person-time; required for a rate ratio.

## Value

A one-row tibble with estimate, confidence limits and group counts.

## Examples

``` r
d <- data.frame(exposure = rep(0:1, each = 4), outcome = c(0, 0, 0, 1, 0, 1, 1, 1))
epi_risk_ratio(d, exposure, outcome)
#> # A tibble: 1 × 9
#>   measure    estimate conf_low conf_high exposed_events exposed_total
#>   <chr>         <dbl>    <dbl>     <dbl>          <dbl>         <dbl>
#> 1 risk_ratio        3    0.501      18.0              3             4
#> # ℹ 3 more variables: unexposed_events <dbl>, unexposed_total <dbl>,
#> #   correction <dbl>
epi_odds_ratio(d, exposure, outcome)
#> # A tibble: 1 × 9
#>   measure    estimate conf_low conf_high exposed_events exposed_total
#>   <chr>         <dbl>    <dbl>     <dbl>          <dbl>         <dbl>
#> 1 odds_ratio        9    0.367      221.              3             4
#> # ℹ 3 more variables: unexposed_events <dbl>, unexposed_total <dbl>,
#> #   correction <dbl>
epi_attributable_risk(d, exposure, outcome)
#> # A tibble: 1 × 9
#>   measure         estimate conf_low conf_high exposed_events exposed_total
#>   <chr>              <dbl>    <dbl>     <dbl>          <dbl>         <dbl>
#> 1 risk_difference      0.5   -0.100      1.10              3             4
#> # ℹ 3 more variables: unexposed_events <dbl>, unexposed_total <dbl>,
#> #   correction <dbl>
d$time <- 1
epi_rate_ratio(d, exposure, outcome, time)
#> # A tibble: 1 × 9
#>   measure    estimate conf_low conf_high exposed_events exposed_total
#>   <chr>         <dbl>    <dbl>     <dbl>          <dbl>         <dbl>
#> 1 rate_ratio        3    0.312      28.8              3             4
#> # ℹ 3 more variables: unexposed_events <dbl>, unexposed_total <dbl>,
#> #   correction <dbl>
```
