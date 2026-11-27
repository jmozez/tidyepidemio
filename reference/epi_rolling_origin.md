# Rolling-origin resampling

Builds non-overlapping rolling splits. The data must already be ordered
by time; rows are not sorted and the optional lag introduces a gap
between analysis and assessment sets.

## Usage

``` r
epi_rolling_origin(
  .data,
  initial = 5,
  assess = 1,
  cumulative = TRUE,
  skip = 0,
  lag = 0
)
```

## Arguments

- .data:

  A chronologically sorted data frame.

- initial:

  Number of rows in the initial analysis set.

- assess:

  Number of rows in each assessment set.

- cumulative:

  Whether to use an expanding analysis window.

- skip:

  Number of resamples to skip between retained resamples.

- lag:

  Number of gap rows before each assessment set.

## Value

An `rset` of rolling splits.

## Examples

``` r
epi_rolling_origin(data.frame(day = 1:10), initial = 5, assess = 2)
#> # Manual resampling 
#> # A tibble: 4 × 2
#>   splits        id    
#>   <list>        <chr> 
#> 1 <split [5/2]> Slice1
#> 2 <split [6/2]> Slice2
#> 3 <split [7/2]> Slice3
#> 4 <split [8/2]> Slice4
```
