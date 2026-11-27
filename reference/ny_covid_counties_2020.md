# Weekly COVID-19 cases in New York State counties, spring 2020

Weekly confirmed COVID-19 cases for the 62 counties of New York State
over the 13 weeks ending 8 March to 31 May 2020, with 2019 population
and county centroids. `x_km` and `y_km` are centroids on a local
equirectangular projection in kilometers, suitable for the planar scan
statistics at state scale.

## Usage

``` r
ny_covid_counties_2020
```

## Format

A tibble with 62 rows and 20 columns: `county`, `fips`, `population`,
`lon`, `lat`, `x_km`, `y_km`, and weekly case counts `week_0308` to
`week_0531` (named by the week's last day, month and day).

## Source

COVID-19 Data Repository by the Center for Systems Science and
Engineering (CSSE) at Johns Hopkins University,
<https://github.com/CSSEGISandData/COVID-19>, CC BY 4.0. Build script:
`data-raw/ny_covid_counties_2020.R`.

## Examples

``` r
head(ny_covid_counties_2020[, c("county", "population", "week_0405")])
#> # A tibble: 6 × 3
#>   county      population week_0405
#>   <chr>            <int>     <int>
#> 1 Albany          305506       100
#> 2 Allegany         46091        10
#> 3 Bronx          1418207      9046
#> 4 Broome          190488        42
#> 5 Cattaraugus      76117         6
#> 6 Cayuga           76576         6
```
