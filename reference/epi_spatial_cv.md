# Group-blocked cross-validation

Assigns precomputed spatial block labels to folds. All rows in a block
stay together. Optionally exclude analysis observations within a
Euclidean distance of any assessment observation; this uses planar
coordinates and does not buffer polygon boundaries. Supply projected
coordinates, not longitude/latitude. Random block assignment is
reproducible with [`set.seed()`](https://rdrr.io/r/base/Random.html).
Block sizes may differ, and buffering can substantially reduce analysis
data.

## Usage

``` r
epi_spatial_cv(.data, block, v = 5L, x = NULL, y = NULL, buffer = 0)
```

## Arguments

- .data:

  A data frame.

- block:

  A non-missing column of spatial block labels.

- v:

  Number of folds, at least 2 and no larger than the number of blocks.

- x, y:

  Optional projected coordinate columns, both required for buffering.

- buffer:

  Non-negative distance in coordinate units. A positive value excludes
  analysis rows at or within that distance of assessment rows.

## Value

An rsample `rset` with analysis and assessment splits.

## Examples

``` r
d <- data.frame(block = rep(1:4, each = 2), value = 1:8)
set.seed(1)
epi_spatial_cv(d, block, v = 2)
#> # Manual resampling 
#> # A tibble: 2 × 2
#>   splits        id   
#>   <list>        <chr>
#> 1 <split [4/4]> Fold1
#> 2 <split [4/4]> Fold2
```
