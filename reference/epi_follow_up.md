# Derive cohort follow-up and administrative censoring

Computes observed follow-up from entry and exit dates, with an optional
administrative censoring date. If the original exit is after
`censor_at`, follow-up ends at the censoring date and the event
indicator becomes zero. An event on the censoring date is retained. A
subject entering after the censoring date is rejected rather than
silently discarded; zero-day follow-up is allowed. Each row is assumed
to represent one distinct subject.

## Usage

``` r
epi_follow_up(
  .data,
  entry,
  exit,
  event,
  censor_at = NULL,
  unit = c("days", "years")
)
```

## Arguments

- .data:

  An ungrouped data frame, one row per subject.

- entry, exit:

  Complete whole-day Date columns of entry and observed exit.

- event:

  Binary event indicator, 1 if the event occurred at the exit date and 0
  if exit was already censoring.

- censor_at:

  Optional single whole-day Date for administrative censoring.

- unit:

  Either `"days"` or `"years"`; years are calculated using 365.25 days.

## Value

Input tibble with `followup_end` (Date), `follow_up` (numeric time in
selected units), and binary `event_observed` columns.

## Details

This helper does not infer event dates from the record or handle
recurrent events, competing risks, delayed reporting, loss-to-follow-up
mechanisms, time-varying covariates or causal assumptions. A year is a
fixed `365.25` days, not a calendar-year calculation. Censoring must be
appropriately handled in the downstream analysis.

## Examples

``` r
d <- data.frame(
  start = as.Date("2024-01-01") + c(0, 1),
  end = as.Date("2024-01-01") + c(5, 10), event = c(1, 1)
)
epi_follow_up(d, start, end, event, censor_at = as.Date("2024-01-08"))
#> # A tibble: 2 × 6
#>   start      end        event followup_end follow_up event_observed
#>   <date>     <date>     <dbl> <date>           <dbl>          <dbl>
#> 1 2024-01-01 2024-01-06     1 2024-01-06           5              1
#> 2 2024-01-02 2024-01-11     1 2024-01-08           6              0
```
