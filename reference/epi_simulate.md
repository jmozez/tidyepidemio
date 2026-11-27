# Simulate a discrete-time SIR or SEIR epidemic

Uses mass-action transmission with per-step infection probability
`1 - exp(-beta * I / N * dt)`. Progression and recovery similarly use
exponential transition probabilities. Transitions use the start-of-step
state, and there are no births, deaths, imports, or interventions.
Deterministic transitions use expected counts; stochastic transitions
use independent binomial draws. Supply rates per time unit; `dt` sets
step length. Set a seed before stochastic runs for reproducibility.

## Usage

``` r
epi_simulate(
  .data,
  beta,
  gamma,
  sigma = NULL,
  steps = 100L,
  dt = 1,
  model = c("sir", "seir"),
  stochastic = FALSE
)
```

## Arguments

- .data:

  A one-row data frame containing numeric `S`, `I`, `R`, and for SEIR,
  `E` compartment counts.

- beta:

  Non-negative transmission rate.

- gamma:

  Non-negative recovery rate.

- sigma:

  Non-negative progression rate, required for SEIR.

- steps:

  Number of discrete time steps.

- dt:

  Positive time step.

- model:

  Either `"sir"` or `"seir"`.

- stochastic:

  Whether to sample transitions rather than take expectations.

## Value

A tibble with time and compartment columns, including initial state.

## Examples

``` r
epi_simulate(data.frame(S = 999, I = 1, R = 0), beta = 0.3, gamma = 0.1, steps = 10)
#> # A tibble: 11 × 4
#>     time     S     I      R
#>    <dbl> <dbl> <dbl>  <dbl>
#>  1     0  999   1    0     
#>  2     1  999.  1.20 0.0952
#>  3     2  998.  1.45 0.210 
#>  4     3  998.  1.75 0.348 
#>  5     4  997.  2.10 0.514 
#>  6     5  997.  2.53 0.714 
#>  7     6  996.  3.05 0.955 
#>  8     7  995.  3.67 1.25  
#>  9     8  994.  4.41 1.59  
#> 10     9  993.  5.31 2.01  
#> 11    10  991.  6.38 2.52  
```
