# Naive and delay-adjusted case fatality ratio

During an outbreak, dividing deaths by cases underestimates the case
fatality ratio (CFR), because many recent cases have not yet had time to
die. The delay-adjusted estimator of Nishiura et al. (2009) divides
deaths by the expected number of cases with a known outcome, given the
distribution of the delay from onset (or report) to death, as in the cfr
package. Intervals are likelihood-ratio intervals from a binomial
likelihood in which the cases with known outcomes are the trials.

## Usage

``` r
epi_cfr(
  .data,
  cases,
  deaths,
  delay = NULL,
  conf_level = 0.95,
  cumulative = FALSE
)
```

## Arguments

- .data:

  A data frame in date order with equally spaced rows (days).

- cases:

  Daily cases.

- deaths:

  Daily deaths.

- delay:

  Probabilities of the delay from case to death, starting at a delay of
  0 days, such as the `probability` column of
  [`epi_delay_pmf()`](https://tidyepidemio.in4metrix.dev/reference/epi_delay_pmf.md).
  `NULL` gives only the naive estimate.

- conf_level:

  Confidence level.

- cumulative:

  If `TRUE`, returns the estimate using the data up to each row (to
  watch the estimate settle), added to `.data`.

## Value

A tibble with `method` (`"naive"` and `"delay_adjusted"`), `deaths`,
`cases`, `known_outcomes`, `cfr`, `lower` and `upper`; with
`cumulative = TRUE`, `.data` with `cfr_naive`, `cfr_adjusted`,
`cfr_lower` and `cfr_upper` (for the adjusted estimate).

## References

Nishiura, H., Klinkenberg, D., Roberts, M. and Heesterbeek, J. A. P.
(2009). Early epidemiological assessment of the virulence of emerging
infectious diseases: a case study of an influenza pandemic. PLOS ONE, 4,
e6852.
[doi:10.1371/journal.pone.0006852](https://doi.org/10.1371/journal.pone.0006852)

Linton, N. M., Kobayashi, T., Yang, Y., Hayashi, K., Akhmetzhanov, A.
R., Jung, S., Yuan, B., Kinoshita, R. and Nishiura, H. (2020).
Incubation period and other epidemiological characteristics of 2019
novel coronavirus infections with right truncation. Journal of Clinical
Medicine, 9, 538.
[doi:10.3390/jcm9020538](https://doi.org/10.3390/jcm9020538)

## Examples

``` r
# Onset-to-death delay for COVID-19: lognormal, mean 20.2 days, SD 11.6
# (Linton et al. 2020)
sdlog <- sqrt(log(1 + (11.6 / 20.2)^2))
meanlog <- log(20.2) - sdlog^2 / 2
pmf <- diff(plnorm(0:61, meanlog, sdlog))
epi_cfr(nz_covid_outcomes_2020, cases, deaths, delay = pmf / sum(pmf))
#> # A tibble: 2 × 7
#>   method         deaths cases known_outcomes    cfr   lower  upper
#>   <chr>           <int> <int>          <dbl>  <dbl>   <dbl>  <dbl>
#> 1 naive              23  1530          1530  0.0150 0.00972 0.0220
#> 2 delay_adjusted     23  1530          1509. 0.0152 0.00986 0.0223

early <- nz_covid_outcomes_2020[1:50, ]
epi_cfr(early, cases, deaths, delay = pmf / sum(pmf))
#> # A tibble: 2 × 7
#>   method         deaths cases known_outcomes     cfr   lower  upper
#>   <chr>           <int> <int>          <dbl>   <dbl>   <dbl>  <dbl>
#> 1 naive              12  1386          1386  0.00866 0.00465 0.0145
#> 2 delay_adjusted     12  1386           528. 0.0227  0.0122  0.0378
```
