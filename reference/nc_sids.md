# Sudden infant death syndrome in North Carolina counties

SIDS deaths and live births in the 100 counties of North Carolina for
1974-78 and 1979-84, with county centroids in projected UTM (zone 17)
kilometers. The standard benchmark for disease-cluster detection.

## Usage

``` r
nc_sids
```

## Format

A tibble with 100 rows and 10 columns: `county`, `x_km`, `y_km`, `lon`,
`lat`, `births_1974`, `sids_1974`, `births_1979`, `sids_1979`,
`nonwhite_births_1974`.

## Source

`spData::nc.sids` (CC0), from Cressie N, Chan NH (1989). Spatial
modeling of regional variables. *Journal of the American Statistical
Association* 84:393-401. Build script: `data-raw/nc_sids.R`.

## Examples

``` r
epi_spatial_scan(nc_sids, x_km, y_km, sids_1974, births_1974,
  radii = c(30, 60), nsim = 99
)
#> # A tibble: 1 × 11
#>   center_x center_y radius observed expected population relative_risk
#>      <dbl>    <dbl>  <dbl>    <dbl>    <dbl>      <dbl>         <dbl>
#> 1     161.    3802.     60       54     26.3      13021          2.14
#> # ℹ 4 more variables: log_likelihood_ratio <dbl>, p_value <dbl>,
#> #   simulations <int>, candidates <int>
```
