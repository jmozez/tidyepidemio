# Plot epidemiological data and results

`epi_ts` plots pre-aggregated `time` and `cases` columns, or `time` and
`rt` for `type = "rt"`. The Rt plot also accepts `rt_mean`, `rt_low`,
and `rt_high` as produced by
[`epi_rt_gamma()`](https://tidyepidemio.in4metrix.dev/reference/epi_rt_gamma.md).
`epi_linelist` bins a Date column named `onset` by day. `epi_cohort`
draws Lexis line segments from numeric `start_time`, `end_time`, and
`start_age` in the same units. Association results use forest plots.
Data are not completed for missing dates. Confidence intervals, when
present, are shown on a linear scale. See method documentation for
object schemas.

## Usage

``` r
# S3 method for class 'epi_ts'
autoplot(object, type = c("cases", "rt"), ...)

# S3 method for class 'epi_linelist'
autoplot(object, ...)

# S3 method for class 'epi_cohort'
autoplot(object, ...)

# S3 method for class 'epi_result'
autoplot(object, ...)
```

## Arguments

- object:

  An epidemiological tibble or association result.

- type:

  For `epi_ts`, either `"cases"` or `"rt"`.

- ...:

  Unused.

## Value

A ggplot object.

## Examples

``` r
x <- epi_ts(data.frame(time = 1:4, cases = c(2, 4, 3, 1)))
ggplot2::autoplot(x)

ggplot2::autoplot(epi_linelist(data.frame(onset = as.Date("2024-01-01") + 0:2)))
```
