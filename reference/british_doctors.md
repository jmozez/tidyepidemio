# British Doctors Study: smoking and coronary deaths

Coronary heart disease deaths and person-years among male British
doctors by age group and smoking status over ten years of follow-up, the
classic dataset for Poisson rate-ratio regression.

## Usage

``` r
british_doctors
```

## Format

A tibble with 10 rows and 4 columns:

- age_group:

  Age group in years (factor).

- smoker:

  1 for smokers, 0 for non-smokers.

- deaths:

  Coronary heart disease deaths.

- person_years:

  Person-years of follow-up.

## Source

Doll R, Hill AB (1966). Mortality of British doctors in relation to
smoking: observations on coronary thrombosis. *National Cancer Institute
Monograph* 19:205-268, as tabulated in Breslow NE, Day NE (1987).
*Statistical Methods in Cancer Research, Volume II*. IARC. Build script:
`data-raw/british_doctors.R`.

## Examples

``` r
epi_adjusted_rate_ratio(british_doctors, deaths, person_years, smoker, adjust = age_group)
#> # A tibble: 1 × 8
#>   measure          estimate conf_low conf_high     n events se_type adjusted_for
#>   <chr>               <dbl>    <dbl>     <dbl> <int>  <int> <chr>   <chr>       
#> 1 adjusted_rate_r…     1.43     1.15      1.76    10    731 model   age_group   
```
