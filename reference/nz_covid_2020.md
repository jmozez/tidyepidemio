# Daily COVID-19 cases in New Zealand, first wave 2020

Daily confirmed COVID-19 cases in New Zealand from 26 February to 30
June 2020, covering the first wave and its elimination after a national
lockdown from 26 March. Daily counts are differences of the cumulative
series (negative corrections set to zero).

## Usage

``` r
nz_covid_2020
```

## Format

A tibble with 126 rows and 2 columns:

- date:

  Report date.

- cases:

  Newly confirmed cases.

## Source

COVID-19 Data Repository by the Center for Systems Science and
Engineering (CSSE) at Johns Hopkins University,
<https://github.com/CSSEGISandData/COVID-19>, CC BY 4.0. Dong E, Du H,
Gardner L (2020). An interactive web-based dashboard to track COVID-19
in real time. *Lancet Infectious Diseases* 20(5):533-534. Build script:
`data-raw/nz_covid_2020.R`.

## Examples

``` r
pre <- subset(nz_covid_2020, cases > 0 &
  date >= as.Date("2020-03-15") & date <= as.Date("2020-03-28"))
pre$day <- as.numeric(pre$date - min(pre$date))
epi_doubling_time(pre, day, cases)
#> # A tibble: 1 × 3
#>   growth_rate     n doubling_time
#>         <dbl> <int>         <dbl>
#> 1       0.300    12          2.31
```
