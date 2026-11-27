# Estimate an epidemiological delay distribution

Fits lognormal, gamma and Weibull distributions to delays between two
events, such as symptom onset to reporting, onset to death or the serial
interval, by maximum likelihood. With daily data both events are known
only to the day, so the observed delay is doubly interval censored; with
an ongoing outbreak, long delays are not yet observed, so the data are
right truncated. Ignoring either biases the estimated mean, usually
downwards (Park et al. 2024). This function accounts for both, using the
exact (closed-form) probability of each whole-day delay when the primary
event is uniformly distributed within its day (Charniga et al. 2024).

## Usage

``` r
epi_delay_dist(
  .data,
  delay,
  max_delay = NULL,
  family = c("lognormal", "gamma", "weibull"),
  censoring = c("double", "none"),
  conf_level = 0.95
)
```

## Arguments

- .data:

  A data frame with one row per individual.

- delay:

  Observed delays. With `censoring = "double"`, whole numbers of days (0
  or more); with `censoring = "none"`, exact positive delays.

- max_delay:

  Optional column with the longest delay that could have been observed
  for each individual (days from the primary event to the end of data
  collection). Supplying it corrects for right truncation.

- family:

  One or more of `"lognormal"`, `"gamma"` and `"weibull"`.

- censoring:

  `"double"` (default) for whole-day data, `"none"` for exact delays.

- conf_level:

  Confidence level for the mean (delta method on the log scale).

## Value

A `tep_delay` tibble with one row per family, best first by AIC:
`family`, `parameters` (a list column of named estimates), `mean`,
`mean_lower`, `mean_upper`, `sd`, `median`, `q95` (95th percentile),
`loglik`, `aic`, `delta_aic`, `n`, `censoring` and `truncated`. Pass it
to
[`epi_delay_pmf()`](https://tidyepidemio.in4metrix.dev/reference/epi_delay_pmf.md)
for discretised probabilities to use with
[`epi_cfr()`](https://tidyepidemio.in4metrix.dev/reference/epi_cfr.md),
[`epi_nowcast()`](https://tidyepidemio.in4metrix.dev/reference/epi_nowcast.md)
or [`epi_rt()`](https://tidyepidemio.in4metrix.dev/reference/epi_rt.md).

## References

Park, S. W., Akhmetzhanov, A. R., Charniga, K., Cori, A., Davies, N. G.,
Dushoff, J., Funk, S., Gostic, K., Grenfell, B., Linton, N. M.,
Lipsitch, M., Lison, A., Overton, C. E., Ward, T. and Abbott, S. (2024).
Estimating epidemiological delay distributions for infectious diseases.
medRxiv.
[doi:10.1101/2024.01.12.24301247](https://doi.org/10.1101/2024.01.12.24301247)

Charniga, K., Park, S. W., Akhmetzhanov, A. R., Cori, A., Dushoff, J.,
Funk, S., Gostic, K. M., Linton, N. M., Lison, A., Overton, C. E.,
Pulliam, J. R. C., Ward, T., Cauchemez, S. and Abbott, S. (2024). Best
practices for estimating and reporting epidemiological delay
distributions of infectious diseases. PLOS Computational Biology, 20,
e1012520.
[doi:10.1371/journal.pcbi.1012520](https://doi.org/10.1371/journal.pcbi.1012520)

## Examples

``` r
set.seed(1)
onset <- runif(300, 0, 40)
report <- onset + rlnorm(300, 1.5, 0.5)
d <- data.frame(delay = floor(report) - floor(onset))
epi_delay_dist(d, delay)
#> # A tibble: 3 × 14
#>   family  parameters  mean mean_lower mean_upper    sd median   q95 loglik   aic
#>   <chr>   <list>     <dbl>      <dbl>      <dbl> <dbl>  <dbl> <dbl>  <dbl> <dbl>
#> 1 lognor… <dbl [2]>   5.12       4.81       5.44  2.79   4.49 10.4   -685. 1374.
#> 2 gamma   <dbl [2]>   5.10       4.81       5.40  2.55   4.68  9.88  -686. 1375.
#> 3 weibull <dbl [2]>   5.11       4.81       5.42  2.63   4.81  9.88  -696. 1396.
#> # ℹ 4 more variables: delta_aic <dbl>, n <int>, censoring <chr>,
#> #   truncated <lgl>

# Only reports up to day 40 are known: correct for right truncation
d$max_delay <- 40 - floor(onset)
seen <- d[d$delay <= d$max_delay, ]
epi_delay_dist(seen, delay, max_delay = max_delay, family = "lognormal")
#> # A tibble: 1 × 14
#>   family  parameters  mean mean_lower mean_upper    sd median   q95 loglik   aic
#>   <chr>   <list>     <dbl>      <dbl>      <dbl> <dbl>  <dbl> <dbl>  <dbl> <dbl>
#> 1 lognor… <dbl [2]>   5.14       4.79       5.52  2.80   4.51  10.4  -598. 1199.
#> # ℹ 4 more variables: delta_aic <dbl>, n <int>, censoring <chr>,
#> #   truncated <lgl>
```
