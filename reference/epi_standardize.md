# Standardize rates across strata

Direct standardization weights stratum-specific observed rates by the
standard populations. Indirect standardization returns an
observed-to-expected ratio using standard rates. Strata must be mutually
exclusive and exhaustive; no uncertainty intervals are calculated.

## Usage

``` r
epi_standardize(
  .data,
  events,
  population,
  standard,
  method = c("direct", "indirect"),
  multiplier = 1
)
```

## Arguments

- .data:

  A data frame with one row per stratum.

- events:

  Observed event counts.

- population:

  Observed population or person-time.

- standard:

  Standard population for direct, or standard rate for indirect.

- method:

  Either `"direct"` or `"indirect"`.

- multiplier:

  Positive rate scale used for the output. For indirect standardization,
  standard rates must be supplied per one, not per multiplier.

## Value

A one-row tibble with the standardized estimate; for indirect
standardization it also includes observed and expected events.

## Examples

``` r
d <- data.frame(events = c(10, 20), pop = c(100, 100), standard = c(150, 50))
epi_standardize(d, events, pop, standard)
#> # A tibble: 1 × 2
#>   method estimate
#>   <chr>     <dbl>
#> 1 direct    0.125
```
