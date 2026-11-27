# Simulate SIR or SEIR with time-varying rates

The schedule has one row per time step, with non-negative transmission
(`beta`), recovery (`gamma`), and, for SEIR, progression (`sigma`)
rates. All rates apply during the corresponding step. This supports
explicitly scheduled interventions, not feedback policies or
transmission heterogeneity. The infection, progression and recovery
probabilities use exponential hazards over `dt`, with each transition
based on the state at the start of the step. Deterministic transitions
are conditional expected flows; stochastic transitions are independent
binomial draws from their source compartments. The first output row is
the initial state and has missing transition flows. The output has no
births, deaths, importations or observation model. These are
discrete-time approximations, not continuous-time exact Markov or ODE
models. Set the R random seed for reproducible stochastic simulations.

## Usage

``` r
epi_simulate_schedule(
  .data,
  initial,
  dt = 1,
  model = c("sir", "seir"),
  stochastic = FALSE
)
```

## Arguments

- .data:

  A non-empty data frame, with one row per time step and numeric `beta`
  and `gamma` columns; SEIR also requires `sigma`.

- initial:

  A one-row data frame with `S`, `I`, `R` and for SEIR `E`.

- dt:

  Positive duration of each step, in units compatible with the rates.

- model:

  Either `"sir"` or `"seir"`.

- stochastic:

  Whether to draw integer transitions.

## Value

A tibble with time, compartment counts and new infection, progression
and recovery flows. SIR progression flow is always missing.

## Examples

``` r
schedule <- data.frame(beta = c(.3, .3, .1, .1), gamma = .1)
epi_simulate_schedule(schedule, initial = data.frame(S = 999, I = 1, R = 0))
#> # A tibble: 5 × 7
#>    time     S     I      R new_infections new_progressions new_recoveries
#>   <dbl> <dbl> <dbl>  <dbl>          <dbl>            <dbl>          <dbl>
#> 1     0  999   1    0              NA                   NA        NA     
#> 2     1  999.  1.20 0.0952          0.300               NA         0.0952
#> 3     2  998.  1.45 0.210           0.361               NA         0.115 
#> 4     3  998.  1.46 0.348           0.145               NA         0.138 
#> 5     4  998.  1.46 0.487           0.145               NA         0.139 
```
