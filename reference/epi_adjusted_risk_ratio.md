# Adjusted risk ratio using modified Poisson regression

Fits a Poisson log-link model to a binary outcome and reports an
exponentiated exposure coefficient with a sandwich-based normal-Wald
interval. The sandwich estimator uses uncorrected HC0
independent-observation scores by default, or cluster-summed scores when
`cluster` is supplied; `robust = "HC1"` adds the usual small-sample
factor. Normal inference can be inaccurate with few clusters. Unlike a
Poisson mean model for counts, this method uses a robust variance
estimator because the outcome is binary. Fitted means can exceed one; a
warning is issued and the working model should then be scrutinized.

## Usage

``` r
epi_adjusted_risk_ratio(
  .data,
  exposure,
  outcome,
  adjust = c(),
  cluster = NULL,
  conf_level = 0.95,
  weights = NULL,
  robust = c("HC0", "HC1"),
  modifier = NULL,
  nonlinear = c()
)
```

## Arguments

- .data:

  An ungrouped data frame, one row per individual.

- exposure:

  Binary 0/1 exposure column.

- outcome:

  Binary 0/1 outcome column.

- adjust:

  Tidy selection of complete numeric, factor or logical covariates.

- cluster:

  Optional complete cluster identifier column. If supplied, all
  observations within a cluster may be dependent; distinct clusters are
  assumed independent.

- conf_level:

  Confidence level strictly between zero and one.

- weights:

  Optional column of finite, non-negative observation weights.

- robust:

  Sandwich standard-error type, `"HC0"` or `"HC1"`.

- modifier:

  Optional effect-modifier column with 2 to 10 levels; every level must
  contain both exposure groups.

- nonlinear:

  Tidy selection of numeric `adjust` columns to model with natural
  splines (3 degrees of freedom) instead of linearly.

## Value

An `epi_result` tibble with risk ratio, confidence limits, number of
observations, standard-error type, cluster count and covariate names.

## Details

Requires complete data, a correctly specified log risk model,
appropriate independence or independent clusters, sufficient overlap and
large-sample inference. The result is a covariate-conditional risk
ratio, not automatically a causal effect. Weights, effect modification
and spline terms work as in
[`epi_adjusted_odds_ratio()`](https://tidyepidemio.in4metrix.dev/reference/epi_adjusted_odds_ratio.md).
There is no imputation or assessment of confounding assumptions.

## Examples

``` r
d <- expand.grid(e = 0:1, age = 20:24, rep = 1:6)
d$y <- as.integer(d$rep <= 1 + d$e + (d$age %% 2))
epi_adjusted_risk_ratio(d, e, y, adjust = age)
#> # A tibble: 1 × 8
#>   measure        estimate conf_low conf_high     n se_type clusters adjusted_for
#>   <chr>             <dbl>    <dbl>     <dbl> <int> <chr>      <int> <chr>       
#> 1 adjusted_risk…     1.71    0.784      3.75    60 HC0           NA age         
```
