# Bake epidemiological recipe features with explicit history

Prep a recipe on training data first. This helper prepends the supplied
raw history to the new data, bakes the combined series, and returns only
the new rows. This allows the package's lag, rolling and exposure steps
to see prior rows at the training/assessment boundary. The helper
accepts only a trained recipe whose steps are
[`step_epi_lags()`](https://tidyepidemio.in4metrix.dev/reference/step_epi_lags.md),
[`step_epi_rolling()`](https://tidyepidemio.in4metrix.dev/reference/step_epi_lags.md),
[`step_epi_rates()`](https://tidyepidemio.in4metrix.dev/reference/step_epi_lags.md),
or
[`step_epi_exposure_window()`](https://tidyepidemio.in4metrix.dev/reference/step_epi_lags.md),
with `skip = FALSE`. Other recipe steps are rejected because arbitrary
steps may alter row order or have different semantics when history is
prepended. The two data frames must have identical column names,
represent a single time series, and be strictly sorted; all history
times must precede all new times. Time units need not be equally spaced,
but lag and window sizes count rows, not elapsed time. The caller must
provide enough raw history for all chained steps.

## Usage

``` r
epi_bake_history(.data, recipe, history, time)
```

## Arguments

- .data:

  An ungrouped, non-empty data frame of new rows for one series.

- recipe:

  A prepped `recipes` recipe containing only the supported steps.

- history:

  An ungrouped, non-empty data frame of earlier raw observations with
  the same columns as `.data`.

- time:

  A single numeric or whole-day Date time column, present in both
  datasets and strictly increasing within each.

## Value

A tibble containing only the baked new rows.

## Details

This does not alter or store history in a recipe. The recipe must have
been prepped without access to future data.
[`step_epi_rolling()`](https://tidyepidemio.in4metrix.dev/reference/step_epi_lags.md)
and
[`step_epi_exposure_window()`](https://tidyepidemio.in4metrix.dev/reference/step_epi_lags.md)
include the current row; they leak information if applied to a target
value unavailable at prediction time. Later new rows can also use
earlier new-row observations, so a multi-step forecast made all at once
must not supply outcomes that would not yet be observed. For grouped
series call separately for each group. Row identity is verified through
validation of supported steps and the baked row count.

## Examples

``` r
d <- data.frame(day = 1:6, cases = 1:6)
rec <- recipes::recipe(~., data = d[1:4, ]) |> step_epi_lags(cases, lag = 1)
prepped <- recipes::prep(rec)
epi_bake_history(d[5:6, ], prepped, history = d[1:4, ], time = day)
#> # A tibble: 2 × 3
#>     day cases lag1_cases
#>   <int> <int>      <int>
#> 1     5     5          4
#> 2     6     6          5
```
