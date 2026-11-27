# Epidemic model engine functions

Low-level fit functions used by the parsnip engines. See
[`epi_renewal()`](https://tidyepidemio.in4metrix.dev/reference/epi_renewal.md)
for the model definitions and assumptions.

## Usage

``` r
fit_epi_renewal(formula, data, weights = c(1))

fit_epi_compartmental(
  formula,
  data,
  population,
  gamma,
  beta_max = 10,
  model = c("sir", "seir"),
  sigma = NULL,
  initial_exposed = 0,
  initial_recovered = 0
)
```

## Arguments

- formula:

  A formula with one response and one numeric time column.

- data:

  Ungrouped data in consecutive time order.

- weights:

  Generation-interval probabilities for lags 1 onward.

- population:

  Fixed total population, greater than initial compartments.

- gamma:

  Fixed non-negative per-step recovery rate.

- beta_max:

  Upper bound for optimization of the transmission rate.

- model:

  Either `"sir"` or `"seir"`.

- sigma:

  Fixed positive per-step progression rate for SEIR.

- initial_exposed:

  Fixed non-negative initial exposed count, defaulting to zero; must be
  zero for SIR.

- initial_recovered:

  Fixed initial recovered count for either model.

## Value

A fitted `epi_model` object.

## Examples

``` r
fit_epi_renewal(cases ~ time, data.frame(time = 1:4, cases = c(1, 2, 4, 8)), weights = 1)
#> $kind
#> [1] "renewal"
#> 
#> $estimate
#> [1] 2
#> 
#> $weights
#> [1] 1
#> 
#> $time
#> [1] 1 2 3 4
#> 
#> $outcome_name
#> [1] "cases"
#> 
#> $time_name
#> [1] "time"
#> 
#> $observed
#> [1] 1 2 4 8
#> 
#> $fitted
#> [1] NA  2  4  8
#> 
#> attr(,"class")
#> [1] "epi_model"
d <- data.frame(time = 0:4, infectious = c(5, 6, 7, 8, 9))
fit_epi_compartmental(infectious ~ time, d, population = 1000, gamma = .1)
#> $kind
#> [1] "compartmental"
#> 
#> $model
#> [1] "sir"
#> 
#> $estimate
#> [1] 0.2612765
#> 
#> $gamma
#> [1] 0.1
#> 
#> $sigma
#> NULL
#> 
#> $initial_exposed
#> [1] 0
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
#> [1] 5.000000 5.823189 6.779768 7.890592 9.179504
#> 
#> attr(,"class")
#> [1] "epi_model"
```
