# Covariate-adjusted Poisson incidence rate ratio

Fits a log-link Poisson regression with log person-time as an offset and
reports the exponentiated binary exposure coefficient with a normal-Wald
confidence interval. Model-based errors require independent counts, a
correctly specified multiplicative rate model and Poisson variance. Use
`robust = "HC0"` or `"HC1"` for sandwich errors that remain valid under
overdispersion, and `cluster` for recurrent events or other dependence
within clusters. Weights, effect modification and spline terms work as
in
[`epi_adjusted_odds_ratio()`](https://tidyepidemio.in4metrix.dev/reference/epi_adjusted_odds_ratio.md).
Missing data are not handled. Assess fit and confounding assumptions
separately; this is not automatically a causal effect.

## Usage

``` r
epi_adjusted_rate_ratio(
  .data,
  events,
  time,
  exposure,
  adjust = c(),
  conf_level = 0.95,
  weights = NULL,
  cluster = NULL,
  robust = c("model", "HC0", "HC1"),
  modifier = NULL,
  nonlinear = c()
)
```

## Arguments

- .data:

  Ungrouped data frame with one row per record or aggregated cell.

- events:

  Non-negative integer event counts.

- time:

  Positive person-time or other exposure per row.

- exposure:

  Binary 0/1 exposure column.

- adjust:

  Tidy selection of complete numeric, factor or logical covariates.

- conf_level:

  Confidence level strictly between zero and one.

- weights:

  Optional column of finite, non-negative observation weights.

- cluster:

  Optional complete cluster identifier column. Observations within a
  cluster may be dependent; distinct clusters are assumed independent.

- robust:

  Standard-error type: `"model"`, `"HC0"` or `"HC1"`.

- modifier:

  Optional effect-modifier column with 2 to 10 levels; every level must
  contain both exposure groups.

- nonlinear:

  Tidy selection of numeric `adjust` columns to model with natural
  splines (3 degrees of freedom) instead of linearly.

## Value

An `epi_result` tibble containing the adjusted rate ratio, Wald
confidence limits, event and record counts, and covariate names.

## Examples

``` r
d <- data.frame(
  e = rep(0:1, each = 6), events = c(1, 2, 1, 2, 3, 1, 3, 4, 2, 4, 5, 3),
  time = rep(10, 12), age = rep(1:3, 4)
)
epi_adjusted_rate_ratio(d, events, time, e, adjust = age)
#> # A tibble: 1 × 8
#>   measure          estimate conf_low conf_high     n events se_type adjusted_for
#>   <chr>               <dbl>    <dbl>     <dbl> <int>  <dbl> <chr>   <chr>       
#> 1 adjusted_rate_r…     2.10    0.989      4.46    12     31 model   age         
```
