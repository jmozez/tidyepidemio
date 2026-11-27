# Create epidemiological tibble subclasses

Classes label input data; they do not validate a clinical schema.
Metadata is a uniquely named list and is restored after compatible
row-preserving dplyr operations. Row-binding a plain table to an
epidemiological table is rejected: assign the appropriate class and
metadata explicitly before combining. Grouped row-preserving operations
also retain metadata and class. Summarise and group_modify can drop them
because arbitrary aggregates need not represent individual-level
epidemiological tables. Rowwise conversion is not supported for metadata
preservation. Joins retain left-hand metadata only.

## Usage

``` r
epi_linelist(.data, metadata = list())

epi_cohort(.data, metadata = list())

epi_ts(.data, metadata = list())
```

## Arguments

- .data:

  A data frame.

- metadata:

  A named list of descriptive metadata.

## Value

A tibble subclass with an `epi_metadata` attribute.

## Examples

``` r
x <- epi_linelist(data.frame(case = 1:3), metadata = list(source = "clinic"))
x[1:2, ]
#> # A tibble: 2 × 1
#>    case
#>   <int>
#> 1     1
#> 2     2
epi_cohort(data.frame(id = 1:3))
#> # A tibble: 3 × 1
#>      id
#>   <int>
#> 1     1
#> 2     2
#> 3     3
epi_ts(data.frame(time = 1:3, cases = c(1, 2, 3)))
#> # A tibble: 3 × 2
#>    time cases
#>   <int> <dbl>
#> 1     1     1
#> 2     2     2
#> 3     3     3
```
