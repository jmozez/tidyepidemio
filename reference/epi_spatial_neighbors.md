# Count neighboring locations within a distance

Computes pairwise Euclidean distances for projected planar coordinates;
it does not handle longitude/latitude, edge correction, statistical
inference, clustering, or area-level disease risk. Distances and radius
must share units. Self-neighbors are excluded, but distinct rows at the
same coordinates count as neighbors. Runtime and memory scale
quadratically with row count.

## Usage

``` r
epi_spatial_neighbors(.data, x, y, radius)
```

## Arguments

- .data:

  A data frame of locations.

- x, y:

  Numeric projected coordinates, without missing values.

- radius:

  Non-negative distance threshold in coordinate units.

## Value

Input tibble with an integer `neighbors` column.

## Examples

``` r
epi_spatial_neighbors(data.frame(x = c(0, 1, 5), y = c(0, 0, 0)), x, y, radius = 1)
#> # A tibble: 3 × 3
#>       x     y neighbors
#>   <dbl> <dbl>     <int>
#> 1     0     0         1
#> 2     1     0         1
#> 3     5     0         0
```
