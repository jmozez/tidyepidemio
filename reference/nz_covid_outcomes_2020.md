# Daily COVID-19 cases and deaths in New Zealand, first wave 2020

Daily confirmed COVID-19 cases and deaths in New Zealand from 26
February to 30 June 2020, the same period as
[nz_covid_2020](https://tidyepidemio.in4metrix.dev/reference/nz_covid_2020.md),
for case fatality analyses with
[`epi_cfr()`](https://tidyepidemio.in4metrix.dev/reference/epi_cfr.md).
Daily counts are differences of the cumulative series (negative
corrections set to zero). Deaths in this source were mostly added once a
week, so use them cumulatively rather than day by day.

## Usage

``` r
nz_covid_outcomes_2020
```

## Format

A tibble with 126 rows and 3 columns:

- date:

  Report date.

- cases:

  Newly confirmed cases.

- deaths:

  Newly reported deaths.

## Source

COVID-19 Data Repository by the Center for Systems Science and
Engineering (CSSE) at Johns Hopkins University,
<https://github.com/CSSEGISandData/COVID-19>, CC BY 4.0. Dong E, Du H,
Gardner L (2020). An interactive web-based dashboard to track COVID-19
in real time. *Lancet Infectious Diseases* 20(5):533-534. Build script:
`data-raw/nz_covid_outcomes_2020.R`.

## Examples

``` r
colSums(nz_covid_outcomes_2020[c("cases", "deaths")])
#>  cases deaths 
#>   1530     23 
```
