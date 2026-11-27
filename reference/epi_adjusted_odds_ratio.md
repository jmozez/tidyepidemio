# Covariate-adjusted odds ratio

Fits a binomial logistic regression with a binary exposure and selected
covariates using maximum likelihood, reporting the exponentiated
exposure coefficient with a normal-Wald confidence interval. Categorical
covariates must be factors or logicals; continuous covariates enter
linearly unless listed in `nonlinear`, in which case they enter as
natural cubic splines with three degrees of freedom. This is a
conditional odds ratio, not a risk ratio, and can differ from a marginal
odds ratio even without confounding. It is not automatically a causal
effect.

## Usage

``` r
epi_adjusted_odds_ratio(
  .data,
  exposure,
  outcome,
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

  A data frame with one row per individual.

- exposure:

  Binary exposure column, coded 0/1.

- outcome:

  Binary outcome column, coded 0/1.

- adjust:

  Tidy selection of covariate columns, such as `c(age, sex)`; defaults
  to none. Each must be numeric, factor, or logical and complete.

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

An `epi_result` tibble with the exposure odds ratio, confidence limits,
sample size, standard-error type and adjusted covariate names. With
`modifier`, one row per modifier level plus `interaction_p_value`.

## Details

Standard errors are model-based by default. `robust = "HC0"` or `"HC1"`
requests sandwich standard errors (HC1 adds the `n / (n - p)`
small-sample factor); supplying `cluster` sums scores within clusters
and implies a sandwich estimator. Sandwich errors are recommended with
`weights`, which are treated as sampling or analytic weights rather than
frequency counts.

With `modifier`, the model includes an exposure-by-modifier interaction
and one row is returned per modifier level, giving the exposure effect
within that level, together with a joint Wald p-value for the
interaction terms.

Complete data, independent observations (or independent clusters), a
correctly specified model, adequate overlap and no serious separation
are required; sparse data can render estimates and Wald intervals
unreliable. Missing data are not handled.

## Examples

``` r
d <- data.frame(
  e = rep(0:1, each = 20), y = rep(c(0, 1, 0, 0, 1), 8),
  age = rep(20:29, 4), sex = rep(c("f", "m"), 20)
)
epi_adjusted_odds_ratio(d, e, y, adjust = age)
#> # A tibble: 1 × 7
#>   measure             estimate conf_low conf_high     n se_type adjusted_for
#>   <chr>                  <dbl>    <dbl>     <dbl> <int> <chr>   <chr>       
#> 1 adjusted_odds_ratio        1    0.279      3.59    40 model   age         
epi_adjusted_odds_ratio(d, e, y, adjust = age, robust = "HC1")
#> # A tibble: 1 × 7
#>   measure             estimate conf_low conf_high     n se_type adjusted_for
#>   <chr>                  <dbl>    <dbl>     <dbl> <int> <chr>   <chr>       
#> 1 adjusted_odds_ratio        1    0.265      3.78    40 HC1     age         
epi_adjusted_odds_ratio(d, e, y, adjust = age, modifier = sex)
#> # A tibble: 2 × 10
#>   measure             modifier modifier_level estimate conf_low conf_high
#>   <chr>               <chr>    <chr>             <dbl>    <dbl>     <dbl>
#> 1 adjusted_odds_ratio sex      f                     1    0.164      6.10
#> 2 adjusted_odds_ratio sex      m                     1    0.164      6.10
#> # ℹ 4 more variables: interaction_p_value <dbl>, n <int>, se_type <chr>,
#> #   adjusted_for <chr>
```
