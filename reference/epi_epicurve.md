# Aggregate an epidemic curve

Counts one case per input row by onset date, optionally stratified by a
grouping column, and fills absent bins with zero. Weekly bins start on
Monday; daily bins start on the onset date. When `start` and `end` are
supplied they must enclose every observed onset date, preventing silent
case loss. Bounds are inclusive and weekly bounds are rounded down to
their bin's Monday. The function does not distinguish dates of onset
from specimen or report dates, correct incomplete ascertainment, or
insert unknown-onset cases.

## Usage

``` r
epi_epicurve(
  .data,
  onset,
  group = NULL,
  interval = c("day", "week"),
  start = NULL,
  end = NULL
)
```

## Arguments

- .data:

  An ungrouped data frame with one row per case.

- onset:

  Non-missing Date column of case onset dates.

- group:

  Optional complete character, factor, logical or numeric group column.
  Defaults to a single group named `"All"`.

- interval:

  Either `"day"` or `"week"`.

- start, end:

  Optional single Date bounds, defaulting to the earliest and latest
  observed onset date.

## Value

A tibble with `group`, bin-start `date`, and integer `cases`, ordered by
first appearance of group and ascending date. Empty bins are zero.

## Examples

``` r
d <- data.frame(onset = as.Date("2024-01-01") + c(0, 0, 2), region = c("a", "b", "a"))
epi_epicurve(d, onset, group = region)
#> # A tibble: 6 × 3
#>   group date       cases
#>   <chr> <date>     <int>
#> 1 a     2024-01-01     1
#> 2 a     2024-01-02     0
#> 3 a     2024-01-03     1
#> 4 b     2024-01-01     1
#> 5 b     2024-01-02     0
#> 6 b     2024-01-03     0
```
