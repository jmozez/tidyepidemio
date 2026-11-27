# Past-only temporal features with explicit history

Creates row-lag and past-window-mean features for numeric columns in
`.data`. Optional `history` supplies earlier observations for the same
groups and is used only as context; history rows are not returned. For
each row, the lag is the value `lag` rows earlier, and the rolling mean
uses the `window` rows immediately before the row, excluding the current
value. Incomplete history or any missing value in the rolling window
yields `NA`. Features are based on **rows**, not elapsed duration; no
regular time spacing is inferred or filled.

## Usage

``` r
epi_temporal_features(
  .data,
  ...,
  time,
  group = NULL,
  history = NULL,
  lag = 1L,
  window = 7L
)
```

## Arguments

- .data:

  An ungrouped data frame of new observations in time order within each
  group.

- ...:

  Tidy selection of one or more numeric feature columns.

- time:

  A single numeric or Date time column, strictly increasing within each
  group in both `.data` and `history`.

- group:

  Optional complete character, factor, logical, or numeric group column.
  With no group all rows form a single series.

- history:

  Optional earlier data frame containing the selected features, time,
  and group columns with compatible types.

- lag:

  Positive integer number of preceding rows to lag.

- window:

  Positive integer number of preceding rows in the rolling mean.

## Value

Input tibble in original order with `lag{lag}_<column>` and
`past_mean{window}_<column>` columns. Existing output names are
rejected.

## Details

Within each group, time must be strictly increasing in both input
datasets, and all matched history times must precede all `.data` times.
Groups may be interleaved; output preserves `.data` order. History for
groups absent from `.data` is ignored. `time` is numeric or a whole-day
Date, with the same kind in both datasets. Missing feature values are
permitted and propagated.

This helper is outside `recipes`: it does not change the existing recipe
steps' history behavior. For sequential one-step-ahead scoring it may
use earlier observed values within `.data`. For a multi-step forecast
made all at once, those later outcomes are not yet known; supplying them
would leak future information. Supply only values actually available at
each prediction time.

## Examples

``` r
history <- data.frame(day = 1:3, cases = c(1, 2, 3))
new <- data.frame(day = 4:5, cases = c(4, 5))
epi_temporal_features(new, cases, time = day, history = history, lag = 1, window = 2)
#> # A tibble: 2 × 4
#>     day cases lag1_cases past_mean2_cases
#>   <int> <dbl>      <dbl>            <dbl>
#> 1     4     4          3              2.5
#> 2     5     5          4              3.5
```
