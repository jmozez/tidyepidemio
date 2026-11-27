# Epidemiological frequency measures

Functions operate on complete records, rejecting missing and invalid
inputs. Incidence and attack rate are cumulative proportions; prevalence
is a point prevalence. Person-time rates use the units supplied by the
caller.

## Usage

``` r
epi_incidence(.data, event, multiplier = 1)

epi_prevalence(.data, case, multiplier = 1)

epi_attack_rate(.data, event, multiplier = 1)

epi_person_time(.data, event, time, multiplier = 1)
```

## Arguments

- .data:

  A data frame, with one row per individual.

- event:

  A 0/1 event indicator.

- multiplier:

  A positive scale factor; for example 1000 for per 1000.

- case:

  A 0/1 indicator of existing disease.

- time:

  Non-negative follow-up time per person.

## Value

A one-row tibble with numerator, denominator, and estimate.

## Examples

``` r
d <- data.frame(event = c(1, 0, 1), time = c(1, 2, 3))
epi_incidence(d, event)
#> # A tibble: 1 × 3
#>   events population estimate
#>    <dbl>      <int>    <dbl>
#> 1      2          3    0.667
epi_prevalence(d, event)
#> # A tibble: 1 × 3
#>   cases population estimate
#>   <dbl>      <int>    <dbl>
#> 1     2          3    0.667
epi_attack_rate(d, event, multiplier = 100)
#> # A tibble: 1 × 3
#>   events population estimate
#>    <dbl>      <int>    <dbl>
#> 1      2          3     66.7
epi_person_time(d, event, time, multiplier = 100)
#> # A tibble: 1 × 3
#>   events person_time estimate
#>    <dbl>       <dbl>    <dbl>
#> 1      2           6     33.3
```
