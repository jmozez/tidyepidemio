# Number needed to treat or harm

Compares a binary adverse outcome in treated and untreated groups over
the same follow-up. A lower treated risk gives number needed to treat
(NNT); a higher treated risk gives number needed to harm (NNH). The
absolute risk reduction is `risk_untreated - risk_treated`; the reported
number is its reciprocal magnitude, rounded up to a whole person.
Identical risks return `NA` rather than infinity and
`type = "no_difference"`.

## Usage

``` r
epi_number_needed(.data, treatment, outcome)
```

## Arguments

- .data:

  An ungrouped data frame of individual records.

- treatment:

  Binary treatment indicator; 1 denotes treated.

- outcome:

  Binary adverse outcome indicator; 1 denotes an adverse event.

## Value

A one-row tibble with risks, absolute risk reduction, `type`, and the
rounded-up `number_needed`.

## Details

This is an unadjusted descriptive contrast, not a randomized treatment
effect unless justified by study design and assumptions. NNT/NNH depends
on outcome definition, baseline risk and follow-up duration. This
function does not calculate confidence intervals; inversion of intervals
crossing zero requires careful interpretation and is not a single
conventional finite interval.

## Examples

``` r
d <- data.frame(treated = rep(0:1, each = 4), adverse = c(1, 1, 0, 0, 1, 0, 0, 0))
epi_number_needed(d, treated, adverse)
#> # A tibble: 1 × 7
#>   risk_untreated risk_treated absolute_risk_reduction type  number_needed
#>            <dbl>        <dbl>                   <dbl> <chr>         <dbl>
#> 1            0.5         0.25                    0.25 NNT               4
#> # ℹ 2 more variables: n_untreated <dbl>, n_treated <dbl>
```
