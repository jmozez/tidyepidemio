# Fit simplified epidemic models with data-first column selection

Data-first alternatives to the formula-based engine functions used by
parsnip. The renewal fit estimates a constant reproduction number using
a conditional Poisson mean and fixed generation weights. The
compartmental fit estimates transmission by least squares with the
population, recovery and initial states fixed. These methods use the
same models and assumptions as
[`epi_renewal()`](https://tidyepidemio.in4metrix.dev/reference/epi_renewal.md)
and
[`epi_compartmental()`](https://tidyepidemio.in4metrix.dev/reference/epi_renewal.md);
this is not a calibrated or validated forecasting system. Select exactly
one distinct column for each argument; non-syntactic names can be
selected using backticks or `all_of()`.

## Usage

``` r
epi_fit_renewal(.data, time, cases, weights = 1)

epi_fit_compartmental(
  .data,
  time,
  infectious,
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

- .data:

  An ungrouped data frame with consecutive integer time steps.

- time:

  A single time column selected using tidy selection.

- cases:

  A single non-negative integer incidence column for renewal.

- weights:

  Generation-interval probabilities by lag, summing to one.

- infectious:

  A single non-negative infectious prevalence column for the
  compartmental fit. The first value supplies the initial infectious
  count.

- population:

  Fixed total population greater than initial compartments.

- gamma:

  Fixed non-negative recovery rate.

- beta_max:

  Positive upper bound for transmission-rate optimization.

- model:

  Either `"sir"` or `"seir"`.

- sigma:

  Fixed positive progression rate, required for SEIR.

- initial_exposed:

  Fixed non-negative initial exposed count, zero for SIR.

- initial_recovered:

  Fixed non-negative initial recovered count.

## Value

A fitted `epi_model` suitable for
[`predict()`](https://rdrr.io/r/stats/predict.html),
[`generics::tidy()`](https://generics.r-lib.org/reference/tidy.html),
[`generics::glance()`](https://generics.r-lib.org/reference/glance.html)
and
[`generics::augment()`](https://generics.r-lib.org/reference/augment.html).
This is an engine model, not a parsnip model specification.

## Examples

``` r
d <- data.frame(day = 1:5, cases = c(1, 2, 4, 8, 16))
fit <- epi_fit_renewal(d, day, cases, weights = 1)
predict(fit, newdata = data.frame(day = 6:7))
#> [1] 32 64
c <- data.frame(day = 0:4, infectious = c(5, 6, 7, 8, 9))
epi_fit_compartmental(c, day, infectious, population = 1000, gamma = .1)
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
#> [1] "day"
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
