# Confidence intervals for standardized rates and ratios

For direct standardization, uses the Fay-Feuer gamma interval for a
weighted sum of independent Poisson counts. For indirect
standardization, calculates an exact Poisson interval for the
standardized mortality/incidence ratio (SMR/SIR), conditional on the
expected count. Standard rates must be supplied per one, not per
multiplier. The indirect ratio is dimensionless and is not multiplied.
Assumes independent Poisson counts, fixed population/exposure and fixed
standard rates; overdispersion or uncertain standard rates invalidate
these simple intervals.

## Usage

``` r
epi_standardize_ci(
  .data,
  events,
  population,
  standard,
  method = c("direct", "indirect"),
  multiplier = 1,
  conf_level = 0.95
)
```

## Arguments

- .data:

  Data frame with one row per stratum.

- events:

  Non-negative integer event counts.

- population:

  Positive population or person-time.

- standard:

  Standard population for direct, or rate per one for indirect.

- method:

  Either `"direct"` or `"indirect"`.

- multiplier:

  Positive scale factor for a directly standardized rate.

- conf_level:

  Confidence level strictly between zero and one.

## Value

One-row tibble with method, estimate and confidence limits.

## References

Fay MP and Feuer EJ (1997). Confidence intervals for directly
standardized rates: a method based on the gamma distribution. Statistics
in Medicine 16:791-801.
doi:10.1002/(SICI)1097-0258(19970415)16:7\<791::AID-SIM500\>3.0.CO;2-#

## Examples

``` r
d <- data.frame(events = c(10, 20), pop = c(100, 100), standard = c(150, 50))
epi_standardize_ci(d, events, pop, standard)
#> # A tibble: 1 × 5
#>   method estimate conf_low conf_high conf_level
#>   <chr>     <dbl>    <dbl>     <dbl>      <dbl>
#> 1 direct    0.125   0.0790     0.191       0.95
```
