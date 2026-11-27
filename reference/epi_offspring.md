# Reproduction number and dispersion of secondary cases (superspreading)

`epi_offspring()` fits a negative binomial offspring distribution to the
number of secondary cases caused by each case (from contact tracing),
estimating the reproduction number `R` and the dispersion `k`. Small `k`
(below about 1) means transmission is concentrated in a few
superspreaders (Lloyd-Smith et al. 2005). `prop_80` is the proportion of
cases expected to cause 80% of transmission (Endo et al. 2020).

`epi_chain_size()` estimates the same two quantities from the final
sizes of transmission chains (clusters), each started by one introduced
case, using the chain-size distribution of Blumberg and Lloyd-Smith
(2013). This needs `R` below 1 (chains that died out).

## Usage

``` r
epi_offspring(.data, secondary, conf_level = 0.95)

epi_chain_size(.data, size, conf_level = 0.95)
```

## Arguments

- .data:

  A data frame with one row per case (`epi_offspring()`) or per
  transmission chain (`epi_chain_size()`).

- secondary:

  Number of secondary cases caused by each case.

- conf_level:

  Confidence level (Wald intervals on the log scale).

- size:

  Total number of cases in each chain, including the index case (1 or
  more).

## Value

A one-row tibble with `n`, `r`, `r_lower`, `r_upper`, `k`, `k_lower`,
`k_upper`, `prop_80`, `p_zero` (expected proportion of cases with no
secondary cases), `loglik` and, for `epi_offspring()`, `aic_poisson` and
`aic_negbin` (a smaller negative binomial AIC is evidence of
overdispersion).

## References

Lloyd-Smith, J. O., Schreiber, S. J., Kopp, P. E. and Getz, W. M.
(2005). Superspreading and the effect of individual variation on disease
emergence. Nature, 438, 355-359.
[doi:10.1038/nature04153](https://doi.org/10.1038/nature04153)

Blumberg, S. and Lloyd-Smith, J. O. (2013). Inference of R0 and
transmission heterogeneity from the size distribution of stuttering
chains. PLOS Computational Biology, 9, e1002993.
[doi:10.1371/journal.pcbi.1002993](https://doi.org/10.1371/journal.pcbi.1002993)

Endo, A., Abbott, S., Kucharski, A. J. and Funk, S. (2020). Estimating
the overdispersion in COVID-19 transmission using outbreak sizes outside
China. Wellcome Open Research, 5, 67.
[doi:10.12688/wellcomeopenres.15842.3](https://doi.org/10.12688/wellcomeopenres.15842.3)

## Examples

``` r
set.seed(3)
d <- data.frame(secondary = rnbinom(150, size = 0.3, mu = 1.2))
epi_offspring(d, secondary)
#> # A tibble: 1 × 12
#>       n     r r_lower r_upper     k k_lower k_upper prop_80 p_zero loglik
#>   <int> <dbl>   <dbl>   <dbl> <dbl>   <dbl>   <dbl>   <dbl>  <dbl>  <dbl>
#> 1   150 0.967   0.722    1.29 0.434   0.274   0.688   0.292  0.601  -199.
#> # ℹ 2 more variables: aic_poisson <dbl>, aic_negbin <dbl>

chains <- data.frame(size = c(rep(1, 40), rep(2, 9), rep(3, 4), 5, 8, 21))
epi_chain_size(chains, size)
#> # A tibble: 1 × 10
#>       n     r r_lower r_upper     k k_lower k_upper prop_80 p_zero loglik
#>   <int> <dbl>   <dbl>   <dbl> <dbl>   <dbl>   <dbl>   <dbl>  <dbl>  <dbl>
#> 1    56 0.462   0.312   0.682 0.510   0.118    2.21   0.319  0.720  -60.4
```
