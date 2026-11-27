# Attributable fractions from individual-level risks

Calculates the exposed attributable fraction
`(risk_exposed - risk_unexposed) / risk_exposed` and the population
attributable fraction
`(risk_population - risk_unexposed) / risk_population`. Risk is the
observed binary outcome proportion in each group. The fractions may be
negative when exposure is protective. A zero denominator produces a
missing fraction.

## Usage

``` r
epi_attributable_fraction(.data, exposure, outcome)
```

## Arguments

- .data:

  An ungrouped data frame of individual records.

- exposure:

  Binary 0/1 exposure indicator.

- outcome:

  Binary 0/1 outcome indicator over comparable follow-up.

## Value

One-row tibble containing group and population risks, exposed and
population attributable fractions, and sample size.

## Details

These are unadjusted descriptive contrasts. Interpreting them as the
fraction of outcomes prevented by removing exposure requires
consistency, exchangeability, positivity, comparable follow-up and an
appropriate intervention. These assumptions are not checked; confounding
and selection bias can be important. This function does not estimate
adjusted effects or confidence intervals.

## Examples

``` r
d <- data.frame(e = rep(0:1, each = 4), y = c(0, 0, 0, 1, 0, 1, 1, 1))
epi_attributable_fraction(d, e, y)
#> # A tibble: 1 × 6
#>   risk_unexposed risk_exposed risk_population attributable_fraction_exposed
#>            <dbl>        <dbl>           <dbl>                         <dbl>
#> 1           0.25         0.75             0.5                         0.667
#> # ℹ 2 more variables: population_attributable_fraction <dbl>, n <int>
```
