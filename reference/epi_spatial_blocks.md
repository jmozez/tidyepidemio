# Create square spatial blocks

Assigns projected planar coordinates to a fixed square grid of width
`size`. The grid is anchored at (`origin_x`, `origin_y`); indices use
mathematical floor so points immediately west or south of the origin
have index -1. Boundary points belong to the cell on their right or
above. Fixed origins ensure consistent assignments across datasets.
Input is not transformed or projected; latitude/longitude coordinates
must first be converted to an appropriate projected coordinate reference
system by the caller.

## Usage

``` r
epi_spatial_blocks(.data, x, y, size, origin_x = 0, origin_y = 0)
```

## Arguments

- .data:

  A data frame of locations.

- x, y:

  Numeric finite projected coordinate columns.

- size:

  Positive width of each square block.

- origin_x, origin_y:

  Finite numeric coordinates of the grid origin.

## Value

Input tibble with integer `block_x` and `block_y` indices and a
character `block_id` of the form `"x:y"`.

## Details

Blocking alone does not guarantee separation between neighboring train
and assessment observations. Use an appropriate distance buffer with
[`epi_spatial_cv()`](https://tidyepidemio.in4metrix.dev/reference/epi_spatial_cv.md)
if the analysis requires separation. Selection of grid size and origin
should reflect the study's spatial dependence and deployment domain.
Coordinates and grid size share the same units.

## Examples

``` r
d <- data.frame(x = c(-1, 0, 9, 10), y = c(0, 0, 11, 11))
epi_spatial_blocks(d, x, y, size = 10)
#> # A tibble: 4 × 5
#>       x     y block_x block_y block_id
#>   <dbl> <dbl>   <int>   <int> <chr>   
#> 1    -1     0      -1       0 -1:0    
#> 2     0     0       0       0 0:0     
#> 3     9    11       0       1 0:1     
#> 4    10    11       1       1 1:1     
```
