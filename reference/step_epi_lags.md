# Epidemiological recipe steps

All steps operate in the current row order, without grouping or sorting,
and compute features using only rows supplied to `bake()`. They do not
carry history across training and assessment sets; baking a single new
row will therefore produce missing lag and rolling features.
[`epi_bake_history()`](https://tidyepidemio.in4metrix.dev/reference/epi_bake_history.md)
can supply explicit prior rows for supported steps. Sort and split data
beforehand to avoid future leakage. Existing output names are rejected.

## Usage

``` r
step_epi_lags(
  .data,
  ...,
  lag = 1L,
  skip = FALSE,
  id = recipes::rand_id("epi_lags")
)

step_epi_rolling(
  .data,
  ...,
  window = 7L,
  skip = FALSE,
  id = recipes::rand_id("epi_rolling")
)

step_epi_rates(
  .data,
  ...,
  denominator,
  multiplier = 1000,
  skip = FALSE,
  id = recipes::rand_id("epi_rates")
)

step_epi_exposure_window(
  .data,
  ...,
  window = 7L,
  skip = FALSE,
  id = recipes::rand_id("epi_exposure")
)
```

## Arguments

- .data:

  A recipes recipe.

- ...:

  Tidy-selected numeric columns.

- lag:

  Positive integer row lag.

- skip:

  Whether to skip the step when baking new data.

- id:

  Unique step identifier.

- window:

  Positive integer window size, including the current row.

- denominator:

  A single numeric denominator column, for rates.

- multiplier:

  Positive scaling factor for rates.

## Value

An updated recipe. The steps retain their selected original columns.

## Examples

``` r
d <- data.frame(cases = 1:5, population = rep(100, 5))
rec <- recipes::recipe(~., data = d) |>
  step_epi_lags(cases, lag = 1)
recipes::bake(recipes::prep(rec), new_data = d)
#> # A tibble: 5 × 3
#>   cases population lag1_cases
#>   <int>      <dbl>      <int>
#> 1     1        100         NA
#> 2     2        100          1
#> 3     3        100          2
#> 4     4        100          3
#> 5     5        100          4
rec2 <- recipes::recipe(~., data = d) |>
  step_epi_rolling(cases, window = 2) |>
  step_epi_rates(cases, denominator = population)
recipes::bake(recipes::prep(rec2), new_data = d)
#> # A tibble: 5 × 4
#>   cases population roll2_cases rate_cases
#>   <int>      <dbl>       <dbl>      <dbl>
#> 1     1        100        NA           10
#> 2     2        100         1.5         20
#> 3     3        100         2.5         30
#> 4     4        100         3.5         40
#> 5     5        100         4.5         50
ex <- data.frame(exposure = c(0, 1, 1, 0))
rec3 <- recipes::recipe(~., data = ex) |>
  step_epi_exposure_window(exposure, window = 2)
recipes::bake(recipes::prep(rec3), new_data = ex)
#> # A tibble: 4 × 2
#>   exposure exposure2_exposure
#>      <dbl>              <dbl>
#> 1        0                 NA
#> 2        1                  1
#> 3        1                  2
#> 4        0                  1
```
