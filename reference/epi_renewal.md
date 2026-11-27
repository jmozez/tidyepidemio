# Parsnip epidemic model specifications

These regression model specifications fit a single, ungrouped epidemic
series using the `tidyepidemio` engine. Use a formula of the form
`incidence ~ time` with consecutive integer time steps. The renewal
model estimates one constant reproduction number via a conditional
Poisson model with a fixed generation-interval distribution. The
compartmental model fits a deterministic SIR or SEIR trajectory to
infectious prevalence using least squares, with fixed population,
recovery, and (for SEIR) progression rates; only transmission is
estimated. The first observation supplies the initial number infectious,
and initial exposed and recovered numbers are fixed. Fitting can be
weakly identified and the objective may have multiple minima.
Predictions are point estimates only, not calibrated probabilistic
forecasts. These simplified models do not adjust for imports,
observation error, reporting delays, changes in interventions, or
heterogeneous mixing.

## Usage

``` r
epi_renewal(.data = NULL, mode = "regression", engine = "tidyepidemio")

epi_compartmental(.data = NULL, mode = "regression", engine = "tidyepidemio")
```

## Arguments

- .data:

  Optional data frame, retained as a data-first convention. It is not
  used for fitting; supply data to
  [`parsnip::fit()`](https://generics.r-lib.org/reference/fit.html)
  instead.

- mode:

  Only `"regression"` is supported.

- engine:

  Only `"tidyepidemio"` is supported.

## Value

A parsnip model specification.

## Examples

``` r
d <- data.frame(time = 1:6, cases = c(1, 2, 4, 8, 16, 32))
spec <- epi_renewal() |> parsnip::set_engine("tidyepidemio", weights = 1)
fit <- parsnip::fit(spec, cases ~ time, data = d)
predict(fit, new_data = data.frame(time = 7:8))
#> # A tibble: 2 × 1
#>   .pred
#>   <dbl>
#> 1    64
#> 2   128
d <- data.frame(time = 0:4, infectious = c(5, 6, 7, 8, 9))
spec <- epi_compartmental() |>
  parsnip::set_engine("tidyepidemio", population = 1000, gamma = 0.1)
fit <- parsnip::fit(spec, infectious ~ time, data = d)
predict(fit, new_data = data.frame(time = 5:6))
#> # A tibble: 2 × 1
#>   .pred
#>   <dbl>
#> 1  10.7
#> 2  12.4
seir <- epi_compartmental() |>
  parsnip::set_engine("tidyepidemio",
    population = 1000, gamma = .1,
    model = "seir", sigma = .2, initial_exposed = 5
  )
parsnip::fit(seir, infectious ~ time, data = d)
#> parsnip model object
#> 
#> $kind
#> [1] "compartmental"
#> 
#> $model
#> [1] "seir"
#> 
#> $estimate
#> [1] 0.7581986
#> 
#> $gamma
#> [1] 0.1
#> 
#> $sigma
#> [1] 0.2
#> 
#> $initial_exposed
#> [1] 5
#> 
#> $initial_recovered
#> [1] 0
#> 
#> $population
#> [1] 1000
#> 
#> $time
#> [1] 0 1 2 3 4
#> 
#> $outcome_name
#> [1] "infectious"
#> 
#> $time_name
#> [1] "time"
#> 
#> $observed
#> [1] 5 6 7 8 9
#> 
#> $fitted
#> [1] 5.000000 5.430533 6.334834 7.630069 9.311085
#> 
#> attr(,"class")
#> [1] "epi_model"
```
