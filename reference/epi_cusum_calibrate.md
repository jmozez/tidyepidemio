# Monte Carlo calibration of a finite-horizon Poisson CUSUM

Simulates independent Poisson counts under externally supplied baseline
means and calculates the maximum one-sided CUSUM over the entire
monitoring horizon using the same recursion as
[`epi_cusum()`](https://tidyepidemio.in4metrix.dev/reference/epi_cusum.md).
The threshold is slightly greater than the `k`th ordered simulated
maximum, where `k = ceiling((nsim + 1) * (1 - alpha))`. Under
exchangeability of the null simulations and a future null sequence, this
strict rank construction controls the marginal probability that its
maximum crosses the threshold at at most `(nsim + 1 - k) / (nsim + 1)`,
including simulation randomness; ties only make it more conservative.
This is not a confidence guarantee conditional on the particular
simulated calibration set and is not average run length control.

## Usage

``` r
epi_cusum_calibrate(
  .data,
  baseline,
  relative_risk = 2,
  alpha = 0.05,
  nsim = 999L,
  initial = 0,
  size = Inf,
  n_series = 1L
)
```

## Arguments

- .data:

  A non-empty data frame containing the baseline sequence, one row per
  monitoring time step.

- baseline:

  Positive expected count at each monitoring step.

- relative_risk:

  Alternative-to-baseline rate ratio, strictly above one.

- alpha:

  Desired maximum false-alarm probability, strictly in (0,1).

- nsim:

  Number of null trajectories; must be large enough for the rank.

- initial:

  Non-negative CUSUM statistic at the start of each trajectory.

- size:

  Negative binomial size (dispersion) for null counts; `Inf` (default)
  gives Poisson counts. Smaller values mean more overdispersion.

- n_series:

  Number of independent series monitored together.

## Value

One-row tibble with `threshold`, `alpha`, `series_alpha`,
`marginal_bound`, `simulations`, and the number of monitoring `steps`.

## Details

Calibration is valid only if the assumed independent count baseline is a
suitable null for the entire horizon. Set `size` to simulate negative
binomial null counts for overdispersed series. With `n_series > 1`, each
series is calibrated at the Sidak level
`1 - (1 - alpha)^(1 / n_series)`, which bounds the probability of any
false alarm across that many independent series. Estimated baselines,
serial dependence and reporting changes can still invalidate it. It does
not account for later restarting, changing horizon, or retuning the
threshold. Set a seed to reproduce the Monte Carlo result.

## Examples

``` r
d <- data.frame(base = rep(2, 10))
set.seed(1)
epi_cusum_calibrate(d, base, relative_risk = 2, alpha = .1, nsim = 99)
#> # A tibble: 1 × 6
#>   threshold alpha series_alpha marginal_bound simulations steps
#>       <dbl> <dbl>        <dbl>          <dbl>       <int> <int>
#> 1      3.41   0.1          0.1            0.1          99    10
```
